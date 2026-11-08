-- 29 · Staff residence state and LGA
--
-- The staff forms now also ask where the person lives, beside the existing
-- private home address. Two nullable text columns go in
-- staff_private_details, private in the same way as address: leaders, the
-- bursar, the person themselves and platform admins can read them; only
-- leaders can edit them.
--
-- create_staff and update_staff gain p_residence_state and p_residence_lga.
-- Their return types do not change, but the signatures do, so the old
-- functions are dropped first. This file contains DROP FUNCTION, which the
-- Supabase connector refuses to run: apply it in the SQL editor, then record
-- it in supabase_migrations.schema_migrations.
--
-- Test: supabase/tests/02_people_access_test.sql (13e, 13f, 13g).
-- Design notes: docs/people-schema.md

-- ─────────────────────────────────────────────────────────────
-- Residence columns on the private details row
-- ─────────────────────────────────────────────────────────────
alter table public.staff_private_details
  add column residence_state text,
  add column residence_lga   text;

comment on column public.staff_private_details.residence_state is
  'Where the staff member lives now, e.g. Lagos. Private like address.';
comment on column public.staff_private_details.residence_lga is
  'The LGA of the residence, e.g. Ikeja. Private like address.';

-- Column-level edit access follows the existing private fields. Read is
-- already covered by the table select grant and the RLS policies.
grant update (residence_state, residence_lga)
  on public.staff_private_details to authenticated;

-- ─────────────────────────────────────────────────────────────
-- Saving the staff form in one call
-- The admin app's Add and Edit staff forms send every field at once. These
-- write the profile and the private details in ONE transaction, so a form is
-- saved completely or not at all. They run as the caller (security invoker),
-- so the normal RLS decides who may do it: leaders only.
-- ─────────────────────────────────────────────────────────────

-- Add staff. Leave p_staff_number blank to have it generated.
drop function public.create_staff(
  uuid, text, text, text, text, public.gender, text, text, text, text, text,
  public.staff_type, public.staff_status, date, text, text, date
);

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
  p_employment_date date                default null,
  p_residence_state text                default null,
  p_residence_lga   text                default null
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
      employment_date = p_employment_date,
      residence_state = p_residence_state,
      residence_lga   = p_residence_lga
  where d.staff_id = v_staff.id;

  return v_staff;
end;
$$;

-- Edit staff. Every argument is required: the form sends the whole record,
-- and null clears a field. A blank staff number keeps the current one.
drop function public.update_staff(
  uuid, text, text, text, text, public.gender, text, text, text, text, text,
  public.staff_type, public.staff_status, date, text, text, date
);

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
  p_employment_date date,
  p_residence_state text,
  p_residence_lga   text
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
      employment_date = p_employment_date,
      residence_state = p_residence_state,
      residence_lga   = p_residence_lga
  where d.staff_id = p_staff_id;

  return v_staff;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- Privileges: same roles as before
-- ─────────────────────────────────────────────────────────────
revoke execute on function public.create_staff(uuid, text, text, text, text, public.gender, text, text, text, text, text,
                                               public.staff_type, public.staff_status, date, text, text, date, text, text) from public, anon;
revoke execute on function public.update_staff(uuid, text, text, text, text, public.gender, text, text, text, text, text,
                                               public.staff_type, public.staff_status, date, text, text, date, text, text) from public, anon;
grant  execute on function public.create_staff(uuid, text, text, text, text, public.gender, text, text, text, text, text,
                                               public.staff_type, public.staff_status, date, text, text, date, text, text) to authenticated;
grant  execute on function public.update_staff(uuid, text, text, text, text, public.gender, text, text, text, text, text,
                                               public.staff_type, public.staff_status, date, text, text, date, text, text) to authenticated;

-- Down (manual): drop these two function signatures, recreate the migration
-- 05 versions, revoke update on the two new columns, then
-- alter table public.staff_private_details
--   drop column residence_state,
--   drop column residence_lga;
