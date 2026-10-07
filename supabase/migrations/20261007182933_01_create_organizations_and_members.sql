-- 01 · Organizations (tenants), memberships, platform admins, claim codes
--
-- Every school is an organization. School-owned tables carry organization_id and RLS
-- only returns rows from organizations the caller is an active member of.
-- Hamrash platform admins create schools and can read every school.
-- Design notes: docs/organization-schema.md

-- ─────────────────────────────────────────────────────────────
-- Types
-- ─────────────────────────────────────────────────────────────
create type public.org_status as enum ('trial', 'active', 'suspended', 'archived');

create type public.member_role as enum (
  'owner', 'admin', 'principal', 'vice_principal', 'bursar',  -- admin app
  'teacher', 'staff',                                         -- staff app
  'parent', 'student'                                         -- portal
);

create type public.member_status as enum ('invited', 'active', 'suspended');

-- ─────────────────────────────────────────────────────────────
-- Private schema: helpers for RLS and triggers. Not exposed by the Data API.
-- ─────────────────────────────────────────────────────────────
create schema if not exists private;
grant usage on schema private to authenticated;

create function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- Random code from a 32-char alphabet without look-alikes (no 0/O, 1/I).
-- Uses pgcrypto bytes rather than random(); 256 % 32 = 0 keeps it uniform.
create function private.random_code(p_length int)
returns text
language sql
volatile
set search_path = ''
as $$
  select string_agg(substr('ABCDEFGHJKLMNPQRSTUVWXYZ23456789', (get_byte(r.bytes, i) % 32) + 1, 1), '' order by i)
  from (select extensions.gen_random_bytes(p_length) as bytes) r,
       generate_series(0, p_length - 1) as i;
$$;

-- ─────────────────────────────────────────────────────────────
-- platform_admins: Hamrash team members who onboard schools and can read every
-- school. Managed with the service role / SQL editor; clients can only read.
-- ─────────────────────────────────────────────────────────────
create table public.platform_admins (
  clerk_user_id  text primary key,
  full_name      text not null,
  email          text,
  is_active      boolean not null default true,
  created_at     timestamptz not null default now()
);

alter table public.platform_admins enable row level security;

-- ─────────────────────────────────────────────────────────────
-- organizations: one row per school
-- ─────────────────────────────────────────────────────────────
create table public.organizations (
  id          uuid primary key default gen_random_uuid(),
  code        text not null unique,
  name        text not null,
  email       text,
  phone       text,
  address     text,
  state       text,
  logo_url    text,
  status      public.org_status not null default 'trial',
  created_by  text not null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  constraint organizations_code_format check (code ~ '^HMR-[A-Z0-9]{6}$'),
  constraint organizations_name_not_blank check (length(trim(name)) > 0)
);

alter table public.organizations enable row level security;

create trigger organizations_set_updated_at
  before update on public.organizations
  for each row execute function private.set_updated_at();

-- ─────────────────────────────────────────────────────────────
-- organization_members: who can sign in to which school, and as what.
-- One row per (school, person, role). clerk_user_id stays null until the
-- invite's claim code is redeemed.
-- ─────────────────────────────────────────────────────────────
create table public.organization_members (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete restrict,
  clerk_user_id    text,
  role             public.member_role not null,
  status           public.member_status not null default 'invited',
  claim_code       text unique,
  invited_by       text default (auth.jwt() ->> 'sub'),
  joined_at        timestamptz,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  -- lets people tables use composite FKs: (organization_id, member_id)
  constraint organization_members_org_id_key unique (organization_id, id),
  constraint organization_members_one_role_per_user unique (organization_id, clerk_user_id, role),
  constraint organization_members_active_has_user check (status <> 'active' or clerk_user_id is not null),
  constraint organization_members_invite_has_code check (status <> 'invited' or claim_code is not null),
  constraint organization_members_claim_code_format check (claim_code ~ '^[A-Z0-9]{8}$')
);

alter table public.organization_members enable row level security;

-- Covers private.my_org_ids(): lookup by caller, return org + role.
create index organization_members_active_by_user_idx
  on public.organization_members (clerk_user_id, organization_id, role)
  where status = 'active';

create trigger organization_members_set_updated_at
  before update on public.organization_members
  for each row execute function private.set_updated_at();

-- ─────────────────────────────────────────────────────────────
-- RLS helpers. security definer so policies on these tables can call them
-- without recursing; both only ever look up the caller's own JWT sub.
-- ─────────────────────────────────────────────────────────────
create function private.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.platform_admins pa
    where pa.clerk_user_id = (select auth.jwt() ->> 'sub')
      and pa.is_active
  );
$$;

-- Org ids the caller is an active member of, optionally limited to some roles.
-- Suspended/archived schools are excluded unless p_include_inactive_orgs is true
-- (used only so members can still see their school's row and its status).
create function private.my_org_ids(
  p_roles                 public.member_role[] default null,
  p_include_inactive_orgs boolean default false
)
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select m.organization_id
  from public.organization_members m
  join public.organizations o on o.id = m.organization_id
  where m.clerk_user_id = (select auth.jwt() ->> 'sub')
    and m.status = 'active'
    and (p_roles is null or m.role = any (p_roles))
    and (p_include_inactive_orgs or o.status in ('trial', 'active'));
$$;

-- ─────────────────────────────────────────────────────────────
-- Triggers on organization_members
-- ─────────────────────────────────────────────────────────────

-- Give every invite an unused 8-char claim code (shown to users as XXXX-XXXX).
-- security definer so the uniqueness check sees codes in every school.
create function private.assign_claim_code()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_code text;
begin
  if new.status = 'invited' and new.claim_code is null then
    loop
      v_code := private.random_code(8);
      exit when not exists (select 1 from public.organization_members m where m.claim_code = v_code);
    end loop;
    new.claim_code := v_code;
  end if;
  return new;
end;
$$;

create trigger organization_members_assign_claim_code
  before insert on public.organization_members
  for each row execute function private.assign_claim_code();

-- Only owners (or platform admins) may touch owner rows, and a school can never
-- lose its last active owner. Runs as the caller; service role, the SQL editor
-- and our own security-definer RPCs are trusted and skip the checks.
create function private.guard_owner_changes()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if current_user not in ('authenticated', 'anon') then
    return coalesce(new, old);
  end if;

  if (old.role = 'owner' or (tg_op = 'UPDATE' and new.role = 'owner'))
     and not private.is_platform_admin()
     and not exists (
       select 1 from public.organization_members m
       where m.organization_id = old.organization_id
         and m.clerk_user_id = (select auth.jwt() ->> 'sub')
         and m.role = 'owner'
         and m.status = 'active'
     )
  then
    raise exception 'Only an owner can change owner memberships' using errcode = '42501';
  end if;

  if old.role = 'owner' and old.status = 'active'
     and (tg_op = 'DELETE' or new.role <> 'owner' or new.status <> 'active')
     and not exists (
       select 1 from public.organization_members m
       where m.organization_id = old.organization_id
         and m.role = 'owner'
         and m.status = 'active'
         and m.id <> old.id
     )
  then
    raise exception 'A school must keep at least one active owner' using errcode = 'P0001';
  end if;

  return coalesce(new, old);
end;
$$;

create trigger organization_members_guard_owner
  before update or delete on public.organization_members
  for each row execute function private.guard_owner_changes();

-- ─────────────────────────────────────────────────────────────
-- Policies: platform_admins
-- ─────────────────────────────────────────────────────────────
create policy "platform_admins: read own row, platform admins read all"
  on public.platform_admins for select to authenticated
  using (
    clerk_user_id = (select auth.jwt() ->> 'sub')
    or (select private.is_platform_admin())
  );

-- ─────────────────────────────────────────────────────────────
-- Policies: organizations
-- No insert policy (create_organization RPC) and no delete policy (archive instead).
-- ─────────────────────────────────────────────────────────────
create policy "organizations: members and platform admins can read"
  on public.organizations for select to authenticated
  using (
    id in (select private.my_org_ids(null, true))
    or (select private.is_platform_admin())
  );

create policy "organizations: owners, admins and platform admins can update"
  on public.organizations for update to authenticated
  using (
    id in (select private.my_org_ids(array['owner', 'admin']::public.member_role[]))
    or (select private.is_platform_admin())
  )
  with check (
    id in (select private.my_org_ids(array['owner', 'admin']::public.member_role[]))
    or (select private.is_platform_admin())
  );

-- ─────────────────────────────────────────────────────────────
-- Policies: organization_members
-- ─────────────────────────────────────────────────────────────
create policy "organization_members: own rows, school leaders and platform admins can read"
  on public.organization_members for select to authenticated
  using (
    clerk_user_id = (select auth.jwt() ->> 'sub')
    or organization_id in (
      select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])
    )
    or (select private.is_platform_admin())
  );

create policy "organization_members: owners and admins invite; platform admins invite owners"
  on public.organization_members for insert to authenticated
  with check (
    status = 'invited'
    and (
      (role <> 'owner'
       and organization_id in (select private.my_org_ids(array['owner', 'admin']::public.member_role[])))
      or (select private.is_platform_admin())
    )
  );

create policy "organization_members: owners, admins and platform admins can change role/status"
  on public.organization_members for update to authenticated
  using (
    organization_id in (select private.my_org_ids(array['owner', 'admin']::public.member_role[]))
    or (select private.is_platform_admin())
  )
  with check (
    organization_id in (select private.my_org_ids(array['owner', 'admin']::public.member_role[]))
    or (select private.is_platform_admin())
  );

create policy "organization_members: owners, admins and platform admins can delete unclaimed invites"
  on public.organization_members for delete to authenticated
  using (
    status = 'invited'
    and (
      organization_id in (select private.my_org_ids(array['owner', 'admin']::public.member_role[]))
      or (select private.is_platform_admin())
    )
  );

-- ─────────────────────────────────────────────────────────────
-- RPC: platform admin creates a school + an owner invite
-- ─────────────────────────────────────────────────────────────
create function public.create_organization(
  p_name    text,
  p_email   text default null,
  p_phone   text default null,
  p_address text default null,
  p_state   text default null
)
returns table (organization_id uuid, organization_code text, owner_claim_code text)
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_sub   text := (select auth.jwt() ->> 'sub');
  v_code  text;
  v_org   public.organizations;
  v_claim text;
begin
  if not private.is_platform_admin() then
    raise exception 'Only Hamrash platform admins can create schools' using errcode = '42501';
  end if;

  loop
    v_code := 'HMR-' || private.random_code(6);
    exit when not exists (select 1 from public.organizations o where o.code = v_code);
  end loop;

  insert into public.organizations (code, name, email, phone, address, state, created_by)
  values (v_code, trim(p_name), p_email, p_phone, p_address, p_state, v_sub)
  returning * into v_org;

  insert into public.organization_members (organization_id, role, invited_by)
  values (v_org.id, 'owner', v_sub)
  returning claim_code into v_claim;

  return query select v_org.id, v_org.code, v_claim;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- RPC: platform admin suspends / reactivates / archives a school
-- ─────────────────────────────────────────────────────────────
create function public.set_organization_status(
  p_organization_id uuid,
  p_status          public.org_status
)
returns public.organizations
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_org public.organizations;
begin
  if not private.is_platform_admin() then
    raise exception 'Only Hamrash platform admins can change a school''s status' using errcode = '42501';
  end if;

  update public.organizations o
  set status = p_status
  where o.id = p_organization_id
  returning * into v_org;

  if not found then
    raise exception 'School not found' using errcode = 'P0002';
  end if;

  return v_org;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- RPC: redeem a claim code and bind the caller's Clerk account
-- Accepts "abcd-2345", "ABCD2345", etc.
-- ─────────────────────────────────────────────────────────────
create function public.redeem_claim_code(p_code text)
returns public.organization_members
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_sub    text := (select auth.jwt() ->> 'sub');
  v_member public.organization_members;
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

  return v_member;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- Privileges
-- This project's default privileges grant anon/authenticated ALL on new tables
-- and EXECUTE on new functions in public, so revoke first, then grant only
-- what each role needs. Column-level grants keep status, code, clerk_user_id
-- and claim_code out of client hands.
-- ─────────────────────────────────────────────────────────────
revoke all on public.platform_admins      from anon, authenticated;
revoke all on public.organizations        from anon, authenticated;
revoke all on public.organization_members from anon, authenticated;

grant select on public.platform_admins to authenticated;

grant select on public.organizations to authenticated;
grant update (name, email, phone, address, state, logo_url) on public.organizations to authenticated;

grant select, delete on public.organization_members to authenticated;
grant insert (organization_id, role) on public.organization_members to authenticated;
grant update (role, status) on public.organization_members to authenticated;

revoke execute on function private.set_updated_at()                                  from public, anon, authenticated;
revoke execute on function private.random_code(int)                                  from public, anon, authenticated;
revoke execute on function private.assign_claim_code()                               from public, anon, authenticated;
revoke execute on function private.guard_owner_changes()                             from public, anon, authenticated;
revoke execute on function private.is_platform_admin()                               from public, anon;
revoke execute on function private.my_org_ids(public.member_role[], boolean)         from public, anon;
grant  execute on function private.is_platform_admin()                               to authenticated;
grant  execute on function private.my_org_ids(public.member_role[], boolean)         to authenticated;

revoke execute on function public.create_organization(text, text, text, text, text)  from public, anon;
revoke execute on function public.set_organization_status(uuid, public.org_status)   from public, anon;
revoke execute on function public.redeem_claim_code(text)                            from public, anon;
grant  execute on function public.create_organization(text, text, text, text, text)  to authenticated;
grant  execute on function public.set_organization_status(uuid, public.org_status)   to authenticated;
grant  execute on function public.redeem_claim_code(text)                            to authenticated;
