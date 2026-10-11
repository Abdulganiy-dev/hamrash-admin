-- 04 · Academic structure: sections, classes, arms, sessions, terms,
--      class teachers and student placements
--
--   Section    Nursery · Primary · Secondary           (created by the school, ordered)
--   Class      Primary 1 … JSS 1 …                     (ordered within its section → promotion order)
--   Arm        A · B · Gold · Science  →  "JSS 1A"     (created by the school; the real group of pupils)
--   Session    2026/2027, split into terms
--   Placement  which arm a student is in for a session (keeps class history)
--
-- Sections, classes, arms, sessions, terms and class teachers are school-wide
-- reference data: any member of the school can read them, leaders write them.
-- Placements are read like students (staff, the child's parents, the student).
-- Design notes: docs/academic-structure.md

-- ─────────────────────────────────────────────────────────────
-- sections
-- ─────────────────────────────────────────────────────────────
create table public.sections (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete restrict,
  name             text not null,
  sort_order       int  not null default 0,
  head_staff_id    uuid,
  is_active        boolean not null default true,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint sections_org_id_key unique (organization_id, id),
  constraint sections_head_staff_fkey foreign key (organization_id, head_staff_id)
    references public.staff (organization_id, id) on delete set null (head_staff_id),
  constraint sections_name_not_blank check (length(trim(name)) > 0)
);

alter table public.sections enable row level security;

create unique index sections_org_name_key on public.sections (organization_id, lower(name));
create index sections_org_sort_idx on public.sections (organization_id, sort_order);
create index sections_head_staff_idx on public.sections (organization_id, head_staff_id);

create trigger sections_set_updated_at
  before update on public.sections
  for each row execute function private.set_updated_at();

-- ─────────────────────────────────────────────────────────────
-- classes: levels within a section. Promotion order is
-- (section.sort_order, class.sort_order), so Primary 6 → JSS 1 works
-- across sections. is_graduating_class is set by the school's admin:
-- students promoted out of such a class graduate (e.g. SS 3, or
-- Primary 6 in a school that ends there).
-- ─────────────────────────────────────────────────────────────
create table public.classes (
  id                   uuid primary key default gen_random_uuid(),
  organization_id      uuid not null references public.organizations (id) on delete restrict,
  section_id           uuid not null,
  name                 text not null,
  sort_order           int  not null default 0,
  is_graduating_class  boolean not null default false,
  is_active            boolean not null default true,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint classes_org_id_key unique (organization_id, id),
  constraint classes_section_fkey foreign key (organization_id, section_id)
    references public.sections (organization_id, id) on delete restrict,
  constraint classes_name_not_blank check (length(trim(name)) > 0)
);

alter table public.classes enable row level security;

create unique index classes_org_name_key on public.classes (organization_id, lower(name));
create index classes_section_sort_idx on public.classes (organization_id, section_id, sort_order);

create trigger classes_set_updated_at
  before update on public.classes
  for each row execute function private.set_updated_at();

-- ─────────────────────────────────────────────────────────────
-- class_arms: the actual groups of pupils ("JSS 1A"). A class with a
-- single group still has one arm. capacity is informational.
-- ─────────────────────────────────────────────────────────────
create table public.class_arms (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete restrict,
  class_id         uuid not null,
  name             text not null,
  capacity         int,
  is_active        boolean not null default true,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint class_arms_org_id_key unique (organization_id, id),
  constraint class_arms_class_fkey foreign key (organization_id, class_id)
    references public.classes (organization_id, id) on delete restrict,
  constraint class_arms_name_not_blank check (length(trim(name)) > 0),
  constraint class_arms_capacity_positive check (capacity > 0)
);

alter table public.class_arms enable row level security;

create unique index class_arms_class_name_key on public.class_arms (class_id, lower(name));
create index class_arms_class_idx on public.class_arms (organization_id, class_id);

create trigger class_arms_set_updated_at
  before update on public.class_arms
  for each row execute function private.set_updated_at();

-- ─────────────────────────────────────────────────────────────
-- academic_sessions: e.g. 2026/2027. At most one current per school,
-- changed only through set_current_session / set_current_term.
-- ─────────────────────────────────────────────────────────────
create table public.academic_sessions (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete restrict,
  name             text not null,
  starts_on        date not null,
  ends_on          date not null,
  is_current       boolean not null default false,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint academic_sessions_org_id_key unique (organization_id, id),
  constraint academic_sessions_name_not_blank check (length(trim(name)) > 0),
  constraint academic_sessions_dates_valid check (ends_on > starts_on)
);

alter table public.academic_sessions enable row level security;

create unique index academic_sessions_org_name_key on public.academic_sessions (organization_id, lower(name));
create unique index academic_sessions_one_current_idx on public.academic_sessions (organization_id) where is_current;

create trigger academic_sessions_set_updated_at
  before update on public.academic_sessions
  for each row execute function private.set_updated_at();

-- ─────────────────────────────────────────────────────────────
-- academic_terms: First/Second/Third term (or semesters). At most one
-- current per school; the current term's session is always current too.
-- ─────────────────────────────────────────────────────────────
create table public.academic_terms (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete restrict,
  session_id       uuid not null,
  name             text not null,
  sequence         int  not null,
  starts_on        date not null,
  ends_on          date not null,
  is_current       boolean not null default false,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint academic_terms_org_id_key unique (organization_id, id),
  constraint academic_terms_session_sequence_key unique (session_id, sequence),
  constraint academic_terms_session_fkey foreign key (organization_id, session_id)
    references public.academic_sessions (organization_id, id) on delete restrict,
  constraint academic_terms_name_not_blank check (length(trim(name)) > 0),
  constraint academic_terms_sequence_valid check (sequence between 1 and 6),
  constraint academic_terms_dates_valid check (ends_on > starts_on)
);

alter table public.academic_terms enable row level security;

create unique index academic_terms_session_name_key on public.academic_terms (session_id, lower(name));
create unique index academic_terms_one_current_idx on public.academic_terms (organization_id) where is_current;
create index academic_terms_session_idx on public.academic_terms (organization_id, session_id);

create trigger academic_terms_set_updated_at
  before update on public.academic_terms
  for each row execute function private.set_updated_at();

-- A term must fall inside its session's dates.
create function private.check_term_within_session()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.academic_sessions s
    where s.id = new.session_id
      and new.starts_on >= s.starts_on
      and new.ends_on   <= s.ends_on
  ) then
    raise exception 'Term dates must fall within the session''s dates' using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger academic_terms_within_session
  before insert or update of session_id, starts_on, ends_on on public.academic_terms
  for each row execute function private.check_term_within_session();

-- ─────────────────────────────────────────────────────────────
-- class_teachers: who looks after an arm in a session. At most one lead
-- and at most two assistants per arm per session; neither is required.
-- ─────────────────────────────────────────────────────────────
create table public.class_teachers (
  organization_id  uuid not null references public.organizations (id) on delete restrict,
  session_id       uuid not null,
  arm_id           uuid not null,
  staff_id         uuid not null,
  is_lead          boolean not null default true,
  created_at       timestamptz not null default now(),
  primary key (session_id, arm_id, staff_id),
  constraint class_teachers_session_fkey foreign key (organization_id, session_id)
    references public.academic_sessions (organization_id, id) on delete cascade,
  constraint class_teachers_arm_fkey foreign key (organization_id, arm_id)
    references public.class_arms (organization_id, id) on delete cascade,
  constraint class_teachers_staff_fkey foreign key (organization_id, staff_id)
    references public.staff (organization_id, id) on delete cascade
);

alter table public.class_teachers enable row level security;

create unique index class_teachers_one_lead_idx on public.class_teachers (session_id, arm_id) where is_lead;
create index class_teachers_session_idx on public.class_teachers (organization_id, session_id);
create index class_teachers_arm_idx on public.class_teachers (organization_id, arm_id);
create index class_teachers_staff_idx on public.class_teachers (organization_id, staff_id);

-- Making someone the lead demotes the arm's previous lead to assistant.
create function private.keep_single_lead_class_teacher()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.is_lead then
    update public.class_teachers ct
    set is_lead = false
    where ct.session_id = new.session_id
      and ct.arm_id = new.arm_id
      and ct.staff_id <> new.staff_id
      and ct.is_lead;
  end if;
  return new;
end;
$$;

create trigger class_teachers_single_lead
  before insert or update of is_lead on public.class_teachers
  for each row execute function private.keep_single_lead_class_teacher();

-- At most two assistants. Also catches the case where making someone the
-- lead would demote the old lead into a third assistant slot.
create function private.limit_assistant_class_teachers()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not new.is_lead and (
    select count(*)
    from public.class_teachers ct
    where ct.session_id = new.session_id
      and ct.arm_id = new.arm_id
      and ct.staff_id <> new.staff_id
      and not ct.is_lead
  ) >= 2 then
    raise exception 'An arm can have at most 2 assistant class teachers per session (changing the lead makes the old lead an assistant)'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger class_teachers_limit_assistants
  before insert or update of is_lead on public.class_teachers
  for each row execute function private.limit_assistant_class_teachers();

-- ─────────────────────────────────────────────────────────────
-- student_placements: one arm per student per session. Moving a pupil to
-- another arm mid-session updates the row; past sessions stay as history.
-- ─────────────────────────────────────────────────────────────
create table public.student_placements (
  organization_id  uuid not null references public.organizations (id) on delete restrict,
  student_id       uuid not null,
  session_id       uuid not null,
  arm_id           uuid not null,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  primary key (student_id, session_id),
  constraint student_placements_student_fkey foreign key (organization_id, student_id)
    references public.students (organization_id, id) on delete cascade,
  constraint student_placements_session_fkey foreign key (organization_id, session_id)
    references public.academic_sessions (organization_id, id) on delete restrict,
  constraint student_placements_arm_fkey foreign key (organization_id, arm_id)
    references public.class_arms (organization_id, id) on delete restrict
);

alter table public.student_placements enable row level security;

-- "everyone in JSS 1A this session"
create index student_placements_arm_session_idx on public.student_placements (organization_id, arm_id, session_id);
create index student_placements_session_idx on public.student_placements (organization_id, session_id);
create index student_placements_student_idx on public.student_placements (organization_id, student_id);

create trigger student_placements_set_updated_at
  before update on public.student_placements
  for each row execute function private.set_updated_at();

-- ─────────────────────────────────────────────────────────────
-- Policies
-- Leaders = owner, admin, principal, vice_principal.
-- ─────────────────────────────────────────────────────────────

-- sections
create policy "sections: members and platform admins can read"
  on public.sections for select to authenticated
  using (organization_id in (select private.my_org_ids()) or (select private.is_platform_admin()));
create policy "sections: leaders can add"
  on public.sections for insert to authenticated
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
create policy "sections: leaders can edit"
  on public.sections for update to authenticated
  using      (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])))
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
create policy "sections: owners and admins can delete"
  on public.sections for delete to authenticated
  using (organization_id in (select private.my_org_ids(array['owner', 'admin']::public.member_role[])));

-- classes
create policy "classes: members and platform admins can read"
  on public.classes for select to authenticated
  using (organization_id in (select private.my_org_ids()) or (select private.is_platform_admin()));
create policy "classes: leaders can add"
  on public.classes for insert to authenticated
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
create policy "classes: leaders can edit"
  on public.classes for update to authenticated
  using      (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])))
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
create policy "classes: owners and admins can delete"
  on public.classes for delete to authenticated
  using (organization_id in (select private.my_org_ids(array['owner', 'admin']::public.member_role[])));

-- class_arms
create policy "class_arms: members and platform admins can read"
  on public.class_arms for select to authenticated
  using (organization_id in (select private.my_org_ids()) or (select private.is_platform_admin()));
create policy "class_arms: leaders can add"
  on public.class_arms for insert to authenticated
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
create policy "class_arms: leaders can edit"
  on public.class_arms for update to authenticated
  using      (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])))
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
create policy "class_arms: owners and admins can delete"
  on public.class_arms for delete to authenticated
  using (organization_id in (select private.my_org_ids(array['owner', 'admin']::public.member_role[])));

-- academic_sessions
create policy "academic_sessions: members and platform admins can read"
  on public.academic_sessions for select to authenticated
  using (organization_id in (select private.my_org_ids()) or (select private.is_platform_admin()));
create policy "academic_sessions: leaders can add"
  on public.academic_sessions for insert to authenticated
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
create policy "academic_sessions: leaders can edit"
  on public.academic_sessions for update to authenticated
  using      (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])))
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
create policy "academic_sessions: owners and admins can delete"
  on public.academic_sessions for delete to authenticated
  using (organization_id in (select private.my_org_ids(array['owner', 'admin']::public.member_role[])));

-- academic_terms
create policy "academic_terms: members and platform admins can read"
  on public.academic_terms for select to authenticated
  using (organization_id in (select private.my_org_ids()) or (select private.is_platform_admin()));
create policy "academic_terms: leaders can add"
  on public.academic_terms for insert to authenticated
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
create policy "academic_terms: leaders can edit"
  on public.academic_terms for update to authenticated
  using      (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])))
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
create policy "academic_terms: owners and admins can delete"
  on public.academic_terms for delete to authenticated
  using (organization_id in (select private.my_org_ids(array['owner', 'admin']::public.member_role[])));

-- class_teachers
create policy "class_teachers: members and platform admins can read"
  on public.class_teachers for select to authenticated
  using (organization_id in (select private.my_org_ids()) or (select private.is_platform_admin()));
create policy "class_teachers: leaders can assign"
  on public.class_teachers for insert to authenticated
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
create policy "class_teachers: leaders can edit"
  on public.class_teachers for update to authenticated
  using      (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])))
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
create policy "class_teachers: leaders can unassign"
  on public.class_teachers for delete to authenticated
  using (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));

-- student_placements: read like students
create policy "student_placements: staff, the child's parents, the student and platform admins can read"
  on public.student_placements for select to authenticated
  using (
    organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal', 'bursar', 'teacher']::public.member_role[]))
    or student_id in (select private.my_child_ids())
    or student_id in (select private.my_student_ids())
    or (select private.is_platform_admin())
  );
create policy "student_placements: leaders can place"
  on public.student_placements for insert to authenticated
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
create policy "student_placements: leaders can move"
  on public.student_placements for update to authenticated
  using      (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])))
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
create policy "student_placements: leaders can remove"
  on public.student_placements for delete to authenticated
  using (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));

-- ─────────────────────────────────────────────────────────────
-- Current session / term
-- is_current is not client-writable; these keep the flags consistent:
-- one current session and term per school, and the current term always
-- belongs to the current session.
-- ─────────────────────────────────────────────────────────────

-- Leaders of the school.
create function private.can_manage_academics(p_organization_id uuid)
returns boolean
language sql
stable
set search_path = ''
as $$
  select p_organization_id in (
    select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])
  );
$$;

-- Makes a session current. Any current term from another session is cleared.
create function public.set_current_session(p_session_id uuid)
returns public.academic_sessions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_session public.academic_sessions;
begin
  select s.* into v_session
  from public.academic_sessions s
  where s.id = p_session_id
    and private.can_manage_academics(s.organization_id)
  for update;
  if not found then
    raise exception 'Session not found, or you can''t manage this school''s calendar' using errcode = '42501';
  end if;

  -- clear old flags first so the one-current indexes never clash
  update public.academic_terms t
  set is_current = false
  where t.organization_id = v_session.organization_id
    and t.is_current
    and t.session_id <> v_session.id;

  update public.academic_sessions s
  set is_current = false
  where s.organization_id = v_session.organization_id
    and s.is_current
    and s.id <> v_session.id;

  update public.academic_sessions s
  set is_current = true
  where s.id = v_session.id
    and not s.is_current;

  select s.* into v_session from public.academic_sessions s where s.id = p_session_id;
  return v_session;
end;
$$;

-- Makes a term current, and its session with it.
create function public.set_current_term(p_term_id uuid)
returns public.academic_terms
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_term public.academic_terms;
begin
  select t.* into v_term
  from public.academic_terms t
  where t.id = p_term_id
    and private.can_manage_academics(t.organization_id)
  for update;
  if not found then
    raise exception 'Term not found, or you can''t manage this school''s calendar' using errcode = '42501';
  end if;

  update public.academic_terms t
  set is_current = false
  where t.organization_id = v_term.organization_id
    and t.is_current
    and t.id <> v_term.id;

  update public.academic_sessions s
  set is_current = false
  where s.organization_id = v_term.organization_id
    and s.is_current
    and s.id <> v_term.session_id;

  update public.academic_sessions s
  set is_current = true
  where s.id = v_term.session_id
    and not s.is_current;

  update public.academic_terms t
  set is_current = true
  where t.id = v_term.id
    and not t.is_current;

  select t.* into v_term from public.academic_terms t where t.id = p_term_id;
  return v_term;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- One-tap starting structure for a Nigerian school:
--   Nursery    Nursery 1–3
--   Primary    Primary 1–6
--   Secondary  JSS 1–3, SS 1–3   (SS 3 marked as the graduating class)
-- Only for a school with no sections yet. Everything it creates can be
-- renamed, reordered or deactivated afterwards. Arms are left to the
-- school admin. Runs as the caller, so the normal leader-only RLS applies.
-- ─────────────────────────────────────────────────────────────
create function public.create_standard_structure(p_organization_id uuid)
returns int
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_def     record;
  v_section uuid;
  v_classes int := 0;
begin
  if not private.can_manage_academics(p_organization_id) then
    raise exception 'Only the school''s leaders can set up its structure' using errcode = '42501';
  end if;

  if exists (select 1 from public.sections s where s.organization_id = p_organization_id) then
    raise exception 'This school already has sections; the standard structure is only for a new school' using errcode = 'P0001';
  end if;

  for v_def in
    select d.sort_order, d.name, d.classes
    from (values
      (1, 'Nursery',   array['Nursery 1', 'Nursery 2', 'Nursery 3']),
      (2, 'Primary',   array['Primary 1', 'Primary 2', 'Primary 3', 'Primary 4', 'Primary 5', 'Primary 6']),
      (3, 'Secondary', array['JSS 1', 'JSS 2', 'JSS 3', 'SS 1', 'SS 2', 'SS 3'])
    ) as d (sort_order, name, classes)
  loop
    insert into public.sections (organization_id, name, sort_order)
    values (p_organization_id, v_def.name, v_def.sort_order)
    returning id into v_section;

    insert into public.classes (organization_id, section_id, name, sort_order)
    select p_organization_id, v_section, c.name, c.ord
    from unnest(v_def.classes) with ordinality as c (name, ord);

    v_classes := v_classes + cardinality(v_def.classes);
  end loop;

  update public.classes c
  set is_graduating_class = true
  where c.organization_id = p_organization_id
    and c.name = 'SS 3';

  return v_classes;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- Privileges
-- Revoke the project's default ALL, then grant per column. organization_id
-- is set on insert and never changed; is_current only changes through the
-- functions above; an arm can't be moved to another class (its placements
-- would silently change class).
-- ─────────────────────────────────────────────────────────────
revoke all on public.sections           from anon, authenticated;
revoke all on public.classes            from anon, authenticated;
revoke all on public.class_arms         from anon, authenticated;
revoke all on public.academic_sessions  from anon, authenticated;
revoke all on public.academic_terms     from anon, authenticated;
revoke all on public.class_teachers     from anon, authenticated;
revoke all on public.student_placements from anon, authenticated;

grant select, delete on public.sections to authenticated;
grant insert (id, organization_id, name, sort_order, head_staff_id, is_active) on public.sections to authenticated;
grant update (name, sort_order, head_staff_id, is_active) on public.sections to authenticated;

grant select, delete on public.classes to authenticated;
grant insert (id, organization_id, section_id, name, sort_order, is_graduating_class, is_active) on public.classes to authenticated;
grant update (section_id, name, sort_order, is_graduating_class, is_active) on public.classes to authenticated;

grant select, delete on public.class_arms to authenticated;
grant insert (id, organization_id, class_id, name, capacity, is_active) on public.class_arms to authenticated;
grant update (name, capacity, is_active) on public.class_arms to authenticated;

grant select, delete on public.academic_sessions to authenticated;
grant insert (id, organization_id, name, starts_on, ends_on) on public.academic_sessions to authenticated;
grant update (name, starts_on, ends_on) on public.academic_sessions to authenticated;

grant select, delete on public.academic_terms to authenticated;
grant insert (id, organization_id, session_id, name, sequence, starts_on, ends_on) on public.academic_terms to authenticated;
grant update (name, sequence, starts_on, ends_on) on public.academic_terms to authenticated;

grant select, delete on public.class_teachers to authenticated;
grant insert (organization_id, session_id, arm_id, staff_id, is_lead) on public.class_teachers to authenticated;
grant update (is_lead) on public.class_teachers to authenticated;

grant select, delete on public.student_placements to authenticated;
grant insert (organization_id, student_id, session_id, arm_id) on public.student_placements to authenticated;
grant update (arm_id) on public.student_placements to authenticated;

revoke execute on function private.check_term_within_session()        from public, anon, authenticated;
revoke execute on function private.keep_single_lead_class_teacher()   from public, anon, authenticated;
revoke execute on function private.limit_assistant_class_teachers()   from public, anon, authenticated;
-- can_manage_academics only reveals whether the caller leads a given school;
-- authenticated needs it because create_standard_structure runs as the caller.
revoke execute on function private.can_manage_academics(uuid)         from public, anon;
grant  execute on function private.can_manage_academics(uuid)         to authenticated;

revoke execute on function public.set_current_session(uuid)       from public, anon;
revoke execute on function public.set_current_term(uuid)          from public, anon;
revoke execute on function public.create_standard_structure(uuid) from public, anon;
grant  execute on function public.set_current_session(uuid)       to authenticated;
grant  execute on function public.set_current_term(uuid)          to authenticated;
grant  execute on function public.create_standard_structure(uuid) to authenticated;
