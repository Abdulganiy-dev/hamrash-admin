-- 39 · Standard structure in the four Nigerian school sections
--
-- Nigerian schools run four sections, each with its own head and, in
-- secondary, its own exams: Nursery, Primary, Junior Secondary (JSS 1–3,
-- BECE) and Senior Secondary (SS 1–3, WAEC/NECO). Migration 04's one-tap
-- structure put JSS and SS together in one "Secondary" section, so a school
-- couldn't give Junior and Senior Secondary their own head, grading or
-- switch. This splits it:
--
--   Nursery           Nursery 1–3
--   Primary           Primary 1–6
--   Junior Secondary  JSS 1–3
--   Senior Secondary  SS 1–3   (SS 3 still the graduating class)
--
-- Same 15 classes with the same names, so create_standard_subjects,
-- apply_standard_curriculum and private.standard_curriculum need no change:
-- they match the curriculum by class name ("Nursery n", "Primary n",
-- "JSS n", "SS n"), not by section.
--
-- create_standard_grading gave a section named "Secondary" the WAEC grades
-- (A1–F9). It now gives them to "Senior Secondary", where WAEC is written.
-- Junior Secondary uses the school's A–F, which every section falls back
-- to; leaders can give it its own scale later. A school set up before this
-- migration still has "Secondary", so that name keeps getting WAEC too.
--
-- Existing schools are not changed: no section is renamed or split, and
-- both functions still refuse a school that already has sections or a
-- grading setup.
--
-- Security: unchanged. create_standard_structure stays security invoker
-- (RLS and the leader check decide); create_standard_grading stays security
-- definer with its explicit leader check, writing only p_organization_id.
--
-- No DROP: create or replace, same signatures and return types.
-- Test: supabase/tests/26_standard_structure_four_sections_test.sql
-- (tests 05 and 21 now read the WAEC scale from Senior Secondary).

create or replace function public.create_standard_structure(p_organization_id uuid)
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
      (1, 'Nursery',          array['Nursery 1', 'Nursery 2', 'Nursery 3']),
      (2, 'Primary',          array['Primary 1', 'Primary 2', 'Primary 3', 'Primary 4', 'Primary 5', 'Primary 6']),
      (3, 'Junior Secondary', array['JSS 1', 'JSS 2', 'JSS 3']),
      (4, 'Senior Secondary', array['SS 1', 'SS 2', 'SS 3'])
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

-- One-tap standard grading (migrations 08 and 34): the school's CA 1 (20) +
-- CA 2 (20) + Exam (60) and A–F; WAEC grades for "Senior Secondary" (or a
-- pre-39 "Secondary"). Only the section lookup changed.
create or replace function public.create_standard_grading(p_organization_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_section uuid;
begin
  if p_organization_id is null or not private.can_manage_academics(p_organization_id) then
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

  insert into public.grade_boundaries (organization_id, grade, min_percent, max_percent, remark, is_pass)
  values (p_organization_id, 'A', 70, 100, 'Excellent', true),
         (p_organization_id, 'B', 60,  69, 'Very Good', true),
         (p_organization_id, 'C', 50,  59, 'Good',      true),
         (p_organization_id, 'D', 45,  49, 'Fair',      true),
         (p_organization_id, 'E', 40,  44, 'Pass',      true),
         (p_organization_id, 'F',  0,  39, 'Fail',      false);

  -- WAEC grade boundaries for each senior section: "Senior Secondary", or
  -- "Secondary" in a school set up before migration 39
  for v_section in
    select s.id
    from public.sections s
    where s.organization_id = p_organization_id
      and lower(s.name) in ('senior secondary', 'secondary')
  loop
    insert into public.grade_boundaries (organization_id, section_id, grade, min_percent, max_percent, remark, is_pass)
    values (p_organization_id, v_section, 'A1', 75, 100, 'Excellent', true),
           (p_organization_id, v_section, 'B2', 70,  74, 'Very Good', true),
           (p_organization_id, v_section, 'B3', 65,  69, 'Good',      true),
           (p_organization_id, v_section, 'C4', 60,  64, 'Credit',    true),
           (p_organization_id, v_section, 'C5', 55,  59, 'Credit',    true),
           (p_organization_id, v_section, 'C6', 50,  54, 'Credit',    true),
           (p_organization_id, v_section, 'D7', 45,  49, 'Pass',      true),
           (p_organization_id, v_section, 'E8', 40,  44, 'Pass',      true),
           (p_organization_id, v_section, 'F9',  0,  39, 'Fail',      false);
  end loop;
end;
$$;
