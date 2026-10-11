-- 08 · Grading setup: score columns and grade boundaries
--
--   score_columns      CA 1 (20) · CA 2 (20) · Exam (60) …
--   grade_boundaries   where each grade starts: A1 75% · B2 70% … F9 0%
--
-- Behaviour traits and their 1–5 ratings are a fixed list in the app; the
-- gradebook migration stores them as an enum on the behaviour ratings.
--
-- score_columns and grade_boundaries rows with section_id = null are the
-- SCHOOL's setup; rows with a section_id are that section's own. An arm uses
-- its section's score columns if the section has any, otherwise the
-- school's — and the same, independently, for grade boundaries. So Secondary
-- can keep the school's columns and only change its grade boundaries.
--
-- A subject's percentage = total ÷ (sum of the score columns' max scores)
-- × 100, and its grade is the highest boundary it reaches, so decimals like
-- 74.5 can never fall into a gap. Scores (and the rule protecting score
-- columns once scores exist) come in the gradebook migration.
-- Design notes: docs/results-design.md

-- ─────────────────────────────────────────────────────────────
-- score_columns: the columns a term's score is made of, each with a max.
-- section_id null = the school's columns.
-- ─────────────────────────────────────────────────────────────
create table public.score_columns (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete restrict,
  section_id       uuid,
  name             text not null,
  max_score        numeric(6, 2) not null,
  sort_order       int  not null default 0,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint score_columns_org_id_key unique (organization_id, id),
  constraint score_columns_section_fkey foreign key (organization_id, section_id)
    references public.sections (organization_id, id) on delete cascade,
  constraint score_columns_name_not_blank check (length(trim(name)) > 0),
  constraint score_columns_max_positive check (max_score > 0)
);

alter table public.score_columns enable row level security;

-- names unique within the school's set and within each section's set
create unique index score_columns_scope_name_key
  on public.score_columns (organization_id, section_id, lower(name)) nulls not distinct;

create trigger score_columns_set_updated_at
  before update on public.score_columns
  for each row execute function private.set_updated_at();

-- ─────────────────────────────────────────────────────────────
-- grade_boundaries: where each grade starts. A percentage gets the grade
-- with the highest min_percent it reaches. section_id null = the school's.
-- A set is complete when it has a boundary at 0%.
-- ─────────────────────────────────────────────────────────────
create table public.grade_boundaries (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete restrict,
  section_id       uuid,
  grade            text not null,
  min_percent      numeric(5, 2) not null,
  remark           text,
  is_pass          boolean not null default true,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint grade_boundaries_org_id_key unique (organization_id, id),
  constraint grade_boundaries_section_fkey foreign key (organization_id, section_id)
    references public.sections (organization_id, id) on delete cascade,
  constraint grade_boundaries_grade_not_blank check (length(trim(grade)) > 0),
  constraint grade_boundaries_threshold_range check (min_percent >= 0 and min_percent < 100)
);

alter table public.grade_boundaries enable row level security;

-- one grade per starting point, and grade names unique, within each set
create unique index grade_boundaries_scope_threshold_key
  on public.grade_boundaries (organization_id, section_id, min_percent) nulls not distinct;
create unique index grade_boundaries_scope_grade_key
  on public.grade_boundaries (organization_id, section_id, lower(grade)) nulls not distinct;

create trigger grade_boundaries_set_updated_at
  before update on public.grade_boundaries
  for each row execute function private.set_updated_at();

-- ─────────────────────────────────────────────────────────────
-- Lookups the gradebook and report cards will use
-- ─────────────────────────────────────────────────────────────

-- The score columns an arm uses: its section's own if it has any,
-- otherwise the school's. In report-card order.
create function public.score_columns_for_arm(p_arm_id uuid)
returns setof public.score_columns
language sql
stable
security invoker
set search_path = ''
as $$
  with arm as (
    select a.organization_id, c.section_id
    from public.class_arms a
    join public.classes c on c.id = a.class_id
    where a.id = p_arm_id
  ),
  scope as (
    select arm.organization_id,
           case when exists (select 1 from public.score_columns x where x.section_id = arm.section_id)
                then arm.section_id end as section_id
    from arm
  )
  select sc.*
  from public.score_columns sc
  join scope on sc.organization_id = scope.organization_id
            and sc.section_id is not distinct from scope.section_id
  order by sc.sort_order, sc.name;
$$;

-- The grade boundaries an arm uses: its section's own if it has any,
-- otherwise the school's. Highest first.
create function public.grade_boundaries_for_arm(p_arm_id uuid)
returns setof public.grade_boundaries
language sql
stable
security invoker
set search_path = ''
as $$
  with arm as (
    select a.organization_id, c.section_id
    from public.class_arms a
    join public.classes c on c.id = a.class_id
    where a.id = p_arm_id
  ),
  scope as (
    select arm.organization_id,
           case when exists (select 1 from public.grade_boundaries x where x.section_id = arm.section_id)
                then arm.section_id end as section_id
    from arm
  )
  select gb.*
  from public.grade_boundaries gb
  join scope on gb.organization_id = scope.organization_id
            and gb.section_id is not distinct from scope.section_id
  order by gb.min_percent desc;
$$;

-- The grade a percentage gets in an arm (null if its boundaries don't reach
-- down that far, i.e. the setup is incomplete).
create function public.grade_for(p_arm_id uuid, p_percent numeric)
returns public.grade_boundaries
language sql
stable
security invoker
set search_path = ''
as $$
  select gb.*
  from public.grade_boundaries_for_arm(p_arm_id) gb
  where gb.min_percent <= p_percent
  order by gb.min_percent desc
  limit 1;
$$;

-- What's missing before a section (or, with no section, the school) can be
-- graded — taking the fall-back to the school's setup into account.
create function public.grading_problems(p_organization_id uuid, p_section_id uuid default null)
returns text[]
language sql
stable
security invoker
set search_path = ''
as $$
  with scope as (
    select
      case when p_section_id is not null
                and exists (select 1 from public.score_columns x where x.section_id = p_section_id)
           then p_section_id end as columns_section,
      case when p_section_id is not null
                and exists (select 1 from public.grade_boundaries x where x.section_id = p_section_id)
           then p_section_id end as boundaries_section
  )
  select array_remove(array[
    case when not exists (
           select 1 from public.score_columns sc, scope
           where sc.organization_id = p_organization_id
             and sc.section_id is not distinct from scope.columns_section)
         then 'No score columns yet' end,
    case when not exists (
           select 1 from public.grade_boundaries gb, scope
           where gb.organization_id = p_organization_id
             and gb.section_id is not distinct from scope.boundaries_section
             and gb.min_percent = 0)
         then 'No grade boundary at 0%' end
  ], null)
  from scope;
$$;

-- ─────────────────────────────────────────────────────────────
-- Policies (school-wide reference data: every member reads, leaders write)
-- Leaders = owner, admin, principal, vice_principal.
-- ─────────────────────────────────────────────────────────────
create policy "score_columns: members and platform admins can read"
  on public.score_columns for select to authenticated
  using (organization_id in (select private.my_org_ids()) or (select private.is_platform_admin()));
create policy "score_columns: leaders can add"
  on public.score_columns for insert to authenticated
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
create policy "score_columns: leaders can edit"
  on public.score_columns for update to authenticated
  using      (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])))
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
create policy "score_columns: leaders can remove"
  on public.score_columns for delete to authenticated
  using (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));

create policy "grade_boundaries: members and platform admins can read"
  on public.grade_boundaries for select to authenticated
  using (organization_id in (select private.my_org_ids()) or (select private.is_platform_admin()));
create policy "grade_boundaries: leaders can add"
  on public.grade_boundaries for insert to authenticated
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
create policy "grade_boundaries: leaders can edit"
  on public.grade_boundaries for update to authenticated
  using      (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])))
  with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
create policy "grade_boundaries: leaders can remove"
  on public.grade_boundaries for delete to authenticated
  using (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));

-- ─────────────────────────────────────────────────────────────
-- One-tap standard setup
--   the school's (used by Nursery and Primary):
--     score columns CA 1 (20) + CA 2 (20) + Exam (60)
--     grades A 70 · B 60 · C 50 · D 45 · E 40 · F 0
--   "Secondary" section, if it exists: its own grade boundaries only (WAEC)
--     A1 75 · B2 70 · B3 65 · C4 60 · C5 55 · C6 50 · D7 45 · E8 40 · F9 0
--     — it keeps the school's score columns
-- Only for a school with no grading setup yet; everything stays editable.
-- Runs as the caller (leaders only).
-- ─────────────────────────────────────────────────────────────
create function public.create_standard_grading(p_organization_id uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_secondary uuid;
begin
  if not private.can_manage_academics(p_organization_id) then
    raise exception 'Only the school''s leaders can set up grading' using errcode = '42501';
  end if;

  if exists (select 1 from public.score_columns x where x.organization_id = p_organization_id)
     or exists (select 1 from public.grade_boundaries x where x.organization_id = p_organization_id) then
    raise exception 'This school already has a grading setup; the standard one is only for a new school' using errcode = 'P0001';
  end if;

  -- the school's score columns and grade boundaries
  insert into public.score_columns (organization_id, name, max_score, sort_order)
  values (p_organization_id, 'CA 1', 20, 1),
         (p_organization_id, 'CA 2', 20, 2),
         (p_organization_id, 'Exam', 60, 3);

  insert into public.grade_boundaries (organization_id, grade, min_percent, remark, is_pass)
  values (p_organization_id, 'A', 70, 'Excellent', true),
         (p_organization_id, 'B', 60, 'Very Good', true),
         (p_organization_id, 'C', 50, 'Good',      true),
         (p_organization_id, 'D', 45, 'Fair',      true),
         (p_organization_id, 'E', 40, 'Pass',      true),
         (p_organization_id, 'F',  0, 'Fail',      false);

  -- WAEC grade boundaries for a section named "Secondary"
  select s.id into v_secondary
  from public.sections s
  where s.organization_id = p_organization_id and lower(s.name) = 'secondary';

  if found then
    insert into public.grade_boundaries (organization_id, section_id, grade, min_percent, remark, is_pass)
    values (p_organization_id, v_secondary, 'A1', 75, 'Excellent', true),
           (p_organization_id, v_secondary, 'B2', 70, 'Very Good', true),
           (p_organization_id, v_secondary, 'B3', 65, 'Good',      true),
           (p_organization_id, v_secondary, 'C4', 60, 'Credit',    true),
           (p_organization_id, v_secondary, 'C5', 55, 'Credit',    true),
           (p_organization_id, v_secondary, 'C6', 50, 'Credit',    true),
           (p_organization_id, v_secondary, 'D7', 45, 'Pass',      true),
           (p_organization_id, v_secondary, 'E8', 40, 'Pass',      true),
           (p_organization_id, v_secondary, 'F9',  0, 'Fail',      false);
  end if;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- Privileges
-- ─────────────────────────────────────────────────────────────
revoke all on public.score_columns          from anon, authenticated;
revoke all on public.grade_boundaries       from anon, authenticated;

grant select, delete on public.score_columns to authenticated;
grant insert (id, organization_id, section_id, name, max_score, sort_order) on public.score_columns to authenticated;
grant update (name, max_score, sort_order) on public.score_columns to authenticated;

grant select, delete on public.grade_boundaries to authenticated;
grant insert (id, organization_id, section_id, grade, min_percent, remark, is_pass) on public.grade_boundaries to authenticated;
grant update (grade, min_percent, remark, is_pass) on public.grade_boundaries to authenticated;

revoke execute on function public.score_columns_for_arm(uuid)       from public, anon;
revoke execute on function public.grade_boundaries_for_arm(uuid)    from public, anon;
revoke execute on function public.grade_for(uuid, numeric)          from public, anon;
revoke execute on function public.grading_problems(uuid, uuid)      from public, anon;
revoke execute on function public.create_standard_grading(uuid)     from public, anon;
grant  execute on function public.score_columns_for_arm(uuid)       to authenticated;
grant  execute on function public.grade_boundaries_for_arm(uuid)    to authenticated;
grant  execute on function public.grade_for(uuid, numeric)          to authenticated;
grant  execute on function public.grading_problems(uuid, uuid)      to authenticated;
grant  execute on function public.create_standard_grading(uuid)     to authenticated;
