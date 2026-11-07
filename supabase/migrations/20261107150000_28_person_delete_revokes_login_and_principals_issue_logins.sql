-- 28 · Deleting a person revokes their login; principals and VPs issue logins
--
-- Two gaps found by the handbook audit (docs/handbook → Known gaps):
--
-- 1. Deleting a staff, student or parent record left its organization_members
--    row untouched, so the person kept school access with no record behind it.
--    Now, after the record is deleted:
--      * an unclaimed invite is deleted (its code stops working);
--      * an active or suspended login is suspended.
--    An active owner's staff record can't be deleted: the owner would keep
--    full access with no record, and suspending them could leave the school
--    with no owner. Change the owner first.
--
-- 2. Migration 17 lets principals and vice principals invite the team
--    (principal, VP, bursar, teacher, staff), but invite_staff only allowed
--    owners and admins, and it is the only way to link an invite to a staff
--    record. invite_staff now follows the same tiers as the insert policy.
--    invite_student and invite_parent stay owner/admin only, as in migration 17.
--
-- No DROP: functions keep their signatures.
-- Test: supabase/tests/17_person_delete_and_principal_logins_test.sql

-- ─────────────────────────────────────────────────────────────
-- 1. Deleting a person record revokes the login it was linked to
-- ─────────────────────────────────────────────────────────────
-- AFTER DELETE, so the person row is already gone and the member row can be
-- deleted or updated without fighting the ON DELETE SET NULL link.
-- security definer: owners and admins may delete people but the member row
-- change must not depend on member policies. The owner guard trigger skips
-- definer code, so the last-owner rule is checked here instead.
create function private.revoke_login_of_deleted_person()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member public.organization_members;
begin
  if old.member_id is null then
    return old;
  end if;

  select m.* into v_member
  from public.organization_members m
  where m.id = old.member_id
  for update;

  if not found then
    return old;
  end if;

  if v_member.role = 'owner' and v_member.status = 'active' then
    raise exception 'This is an owner''s staff record. Make someone else the owner, or suspend this owner, before removing it.'
      using errcode = 'P0001';
  end if;

  if v_member.status = 'invited' then
    delete from public.organization_members m where m.id = v_member.id;
  elsif v_member.status = 'active' then
    update public.organization_members m set status = 'suspended' where m.id = v_member.id;
  end if;

  return old;
end;
$$;

create trigger staff_revoke_login
  after delete on public.staff
  for each row execute function private.revoke_login_of_deleted_person();

create trigger students_revoke_login
  after delete on public.students
  for each row execute function private.revoke_login_of_deleted_person();

create trigger parents_revoke_login
  after delete on public.parents
  for each row execute function private.revoke_login_of_deleted_person();

revoke execute on function private.revoke_login_of_deleted_person() from public, anon, authenticated;

-- ─────────────────────────────────────────────────────────────
-- 2. Who may issue a login for a given role
-- ─────────────────────────────────────────────────────────────
-- Owners and admins: any role except owner (the role lists below never
-- include owner). Principals and VPs: principal, VP, bursar, teacher, staff,
-- matching the organization_members insert policy (migration 17).
-- Hamrash platform admins: any.
create function private.can_issue_login_for(p_organization_id uuid, p_role public.member_role)
returns boolean
language sql
stable
set search_path = ''
as $$
  select private.can_issue_logins(p_organization_id)
      or (
        p_role in ('principal', 'vice_principal', 'bursar', 'teacher', 'staff')
        and p_organization_id in (
          select private.my_org_ids(array['principal', 'vice_principal']::public.member_role[])
        )
      );
$$;

revoke execute on function private.can_issue_login_for(uuid, public.member_role) from public, anon, authenticated;

-- ensure_invite: checks the role being issued, and the role of an existing
-- invite it would change, so a principal can't reissue an admin's invite.
create or replace function private.ensure_invite(
  p_organization_id uuid,
  p_member_id       uuid,
  p_role            public.member_role
)
returns public.organization_members
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member public.organization_members;
begin
  if not private.can_issue_login_for(p_organization_id, p_role) then
    raise exception 'You can''t issue a login for that role' using errcode = '42501';
  end if;

  if p_member_id is not null then
    select m.* into v_member
    from public.organization_members m
    where m.id = p_member_id
    for update;

    if v_member.status <> 'invited' then
      raise exception 'This person already has a login' using errcode = 'P0001';
    end if;

    if not private.can_issue_login_for(p_organization_id, v_member.role) then
      raise exception 'You can''t change this person''s invite' using errcode = '42501';
    end if;

    if v_member.role <> p_role then
      update public.organization_members m
      set role = p_role
      where m.id = v_member.id
      returning m.* into v_member;
    end if;

    return v_member;
  end if;

  insert into public.organization_members (organization_id, role, invited_by)
  values (p_organization_id, p_role, (select auth.jwt() ->> 'sub'))
  returning * into v_member;

  return v_member;
end;
$$;

-- invite_staff: the record is visible to anyone who may issue some staff
-- login there; ensure_invite then checks the specific role.
create or replace function public.invite_staff(p_staff_id uuid, p_role public.member_role default 'teacher')
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_staff  public.staff;
  v_member public.organization_members;
begin
  if p_role not in ('admin', 'principal', 'vice_principal', 'bursar', 'teacher', 'staff') then
    raise exception 'Staff can be invited as admin, principal, vice principal, bursar, teacher or staff' using errcode = '22023';
  end if;

  select s.* into v_staff
  from public.staff s
  where s.id = p_staff_id
    and private.can_issue_login_for(s.organization_id, p_role)
  for update;
  if not found then
    raise exception 'Staff record not found, or you can''t issue that login for it' using errcode = '42501';
  end if;
  if v_staff.status = 'exited' then
    raise exception 'This staff member has left the school' using errcode = 'P0001';
  end if;

  v_member := private.ensure_invite(v_staff.organization_id, v_staff.member_id, p_role);

  update public.staff s
  set member_id = v_member.id
  where s.id = v_staff.id
    and s.member_id is distinct from v_member.id;

  return v_member.claim_code;
end;
$$;
