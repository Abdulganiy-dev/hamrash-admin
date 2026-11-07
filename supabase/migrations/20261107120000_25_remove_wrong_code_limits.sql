-- 25 · Remove the wrong-code limits
--
-- Migration 13 limited wrong claim codes to 5 per account per hour. That limit
-- is gone: a wrong code is just "not found". (Migration 26 does the same for
-- platform invites by replacing them altogether.)
--
-- * Drops private.claim_code_attempts and the three helpers that only served
--   the limit.
-- * check_claim_code no longer returns tries_left or retry_at, and the
--   'locked' status no longer exists. The return type changes, so it is
--   dropped and recreated.
-- * redeem_claim_code keeps its signature and still returns NULL for a wrong
--   code. It no longer counts tries, locks anyone out, or raises
--   "Too many wrong codes".
--
-- Contains DROP, which the Supabase connector refuses to run: apply it in the
-- SQL editor, then record it in supabase_migrations.schema_migrations.

-- ─────────────────────────────────────────────────────────────
-- check_claim_code: same lookup, without the limit columns
-- ─────────────────────────────────────────────────────────────
drop function public.check_claim_code(text);

create function public.check_claim_code(p_code text)
returns table (
  status          text,
  organization_id uuid,
  school_name     text,
  school_code     text,
  school_address  text,
  school_state    text,
  school_logo_url text,
  role            public.member_role,
  app             text,
  needs_name      boolean
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_sub    text := (select auth.jwt() ->> 'sub');
  v_code   text := private.normalise_claim_code(p_code);
  v_member public.organization_members;
  v_org    public.organizations;
begin
  if v_sub is null or v_sub = '' then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  select m.* into v_member
  from public.organization_members m
  where m.claim_code = v_code
    and m.status = 'invited';

  if not found then
    return query select 'not_found', null::uuid, null::text, null::text, null::text, null::text, null::text,
                        null::public.member_role, null::text, null::boolean;
    return;
  end if;

  select o.* into v_org from public.organizations o where o.id = v_member.organization_id;

  return query select
    case
      when v_org.status not in ('trial', 'active') then 'school_inactive'
      when exists (
        select 1 from public.organization_members m
        where m.organization_id = v_member.organization_id
          and m.clerk_user_id = v_sub
          and m.role = v_member.role
      ) then 'already_member'
      else 'ok'
    end,
    v_org.id, v_org.name, v_org.code, v_org.address, v_org.state, v_org.logo_url,
    v_member.role,
    private.member_role_app(v_member.role),
    private.owner_needs_staff_record(v_member, v_sub);
end;
$$;

revoke execute on function public.check_claim_code(text) from public, anon;
grant  execute on function public.check_claim_code(text) to authenticated;

-- ─────────────────────────────────────────────────────────────
-- redeem_claim_code: same, without the limit
-- ─────────────────────────────────────────────────────────────
create or replace function public.redeem_claim_code(
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
  v_code        text := private.normalise_claim_code(p_code);
  v_member      public.organization_members;
  v_needs_staff boolean;
begin
  if v_sub is null or v_sub = '' then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  select m.* into v_member
  from public.organization_members m
  where m.claim_code = v_code
    and m.status = 'invited'
  for update;

  if not found then
    return null;
  end if;

  if not exists (
    select 1 from public.organizations o
    where o.id = v_member.organization_id
      and o.status in ('trial', 'active')
  ) then
    raise exception 'This school is not currently active' using errcode = 'P0001';
  end if;

  v_needs_staff := private.owner_needs_staff_record(v_member, v_sub);

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

-- ─────────────────────────────────────────────────────────────
-- Drop the tables and the helpers only they used
-- ─────────────────────────────────────────────────────────────
drop function private.claim_code_locked_until(text);
drop function private.claim_code_tries_left(text);
drop function private.record_claim_code_attempt(text);

drop table private.claim_code_attempts;
