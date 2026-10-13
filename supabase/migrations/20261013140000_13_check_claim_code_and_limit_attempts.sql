-- 13 · Check a claim code before redeeming it, and limit wrong codes
--
-- The apps now look a code up before using it, so the person can see which
-- school and role it's for and confirm. Hamrash Admin uses this to turn away
-- teacher, parent and student codes without using them up: the code still
-- works in the right app.
--
-- Decisions:
-- * check_claim_code never changes the code. It returns one row with a status:
--     ok              the code works; school, role and app are filled in
--     not_found       no unused code like this (wrong, used or deleted)
--     locked          too many wrong codes; retry_at says when to try again
--     school_inactive the school is suspended or archived
--     already_member  the caller already has this role at this school
-- * app says which app a role signs in to: 'admin' (owner, admin, principal,
--   vice_principal, bursar), 'staff' (teacher, staff) or 'family' (parent,
--   student). Each app decides what to accept; the database doesn't.
-- * 5 wrong codes per account per hour, shared by check_claim_code and
--   redeem_claim_code, so calling redeem directly doesn't get around it.
--   The lock lifts an hour after the oldest of the last 5 wrong tries.
-- * Only well-formed codes (8 letters or numbers) count as wrong tries; a
--   half-typed code is just "not found".
-- * A successful redeem clears the caller's wrong tries.
-- * redeem_claim_code now returns NULL for a wrong or used code instead of
--   raising, so the wrong try is recorded (a raise would roll it back). Same
--   pattern as redeem_platform_invite. Its other errors are unchanged.
--
-- No DROP: redeem_claim_code keeps its signature and return type.
-- Design notes: docs/organization-schema.md → Checking a code first

-- ─────────────────────────────────────────────────────────────
-- Wrong-code attempts. Rows older than a day are pruned on use.
-- ─────────────────────────────────────────────────────────────
create table private.claim_code_attempts (
  id             bigint generated always as identity primary key,
  clerk_user_id  text not null,
  attempted_at   timestamptz not null default now()
);

create index claim_code_attempts_user_time_idx
  on private.claim_code_attempts (clerk_user_id, attempted_at desc);

-- Not exposed and no grants, but RLS (with no policies) as a second layer:
-- only the security-definer functions below can touch this table.
alter table private.claim_code_attempts enable row level security;
revoke all on private.claim_code_attempts from public, anon, authenticated;

-- ─────────────────────────────────────────────────────────────
-- Helpers (private; called only from the RPCs below)
-- ─────────────────────────────────────────────────────────────

-- "kq7m-2x9p" → "KQ7M2X9P", the way claim codes are stored
create function private.normalise_claim_code(p_code text)
returns text
language sql
immutable
set search_path = ''
as $$
  select upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g'));
$$;

-- Which app a role signs in to
create function private.member_role_app(p_role public.member_role)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when p_role in ('owner', 'admin', 'principal', 'vice_principal', 'bursar') then 'admin'
    when p_role in ('teacher', 'staff') then 'staff'
    else 'family'
  end;
$$;

-- When the caller may try again, or NULL if they aren't locked out.
-- Locked = 5 or more wrong tries in the last hour; it lifts an hour after
-- the 5th most recent one.
create function private.claim_code_locked_until(p_sub text)
returns timestamptz
language sql
stable
set search_path = ''
as $$
  select a.attempted_at + interval '1 hour'
  from private.claim_code_attempts a
  where a.clerk_user_id = p_sub
    and a.attempted_at > now() - interval '1 hour'
  order by a.attempted_at desc
  offset 4
  limit 1;
$$;

create function private.claim_code_tries_left(p_sub text)
returns int
language sql
stable
set search_path = ''
as $$
  select greatest(0, 5 - count(*))::int
  from private.claim_code_attempts a
  where a.clerk_user_id = p_sub
    and a.attempted_at > now() - interval '1 hour';
$$;

create function private.record_claim_code_attempt(p_sub text)
returns void
language sql
volatile
set search_path = ''
as $$
  delete from private.claim_code_attempts a
  where a.clerk_user_id = p_sub and a.attempted_at < now() - interval '1 day';

  insert into private.claim_code_attempts (clerk_user_id) values (p_sub);
$$;

-- An owner code needs a name (to create the owner's staff record) unless the
-- invite already has a staff record, or the caller already has one at this
-- school through another role. Moved here from redeem_claim_code (migration
-- 11) so check_claim_code gives the same answer.
create function private.owner_needs_staff_record(p_member public.organization_members, p_sub text)
returns boolean
language sql
stable
set search_path = ''
as $$
  select p_member.role = 'owner'
    and not exists (select 1 from public.staff s where s.member_id = p_member.id)
    and not exists (
      select 1
      from public.staff s
      join public.organization_members m on m.id = s.member_id
      where s.organization_id = p_member.organization_id
        and m.clerk_user_id = p_sub
    );
$$;

-- ─────────────────────────────────────────────────────────────
-- RPC: look a code up without using it (any signed-in user)
-- ─────────────────────────────────────────────────────────────
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
  needs_name      boolean,
  tries_left      int,
  retry_at        timestamptz
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
  v_retry  timestamptz;
  v_member public.organization_members;
  v_org    public.organizations;
begin
  if v_sub is null or v_sub = '' then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  -- one check or redeem at a time per account, so parallel calls can't
  -- slip past the limit
  perform pg_advisory_xact_lock(hashtextextended('claim_code_attempts:' || v_sub, 0));

  v_retry := private.claim_code_locked_until(v_sub);
  if v_retry is not null then
    return query select 'locked', null::uuid, null::text, null::text, null::text, null::text, null::text,
                        null::public.member_role, null::text, null::boolean, 0, v_retry;
    return;
  end if;

  select m.* into v_member
  from public.organization_members m
  where m.claim_code = v_code
    and m.status = 'invited';

  if not found then
    if v_code ~ '^[A-Z0-9]{8}$' then
      perform private.record_claim_code_attempt(v_sub);
    end if;
    v_retry := private.claim_code_locked_until(v_sub);
    return query select case when v_retry is null then 'not_found' else 'locked' end,
                        null::uuid, null::text, null::text, null::text, null::text, null::text,
                        null::public.member_role, null::text, null::boolean,
                        private.claim_code_tries_left(v_sub), v_retry;
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
    private.owner_needs_staff_record(v_member, v_sub),
    private.claim_code_tries_left(v_sub),
    null::timestamptz;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- RPC: redeem a code (replaces migration 11's version)
--
-- Returns the new membership, or NULL when the code is wrong or already used
-- (the wrong try is recorded). Raises when locked out, when the school isn't
-- active, when an owner name is missing, or when the caller already has the
-- role.
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
  v_retry       timestamptz;
  v_member      public.organization_members;
  v_needs_staff boolean;
begin
  if v_sub is null or v_sub = '' then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  perform pg_advisory_xact_lock(hashtextextended('claim_code_attempts:' || v_sub, 0));

  v_retry := private.claim_code_locked_until(v_sub);
  if v_retry is not null then
    raise exception 'Too many wrong codes. Try again in % minutes.',
      greatest(1, ceil(extract(epoch from v_retry - now()) / 60))::int
      using errcode = 'P0001';
  end if;

  select m.* into v_member
  from public.organization_members m
  where m.claim_code = v_code
    and m.status = 'invited'
  for update;

  if not found then
    if v_code ~ '^[A-Z0-9]{8}$' then
      perform private.record_claim_code_attempt(v_sub);
    end if;
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

  delete from private.claim_code_attempts a where a.clerk_user_id = v_sub;

  return v_member;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- Privileges
-- ─────────────────────────────────────────────────────────────
revoke execute on function private.normalise_claim_code(text)                                      from public, anon, authenticated;
revoke execute on function private.member_role_app(public.member_role)                             from public, anon, authenticated;
revoke execute on function private.claim_code_locked_until(text)                                   from public, anon, authenticated;
revoke execute on function private.claim_code_tries_left(text)                                     from public, anon, authenticated;
revoke execute on function private.record_claim_code_attempt(text)                                 from public, anon, authenticated;
revoke execute on function private.owner_needs_staff_record(public.organization_members, text)     from public, anon, authenticated;
revoke execute on function public.check_claim_code(text)                                           from public, anon;
revoke execute on function public.redeem_claim_code(text, text, text, text, text)                  from public, anon;
grant  execute on function public.check_claim_code(text)                                           to authenticated;
grant  execute on function public.redeem_claim_code(text, text, text, text, text)                  to authenticated;
