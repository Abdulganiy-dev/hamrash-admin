-- 15 · The database stamps who checked a school's details, and when
--
-- Migration 14 let the app send details_confirmed_at and _by itself, so any
-- owner or admin could send any time or someone else's id, and confirming
-- again overwrote the first confirmation.
--
-- Now the app only sets details_confirmed_at (to any value). This trigger:
-- * stamps now() and the caller's Clerk id the first time;
-- * keeps the first confirmation if it is set again;
-- * ignores details_confirmed_by sent on its own.

create or replace function private.stamp_details_confirmed()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.details_confirmed_at is distinct from old.details_confirmed_at then
    if old.details_confirmed_at is not null then
      -- keep the first confirmation
      new.details_confirmed_at := old.details_confirmed_at;
      new.details_confirmed_by := old.details_confirmed_by;
    else
      new.details_confirmed_at := now();
      new.details_confirmed_by := (select auth.jwt() ->> 'sub');
    end if;
  elsif new.details_confirmed_by is distinct from old.details_confirmed_by then
    new.details_confirmed_by := old.details_confirmed_by;
  end if;
  return new;
end $$;

create trigger organizations_stamp_details_confirmed
  before update on public.organizations
  for each row execute function private.stamp_details_confirmed();
