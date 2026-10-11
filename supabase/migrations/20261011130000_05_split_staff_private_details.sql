-- 05 · Split staff into a public profile and private details
--
-- Everyone in a school (staff, parents, students) can now read the staff
-- profile: names, photo, job title, staff number, gender, type, status,
-- phone and email, so parents can see and contact their child's teachers.
-- Personal details move to staff_private_details, readable only by leaders,
-- the bursar, the staff member themselves and platform admins.
--
-- No staff existed when this was written; the copy step is there for safety.
-- Contains DROP COLUMN, so the Supabase connector won't run it: apply it in
-- the SQL editor and record it in supabase_migrations.schema_migrations.
-- Design notes: docs/people-schema.md

-- ─────────────────────────────────────────────────────────────
-- staff_private_details: exactly one row per staff member
-- ─────────────────────────────────────────────────────────────
create table public.staff_private_details (
  staff_id         uuid primary key,
  organization_id  uuid not null references public.organizations (id) on delete restrict,
  date_of_birth    date,
  address          text,
  state_of_origin  text,
  employment_date  date,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint staff_private_details_staff_fkey foreign key (organization_id, staff_id)
    references public.staff (organization_id, id) on delete cascade
);

alter table public.staff_private_details enable row level security;

create index staff_private_details_org_staff_idx on public.staff_private_details (organization_id, staff_id);

create trigger staff_private_details_set_updated_at
  before update on public.staff_private_details
  for each row execute function private.set_updated_at();

-- Copy anything that exists, then drop the private columns from staff.
insert into public.staff_private_details
  (staff_id, organization_id, date_of_birth, address, state_of_origin, employment_date)
select id, organization_id, date_of_birth, address, state_of_origin, employment_date
from public.staff;

alter table public.staff
  drop column date_of_birth,
  drop column address,
  drop column state_of_origin,
  drop column employment_date;

-- Every new staff member gets their (empty) details row automatically, so the
-- app only ever updates it. security definer so clients need no insert grant.
create function private.create_staff_private_details()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.staff_private_details (staff_id, organization_id)
  values (new.id, new.organization_id);
  return new;
end;
$$;

create trigger staff_create_private_details
  after insert on public.staff
  for each row execute function private.create_staff_private_details();

-- Staff records that are the caller.
create function private.my_staff_ids()
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select s.id
  from public.staff s
  where s.member_id in (select private.my_member_ids());
$$;

-- ─────────────────────────────────────────────────────────────
-- Policies
-- ─────────────────────────────────────────────────────────────

-- staff profile: now readable by every member of the school
alter policy "staff: leaders, bursars, self and platform admins can read" on public.staff
  rename to "staff: members and platform admins can read";
alter policy "staff: members and platform admins can read" on public.staff
  using (organization_id in (select private.my_org_ids()) or (select private.is_platform_admin()));

-- private details: leaders, bursar, the staff member, platform admins
create policy "staff_private_details: leaders, bursars, self and platform admins can read"
  on public.staff_private_details for select to authenticated
  using (
    organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal', 'bursar']::public.member_role[]))
    or staff_id in (select private.my_staff_ids())
    or (select private.is_platform_admin())
  );

create policy "staff_private_details: leaders can edit"
  on public.staff_private_details for update to authenticated
  using      (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])))
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));

-- No insert or delete policy: rows are created with the staff member (trigger)
-- and removed with them (cascade).

-- ─────────────────────────────────────────────────────────────
-- Saving the staff form in one call
-- The admin app's Add / Edit staff forms send every field at once. These
-- write the profile and the private details in ONE transaction, so a form
-- is saved completely or not at all. They run as the caller (security
-- invoker), so the normal RLS decides who may do it: leaders only.
-- ─────────────────────────────────────────────────────────────

-- Add staff. Leave p_staff_number blank to have it generated.
create function public.create_staff(
  p_organization_id uuid,
  p_first_name      text,
  p_last_name       text,
  p_middle_name     text                default null,
  p_staff_number    text                default null,
  p_gender          public.gender       default null,
  p_phone           text                default null,
  p_email           text                default null,
  p_photo_id        text                default null,
  p_photo_url       text                default null,
  p_job_title       text                default null,
  p_staff_type      public.staff_type   default 'teaching',
  p_status          public.staff_status default 'active',
  p_date_of_birth   date                default null,
  p_address         text                default null,
  p_state_of_origin text                default null,
  p_employment_date date                default null
)
returns public.staff
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_staff public.staff;
begin
  insert into public.staff (organization_id, staff_number, first_name, middle_name, last_name, gender,
                            phone, email, photo_id, photo_url, job_title, staff_type, status)
  values (p_organization_id, p_staff_number, p_first_name, p_middle_name, p_last_name, p_gender,
          p_phone, p_email, p_photo_id, p_photo_url, p_job_title, p_staff_type, p_status)
  returning * into v_staff;

  -- the details row was just created by the staff_create_private_details trigger
  update public.staff_private_details d
  set date_of_birth   = p_date_of_birth,
      address         = p_address,
      state_of_origin = p_state_of_origin,
      employment_date = p_employment_date
  where d.staff_id = v_staff.id;

  return v_staff;
end;
$$;

-- Edit staff. Every argument is required: the form sends the whole record,
-- and null clears a field. A blank staff number keeps the current one.
create function public.update_staff(
  p_staff_id        uuid,
  p_first_name      text,
  p_last_name       text,
  p_middle_name     text,
  p_staff_number    text,
  p_gender          public.gender,
  p_phone           text,
  p_email           text,
  p_photo_id        text,
  p_photo_url       text,
  p_job_title       text,
  p_staff_type      public.staff_type,
  p_status          public.staff_status,
  p_date_of_birth   date,
  p_address         text,
  p_state_of_origin text,
  p_employment_date date
)
returns public.staff
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_staff public.staff;
begin
  update public.staff s
  set staff_number = coalesce(nullif(trim(p_staff_number), ''), s.staff_number),
      first_name   = p_first_name,
      middle_name  = p_middle_name,
      last_name    = p_last_name,
      gender       = p_gender,
      phone        = p_phone,
      email        = p_email,
      photo_id     = p_photo_id,
      photo_url    = p_photo_url,
      job_title    = p_job_title,
      staff_type   = p_staff_type,
      status       = p_status
  where s.id = p_staff_id
  returning s.* into v_staff;

  if not found then
    raise exception 'Staff record not found, or you can''t edit it' using errcode = '42501';
  end if;

  update public.staff_private_details d
  set date_of_birth   = p_date_of_birth,
      address         = p_address,
      state_of_origin = p_state_of_origin,
      employment_date = p_employment_date
  where d.staff_id = p_staff_id;

  return v_staff;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- Privileges
-- ─────────────────────────────────────────────────────────────
revoke all on public.staff_private_details from anon, authenticated;
grant select on public.staff_private_details to authenticated;
grant update (date_of_birth, address, state_of_origin, employment_date)
  on public.staff_private_details to authenticated;

revoke execute on function private.create_staff_private_details() from public, anon, authenticated;
revoke execute on function private.my_staff_ids()                 from public, anon;
grant  execute on function private.my_staff_ids()                 to authenticated;

revoke execute on function public.create_staff(uuid, text, text, text, text, public.gender, text, text, text, text, text,
                                               public.staff_type, public.staff_status, date, text, text, date) from public, anon;
revoke execute on function public.update_staff(uuid, text, text, text, text, public.gender, text, text, text, text, text,
                                               public.staff_type, public.staff_status, date, text, text, date) from public, anon;
grant  execute on function public.create_staff(uuid, text, text, text, text, public.gender, text, text, text, text, text,
                                               public.staff_type, public.staff_status, date, text, text, date) to authenticated;
grant  execute on function public.update_staff(uuid, text, text, text, text, public.gender, text, text, text, text, text,
                                               public.staff_type, public.staff_status, date, text, text, date) to authenticated;
