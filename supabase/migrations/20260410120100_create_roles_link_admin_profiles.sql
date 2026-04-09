-- Reference table for admin role names (Type 3 — see docs/RLS_Approach_Guide.md)
-- Links admin_profiles.role → roles.name

-- 1. Create table
create table public.roles (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  created_at timestamptz not null default now(),
  constraint roles_name_key unique (name),
  constraint roles_name_check check (
    name in ('super_admin', 'admin', 'vice_principal', 'principal')
  )
) tablespace pg_default;

comment on table public.roles is 'Allowed admin role names; admin_profiles.role references name.';

-- 2. Enable RLS
alter table public.roles enable row level security;

-- 3. Policies
create policy select_roles on public.roles
  for select to authenticated
  using ((auth.jwt() ->> 'sub') is not null);

create policy service_role_insert_roles on public.roles
  for insert to service_role
  with check (true);

create policy service_role_update_roles on public.roles
  for update to service_role
  using (true)
  with check (true);

create policy service_role_delete_roles on public.roles
  for delete to service_role
  using (true);

-- 4. Seed (idempotent)
insert into public.roles (name, description) values
  ('super_admin', 'Full system access across all campuses'),
  ('principal', 'Head of school with broad administrative access'),
  ('vice_principal', 'Supports principal with delegated access'),
  ('admin', 'General administrative access')
on conflict (name) do nothing;

-- 5. admin_profiles.role references roles.name
alter table public.admin_profiles
  add constraint admin_profiles_role_fkey
  foreign key (role) references public.roles (name);

comment on column public.admin_profiles.role is 'FK to public.roles(name); must match a seeded role.';
