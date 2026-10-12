-- 11 · The owner gets a staff record when they redeem their claim code
--
-- create_organization only makes the owner's membership, so the owner had no
-- staff record: no staff number, not in the staff list. Now, when an owner code
-- is redeemed, redeem_claim_code creates the owner's staff record (job title
-- 'Owner', non-teaching) and links it to the membership. The owner edits it
-- like any other staff record.
--
-- redeem_claim_code takes the name, email and phone for that record; the app
-- fills them from the Clerk profile. The name is required only for owner codes
-- when the caller has no staff record at the school yet. Every other code was
-- issued against an existing record by invite_staff / invite_student /
-- invite_parent, so nothing changes for those.
--
-- Contains DROP FUNCTION (the signature changes), so the Supabase connector
-- won't run it: apply it in the SQL editor and record it in
-- supabase_migrations.schema_migrations.
-- Design notes: docs/organization-schema.md

drop function public.redeem_claim_code(text);

create function public.redeem_claim_code(
  p_code       text,
  p_first_name text default null,
  p_last_name  text default null,
  p_email      text default null,
  p_phone      text default null
)
returns public.organization_members
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_sub         text := (select auth.jwt() ->> 'sub');
  v_member      public.organization_members;
  v_needs_staff boolean;
begin
  if v_sub is null or v_sub = '' then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  select m.* into v_member
  from public.organization_members m
  where m.claim_code = upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g'))
    and m.status = 'invited'
  for update;

  if not found then
    raise exception 'This code is invalid or has already been used' using errcode = 'P0001';
  end if;

  if not exists (
    select 1 from public.organizations o
    where o.id = v_member.organization_id
      and o.status in ('trial', 'active')
  ) then
    raise exception 'This school is not currently active' using errcode = 'P0001';
  end if;

  -- An owner needs a staff record unless this invite already has one, or the
  -- caller already has one at this school through another role.
  v_needs_staff := v_member.role = 'owner'
    and not exists (select 1 from public.staff s where s.member_id = v_member.id)
    and not exists (
      select 1
      from public.staff s
      join public.organization_members m on m.id = s.member_id
      where s.organization_id = v_member.organization_id
        and m.clerk_user_id = v_sub
    );

  -- checked before anything changes, so the code still works on retry
  if v_needs_staff
     and (nullif(trim(p_first_name), '') is null or nullif(trim(p_last_name), '') is null) then
    raise exception 'Enter your first and last name to finish setting up your school' using errcode = '22023';
  end if;

  begin
    update public.organization_members m
    set clerk_user_id = v_sub,
        status        = 'active',
        claim_code    = null,
        joined_at     = now()
    where m.id = v_member.id
    returning m.* into v_member;
  exception
    when unique_violation then
      raise exception 'You already have this role at this school' using errcode = 'P0001';
  end;

  -- staff number and the staff_private_details row come from the staff triggers
  if v_needs_staff then
    insert into public.staff (organization_id, member_id, first_name, last_name, email, phone, job_title, staff_type)
    values (v_member.organization_id, v_member.id, trim(p_first_name), trim(p_last_name),
            nullif(trim(p_email), ''), nullif(trim(p_phone), ''), 'Owner', 'non_teaching');
  end if;

  return v_member;
end;
$$;

revoke execute on function public.redeem_claim_code(text, text, text, text, text) from public, anon;
grant  execute on function public.redeem_claim_code(text, text, text, text, text) to authenticated;
