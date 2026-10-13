-- 14 · Remember when a school's details were checked, and guard org updates
--
-- The first owner or admin to open Hamrash Admin checks the details Hamrash
-- filled in (name, logo, address, phone, email, number prefix) and taps
-- "Looks good". details_confirmed_at marks that step done, so the screen
-- doesn't come back and the setup checklist can tick "School details".
--
-- The update policy lets owners and admins edit their school row. They may
-- edit the details above, but status, code and creator stay with Hamrash:
-- the trigger refuses those changes unless a platform admin makes them.

alter table public.organizations
  add column details_confirmed_at timestamptz,
  add column details_confirmed_by text;

create or replace function private.guard_organization_update()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if (select private.is_platform_admin()) then
    return new;
  end if;
  if new.status is distinct from old.status
     or new.code is distinct from old.code
     or new.created_by is distinct from old.created_by
     or new.created_at is distinct from old.created_at then
    raise exception 'Only Hamrash can change this' using errcode = '42501';
  end if;
  return new;
end $$;

create trigger organizations_guard_update
  before update on public.organizations
  for each row execute function private.guard_organization_update();
