-- admin_profiles.role: nullable + FK clears when a row in public.roles is deleted

alter table public.admin_profiles
  drop constraint if exists admin_profiles_role_fkey;

alter table public.admin_profiles
  alter column role drop not null;

alter table public.admin_profiles
  add constraint admin_profiles_role_fkey
  foreign key (role) references public.roles (name)
  on delete set null;

comment on column public.admin_profiles.role is
  'FK to public.roles(name). Set to null if the referenced role row is deleted; otherwise must match a role name.';
