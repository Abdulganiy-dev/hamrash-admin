-- 06 · Subjects, curriculum, teaching assignments, electives — and teachers'
--      view narrowed to the students they teach
--
--   Subject             Mathematics · English · Physics …   (the school's catalogue, ordered for report cards)
--   Arm subjects        the curriculum PER ARM: SS 1 Science offers Physics,
--                       SS 1 Arts offers Literature … compulsory or optional
--   Teaching assignment one teacher per subject per arm per session
--   Student subjects    who takes each OPTIONAL subject, per session
--                       (compulsory subjects apply to everyone in the arm)
--
-- Teachers now see the full record of only the students they teach in the
-- CURRENT session (as class teacher or subject teacher; for an optional
-- subject, only the students who take it), plus those students' parents,
-- links and placements. Past students stay reachable later only through the
-- academic work for the subject the teacher taught them (results,
-- assignments, projects), which the results tables will grant permanently.
-- Leaders and the bursar keep whole-school access.
-- Design notes: docs/subjects.md

-- ─────────────────────────────────────────────────────────────
-- subjects
-- ─────────────────────────────────────────────────────────────
create table public.subjects (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete restrict,
  name             text not null,
  code             text,
  sort_order       int  not null default 0,
  is_active        boolean not null default true,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint subjects_org_id_key unique (organization_id, id),
  constraint subjects_name_not_blank check (length(trim(name)) > 0),
  constraint subjects_code_format check (code ~ '^[A-Za-z0-9]{2,10}$')
);

alter table public.subjects enable row level security;

create unique index subjects_org_name_key on public.subjects (organization_id, lower(name));
create unique index subjects_org_code_key on public.subjects (organization_id, upper(code)) where code is not null;
create index subjects_org_sort_idx on public.subjects (organization_id, sort_order);

create trigger subjects_set_updated_at
  before update on public.subjects
  for each row execute function private.set_updated_at();

-- ─────────────────────────────────────────────────────────────
-- arm_subjects: the curriculum, per arm. Arms of the same class can differ
-- (SS 1 Science vs SS 1 Arts). Removing an arm or subject removes its links.
-- copy_arm_subjects / apply_standard_curriculum save re-entering lists.
-- ─────────────────────────────────────────────────────────────
create table public.arm_subjects (
  organization_id  uuid not null references public.organizations (id) on delete restrict,
  arm_id           uuid not null,
  subject_id       uuid not null,
  is_compulsory    boolean not null default true,
  created_at       timestamptz not null default now(),
  primary key (arm_id, subject_id),
  constraint arm_subjects_arm_fkey foreign key (organization_id, arm_id)
    references public.class_arms (organization_id, id) on delete cascade,
  constraint arm_subjects_subject_fkey foreign key (organization_id, subject_id)
    references public.subjects (organization_id, id) on delete cascade
);

alter table public.arm_subjects enable row level security;

create index arm_subjects_arm_idx on public.arm_subjects (organization_id, arm_id);
create index arm_subjects_subject_idx on public.arm_subjects (organization_id, subject_id);

-- Shared check: the subject must be on the arm's curriculum.
create function private.check_subject_offered_to_arm()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not exists (
    select 1
    from public.arm_subjects asub
    where asub.arm_id = new.arm_id
      and asub.subject_id = new.subject_id
  ) then
    raise exception 'This subject isn''t offered to this arm; add it to the arm''s subjects first'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- teaching_assignments: one teacher per subject per arm per session.
-- Changing the teacher updates the row.
-- ─────────────────────────────────────────────────────────────
create table public.teaching_assignments (
  organization_id  uuid not null references public.organizations (id) on delete restrict,
  session_id       uuid not null,
  arm_id           uuid not null,
  subject_id       uuid not null,
  staff_id         uuid not null,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  primary key (session_id, arm_id, subject_id),
  constraint teaching_assignments_session_fkey foreign key (organization_id, session_id)
    references public.academic_sessions (organization_id, id) on delete cascade,
  constraint teaching_assignments_arm_fkey foreign key (organization_id, arm_id)
    references public.class_arms (organization_id, id) on delete cascade,
  constraint teaching_assignments_subject_fkey foreign key (organization_id, subject_id)
    references public.subjects (organization_id, id) on delete restrict,
  constraint teaching_assignments_staff_fkey foreign key (organization_id, staff_id)
    references public.staff (organization_id, id) on delete cascade
);

alter table public.teaching_assignments enable row level security;

create index teaching_assignments_session_idx on public.teaching_assignments (organization_id, session_id);
create index teaching_assignments_arm_idx on public.teaching_assignments (organization_id, arm_id);
create index teaching_assignments_subject_idx on public.teaching_assignments (organization_id, subject_id);
create index teaching_assignments_staff_idx on public.teaching_assignments (organization_id, staff_id);

create trigger teaching_assignments_set_updated_at
  before update on public.teaching_assignments
  for each row execute function private.set_updated_at();

create trigger teaching_assignments_subject_offered
  before insert or update of arm_id, subject_id on public.teaching_assignments
  for each row execute function private.check_subject_offered_to_arm();

-- ─────────────────────────────────────────────────────────────
-- student_subjects: who takes each OPTIONAL subject, per session.
-- Compulsory subjects aren't listed here — everyone in the arm takes them.
-- ─────────────────────────────────────────────────────────────
create table public.student_subjects (
  organization_id  uuid not null references public.organizations (id) on delete restrict,
  student_id       uuid not null,
  session_id       uuid not null,
  subject_id       uuid not null,
  created_at       timestamptz not null default now(),
  primary key (student_id, session_id, subject_id),
  constraint student_subjects_student_fkey foreign key (organization_id, student_id)
    references public.students (organization_id, id) on delete cascade,
  constraint student_subjects_session_fkey foreign key (organization_id, session_id)
    references public.academic_sessions (organization_id, id) on delete restrict,
  constraint student_subjects_subject_fkey foreign key (organization_id, subject_id)
    references public.subjects (organization_id, id) on delete restrict
);

alter table public.student_subjects enable row level security;

create index student_subjects_student_idx on public.student_subjects (organization_id, student_id);
create index student_subjects_session_subject_idx on public.student_subjects (organization_id, session_id, subject_id);
create index student_subjects_subject_idx on public.student_subjects (organization_id, subject_id);

-- The student must be placed that session in an arm that offers the
-- subject, and the subject must be optional for that arm.
create function private.check_student_subject()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_compulsory boolean;
begin
  select asub.is_compulsory into v_compulsory
  from public.student_placements sp
  join public.arm_subjects asub on asub.arm_id = sp.arm_id and asub.subject_id = new.subject_id
  where sp.student_id = new.student_id
    and sp.session_id = new.session_id;

  if not found then
    raise exception 'The student isn''t placed that session in an arm that offers this subject'
      using errcode = '23514';
  end if;
  if v_compulsory then
    raise exception 'This subject is compulsory for the student''s arm, so every student already takes it'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger student_subjects_valid
  before insert on public.student_subjects
  for each row execute function private.check_student_subject();

-- ─────────────────────────────────────────────────────────────
-- Who a teacher teaches, this session
-- ─────────────────────────────────────────────────────────────

-- Students the caller teaches in the CURRENT session — placed in an arm
-- where, this session, the caller is:
--   · a class teacher (lead or assistant) → everyone in the arm
--   · teaching a compulsory subject       → everyone in the arm
--   · teaching an optional subject        → only students taking it
create function private.my_taught_student_ids()
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select sp.student_id
  from public.student_placements sp
  join public.academic_sessions s on s.id = sp.session_id and s.is_current
  join public.class_teachers ct on ct.session_id = sp.session_id and ct.arm_id = sp.arm_id
  where ct.staff_id in (select private.my_staff_ids())

  union

  select sp.student_id
  from public.student_placements sp
  join public.academic_sessions s on s.id = sp.session_id and s.is_current
  join public.teaching_assignments ta on ta.session_id = sp.session_id and ta.arm_id = sp.arm_id
  join public.arm_subjects asub on asub.arm_id = sp.arm_id and asub.subject_id = ta.subject_id
  where ta.staff_id in (select private.my_staff_ids())
    and asub.is_compulsory

  union

  select sp.student_id
  from public.student_placements sp
  join public.academic_sessions s on s.id = sp.session_id and s.is_current
  join public.teaching_assignments ta on ta.session_id = sp.session_id and ta.arm_id = sp.arm_id
  join public.arm_subjects asub on asub.arm_id = sp.arm_id and asub.subject_id = ta.subject_id
  join public.student_subjects ss on ss.student_id = sp.student_id
                                 and ss.session_id = sp.session_id
                                 and ss.subject_id = ta.subject_id
  where ta.staff_id in (select private.my_staff_ids())
    and not asub.is_compulsory;
$$;

-- Parents of the students the caller teaches.
create function private.my_taught_students_parent_ids()
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select sp.parent_id
  from public.student_parents sp
  where sp.student_id in (select private.my_taught_student_ids());
$$;

-- ─────────────────────────────────────────────────────────────
-- Narrow teachers' view (rename + new rules; the stored names of two of
-- these policies were already cut to 63 characters, used as stored).
-- Leaders and the bursar keep whole-school access.
-- ─────────────────────────────────────────────────────────────
alter policy "students: staff, own parents, self and platform admins can read" on public.students
  rename to "students: read by leaders, bursars, teachers, family, self";
alter policy "students: read by leaders, bursars, teachers, family, self" on public.students
  using (
    organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal', 'bursar']::public.member_role[]))
    or id in (select private.my_taught_student_ids())
    or id in (select private.my_child_ids())
    or member_id in (select private.my_member_ids())
    or (select private.is_platform_admin())
  );

alter policy "parents: staff, self, co-parents and platform admins can read" on public.parents
  rename to "parents: read by leaders, bursars, teachers, family, self";
alter policy "parents: read by leaders, bursars, teachers, family, self" on public.parents
  using (
    organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal', 'bursar']::public.member_role[]))
    or id in (select private.my_taught_students_parent_ids())
    or member_id in (select private.my_member_ids())
    or id in (select private.my_childrens_parent_ids())
    or (select private.is_platform_admin())
  );

alter policy "student_parents: staff, the child's parents, the student and pl" on public.student_parents
  rename to "student_parents: read by leaders, bursars, teachers, family";
alter policy "student_parents: read by leaders, bursars, teachers, family" on public.student_parents
  using (
    organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal', 'bursar']::public.member_role[]))
    or student_id in (select private.my_taught_student_ids())
    or student_id in (select private.my_child_ids())
    or student_id in (select private.my_student_ids())
    or (select private.is_platform_admin())
  );

alter policy "student_placements: staff, the child's parents, the student and" on public.student_placements
  rename to "student_placements: read by leaders, bursars, teachers, family";
alter policy "student_placements: read by leaders, bursars, teachers, family" on public.student_placements
  using (
    organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal', 'bursar']::public.member_role[]))
    or student_id in (select private.my_taught_student_ids())
    or student_id in (select private.my_child_ids())
    or student_id in (select private.my_student_ids())
    or (select private.is_platform_admin())
  );

-- ─────────────────────────────────────────────────────────────
-- Policies for the new tables
-- Leaders = owner, admin, principal, vice_principal.
-- ─────────────────────────────────────────────────────────────

-- subjects: school-wide reference data
create policy "subjects: members and platform admins can read"
  on public.subjects for select to authenticated
  using (organization_id in (select private.my_org_ids()) or (select private.is_platform_admin()));
create policy "subjects: leaders can add"
  on public.subjects for insert to authenticated
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
create policy "subjects: leaders can edit"
  on public.subjects for update to authenticated
  using      (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])))
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
create policy "subjects: owners and admins can delete"
  on public.subjects for delete to authenticated
  using (organization_id in (select private.my_org_ids(array['owner', 'admin']::public.member_role[])));

-- arm_subjects: school-wide reference data
create policy "arm_subjects: members and platform admins can read"
  on public.arm_subjects for select to authenticated
  using (organization_id in (select private.my_org_ids()) or (select private.is_platform_admin()));
create policy "arm_subjects: leaders can add"
  on public.arm_subjects for insert to authenticated
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
create policy "arm_subjects: leaders can edit"
  on public.arm_subjects for update to authenticated
  using      (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])))
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
create policy "arm_subjects: leaders can remove"
  on public.arm_subjects for delete to authenticated
  using (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));

-- teaching_assignments: any member can see who teaches what (parents see
-- their child's subject teachers)
create policy "teaching_assignments: members and platform admins can read"
  on public.teaching_assignments for select to authenticated
  using (organization_id in (select private.my_org_ids()) or (select private.is_platform_admin()));
create policy "teaching_assignments: leaders can assign"
  on public.teaching_assignments for insert to authenticated
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
create policy "teaching_assignments: leaders can change teacher"
  on public.teaching_assignments for update to authenticated
  using      (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])))
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
create policy "teaching_assignments: leaders can unassign"
  on public.teaching_assignments for delete to authenticated
  using (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));

-- student_subjects: read like students
create policy "student_subjects: read by leaders, bursars, teachers, family"
  on public.student_subjects for select to authenticated
  using (
    organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal', 'bursar']::public.member_role[]))
    or student_id in (select private.my_taught_student_ids())
    or student_id in (select private.my_child_ids())
    or student_id in (select private.my_student_ids())
    or (select private.is_platform_admin())
  );
create policy "student_subjects: leaders can enrol"
  on public.student_subjects for insert to authenticated
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
create policy "student_subjects: leaders can remove"
  on public.student_subjects for delete to authenticated
  using (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));

-- ─────────────────────────────────────────────────────────────
-- Standard Nigerian subjects and curriculum
-- ─────────────────────────────────────────────────────────────

-- The standard curriculum: which subjects (by name) a class level offers.
-- Levels match class names from the standard structure: "Nursery n",
-- "Primary n", "JSS n", "SS n".
create function private.standard_curriculum()
returns table (level text, subject text, is_compulsory boolean)
language sql
immutable
set search_path = ''
as $$
  with levels (level, compulsory, optional) as (
    values
      ('Nursery',
       array['Numeracy', 'Literacy', 'Phonics', 'Basic Science', 'Social Habits', 'Health Habits',
             'Cultural and Creative Arts', 'Rhymes', 'Handwriting'],
       array[]::text[]),
      ('Primary',
       array['English Language', 'Mathematics', 'Basic Science', 'Basic Technology', 'Social Studies',
             'Civic Education', 'Cultural and Creative Arts', 'Physical and Health Education',
             'Agricultural Science', 'Home Economics', 'Computer Studies', 'Nigerian Language',
             'Verbal Reasoning', 'Quantitative Reasoning'],
       array['Christian Religious Studies', 'Islamic Religious Studies', 'French']),
      ('JSS',
       array['English Language', 'Mathematics', 'Basic Science', 'Basic Technology', 'Social Studies',
             'Civic Education', 'Security Education', 'Cultural and Creative Arts',
             'Physical and Health Education', 'Agricultural Science', 'Home Economics',
             'Business Studies', 'Computer Studies', 'Nigerian Language'],
       array['Christian Religious Studies', 'Islamic Religious Studies', 'French']),
      ('SS',
       array['English Language', 'Mathematics', 'Civic Education'],
       array['Physics', 'Chemistry', 'Biology', 'Further Mathematics', 'Agricultural Science',
             'Geography', 'Economics', 'Government', 'Literature in English',
             'Christian Religious Studies', 'Islamic Religious Studies', 'History',
             'Financial Accounting', 'Commerce', 'Technical Drawing', 'Food and Nutrition',
             'Visual Arts', 'Computer Studies', 'Data Processing', 'Nigerian Language', 'French'])
  )
  select l.level, x.subject, true  from levels l, unnest(l.compulsory) as x (subject)
  union all
  select l.level, x.subject, false from levels l, unnest(l.optional)   as x (subject);
$$;

-- One-tap setup: a typical Nigerian catalogue (41 subjects), plus the
-- standard curriculum for every EXISTING arm of a standard-named class.
-- Create arms first; arms added later use apply_standard_curriculum or
-- copy_arm_subjects. Only for a school with no subjects yet; everything
-- stays editable. Runs as the caller (leaders only).
create function public.create_standard_subjects(p_organization_id uuid)
returns int
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_subjects int;
begin
  if not private.can_manage_academics(p_organization_id) then
    raise exception 'Only the school''s leaders can set up its subjects' using errcode = '42501';
  end if;

  if exists (select 1 from public.subjects s where s.organization_id = p_organization_id) then
    raise exception 'This school already has subjects; the standard list is only for a new school' using errcode = 'P0001';
  end if;

  -- catalogue, in report-card order
  insert into public.subjects (organization_id, name, code, sort_order)
  select p_organization_id, d.name, d.code, d.ord
  from (values
    ( 1, 'English Language',             'ENG'),
    ( 2, 'Mathematics',                  'MTH'),
    ( 3, 'Numeracy',                     'NUM'),
    ( 4, 'Literacy',                     'LTR'),
    ( 5, 'Phonics',                      'PHN'),
    ( 6, 'Basic Science',                'BSC'),
    ( 7, 'Basic Technology',             'BTE'),
    ( 8, 'Social Studies',               'SST'),
    ( 9, 'Civic Education',              'CVE'),
    (10, 'Security Education',           'SEC'),
    (11, 'Christian Religious Studies',  'CRS'),
    (12, 'Islamic Religious Studies',    'IRS'),
    (13, 'Cultural and Creative Arts',   'CCA'),
    (14, 'Physical and Health Education','PHE'),
    (15, 'Agricultural Science',         'AGR'),
    (16, 'Home Economics',               'HEC'),
    (17, 'Business Studies',             'BUS'),
    (18, 'Computer Studies',             'CMP'),
    (19, 'Nigerian Language',            'NGL'),
    (20, 'French',                       'FRE'),
    (21, 'Verbal Reasoning',             'VBR'),
    (22, 'Quantitative Reasoning',       'QTR'),
    (23, 'Social Habits',                'SOH'),
    (24, 'Health Habits',                'HEH'),
    (25, 'Rhymes',                       'RHY'),
    (26, 'Handwriting',                  'HWR'),
    (27, 'Physics',                      'PHY'),
    (28, 'Chemistry',                    'CHM'),
    (29, 'Biology',                      'BIO'),
    (30, 'Further Mathematics',          'FMT'),
    (31, 'Geography',                    'GEO'),
    (32, 'Economics',                    'ECO'),
    (33, 'Government',                   'GOV'),
    (34, 'Literature in English',        'LIT'),
    (35, 'History',                      'HIS'),
    (36, 'Financial Accounting',         'ACC'),
    (37, 'Commerce',                     'COM'),
    (38, 'Technical Drawing',            'TDR'),
    (39, 'Food and Nutrition',           'FNU'),
    (40, 'Visual Arts',                  'VAR'),
    (41, 'Data Processing',              'DPR')
  ) as d (ord, name, code);
  get diagnostics v_subjects = row_count;

  -- standard curriculum for every existing arm of a standard-named class
  insert into public.arm_subjects (organization_id, arm_id, subject_id, is_compulsory)
  select p_organization_id, a.id, s.id, sc.is_compulsory
  from private.standard_curriculum() sc
  join public.classes    c on c.organization_id = p_organization_id and c.name like sc.level || ' %'
  join public.class_arms a on a.class_id = c.id
  join public.subjects   s on s.organization_id = p_organization_id and s.name = sc.subject;

  return v_subjects;
end;
$$;

-- Give one arm the standard curriculum for its class level (e.g. a new
-- JSS 2 C). Adds what's missing, keeps what's there. Subjects are matched by
-- name in the school's catalogue, so renamed/deleted ones are skipped.
-- Returns how many subjects were added. Runs as the caller (leaders only).
create function public.apply_standard_curriculum(p_arm_id uuid)
returns int
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_org   uuid;
  v_class text;
  v_added int;
begin
  select a.organization_id, c.name into v_org, v_class
  from public.class_arms a
  join public.classes c on c.id = a.class_id
  where a.id = p_arm_id;

  if not found or not private.can_manage_academics(v_org) then
    raise exception 'Arm not found, or you can''t manage this school''s subjects' using errcode = '42501';
  end if;

  insert into public.arm_subjects (organization_id, arm_id, subject_id, is_compulsory)
  select v_org, p_arm_id, s.id, sc.is_compulsory
  from private.standard_curriculum() sc
  join public.subjects s on s.organization_id = v_org and s.name = sc.subject
  where v_class like sc.level || ' %'
  on conflict (arm_id, subject_id) do nothing;
  get diagnostics v_added = row_count;

  return v_added;
end;
$$;

-- Copy one arm's subjects to another arm of the same school (e.g. JSS 1A →
-- JSS 1B, or SS 1 Arts A → SS 1 Arts B). Adds what's missing with the same
-- compulsory/optional setting; keeps the target's existing subjects.
-- Returns how many subjects were added. Runs as the caller (leaders only).
create function public.copy_arm_subjects(p_from_arm_id uuid, p_to_arm_id uuid)
returns int
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_org   uuid;
  v_added int;
begin
  select a.organization_id into v_org
  from public.class_arms a
  where a.id = p_to_arm_id;

  if not found or not private.can_manage_academics(v_org)
     or not exists (select 1 from public.class_arms a where a.id = p_from_arm_id and a.organization_id = v_org) then
    raise exception 'Arm not found, or you can''t manage this school''s subjects' using errcode = '42501';
  end if;

  insert into public.arm_subjects (organization_id, arm_id, subject_id, is_compulsory)
  select v_org, p_to_arm_id, src.subject_id, src.is_compulsory
  from public.arm_subjects src
  where src.arm_id = p_from_arm_id
  on conflict (arm_id, subject_id) do nothing;
  get diagnostics v_added = row_count;

  return v_added;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- Preparing a new session
-- Leaders can set up the next session (placements, assignments) while the
-- old one is still current, then flip it with set_current_session.
-- Teachers' access follows the current session, so preparing first means
-- there's no gap.
-- ─────────────────────────────────────────────────────────────

-- Copy last session's class teachers and subject teachers onto the SAME
-- arms in another session. Anything the target already has is kept:
--   · class teachers are copied only for arms with none in the target yet
--   · a subject teacher is copied only where the target has none for that
--     arm + subject
-- Skips staff who have exited, inactive arms, and subjects the arm no
-- longer offers. Runs as the caller (leaders only).
create function public.copy_assignments_forward(p_from_session_id uuid, p_to_session_id uuid)
returns table (class_teachers_copied int, subject_teachers_copied int)
language plpgsql
security invoker
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_org uuid;
  v_ct  int;
  v_ta  int;
begin
  if p_from_session_id = p_to_session_id then
    raise exception 'Choose two different sessions' using errcode = '22023';
  end if;

  select s.organization_id into v_org
  from public.academic_sessions s
  where s.id = p_to_session_id;

  if not found or not private.can_manage_academics(v_org)
     or not exists (select 1 from public.academic_sessions s where s.id = p_from_session_id and s.organization_id = v_org) then
    raise exception 'Session not found, or you can''t manage this school''s calendar' using errcode = '42501';
  end if;

  insert into public.class_teachers (organization_id, session_id, arm_id, staff_id, is_lead)
  select v_org, p_to_session_id, ct.arm_id, ct.staff_id, ct.is_lead
  from public.class_teachers ct
  join public.class_arms a on a.id = ct.arm_id and a.is_active
  join public.staff st on st.id = ct.staff_id and st.status <> 'exited'
  where ct.session_id = p_from_session_id
    and not exists (
      select 1 from public.class_teachers x
      where x.session_id = p_to_session_id and x.arm_id = ct.arm_id
    )
  order by ct.is_lead desc;
  get diagnostics v_ct = row_count;

  insert into public.teaching_assignments (organization_id, session_id, arm_id, subject_id, staff_id)
  select v_org, p_to_session_id, ta.arm_id, ta.subject_id, ta.staff_id
  from public.teaching_assignments ta
  join public.class_arms a on a.id = ta.arm_id and a.is_active
  join public.arm_subjects asub on asub.arm_id = ta.arm_id and asub.subject_id = ta.subject_id
  join public.staff st on st.id = ta.staff_id and st.status <> 'exited'
  where ta.session_id = p_from_session_id
  on conflict (session_id, arm_id, subject_id) do nothing;
  get diagnostics v_ta = row_count;

  return query select v_ct, v_ta;
end;
$$;

-- What's still missing before a session is made current. The app shows
-- this (and warns) before calling set_current_session.
create function public.session_readiness(p_session_id uuid)
returns table (
  terms                         int,  -- terms created for the session
  students_placed               int,  -- students with a placement in the session
  active_students_not_placed    int,  -- active students with no placement yet
  arms_with_students            int,  -- arms that have at least one student
  arms_without_lead_teacher     int,  -- of those, arms with no lead class teacher
  subjects_without_teacher      int   -- arm subjects (in arms with students) with no teacher
)
language plpgsql
stable
security invoker
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_org uuid;
begin
  select s.organization_id into v_org
  from public.academic_sessions s
  where s.id = p_session_id;

  if not found or not private.can_manage_academics(v_org) then
    raise exception 'Session not found, or you can''t manage this school''s calendar' using errcode = '42501';
  end if;

  return query
  with placed as (
    select sp.student_id, sp.arm_id
    from public.student_placements sp
    where sp.session_id = p_session_id
  ),
  arms as (
    select distinct p.arm_id from placed p
  )
  select
    (select count(*) from public.academic_terms t where t.session_id = p_session_id)::int,
    (select count(*) from placed)::int,
    (select count(*) from public.students st
      where st.organization_id = v_org
        and st.status = 'active'
        and not exists (select 1 from placed p where p.student_id = st.id))::int,
    (select count(*) from arms)::int,
    (select count(*) from arms a
      where not exists (
        select 1 from public.class_teachers ct
        where ct.session_id = p_session_id and ct.arm_id = a.arm_id and ct.is_lead
      ))::int,
    (select count(*) from public.arm_subjects asub
      join arms a on a.arm_id = asub.arm_id
      where not exists (
        select 1 from public.teaching_assignments ta
        where ta.session_id = p_session_id and ta.arm_id = asub.arm_id and ta.subject_id = asub.subject_id
      ))::int;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- Privileges
-- ─────────────────────────────────────────────────────────────
revoke all on public.subjects             from anon, authenticated;
revoke all on public.arm_subjects         from anon, authenticated;
revoke all on public.teaching_assignments from anon, authenticated;
revoke all on public.student_subjects     from anon, authenticated;

grant select, delete on public.subjects to authenticated;
grant insert (id, organization_id, name, code, sort_order, is_active) on public.subjects to authenticated;
grant update (name, code, sort_order, is_active) on public.subjects to authenticated;

grant select, delete on public.arm_subjects to authenticated;
grant insert (organization_id, arm_id, subject_id, is_compulsory) on public.arm_subjects to authenticated;
grant update (is_compulsory) on public.arm_subjects to authenticated;

grant select, delete on public.teaching_assignments to authenticated;
grant insert (organization_id, session_id, arm_id, subject_id, staff_id) on public.teaching_assignments to authenticated;
grant update (staff_id) on public.teaching_assignments to authenticated;

grant select, delete on public.student_subjects to authenticated;
grant insert (organization_id, student_id, session_id, subject_id) on public.student_subjects to authenticated;

revoke execute on function private.check_subject_offered_to_arm()   from public, anon, authenticated;
revoke execute on function private.check_student_subject()          from public, anon, authenticated;
revoke execute on function private.my_taught_student_ids()          from public, anon;
revoke execute on function private.my_taught_students_parent_ids()  from public, anon;
grant  execute on function private.my_taught_student_ids()          to authenticated;
grant  execute on function private.my_taught_students_parent_ids()  to authenticated;

revoke execute on function private.standard_curriculum() from public, anon;
grant  execute on function private.standard_curriculum() to authenticated;

revoke execute on function public.create_standard_subjects(uuid)        from public, anon;
revoke execute on function public.apply_standard_curriculum(uuid)       from public, anon;
revoke execute on function public.copy_arm_subjects(uuid, uuid)         from public, anon;
grant  execute on function public.create_standard_subjects(uuid)        to authenticated;
grant  execute on function public.apply_standard_curriculum(uuid)       to authenticated;
grant  execute on function public.copy_arm_subjects(uuid, uuid)         to authenticated;

revoke execute on function public.copy_assignments_forward(uuid, uuid)  from public, anon;
revoke execute on function public.session_readiness(uuid)               from public, anon;
grant  execute on function public.copy_assignments_forward(uuid, uuid)  to authenticated;
grant  execute on function public.session_readiness(uuid)               to authenticated;
