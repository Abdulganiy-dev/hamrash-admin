-- User-owned profile table (Type 1 — see docs/RLS_Approach_Guide.md)
-- Clerk JWT `sub` is compared to column `clerk_id`.

-- 1. Create table
create table public.admin_profiles (
  -- Identity
  id uuid primary key default gen_random_uuid(),
  clerk_id text unique,
  full_name text not null,
  email text not null unique,
  phone_number text,
  gender text,
  constraint admin_profiles_gender_check check (
    gender is null
    or gender in ('male', 'female', 'other')
  ),

  -- Avatar
  avatar_url text,
  avatar_url_id text,

  -- Address
  address text,
  state text,

  -- Push notifications
  fcm_token text,

  -- Role & access
  role text not null default 'admin',
  is_active boolean not null default true,

  -- Metadata
  last_login_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
) tablespace pg_default;

comment on table public.admin_profiles is 'One row per admin; clerk_id links to Clerk JWT sub.';

-- 2. Enable RLS
alter table public.admin_profiles enable row level security;

-- 3. Policies (select → insert → update → delete)
-- SELECT: any signed-in user can read all admin profiles (directory-style; tighten if PII should be hidden)
create policy select_admin_profiles on public.admin_profiles
  for select to authenticated
  using ((auth.jwt() ->> 'sub') is not null);

-- INSERT: only a row where clerk_id matches the current Clerk user
create policy insert_own_admin_profile on public.admin_profiles
  for insert to authenticated
  with check (clerk_id = (auth.jwt() ->> 'sub'));

-- UPDATE: only your own row; clerk_id cannot be moved to another user
create policy update_own_admin_profile on public.admin_profiles
  for update to authenticated
  using (clerk_id = (auth.jwt() ->> 'sub'))
  with check (clerk_id = (auth.jwt() ->> 'sub'));

-- DELETE: only your own row
create policy delete_own_admin_profile on public.admin_profiles
  for delete to authenticated
  using (clerk_id = (auth.jwt() ->> 'sub'));

-- 4. Indexes (email, clerk_id covered by unique constraints)
create index if not exists idx_admin_profiles_is_active
  on public.admin_profiles (is_active)
  where is_active = true;

-- 5. Keep updated_at in sync on row changes
create or replace function public.admin_profiles_set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists admin_profiles_set_updated_at on public.admin_profiles;

create trigger admin_profiles_set_updated_at
  before update on public.admin_profiles
  for each row
  execute function public.admin_profiles_set_updated_at();
