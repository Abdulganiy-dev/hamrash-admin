-- 03 · People: staff, students, parents and the student ↔ parent links
--
-- People tables are the school's records about a person. A record can exist
-- without a login (most pupils). invite_staff / invite_student / invite_parent
-- create an organization_members invite, link it to the record and return the
-- claim code. member_id is never client-writable.
-- Admission and staff numbers are generated when left blank.
-- Design notes: docs/people-schema.md

-- ─────────────────────────────────────────────────────────────
-- Types
-- ─────────────────────────────────────────────────────────────
create type public.gender as enum ('male', 'female');
create type public.staff_type as enum ('teaching', 'non_teaching');
create type public.staff_status as enum ('active', 'on_leave', 'exited');
create type public.student_status as enum ('active', 'graduated', 'transferred', 'withdrawn');
create type public.parent_relationship as enum ('father', 'mother', 'guardian', 'other');

-- ─────────────────────────────────────────────────────────────
-- organizations: number prefix + logo id
-- Every school has a short prefix (e.g. KCL), entered by Hamrash in
-- create_organization, that goes in front of generated numbers:
--   admission: KCL/2026/0001  (counter restarts each admission year)
--   staff:     KCL/STF/0001
-- number_prefix is NOT NULL; this assumes no schools exist yet (true when
-- this migration was written).
-- logo_id is the Cloudflare Images id, needed to replace/delete the logo.
-- ─────────────────────────────────────────────────────────────
alter table public.organizations
  add column number_prefix text not null,
  add column logo_id text,
  add constraint organizations_number_prefix_format check (number_prefix ~ '^[A-Z0-9]{2,8}$');

-- create_organization now takes the prefix (second, required argument).
drop function public.create_organization(text, text, text, text, text);

create function public.create_organization(
  p_name          text,
  p_number_prefix text,
  p_email         text default null,
  p_phone         text default null,
  p_address       text default null,
  p_state         text default null
)
returns table (organization_id uuid, organization_code text, owner_claim_code text)
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_sub    text := (select auth.jwt() ->> 'sub');
  v_prefix text := upper(trim(coalesce(p_number_prefix, '')));
  v_code   text;
  v_org    public.organizations;
  v_claim  text;
begin
  if not private.is_platform_admin() then
    raise exception 'Only Hamrash platform admins can create schools' using errcode = '42501';
  end if;

  if v_prefix !~ '^[A-Z0-9]{2,8}$' then
    raise exception 'Number prefix must be 2 to 8 letters or digits, e.g. KCL' using errcode = '22023';
  end if;

  loop
    v_code := 'HMR-' || private.random_code(6);
    exit when not exists (select 1 from public.organizations o where o.code = v_code);
  end loop;

  insert into public.organizations (code, name, number_prefix, email, phone, address, state, created_by)
  values (v_code, trim(p_name), v_prefix, p_email, p_phone, p_address, p_state, v_sub)
  returning * into v_org;

  insert into public.organization_members (organization_id, role, invited_by)
  values (v_org.id, 'owner', v_sub)
  returning claim_code into v_claim;

  return query select v_org.id, v_org.code, v_claim;
end;
$$;

-- One counter per (school, kind, period). Lives in private: clients never see it.
-- Incremented inside the inserting transaction, so a failed insert leaves no gap.
create table private.number_sequences (
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  kind             text not null check (kind in ('admission', 'staff')),
  period           int  not null,
  last_value       int  not null,
  primary key (organization_id, kind, period)
);

-- Not exposed and no grants, but RLS (with no policies) as a second layer:
-- only the owner, i.e. the security-definer numbering triggers, can touch it.
alter table private.number_sequences enable row level security;

create function private.next_number(p_organization_id uuid, p_kind text, p_period int)
returns int
language sql
volatile
set search_path = ''
as $$
  insert into private.number_sequences as ns (organization_id, kind, period, last_value)
  values (p_organization_id, p_kind, p_period, 1)
  on conflict (organization_id, kind, period)
  do update set last_value = ns.last_value + 1
  returning ns.last_value;
$$;

-- ─────────────────────────────────────────────────────────────
-- staff: every employee, teaching and non-teaching
-- ─────────────────────────────────────────────────────────────
create table public.staff (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete restrict,
  member_id        uuid,
  staff_number     text not null,  -- generated when left blank
  first_name       text not null,
  middle_name      text,
  last_name        text not null,
  gender           public.gender,
  date_of_birth    date,
  email            text,
  phone            text,
  address          text,
  state_of_origin  text,
  photo_id         text,           -- Cloudflare Images id (needed to replace/delete)
  photo_url        text,
  job_title        text,
  staff_type       public.staff_type not null default 'teaching',
  employment_date  date,
  status           public.staff_status not null default 'active',
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint staff_org_id_key unique (organization_id, id),
  constraint staff_member_id_key unique (member_id),
  constraint staff_staff_number_key unique (organization_id, staff_number),
  constraint staff_member_fkey foreign key (organization_id, member_id)
    references public.organization_members (organization_id, id) on delete set null (member_id),
  constraint staff_names_not_blank check (length(trim(first_name)) > 0 and length(trim(last_name)) > 0)
);

alter table public.staff enable row level security;

create index staff_org_name_idx on public.staff (organization_id, last_name, first_name, id);

create trigger staff_set_updated_at
  before update on public.staff
  for each row execute function private.set_updated_at();

-- ─────────────────────────────────────────────────────────────
-- students
-- (class enrollment is added with the classes table)
-- ─────────────────────────────────────────────────────────────
create table public.students (
  id                uuid primary key default gen_random_uuid(),
  organization_id   uuid not null references public.organizations (id) on delete restrict,
  member_id         uuid,
  admission_number  text not null,  -- generated when left blank
  first_name        text not null,
  middle_name       text,
  last_name         text not null,
  gender            public.gender,
  date_of_birth     date,
  admission_date    date,
  photo_id          text,           -- Cloudflare Images id (needed to replace/delete)
  photo_url         text,
  address           text,
  state_of_origin   text,
  lga               text,
  blood_group       text,
  genotype          text,
  medical_notes     text,
  status            public.student_status not null default 'active',
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  constraint students_org_id_key unique (organization_id, id),
  constraint students_member_id_key unique (member_id),
  constraint students_admission_number_key unique (organization_id, admission_number),
  constraint students_member_fkey foreign key (organization_id, member_id)
    references public.organization_members (organization_id, id) on delete set null (member_id),
  constraint students_names_not_blank check (length(trim(first_name)) > 0 and length(trim(last_name)) > 0),
  constraint students_blood_group_valid check (blood_group in ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
  constraint students_genotype_valid check (genotype in ('AA', 'AS', 'AC', 'SS', 'SC', 'CC'))
);

alter table public.students enable row level security;

create index students_org_name_idx on public.students (organization_id, last_name, first_name, id);

create trigger students_set_updated_at
  before update on public.students
  for each row execute function private.set_updated_at();

-- ─────────────────────────────────────────────────────────────
-- parents (and guardians)
-- ─────────────────────────────────────────────────────────────
create table public.parents (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete restrict,
  member_id        uuid,
  title            text,
  first_name       text not null,
  last_name        text not null,
  gender           public.gender,
  phone            text not null,
  alt_phone        text,
  email            text,
  occupation       text,
  address          text,
  photo_id         text,           -- Cloudflare Images id (needed to replace/delete)
  photo_url        text,
  is_active        boolean not null default true,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint parents_org_id_key unique (organization_id, id),
  constraint parents_member_id_key unique (member_id),
  constraint parents_member_fkey foreign key (organization_id, member_id)
    references public.organization_members (organization_id, id) on delete set null (member_id),
  constraint parents_names_not_blank check (length(trim(first_name)) > 0 and length(trim(last_name)) > 0),
  constraint parents_phone_not_blank check (length(trim(phone)) > 0)
);

alter table public.parents enable row level security;

create index parents_org_name_idx on public.parents (organization_id, last_name, first_name, id);
-- finding an existing parent by phone when registering a sibling
create index parents_org_phone_idx on public.parents (organization_id, phone);

create trigger parents_set_updated_at
  before update on public.parents
  for each row execute function private.set_updated_at();

-- ─────────────────────────────────────────────────────────────
-- student_parents: which parents belong to which students.
-- Composite FKs keep both sides in the same school.
-- ─────────────────────────────────────────────────────────────
create table public.student_parents (
  organization_id     uuid not null references public.organizations (id) on delete restrict,
  student_id          uuid not null,
  parent_id           uuid not null,
  relationship        public.parent_relationship not null,
  is_primary_contact  boolean not null default false,
  created_at          timestamptz not null default now(),
  primary key (student_id, parent_id),
  constraint student_parents_student_fkey foreign key (organization_id, student_id)
    references public.students (organization_id, id) on delete cascade,
  constraint student_parents_parent_fkey foreign key (organization_id, parent_id)
    references public.parents (organization_id, id) on delete cascade
);

alter table public.student_parents enable row level security;

create index student_parents_parent_idx on public.student_parents (parent_id);
create index student_parents_org_idx on public.student_parents (organization_id);
create unique index student_parents_one_primary_idx
  on public.student_parents (student_id)
  where is_primary_contact;

-- Making a parent the primary contact clears the flag on the student's other links,
-- so the app never has to unset the old one first.
create function private.keep_single_primary_contact()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.is_primary_contact then
    update public.student_parents sp
    set is_primary_contact = false
    where sp.student_id = new.student_id
      and sp.parent_id <> new.parent_id
      and sp.is_primary_contact;
  end if;
  return new;
end;
$$;

create trigger student_parents_single_primary
  before insert or update of is_primary_contact on public.student_parents
  for each row execute function private.keep_single_primary_contact();

-- ─────────────────────────────────────────────────────────────
-- Fill in admission / staff numbers when the app leaves them blank.
-- A number typed in by the school is kept as-is; generated numbers skip any
-- value already taken (e.g. imported records), so they never collide.
-- security definer so the counter and the "already taken" check see the whole
-- school. If the insert is then rejected by RLS, the transaction rolls back
-- the counter too.
-- ─────────────────────────────────────────────────────────────
create function private.assign_admission_number()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_prefix text;
  v_year   int;
  v_n      int;
  v_number text;
begin
  if nullif(trim(new.admission_number), '') is not null then
    return new;
  end if;

  select o.number_prefix into v_prefix from public.organizations o where o.id = new.organization_id;
  v_year := extract(year from coalesce(new.admission_date, (now() at time zone 'Africa/Lagos')::date))::int;

  loop
    v_n := private.next_number(new.organization_id, 'admission', v_year);
    v_number := concat_ws('/', v_prefix, v_year::text,
                          case when v_n < 10000 then lpad(v_n::text, 4, '0') else v_n::text end);
    exit when not exists (
      select 1 from public.students s
      where s.organization_id = new.organization_id
        and s.admission_number = v_number
    );
  end loop;

  new.admission_number := v_number;
  return new;
end;
$$;

create trigger students_assign_admission_number
  before insert on public.students
  for each row execute function private.assign_admission_number();

create function private.assign_staff_number()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_prefix text;
  v_n      int;
  v_number text;
begin
  if nullif(trim(new.staff_number), '') is not null then
    return new;
  end if;

  select o.number_prefix into v_prefix from public.organizations o where o.id = new.organization_id;

  loop
    v_n := private.next_number(new.organization_id, 'staff', 0);
    v_number := concat_ws('/', v_prefix, 'STF',
                          case when v_n < 10000 then lpad(v_n::text, 4, '0') else v_n::text end);
    exit when not exists (
      select 1 from public.staff s
      where s.organization_id = new.organization_id
        and s.staff_number = v_number
    );
  end loop;

  new.staff_number := v_number;
  return new;
end;
$$;

create trigger staff_assign_staff_number
  before insert on public.staff
  for each row execute function private.assign_staff_number();

-- ─────────────────────────────────────────────────────────────
-- RLS helpers for "my own records". security definer so the policies on
-- students / parents / student_parents can reference each other without
-- recursing. All of them start from the caller's own JWT sub.
-- ─────────────────────────────────────────────────────────────

-- The caller's active memberships in active/trial schools.
create function private.my_member_ids()
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select m.id
  from public.organization_members m
  join public.organizations o on o.id = m.organization_id
  where m.clerk_user_id = (select auth.jwt() ->> 'sub')
    and m.status = 'active'
    and o.status in ('trial', 'active');
$$;

-- Parent records that are the caller.
create function private.my_parent_ids()
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select p.id
  from public.parents p
  where p.member_id in (select private.my_member_ids())
    and p.is_active;
$$;

-- Students the caller is a parent of.
create function private.my_child_ids()
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select sp.student_id
  from public.student_parents sp
  where sp.parent_id in (select private.my_parent_ids());
$$;

-- Every parent of the caller's children (the caller included), so a parent can
-- see the child's other parents and guardians.
create function private.my_childrens_parent_ids()
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select sp.parent_id
  from public.student_parents sp
  where sp.student_id in (select private.my_child_ids());
$$;

-- Student records that are the caller.
create function private.my_student_ids()
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select s.id
  from public.students s
  where s.member_id in (select private.my_member_ids());
$$;

-- ─────────────────────────────────────────────────────────────
-- Policies: staff
-- Leaders = owner, admin, principal, vice_principal.
-- ─────────────────────────────────────────────────────────────
create policy "staff: leaders, bursars, self and platform admins can read"
  on public.staff for select to authenticated
  using (
    organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal', 'bursar']::public.member_role[]))
    or member_id in (select private.my_member_ids())
    or (select private.is_platform_admin())
  );

create policy "staff: leaders can add"
  on public.staff for insert to authenticated
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));

create policy "staff: leaders can edit"
  on public.staff for update to authenticated
  using      (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])))
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));

create policy "staff: owners and admins can delete"
  on public.staff for delete to authenticated
  using (organization_id in (select private.my_org_ids(array['owner', 'admin']::public.member_role[])));

-- ─────────────────────────────────────────────────────────────
-- Policies: students
-- Teachers see every student in the school until classes exist; that
-- narrows to their own classes in the classes migration.
-- ─────────────────────────────────────────────────────────────
create policy "students: staff, own parents, self and platform admins can read"
  on public.students for select to authenticated
  using (
    organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal', 'bursar', 'teacher']::public.member_role[]))
    or id in (select private.my_child_ids())
    or member_id in (select private.my_member_ids())
    or (select private.is_platform_admin())
  );

create policy "students: leaders can add"
  on public.students for insert to authenticated
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));

create policy "students: leaders can edit"
  on public.students for update to authenticated
  using      (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])))
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));

create policy "students: owners and admins can delete"
  on public.students for delete to authenticated
  using (organization_id in (select private.my_org_ids(array['owner', 'admin']::public.member_role[])));

-- ─────────────────────────────────────────────────────────────
-- Policies: parents
-- ─────────────────────────────────────────────────────────────
create policy "parents: staff, self, co-parents and platform admins can read"
  on public.parents for select to authenticated
  using (
    organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal', 'bursar', 'teacher']::public.member_role[]))
    or member_id in (select private.my_member_ids())
    or id in (select private.my_childrens_parent_ids())
    or (select private.is_platform_admin())
  );

create policy "parents: leaders can add"
  on public.parents for insert to authenticated
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));

create policy "parents: leaders can edit"
  on public.parents for update to authenticated
  using      (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])))
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));

create policy "parents: owners and admins can delete"
  on public.parents for delete to authenticated
  using (organization_id in (select private.my_org_ids(array['owner', 'admin']::public.member_role[])));

-- ─────────────────────────────────────────────────────────────
-- Policies: student_parents
-- ─────────────────────────────────────────────────────────────
create policy "student_parents: staff, the child's parents, the student and platform admins can read"
  on public.student_parents for select to authenticated
  using (
    organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal', 'bursar', 'teacher']::public.member_role[]))
    or student_id in (select private.my_child_ids())
    or student_id in (select private.my_student_ids())
    or (select private.is_platform_admin())
  );

create policy "student_parents: leaders can link"
  on public.student_parents for insert to authenticated
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));

create policy "student_parents: leaders can edit links"
  on public.student_parents for update to authenticated
  using      (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])))
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));

create policy "student_parents: leaders can unlink"
  on public.student_parents for delete to authenticated
  using (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));

-- ─────────────────────────────────────────────────────────────
-- Issuing logins
-- The invite_* functions check permission *while* looking the record up:
-- a record is only found (and locked) if the caller may issue logins for its
-- school. Anyone else gets the same generic error whether or not the record
-- exists, so the functions reveal nothing about other schools' records.
-- ─────────────────────────────────────────────────────────────

-- Owners and admins of the school, or Hamrash platform admins.
create function private.can_issue_logins(p_organization_id uuid)
returns boolean
language sql
stable
set search_path = ''
as $$
  select p_organization_id in (select private.my_org_ids(array['owner', 'admin']::public.member_role[]))
      or private.is_platform_admin();
$$;

-- Returns the invite for a person's login, creating it if needed. Calling it
-- again before the code is redeemed returns the same invite (with the role
-- updated), so "show me the code again" is safe.
create function private.ensure_invite(
  p_organization_id uuid,
  p_member_id       uuid,
  p_role            public.member_role
)
returns public.organization_members
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member public.organization_members;
begin
  -- invite_* already checked; repeated here so this helper is never unsafe on its own
  if not private.can_issue_logins(p_organization_id) then
    raise exception 'Only the school''s owners and admins can issue logins' using errcode = '42501';
  end if;

  if p_member_id is not null then
    select m.* into v_member
    from public.organization_members m
    where m.id = p_member_id
    for update;

    if v_member.status <> 'invited' then
      raise exception 'This person already has a login' using errcode = 'P0001';
    end if;

    if v_member.role <> p_role then
      update public.organization_members m
      set role = p_role
      where m.id = v_member.id
      returning m.* into v_member;
    end if;

    return v_member;
  end if;

  insert into public.organization_members (organization_id, role, invited_by)
  values (p_organization_id, p_role, (select auth.jwt() ->> 'sub'))
  returning * into v_member;

  return v_member;
end;
$$;

create function public.invite_staff(p_staff_id uuid, p_role public.member_role default 'teacher')
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_staff  public.staff;
  v_member public.organization_members;
begin
  if p_role not in ('admin', 'principal', 'vice_principal', 'bursar', 'teacher', 'staff') then
    raise exception 'Staff can be invited as admin, principal, vice principal, bursar, teacher or staff' using errcode = '22023';
  end if;

  select s.* into v_staff
  from public.staff s
  where s.id = p_staff_id
    and private.can_issue_logins(s.organization_id)
  for update;
  if not found then
    raise exception 'Staff record not found, or you can''t issue logins for it' using errcode = '42501';
  end if;
  if v_staff.status = 'exited' then
    raise exception 'This staff member has left the school' using errcode = 'P0001';
  end if;

  v_member := private.ensure_invite(v_staff.organization_id, v_staff.member_id, p_role);

  update public.staff s
  set member_id = v_member.id
  where s.id = v_staff.id
    and s.member_id is distinct from v_member.id;

  return v_member.claim_code;
end;
$$;

create function public.invite_student(p_student_id uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_student public.students;
  v_member  public.organization_members;
begin
  select s.* into v_student
  from public.students s
  where s.id = p_student_id
    and private.can_issue_logins(s.organization_id)
  for update;
  if not found then
    raise exception 'Student record not found, or you can''t issue logins for it' using errcode = '42501';
  end if;
  if v_student.status <> 'active' then
    raise exception 'Only active students can be given a login' using errcode = 'P0001';
  end if;

  v_member := private.ensure_invite(v_student.organization_id, v_student.member_id, 'student');

  update public.students s
  set member_id = v_member.id
  where s.id = v_student.id
    and s.member_id is distinct from v_member.id;

  return v_member.claim_code;
end;
$$;

create function public.invite_parent(p_parent_id uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_parent public.parents;
  v_member public.organization_members;
begin
  select p.* into v_parent
  from public.parents p
  where p.id = p_parent_id
    and private.can_issue_logins(p.organization_id)
  for update;
  if not found then
    raise exception 'Parent record not found, or you can''t issue logins for it' using errcode = '42501';
  end if;
  if not v_parent.is_active then
    raise exception 'This parent record is inactive' using errcode = 'P0001';
  end if;

  v_member := private.ensure_invite(v_parent.organization_id, v_parent.member_id, 'parent');

  update public.parents p
  set member_id = v_member.id
  where p.id = v_parent.id
    and p.member_id is distinct from v_member.id;

  return v_member.claim_code;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- Privileges
-- Revoke the project's default ALL, then grant per column. member_id,
-- created_at and updated_at are never client-writable, and organization_id
-- can be set on insert but never changed.
-- ─────────────────────────────────────────────────────────────
revoke all on public.staff           from anon, authenticated;
revoke all on public.students        from anon, authenticated;
revoke all on public.parents         from anon, authenticated;
revoke all on public.student_parents from anon, authenticated;

grant select, delete on public.staff to authenticated;
grant insert (id, organization_id, staff_number, first_name, middle_name, last_name, gender, date_of_birth,
              email, phone, address, state_of_origin, photo_id, photo_url, job_title, staff_type, employment_date, status)
  on public.staff to authenticated;
grant update (staff_number, first_name, middle_name, last_name, gender, date_of_birth,
              email, phone, address, state_of_origin, photo_id, photo_url, job_title, staff_type, employment_date, status)
  on public.staff to authenticated;

grant select, delete on public.students to authenticated;
grant insert (id, organization_id, admission_number, first_name, middle_name, last_name, gender, date_of_birth,
              admission_date, photo_id, photo_url, address, state_of_origin, lga, blood_group, genotype, medical_notes, status)
  on public.students to authenticated;
grant update (admission_number, first_name, middle_name, last_name, gender, date_of_birth,
              admission_date, photo_id, photo_url, address, state_of_origin, lga, blood_group, genotype, medical_notes, status)
  on public.students to authenticated;

grant select, delete on public.parents to authenticated;
grant insert (id, organization_id, title, first_name, last_name, gender, phone, alt_phone, email,
              occupation, address, photo_id, photo_url, is_active)
  on public.parents to authenticated;
grant update (title, first_name, last_name, gender, phone, alt_phone, email,
              occupation, address, photo_id, photo_url, is_active)
  on public.parents to authenticated;

-- owners/admins can correct the prefix and change the logo through the
-- existing organizations update policy
grant update (number_prefix, logo_id) on public.organizations to authenticated;
revoke all on private.number_sequences from public, anon, authenticated;

revoke execute on function public.create_organization(text, text, text, text, text, text) from public, anon;
grant  execute on function public.create_organization(text, text, text, text, text, text) to authenticated;

grant select, delete on public.student_parents to authenticated;
grant insert (organization_id, student_id, parent_id, relationship, is_primary_contact) on public.student_parents to authenticated;
grant update (relationship, is_primary_contact) on public.student_parents to authenticated;

revoke execute on function private.next_number(uuid, text, int)                                 from public, anon, authenticated;
revoke execute on function private.assign_admission_number()                                    from public, anon, authenticated;
revoke execute on function private.assign_staff_number()                                        from public, anon, authenticated;
revoke execute on function private.keep_single_primary_contact()                               from public, anon, authenticated;
revoke execute on function private.can_issue_logins(uuid)                                       from public, anon, authenticated;
revoke execute on function private.ensure_invite(uuid, uuid, public.member_role)                from public, anon, authenticated;
revoke execute on function private.my_member_ids()                                              from public, anon;
revoke execute on function private.my_parent_ids()                                              from public, anon;
revoke execute on function private.my_child_ids()                                               from public, anon;
revoke execute on function private.my_student_ids()                                             from public, anon;
revoke execute on function private.my_childrens_parent_ids()                                    from public, anon;
grant  execute on function private.my_childrens_parent_ids()                                    to authenticated;
grant  execute on function private.my_member_ids()                                              to authenticated;
grant  execute on function private.my_parent_ids()                                              to authenticated;
grant  execute on function private.my_child_ids()                                               to authenticated;
grant  execute on function private.my_student_ids()                                             to authenticated;

revoke execute on function public.invite_staff(uuid, public.member_role)  from public, anon;
revoke execute on function public.invite_student(uuid)                    from public, anon;
revoke execute on function public.invite_parent(uuid)                     from public, anon;
grant  execute on function public.invite_staff(uuid, public.member_role)  to authenticated;
grant  execute on function public.invite_student(uuid)                    to authenticated;
grant  execute on function public.invite_parent(uuid)                     to authenticated;
