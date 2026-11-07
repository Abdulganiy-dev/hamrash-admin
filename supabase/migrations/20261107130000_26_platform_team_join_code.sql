-- 26 · One shared code to join the Hamrash team
--
-- Replaces the per-person, one-time platform invite codes (migration 12) with a
-- single shared team code. Anyone signed in who enters it becomes a platform
-- admin, so use it carefully: a platform admin can read every school.
--
-- Decisions:
-- * One row, one code. Only its SHA-256 hash and last 4 characters are stored;
--   the full code is shown once, when it is created or rotated.
-- * The code is reusable and has no expiry. Rotating it (a new code) stops the
--   old one at once. It can also be switched off without rotating.
-- * Joiners are active straight away. platform_admins.joined_at records when.
-- * A wrong, switched-off or missing code makes redeem return NULL. There is no
--   try limit, the same as claim codes (migration 25).
-- * The first code is made from the SQL editor, since nobody is an admin yet.
--   See "First code" at the bottom. After that any platform admin rotates it
--   from Hamrash Platform Admin.
-- * Already-active admins redeeming get their row back; a turned-off admin is
--   refused, so the code can't be used to undo a suspension.
--
-- Contains DROP, which the Supabase connector refuses to run: apply it in the
-- SQL editor, then record it in supabase_migrations.schema_migrations.
-- Design notes: docs/organization-schema.md → Hamrash team join code

-- ─────────────────────────────────────────────────────────────
-- Remove the per-person invites
-- ─────────────────────────────────────────────────────────────
drop function public.create_platform_invite(text);
drop function public.list_platform_invites();
drop function public.revoke_platform_invite(uuid);
drop function public.redeem_platform_invite(text, text, text);

drop table private.platform_invite_codes;
drop table if exists private.platform_invite_attempts;

-- ─────────────────────────────────────────────────────────────
-- When each admin joined
-- ─────────────────────────────────────────────────────────────
alter table public.platform_admins
  add column joined_at timestamptz not null default now();

-- ─────────────────────────────────────────────────────────────
-- The team code: exactly one row (id is always true)
-- ─────────────────────────────────────────────────────────────
create table private.platform_join_code (
  id          boolean primary key default true check (id),
  code_hash   text not null unique,         -- sha256 hex of the 12-char code
  code_hint   text not null,                -- last 4 chars, so admins can tell which code is live
  is_enabled  boolean not null default true,
  changed_by  text references public.platform_admins (clerk_user_id) on delete set null,
  changed_at  timestamptz not null default now(),
  constraint platform_join_code_hint_format check (code_hint ~ '^[A-Z0-9]{4}$')
);

create index platform_join_code_changed_by_idx on private.platform_join_code (changed_by);

-- Not exposed and no grants, but RLS (with no policies) as a second layer:
-- only the security-definer functions below can touch this table.
alter table private.platform_join_code enable row level security;
revoke all on private.platform_join_code from public, anon, authenticated;

-- ─────────────────────────────────────────────────────────────
-- RPC: join the team with the code (any signed-in user)
--
-- Returns the caller's platform_admins row, or NULL when the code is wrong,
-- switched off, or none has been made yet.
-- ─────────────────────────────────────────────────────────────
create function public.redeem_platform_join_code(
  p_code      text,
  p_full_name text,
  p_email     text default null
)
returns public.platform_admins
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_sub      text := (select auth.jwt() ->> 'sub');
  v_existing public.platform_admins;
  v_admin    public.platform_admins;
begin
  if v_sub is null or v_sub = '' then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  -- Already on the team: nothing to redeem.
  select pa.* into v_existing from public.platform_admins pa where pa.clerk_user_id = v_sub;
  if found then
    if v_existing.is_active then
      return v_existing;
    end if;
    raise exception 'Your platform access was turned off. Ask a Hamrash admin to turn it back on.'
      using errcode = '42501';
  end if;

  if nullif(trim(p_full_name), '') is null then
    raise exception 'Enter your full name to join the Hamrash team' using errcode = '22023';
  end if;

  if not exists (
    select 1 from private.platform_join_code c
    where c.is_enabled
      and c.code_hash = private.platform_code_hash(p_code)
  ) then
    return null;
  end if;

  insert into public.platform_admins (clerk_user_id, full_name, email)
  values (v_sub, trim(p_full_name), nullif(trim(p_email), ''))
  returning * into v_admin;

  return v_admin;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- RPC: make a new team code (platform admins only). The old code stops
-- working at once, and joining is switched on. The full code is returned
-- here and never again.
-- ─────────────────────────────────────────────────────────────
create function public.rotate_platform_join_code()
returns table (code text, code_hint text, changed_at timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_sub  text := (select auth.jwt() ->> 'sub');
  v_code text;
  v_row  private.platform_join_code;
begin
  if not private.is_platform_admin() then
    raise exception 'Only Hamrash platform admins can change the team code' using errcode = '42501';
  end if;

  v_code := private.random_code(12);

  insert into private.platform_join_code (id, code_hash, code_hint, is_enabled, changed_by, changed_at)
  values (true, private.platform_code_hash(v_code), right(v_code, 4), true, v_sub, now())
  on conflict (id) do update
    set code_hash  = excluded.code_hash,
        code_hint  = excluded.code_hint,
        is_enabled = true,
        changed_by = excluded.changed_by,
        changed_at = excluded.changed_at
  returning * into v_row;

  return query select v_code, v_row.code_hint, v_row.changed_at;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- RPC: switch joining on or off without changing the code
-- ─────────────────────────────────────────────────────────────
create function public.set_platform_join_enabled(p_enabled boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.is_platform_admin() then
    raise exception 'Only Hamrash platform admins can change the team code' using errcode = '42501';
  end if;

  update private.platform_join_code c
  set is_enabled = p_enabled,
      changed_by = (select auth.jwt() ->> 'sub'),
      changed_at = now()
  where c.id;

  if not found then
    raise exception 'There is no team code yet. Create one first.' using errcode = 'P0001';
  end if;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- RPC: is there a code, is it on, which one is it (platform admins only)
-- ─────────────────────────────────────────────────────────────
create function public.platform_join_code_status()
returns table (
  has_code        boolean,
  is_enabled      boolean,
  code_hint       text,
  changed_at      timestamptz,
  changed_by_name text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
begin
  if not private.is_platform_admin() then
    raise exception 'Only Hamrash platform admins can see the team code' using errcode = '42501';
  end if;

  return query
    select true, c.is_enabled, c.code_hint, c.changed_at, pa.full_name
    from private.platform_join_code c
    left join public.platform_admins pa on pa.clerk_user_id = c.changed_by;

  if not found then
    return query select false, false, null::text, null::timestamptz, null::text;
  end if;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- Privileges
-- ─────────────────────────────────────────────────────────────
revoke execute on function public.redeem_platform_join_code(text, text, text) from public, anon;
revoke execute on function public.rotate_platform_join_code()                 from public, anon;
revoke execute on function public.set_platform_join_enabled(boolean)          from public, anon;
revoke execute on function public.platform_join_code_status()                 from public, anon;
grant  execute on function public.redeem_platform_join_code(text, text, text) to authenticated;
grant  execute on function public.rotate_platform_join_code()                 to authenticated;
grant  execute on function public.set_platform_join_enabled(boolean)          to authenticated;
grant  execute on function public.platform_join_code_status()                 to authenticated;

-- ─────────────────────────────────────────────────────────────
-- First code (run by hand in the SQL editor, once; not part of the migration)
--
--   with c as (select private.random_code(12) as code),
--   ins as (
--     insert into private.platform_join_code (code_hash, code_hint)
--     select private.platform_code_hash(c.code), right(c.code, 4) from c
--     returning 1
--   )
--   select c.code as team_code from c, ins;
--
-- Copy the result: only its hash is stored. Then sign in to Hamrash Platform
-- Admin and enter it to become the first admin.
-- ─────────────────────────────────────────────────────────────
