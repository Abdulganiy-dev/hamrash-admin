-- 35 · Give a staff member on the app a second role, with no new code
--
-- A principal who also teaches needs two memberships at the same school:
-- one row per (school, person, role), as migration 01 designed. Until now the
-- only way to get a second row was a fresh invite and claim code, which the
-- person already on the app would have to redeem themselves. (TODO.md: "Extra
-- roles for one staff member".)
--
-- add_member_role(p_member_id, p_role) copies an ACTIVE membership into a new
-- ACTIVE row for the same person and school with another role: same
-- organization_id, clerk_user_id and joined_at, status active, no claim code,
-- invited_by = the caller. staff.member_id is not touched; it keeps pointing
-- at the row it already had.
--
-- Who (the invite tiers of migration 17, for school members only):
--   * owners and admins: admin, principal, vice principal, bursar, teacher,
--     staff;
--   * principals and vice principals: principal, vice principal, bursar,
--     teacher, staff;
--   * nobody can add owner (that stays with Hamrash and the owner guard);
--   * the caller must be an active leader of the source row's school. Hamrash
--     platform admins are not school members and are not let through here.
--
-- Readable refusals, all checked before the insert:
--   * the role is owner                         → 42501
--   * the role isn't a staff role               → 22023
--   * the member row isn't in a school where the caller may add that role
--     (also a row in another school)            → 42501
--   * the source row isn't a staff login        → P0001
--   * the source row is still an invite         → P0001
--   * the source row is suspended               → P0001
--   * the person's staff record has left        → P0001
--   * they already hold the role (active)       → P0001
--   * they already hold it, but it's suspended  → P0001 (restore it instead)
-- A concurrent duplicate that slips past the check hits
-- organization_members_one_role_per_user and is re-raised as the same P0001
-- message. P0001 messages reach the app as written (runRefusable).
--
-- Security: security definer, search_path = ''. The client insert policy only
-- allows status = 'invited' and the column grants keep clerk_user_id and
-- status out of client hands, so the active row can only be written here.
-- Every check above runs before that write. The owner guard trigger is
-- update/delete only and owner is refused outright, so it doesn't apply.
--
-- No DROP: a new function.
-- Test: supabase/tests/22_add_member_role_test.sql
-- Design notes: docs/organization-schema.md (organization_members)

-- ─────────────────────────────────────────────────────────────
-- add_member_role
-- ─────────────────────────────────────────────────────────────
-- Returns the new organization_members row.
create function public.add_member_role(
  p_member_id uuid,
  p_role      public.member_role
)
returns public.organization_members
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_sub      text := (select auth.jwt() ->> 'sub');
  v_staff    constant public.member_role[] := array['owner', 'admin', 'principal', 'vice_principal', 'bursar', 'teacher', 'staff']::public.member_role[];
  v_source   public.organization_members;
  v_existing public.organization_members;
  v_label    text := replace(p_role::text, '_', ' ');
  v_member   public.organization_members;
begin
  if v_sub is null or v_sub = '' then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  -- ── the role ────────────────────────────────────────────────
  if p_role is null then
    raise exception 'Choose a role to add' using errcode = '22023';
  end if;
  if p_role = 'owner' then
    raise exception 'The owner role can''t be added this way' using errcode = '42501';
  end if;
  if p_role not in ('admin', 'principal', 'vice_principal', 'bursar', 'teacher', 'staff') then
    raise exception 'A staff member can be given admin, principal, vice principal, bursar, teacher or staff' using errcode = '22023';
  end if;

  -- ── who, and the source row ─────────────────────────────────
  -- Owners and admins: any of the roles above. Principals and VPs: up to their
  -- own level (migration 17). A row in another school is "not found".
  select m.* into v_source
  from public.organization_members m
  where m.id = p_member_id
    and (
      m.organization_id in (select private.my_org_ids(array['owner', 'admin']::public.member_role[]))
      or (p_role in ('principal', 'vice_principal', 'bursar', 'teacher', 'staff')
          and m.organization_id in (select private.my_org_ids(array['principal', 'vice_principal']::public.member_role[])))
    )
  for update;
  if not found then
    raise exception 'Member not found, or you can''t add that role at this school' using errcode = '42501';
  end if;

  if v_source.role <> all (v_staff) then
    raise exception 'Only staff on the app can be given another staff role' using errcode = 'P0001';
  end if;
  if v_source.status = 'invited' or v_source.clerk_user_id is null then
    raise exception 'This person isn''t on the app yet. They need to join with their code before they can get another role'
      using errcode = 'P0001';
  end if;
  if v_source.status <> 'active' then
    raise exception 'This person''s access is suspended. Restore their access before giving them another role'
      using errcode = 'P0001';
  end if;

  if exists (
    select 1
    from public.staff s
    join public.organization_members m on m.id = s.member_id
    where m.organization_id = v_source.organization_id
      and m.clerk_user_id   = v_source.clerk_user_id
      and s.status = 'exited'
  ) then
    raise exception 'This staff member has left the school' using errcode = 'P0001';
  end if;

  -- ── already holds it ────────────────────────────────────────
  select m.* into v_existing
  from public.organization_members m
  where m.organization_id = v_source.organization_id
    and m.clerk_user_id   = v_source.clerk_user_id
    and m.role            = p_role;
  if found then
    if v_existing.status = 'active' then
      raise exception 'They already have the % role at this school', v_label using errcode = 'P0001';
    end if;
    raise exception 'They already have the % role, but it''s suspended. Restore their access instead', v_label
      using errcode = 'P0001';
  end if;

  -- ── the new membership ──────────────────────────────────────
  begin
    insert into public.organization_members (organization_id, clerk_user_id, role, status, joined_at, invited_by)
    values (v_source.organization_id, v_source.clerk_user_id, p_role, 'active', v_source.joined_at, v_sub)
    returning * into v_member;
  exception
    when unique_violation then
      raise exception 'They already have the % role at this school', v_label using errcode = 'P0001';
  end;

  return v_member;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- Privileges (this project's defaults grant EXECUTE to anon on new functions)
-- ─────────────────────────────────────────────────────────────
revoke execute on function public.add_member_role(uuid, public.member_role) from public, anon;
grant  execute on function public.add_member_role(uuid, public.member_role) to authenticated;
