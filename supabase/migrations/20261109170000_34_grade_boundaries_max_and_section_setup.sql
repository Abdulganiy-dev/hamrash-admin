-- 34 · Grade ranges with a maximum, and whole-set grading writes per section
--
-- !! THE APP MUST BE UPDATED BEFORE THIS IS APPLIED. Today's Grading screen
-- !! (GradingService) inserts, updates and deletes grade_boundaries rows
-- !! directly. This migration revokes those writes, so every grade change in
-- !! the current app would fail with "permission denied". Ship the app that
-- !! calls the RPCs below first, then apply this. (TODO.md: "App must follow
-- !! migration 34".)
--
-- The Grading redesign (Paper "§ 9b · Grading by section") gives every
-- section its own score columns and its own grade scale. Three problems:
--
-- 1. grade_boundaries stored only where a grade starts (min_percent). The new
--    sheets have From and To fields, so the end is stored too: max_percent.
-- 2. Setting up, copying or editing a section's scale was several separate
--    row writes. A section with ANY grade rows replaces the school's scale
--    (migration 08's fall-back), so a half-written scale would block report
--    cards for that section. Every grade write now replaces a whole set in
--    one call, and the database refuses a set that doesn't cover 0 to 100.
-- 3. create_standard_grading is school-level only. apply_grade_system puts
--    the WAEC or the standard scale on any section, and copy_section_grading
--    gives a section its own copy of another set ("Give Primary its own
--    setup").
--
-- The rule (owner's decision): whole-number ranges, rounded first.
--   * min_percent and max_percent are whole numbers, min <= max <= 100.
--   * In a set, ranges tile 0 to 100 exactly: the lowest grade starts at 0,
--     each grade starts at the grade below's max + 1, the top ends at 100.
--     No gaps, no overlaps. An empty set is fine (the section falls back to
--     the school's scale).
--   * A percentage is rounded half-up to a whole number before it is graded
--     (grade_for), so nothing falls between 69 and 70. Decimal starts like
--     69.5 are no longer allowed.
--
-- What this file does, in order:
--   1. Stops (and changes nothing) if any existing min_percent has a
--      fractional part, listing those rows. Fix them first.
--   2. Adds max_percent and fills it per set: the next higher grade's start
--      minus 1, and 100 for the top grade. A legacy set that doesn't start at
--      0 is filled the same way and left as it is (incomplete) until someone
--      replaces it; grading_problems reports it. Then max_percent is NOT NULL,
--      and whole-number and range checks replace the old threshold check.
--   3. A deferred constraint trigger checks, at commit, that every set
--      touched in the transaction still tiles 0 to 100 (or is empty).
--   4. New RPCs, all security definer (see "Security" below):
--        set_grade_scale             replace one set's grades with a list
--        apply_grade_system          put the WAEC or standard preset on a section
--        copy_section_grading        copy columns and/or grades into a section
--        remove_section_grade_scale  a section uses the school's scale again
--   5. create_standard_grading writes max_percent (and becomes security
--      definer, because it inserts grade rows); grade_for rounds first;
--      grading_problems also reports a set that doesn't tile.
--   6. Revokes INSERT, UPDATE and DELETE on grade_boundaries from
--      authenticated (SELECT stays) and drops the three write policies.
--
-- Score columns are unchanged: single-row add, edit and remove keep their
-- grants and policies, and reorder_score_columns (migration 33) stays. Only
-- copying a whole set of columns goes through copy_section_grading.
--
-- How the deferred trigger and the RPCs work together:
--   * Each RPC validates the whole new set itself and refuses with a readable
--     P0001 BEFORE writing, so a refusal changes nothing. Then it deletes the
--     set's rows and inserts the new ones in the same transaction. Between the
--     delete and the inserts the set is briefly empty or partial; that is
--     fine, because the trigger is INITIALLY DEFERRED: it runs once per
--     touched row at COMMIT (the end of the PostgREST request), by which time
--     the set is whole. It looks at the set as it is then, so the delete's and
--     the inserts' checks all see the final rows.
--   * The trigger is defence in depth: through the RPCs it should never fire.
--     It catches a write made any other way (the SQL editor, a future
--     function) that would leave a set with a gap or an overlap, with 23514.
--   * Deleting a section cascades to its grade rows (on delete cascade). The
--     trigger fires for those deletes too, finds the set empty, and accepts
--     it, so deleting a section still works.
--   * Sets nobody touches are never checked, so a legacy incomplete set does
--     not block anything until it is replaced (with set_grade_scale) or
--     removed. Editing one row of such a set directly (SQL editor) is
--     refused at commit, because the set as a whole doesn't tile.
--   * Unique indexes are not deferred, but the RPCs delete before they
--     insert, so a replaced set never collides with its own old rows.
--
-- Locking: every RPC takes a transaction-level advisory lock per set it
-- writes (private.lock_grading_set: key = school + section, or school +
-- 'school' for the school-level set). Two leaders changing the same set queue
-- one behind the other; the second replaces the first's result as a whole.
-- copy_section_grading locks the source and the target, in a fixed order, so
-- the source can't change under it and two copies can't deadlock. Direct
-- single-row score column writes (allowed as before) don't take this lock; if
-- one races a column copy into the same section, one of them gets the unique
-- name error and nothing is half done.
--
-- Security: the four new RPCs and create_standard_grading are security
-- definer with search_path = '', because authenticated no longer has write
-- privileges on grade_boundaries. As definer they bypass RLS, so each one
-- checks everything RLS used to, explicitly, before any write:
--   * the caller is a leader of p_organization_id (owner, admin, principal,
--     vice principal) via private.can_manage_academics, which reads the
--     caller's own JWT sub (42501). A null school is refused the same way;
--   * every section id is a section OF THAT SCHOOL. Another school's section
--     gets "That section no longer exists; refresh and try again", the same
--     message as a deleted one, so nothing leaks about other schools;
--   * every write names p_organization_id and the checked section, never an
--     id taken from the payload; the jsonb only carries grade values.
-- The private helpers that write or lock (replace_grade_scale,
-- lock_grading_set) have no EXECUTE for clients at all; only these definer
-- functions (owned by postgres) call them. EXECUTE on every new public
-- function: revoked from public and anon, granted to authenticated.
--
-- Columns copied by copy_section_grading REPLACE the target section's own
-- columns. Once the gradebook exists, scores will reference score columns;
-- replacing columns that already have scores will then be refused by that
-- foreign key and the whole call changes nothing. That is intended: a section
-- with scores keeps its columns.
--
-- Requires migrations 08 and 33. No DROP of anything a client used, except
-- the three grade_boundaries write policies (unusable once the grants go).
-- Test: supabase/tests/21_grade_scales_test.sql (and 05, updated).
-- Design notes: docs/results-design.md (08 · Grading setup)

-- ─────────────────────────────────────────────────────────────
-- 1. Refuse to backfill decimal starts; the owner fixes them first
-- ─────────────────────────────────────────────────────────────
-- Blocks grade writes until this transaction ends, so nothing changes between
-- this check and the backfill.
lock table public.grade_boundaries in share row exclusive mode;

do $$
declare
  v_bad text;
begin
  select string_agg(
           format('%s (id %s, school %s, %s) starts at %s',
                  gb.grade, gb.id, gb.organization_id,
                  coalesce('section ' || gb.section_id::text, 'school-level'),
                  gb.min_percent),
           '; ' order by gb.organization_id, gb.section_id nulls first, gb.min_percent)
    into v_bad
  from public.grade_boundaries gb
  where gb.min_percent <> trunc(gb.min_percent);

  if v_bad is not null then
    raise exception 'Migration 34 stopped before changing anything: these grades start at a decimal percentage, which is no longer allowed. Change each to a whole number (or delete it), then run the migration again: %', v_bad
      using errcode = 'P0001';
  end if;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- 2. max_percent: add, backfill per set, then require it
-- ─────────────────────────────────────────────────────────────
alter table public.grade_boundaries
  add column max_percent numeric(5, 2);

-- Per set (school + section; nulls form one partition, the school-level
-- set): the next higher grade's start minus 1, or 100 for the top grade.
-- Starts are whole and unique within a set, so max >= min always holds.
-- A set that doesn't start at 0 is filled the same way and stays incomplete.
-- The updated_at trigger is paused so the backfill doesn't look like an edit.
alter table public.grade_boundaries disable trigger grade_boundaries_set_updated_at;

update public.grade_boundaries gb
set max_percent = n.next_max
from (
  select x.id,
         coalesce(lead(x.min_percent) over (partition by x.organization_id, x.section_id
                                            order by x.min_percent) - 1,
                  100) as next_max
  from public.grade_boundaries x
) n
where n.id = gb.id;

alter table public.grade_boundaries enable trigger grade_boundaries_set_updated_at;

alter table public.grade_boundaries
  alter column max_percent set not null;

-- The old check (0 <= min < 100) gives way to whole numbers and min <= max <= 100.
alter table public.grade_boundaries
  drop constraint grade_boundaries_threshold_range;
alter table public.grade_boundaries
  add constraint grade_boundaries_min_whole check (min_percent = trunc(min_percent)),
  add constraint grade_boundaries_max_whole check (max_percent = trunc(max_percent)),
  add constraint grade_boundaries_range check (min_percent >= 0 and min_percent <= max_percent and max_percent <= 100);

-- The unique indexes from migration 08 stay: one start per set
-- (grade_boundaries_scope_threshold_key) and one name per set, any case
-- (grade_boundaries_scope_grade_key).

-- ─────────────────────────────────────────────────────────────
-- 3. Helpers
-- ─────────────────────────────────────────────────────────────

-- True when the ranges (min_percent[i], max_percent[i]) tile 0 to 100
-- exactly: the lowest starts at 0, each starts at the one below's max + 1,
-- min <= max, the top ends at 100. False for an empty list. Pure; used by
-- the scale trigger, copy_section_grading and grading_problems.
create function private.grade_ranges_tile(p_mins numeric[], p_maxs numeric[])
returns boolean
language sql
immutable
set search_path = ''
as $$
  with r as (
    select u.mn, u.mx,
           lag(u.mx) over (order by u.mn, u.mx) as prev_max,
           row_number() over (order by u.mn, u.mx) as i,
           count(*) over () as n
    from unnest(p_mins, p_maxs) as u (mn, mx)
  )
  select coalesce(bool_and(
           r.mn is not null and r.mx is not null and r.mn <= r.mx
           and case when r.i = 1 then r.mn = 0 else r.mn = r.prev_max + 1 end
           and (r.i < r.n or r.mx = 100)
         ), false)
  from r;
$$;

-- Serialises writers of one grading set (a school's school-level set when
-- p_section_id is null, otherwise one section's) until the transaction ends.
create function private.lock_grading_set(p_organization_id uuid, p_section_id uuid)
returns void
language sql
volatile
set search_path = ''
as $$
  select pg_advisory_xact_lock(
    hashtextextended('grading_set:' || p_organization_id::text || ':' || coalesce(p_section_id::text, 'school'), 0)
  );
$$;

-- Validates p_grades (the whole new grade scale of one set) and, only if all
-- of it is valid, replaces that set's rows with it. Called only by the
-- security-definer RPCs below, AFTER they have checked the caller and the
-- section and taken the set's lock; clients can't execute it.
-- Each element: {grade, min_percent, max_percent, remark, is_pass}. Other
-- keys (an id the app sends back, say) are ignored. Rows are replaced, so
-- grade ids change; nothing references grade_boundaries ids.
create function private.replace_grade_scale(p_organization_id uuid, p_section_id uuid, p_grades jsonb)
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_item     jsonb;
  v_name     text;
  v_min      numeric;
  v_max      numeric;
  v_names    text[]    := '{}';
  v_mins     numeric[] := '{}';
  v_maxs     numeric[] := '{}';
  v_remarks  text[]    := '{}';
  v_passes   boolean[] := '{}';
  v_expected numeric   := 0;
  v_gap      text;
  r          record;
begin
  -- ── the list ────────────────────────────────────────────────
  if p_grades is null or jsonb_typeof(p_grades) <> 'array' then
    raise exception 'Send the grade scale as a list of grades' using errcode = 'P0001';
  end if;
  if jsonb_array_length(p_grades) = 0 then
    raise exception 'Add at least one grade' using errcode = 'P0001';
  end if;
  if jsonb_array_length(p_grades) > 20 then
    raise exception 'A grade scale can have at most 20 grades' using errcode = 'P0001';
  end if;

  -- ── each grade ──────────────────────────────────────────────
  for v_item in select e from jsonb_array_elements(p_grades) as t (e) loop
    if jsonb_typeof(v_item) <> 'object' then
      raise exception 'Each grade needs a name, a from and to percentage, a remark and whether it is a pass'
        using errcode = 'P0001';
    end if;

    if jsonb_typeof(v_item -> 'grade') is distinct from 'string'
       or nullif(trim(v_item ->> 'grade'), '') is null then
      raise exception 'Every grade needs a name' using errcode = 'P0001';
    end if;
    v_name := trim(v_item ->> 'grade');

    if lower(v_name) in (select lower(x) from unnest(v_names) as t (x)) then
      raise exception 'Two grades are called %. Give each grade its own name', v_name using errcode = 'P0001';
    end if;

    if jsonb_typeof(v_item -> 'min_percent') is distinct from 'number'
       or jsonb_typeof(v_item -> 'max_percent') is distinct from 'number' then
      raise exception 'Grade %: from and to must be whole numbers from 0 to 100', v_name using errcode = 'P0001';
    end if;
    v_min := (v_item ->> 'min_percent')::numeric;
    v_max := (v_item ->> 'max_percent')::numeric;
    if v_min <> trunc(v_min) or v_max <> trunc(v_max) or v_min < 0 or v_max > 100 then
      raise exception 'Grade %: from and to must be whole numbers from 0 to 100', v_name using errcode = 'P0001';
    end if;
    v_min := trunc(v_min);
    v_max := trunc(v_max);
    if v_min > v_max then
      raise exception 'Grade %: from (%) is higher than to (%)', v_name, v_min, v_max using errcode = 'P0001';
    end if;

    if jsonb_typeof(v_item -> 'remark') not in ('string', 'null') then
      raise exception 'Grade %: the remark must be text', v_name using errcode = 'P0001';
    end if;

    if jsonb_typeof(v_item -> 'is_pass') is distinct from 'boolean' then
      raise exception 'Grade %: say whether it is a pass grade', v_name using errcode = 'P0001';
    end if;

    v_names   := array_append(v_names, v_name);
    v_mins    := array_append(v_mins, v_min);
    v_maxs    := array_append(v_maxs, v_max);
    v_remarks := array_append(v_remarks, nullif(trim(v_item ->> 'remark'), ''));
    v_passes  := array_append(v_passes, (v_item -> 'is_pass') = 'true'::jsonb);
  end loop;

  -- ── together they cover 0 to 100, no gaps, no overlaps ──────
  for r in
    select u.g, u.mn, u.mx
    from unnest(v_names, v_mins, v_maxs) as u (g, mn, mx)
    order by u.mn, u.mx
  loop
    if r.mn > v_expected then
      -- the uncovered stretch, "61 to 69" (or just "69" when it is one number)
      v_gap := case when r.mn - 1 = v_expected then v_expected::text else v_expected || ' to ' || (r.mn - 1) end;
      if v_expected = 0 then
        raise exception 'The lowest grade must start at 0. Nothing covers %', v_gap using errcode = 'P0001';
      end if;
      raise exception 'Nothing covers %. % should start at %', v_gap, r.g, v_expected
        using errcode = 'P0001';
    elsif r.mn < v_expected then
      raise exception '% overlaps the grade below it. % should start at %', r.g, r.g, v_expected
        using errcode = 'P0001';
    end if;
    v_expected := r.mx + 1;
  end loop;
  if v_expected <> 101 then
    raise exception 'The highest grade must end at 100. Nothing covers %',
      case when v_expected = 100 then '100' else v_expected || ' to 100' end
      using errcode = 'P0001';
  end if;

  -- ── the write: the whole set, delete then insert ────────────
  delete from public.grade_boundaries gb
  where gb.organization_id = p_organization_id
    and gb.section_id is not distinct from p_section_id;

  insert into public.grade_boundaries (organization_id, section_id, grade, min_percent, max_percent, remark, is_pass)
  select p_organization_id, p_section_id, u.g, u.mn, u.mx, u.rm, u.ps
  from unnest(v_names, v_mins, v_maxs, v_remarks, v_passes) as u (g, mn, mx, rm, ps);
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- 4. The deferred check: every touched set still tiles 0 to 100
-- ─────────────────────────────────────────────────────────────
-- Runs at commit for each inserted, updated or deleted row and checks the
-- whole set that row belonged to (both sets, if an update moved a row). An
-- empty set passes (the section falls back to the school's scale), so section
-- deletes cascade fine. security definer so it sees the whole set whatever
-- the caller's RLS; it only reads, and clients can't execute it.
create function private.check_grade_scale()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_orgs uuid[] := '{}';
  v_secs uuid[] := '{}';
  v_mins numeric[];
  v_maxs numeric[];
  i      int;
begin
  if tg_op in ('INSERT', 'UPDATE') then
    v_orgs := array_append(v_orgs, new.organization_id);
    v_secs := array_append(v_secs, new.section_id);
  end if;
  if tg_op in ('UPDATE', 'DELETE') then
    v_orgs := array_append(v_orgs, old.organization_id);
    v_secs := array_append(v_secs, old.section_id);
  end if;

  for i in 1 .. cardinality(v_orgs) loop
    select array_agg(gb.min_percent), array_agg(gb.max_percent)
      into v_mins, v_maxs
    from public.grade_boundaries gb
    where gb.organization_id = v_orgs[i]
      and gb.section_id is not distinct from v_secs[i];

    if v_mins is not null and not private.grade_ranges_tile(v_mins, v_maxs) then
      raise exception 'A grade scale must cover 0 to 100 exactly, with no gaps or overlaps (school %, %). Change grades with set_grade_scale',
        v_orgs[i], coalesce('section ' || v_secs[i]::text, 'school-level')
        using errcode = '23514';
    end if;
  end loop;

  return null;
end;
$$;

create constraint trigger grade_boundaries_check_scale
  after insert or update or delete on public.grade_boundaries
  deferrable initially deferred
  for each row execute function private.check_grade_scale();

-- ─────────────────────────────────────────────────────────────
-- 5. RPCs
-- ─────────────────────────────────────────────────────────────

-- Replaces ONE set's grades with p_grades, atomically: the section's own
-- scale, or the school-level scale when p_section_id is null. Every grade
-- edit in the app (add, edit, remove, a change that moves a neighbour's
-- start) sends the whole new list. Refusals change nothing.
create function public.set_grade_scale(p_organization_id uuid, p_section_id uuid, p_grades jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_organization_id is null or not private.can_manage_academics(p_organization_id) then
    raise exception 'Only the school''s leaders can change grading' using errcode = '42501';
  end if;

  if p_section_id is not null and not exists (
    select 1 from public.sections s
    where s.id = p_section_id and s.organization_id = p_organization_id
    for key share
  ) then
    raise exception 'That section no longer exists; refresh and try again' using errcode = 'P0001';
  end if;

  perform private.lock_grading_set(p_organization_id, p_section_id);
  perform private.replace_grade_scale(p_organization_id, p_section_id, p_grades);
end;
$$;

-- Replaces a section's own grade scale with a preset, atomically:
--   'waec'     A1 75–100 · B2 70–74 · B3 65–69 · C4 60–64 · C5 55–59 ·
--              C6 50–54 · D7 45–49 · E8 40–44 · F9 0–39 (fail)
--   'standard' A 70–100 · B 60–69 · C 50–59 · D 45–49 · E 40–44 · F 0–39 (fail)
-- Only for a real section of the school (not the school-level set).
create function public.apply_grade_system(p_organization_id uuid, p_section_id uuid, p_system text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_system text := lower(trim(p_system));
  v_grades jsonb;
begin
  if p_organization_id is null or not private.can_manage_academics(p_organization_id) then
    raise exception 'Only the school''s leaders can change grading' using errcode = '42501';
  end if;

  if p_section_id is null then
    raise exception 'Choose a section to apply the grade system to' using errcode = 'P0001';
  end if;

  if v_system is null or v_system not in ('waec', 'standard') then
    raise exception 'Choose a grade system: waec or standard' using errcode = 'P0001';
  end if;

  if not exists (
    select 1 from public.sections s
    where s.id = p_section_id and s.organization_id = p_organization_id
    for key share
  ) then
    raise exception 'That section no longer exists; refresh and try again' using errcode = 'P0001';
  end if;

  if v_system = 'waec' then
    v_grades := jsonb_build_array(
      jsonb_build_object('grade', 'A1', 'min_percent', 75, 'max_percent', 100, 'remark', 'Excellent', 'is_pass', true),
      jsonb_build_object('grade', 'B2', 'min_percent', 70, 'max_percent',  74, 'remark', 'Very Good', 'is_pass', true),
      jsonb_build_object('grade', 'B3', 'min_percent', 65, 'max_percent',  69, 'remark', 'Good',      'is_pass', true),
      jsonb_build_object('grade', 'C4', 'min_percent', 60, 'max_percent',  64, 'remark', 'Credit',    'is_pass', true),
      jsonb_build_object('grade', 'C5', 'min_percent', 55, 'max_percent',  59, 'remark', 'Credit',    'is_pass', true),
      jsonb_build_object('grade', 'C6', 'min_percent', 50, 'max_percent',  54, 'remark', 'Credit',    'is_pass', true),
      jsonb_build_object('grade', 'D7', 'min_percent', 45, 'max_percent',  49, 'remark', 'Pass',      'is_pass', true),
      jsonb_build_object('grade', 'E8', 'min_percent', 40, 'max_percent',  44, 'remark', 'Pass',      'is_pass', true),
      jsonb_build_object('grade', 'F9', 'min_percent',  0, 'max_percent',  39, 'remark', 'Fail',      'is_pass', false)
    );
  else
    v_grades := jsonb_build_array(
      jsonb_build_object('grade', 'A', 'min_percent', 70, 'max_percent', 100, 'remark', 'Excellent', 'is_pass', true),
      jsonb_build_object('grade', 'B', 'min_percent', 60, 'max_percent',  69, 'remark', 'Very Good', 'is_pass', true),
      jsonb_build_object('grade', 'C', 'min_percent', 50, 'max_percent',  59, 'remark', 'Good',      'is_pass', true),
      jsonb_build_object('grade', 'D', 'min_percent', 45, 'max_percent',  49, 'remark', 'Fair',      'is_pass', true),
      jsonb_build_object('grade', 'E', 'min_percent', 40, 'max_percent',  44, 'remark', 'Pass',      'is_pass', true),
      jsonb_build_object('grade', 'F', 'min_percent',  0, 'max_percent',  39, 'remark', 'Fail',      'is_pass', false)
    );
  end if;

  perform private.lock_grading_set(p_organization_id, p_section_id);
  perform private.replace_grade_scale(p_organization_id, p_section_id, v_grades);
end;
$$;

-- Copies score columns and/or grades from one set into a section, replacing
-- the section's own rows of each kind copied, atomically. p_from_section_id
-- null = the school-level set ("Give Primary its own setup"). Columns copy
-- name, max_score and sort_order. Every check (including that the source has
-- what is asked for, and that its grades cover 0 to 100) runs before the
-- first write. Replacing columns that already have scores will be refused by
-- the gradebook's foreign key once it exists, and then nothing changes.
create function public.copy_section_grading(
  p_organization_id uuid,
  p_from_section_id uuid,
  p_to_section_id   uuid,
  p_columns         boolean,
  p_grades          boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_columns  boolean := coalesce(p_columns, false);
  v_grades   boolean := coalesce(p_grades, false);
  v_from     text;
  v_key_from text;
  v_key_to   text;
  v_mins     numeric[];
  v_maxs     numeric[];
  v_list     jsonb;
begin
  -- ── who ─────────────────────────────────────────────────────
  if p_organization_id is null or not private.can_manage_academics(p_organization_id) then
    raise exception 'Only the school''s leaders can change grading' using errcode = '42501';
  end if;

  -- ── what ────────────────────────────────────────────────────
  if p_to_section_id is null then
    raise exception 'Choose the section to copy to' using errcode = 'P0001';
  end if;
  if p_from_section_id is not distinct from p_to_section_id then
    raise exception 'Choose a different set to copy from; a section can''t copy from itself' using errcode = 'P0001';
  end if;
  if not v_columns and not v_grades then
    raise exception 'Choose what to copy: score columns, grades or both' using errcode = 'P0001';
  end if;

  -- ── both sections belong to this school ─────────────────────
  if not exists (
    select 1 from public.sections s
    where s.id = p_to_section_id and s.organization_id = p_organization_id
    for key share
  ) then
    raise exception 'That section no longer exists; refresh and try again' using errcode = 'P0001';
  end if;

  if p_from_section_id is null then
    v_from := 'the school''s setup';
  else
    select s.name into v_from
    from public.sections s
    where s.id = p_from_section_id and s.organization_id = p_organization_id
    for key share;
    if not found then
      raise exception 'That section no longer exists; refresh and try again' using errcode = 'P0001';
    end if;
  end if;

  -- ── lock both sets, always in the same order ────────────────
  v_key_from := coalesce(p_from_section_id::text, 'school');
  v_key_to   := p_to_section_id::text;
  if v_key_from < v_key_to then
    perform private.lock_grading_set(p_organization_id, p_from_section_id);
    perform private.lock_grading_set(p_organization_id, p_to_section_id);
  else
    perform private.lock_grading_set(p_organization_id, p_to_section_id);
    perform private.lock_grading_set(p_organization_id, p_from_section_id);
  end if;

  -- ── the source has what was asked for ───────────────────────
  if v_columns and not exists (
    select 1 from public.score_columns sc
    where sc.organization_id = p_organization_id
      and sc.section_id is not distinct from p_from_section_id
  ) then
    raise exception 'There are no score columns to copy from %', v_from using errcode = 'P0001';
  end if;

  if v_grades then
    select array_agg(gb.min_percent), array_agg(gb.max_percent),
           jsonb_agg(jsonb_build_object('grade', gb.grade, 'min_percent', gb.min_percent,
                                        'max_percent', gb.max_percent, 'remark', gb.remark,
                                        'is_pass', gb.is_pass)
                     order by gb.min_percent desc)
      into v_mins, v_maxs, v_list
    from public.grade_boundaries gb
    where gb.organization_id = p_organization_id
      and gb.section_id is not distinct from p_from_section_id;

    if v_list is null then
      raise exception 'There are no grades to copy from %', v_from using errcode = 'P0001';
    end if;
    if not private.grade_ranges_tile(v_mins, v_maxs) then
      raise exception 'The grades in % don''t cover 0 to 100 yet, so they can''t be copied. Fix them first', v_from
        using errcode = 'P0001';
    end if;
  end if;

  -- ── the writes ──────────────────────────────────────────────
  if v_columns then
    delete from public.score_columns sc
    where sc.organization_id = p_organization_id
      and sc.section_id = p_to_section_id;

    insert into public.score_columns (organization_id, section_id, name, max_score, sort_order)
    select p_organization_id, p_to_section_id, sc.name, sc.max_score, sc.sort_order
    from public.score_columns sc
    where sc.organization_id = p_organization_id
      and sc.section_id is not distinct from p_from_section_id;
  end if;

  if v_grades then
    perform private.replace_grade_scale(p_organization_id, p_to_section_id, v_list);
  end if;
end;
$$;

-- Deletes a section's own grade rows, so it uses the school-level scale
-- again. Nothing to delete is fine. The school-level scale can't be removed.
create function public.remove_section_grade_scale(p_organization_id uuid, p_section_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_organization_id is null or not private.can_manage_academics(p_organization_id) then
    raise exception 'Only the school''s leaders can change grading' using errcode = '42501';
  end if;

  if p_section_id is null then
    raise exception 'Choose a section. The school''s own grade scale can''t be removed' using errcode = 'P0001';
  end if;

  if not exists (
    select 1 from public.sections s
    where s.id = p_section_id and s.organization_id = p_organization_id
    for key share
  ) then
    raise exception 'That section no longer exists; refresh and try again' using errcode = 'P0001';
  end if;

  perform private.lock_grading_set(p_organization_id, p_section_id);

  delete from public.grade_boundaries gb
  where gb.organization_id = p_organization_id
    and gb.section_id = p_section_id;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- 6. Existing functions
-- ─────────────────────────────────────────────────────────────

-- One-tap standard setup (migration 08), now writing max_percent. Same
-- behaviour: only for a school with no grading setup; the school-level CA 1
-- (20) + CA 2 (20) + Exam (60) and A–F; a section named "Secondary", if any,
-- gets its own WAEC grades. security definer because authenticated can no
-- longer insert grade rows; the leader check below is what keeps it to
-- leaders, and every row it writes is for p_organization_id.
create or replace function public.create_standard_grading(p_organization_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_secondary uuid;
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

  -- WAEC grade boundaries for a section named "Secondary"
  select s.id into v_secondary
  from public.sections s
  where s.organization_id = p_organization_id and lower(s.name) = 'secondary';

  if found then
    insert into public.grade_boundaries (organization_id, section_id, grade, min_percent, max_percent, remark, is_pass)
    values (p_organization_id, v_secondary, 'A1', 75, 100, 'Excellent', true),
           (p_organization_id, v_secondary, 'B2', 70,  74, 'Very Good', true),
           (p_organization_id, v_secondary, 'B3', 65,  69, 'Good',      true),
           (p_organization_id, v_secondary, 'C4', 60,  64, 'Credit',    true),
           (p_organization_id, v_secondary, 'C5', 55,  59, 'Credit',    true),
           (p_organization_id, v_secondary, 'C6', 50,  54, 'Credit',    true),
           (p_organization_id, v_secondary, 'D7', 45,  49, 'Pass',      true),
           (p_organization_id, v_secondary, 'E8', 40,  44, 'Pass',      true),
           (p_organization_id, v_secondary, 'F9',  0,  39, 'Fail',      false);
  end if;
end;
$$;

-- The grade a percentage gets in an arm. The percentage is first rounded
-- half-up to a whole number (69.5 → 70, 69.4 → 69), then given the grade with
-- the highest start it reaches. Null if the arm's scale doesn't reach down
-- that far (a legacy incomplete scale).
create or replace function public.grade_for(p_arm_id uuid, p_percent numeric)
returns public.grade_boundaries
language sql
stable
security invoker
set search_path = ''
as $$
  select gb.*
  from public.grade_boundaries_for_arm(p_arm_id) gb
  where gb.min_percent <= round(p_percent)  -- numeric round: halves go up for percentages
  order by gb.min_percent desc
  limit 1;
$$;

-- What's missing before a section (or, with no section, the school) can be
-- graded, taking the fall-back to the school's setup into account. Each
-- message is reported when it is true:
--   'No score columns yet'
--   'No grade boundary at 0%'              (empty set, or no grade from 0)
--   'Grades don''t cover 0% to 100% yet'   (a set exists but doesn't tile
--                                           0 to 100: legacy, from before 34)
create or replace function public.grading_problems(p_organization_id uuid, p_section_id uuid default null)
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
  ),
  grades as (
    select array_agg(gb.min_percent) as mins, array_agg(gb.max_percent) as maxs
    from public.grade_boundaries gb, scope
    where gb.organization_id = p_organization_id
      and gb.section_id is not distinct from scope.boundaries_section
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
         then 'No grade boundary at 0%' end,
    case when grades.mins is not null and not private.grade_ranges_tile(grades.mins, grades.maxs)
         then 'Grades don''t cover 0% to 100% yet' end
  ], null)
  from scope, grades;
$$;

-- ─────────────────────────────────────────────────────────────
-- 7. Grade writes only through the RPCs
-- ─────────────────────────────────────────────────────────────
-- Revoking the table-level privileges also revokes migration 08's
-- column-level insert (…) and update (…) grants. SELECT stays: every member
-- still reads grades (RLS "members and platform admins can read").
revoke insert, update, delete on public.grade_boundaries from authenticated;

-- The three write policies can never apply again (no role has the
-- privileges), so they are dropped rather than left to suggest otherwise. If
-- direct writes were ever granted back by mistake, there would then be no
-- policy allowing them, and RLS would refuse every row: a second lock on
-- the same door.
drop policy "grade_boundaries: leaders can add"    on public.grade_boundaries;
drop policy "grade_boundaries: leaders can edit"   on public.grade_boundaries;
drop policy "grade_boundaries: leaders can remove" on public.grade_boundaries;

-- ─────────────────────────────────────────────────────────────
-- 8. Function privileges
-- ─────────────────────────────────────────────────────────────
-- Private helpers: nothing a client may call directly, except the pure
-- grade_ranges_tile, which grading_problems (security invoker) needs.
revoke execute on function private.grade_ranges_tile(numeric[], numeric[])          from public, anon;
grant  execute on function private.grade_ranges_tile(numeric[], numeric[])          to authenticated;
revoke execute on function private.lock_grading_set(uuid, uuid)                     from public, anon, authenticated;
revoke execute on function private.replace_grade_scale(uuid, uuid, jsonb)           from public, anon, authenticated;
revoke execute on function private.check_grade_scale()                              from public, anon, authenticated;

revoke execute on function public.set_grade_scale(uuid, uuid, jsonb)                from public, anon;
revoke execute on function public.apply_grade_system(uuid, uuid, text)              from public, anon;
revoke execute on function public.copy_section_grading(uuid, uuid, uuid, boolean, boolean) from public, anon;
revoke execute on function public.remove_section_grade_scale(uuid, uuid)            from public, anon;
grant  execute on function public.set_grade_scale(uuid, uuid, jsonb)                to authenticated;
grant  execute on function public.apply_grade_system(uuid, uuid, text)              to authenticated;
grant  execute on function public.copy_section_grading(uuid, uuid, uuid, boolean, boolean) to authenticated;
grant  execute on function public.remove_section_grade_scale(uuid, uuid)            to authenticated;

-- Replaced functions keep their grants (create or replace); stated again.
revoke execute on function public.create_standard_grading(uuid)                     from public, anon;
revoke execute on function public.grade_for(uuid, numeric)                          from public, anon;
revoke execute on function public.grading_problems(uuid, uuid)                      from public, anon;
grant  execute on function public.create_standard_grading(uuid)                     to authenticated;
grant  execute on function public.grade_for(uuid, numeric)                          to authenticated;
grant  execute on function public.grading_problems(uuid, uuid)                      to authenticated;

-- ─────────────────────────────────────────────────────────────
-- Using it from the app (GradingService, supabase_flutter)
-- ─────────────────────────────────────────────────────────────
-- Wrap every call in runRefusable: the P0001 refusals are written to be shown
-- as they are; 42501 becomes the screen's own "only leaders" message.
--
--   // Any grade edit: add, edit, remove, or a change that moves a neighbour.
--   // Send the WHOLE scale as it should be afterwards. sectionId null = the
--   // school-level scale.
--   await _supabase.rpc('set_grade_scale', params: {
--     'p_organization_id': organizationId,
--     'p_section_id': sectionId,
--     'p_grades': [
--       {'grade': 'A', 'min_percent': 70, 'max_percent': 100, 'remark': 'Excellent', 'is_pass': true},
--       {'grade': 'B', 'min_percent': 60, 'max_percent': 69,  'remark': 'Very Good', 'is_pass': true},
--       {'grade': 'C', 'min_percent': 50, 'max_percent': 59,  'remark': null,        'is_pass': true},
--       {'grade': 'F', 'min_percent': 0,  'max_percent': 49,  'remark': 'Fail',      'is_pass': false},
--     ],
--   });
--
--   // A preset on one section: 'waec' or 'standard'.
--   await _supabase.rpc('apply_grade_system', params: {
--     'p_organization_id': organizationId,
--     'p_section_id': sectionId,
--     'p_system': 'waec',
--   });
--
--   // "Give Primary its own setup": copy the school-level set into Primary.
--   await _supabase.rpc('copy_section_grading', params: {
--     'p_organization_id': organizationId,
--     'p_from_section_id': null,            // or another section's id
--     'p_to_section_id': primaryId,
--     'p_columns': true,
--     'p_grades': true,
--   });
--
--   // A section goes back to the school-level grade scale.
--   await _supabase.rpc('remove_section_grade_scale', params: {
--     'p_organization_id': organizationId,
--     'p_section_id': sectionId,
--   });
--
-- Reading is unchanged (select grade_boundaries), now with max_percent.

-- Down (manual), in this order:
--   revoke execute on function public.set_grade_scale(uuid, uuid, jsonb) from authenticated;  -- etc., then:
--   drop function public.set_grade_scale(uuid, uuid, jsonb);
--   drop function public.apply_grade_system(uuid, uuid, text);
--   drop function public.copy_section_grading(uuid, uuid, uuid, boolean, boolean);
--   drop function public.remove_section_grade_scale(uuid, uuid);
--   drop trigger grade_boundaries_check_scale on public.grade_boundaries;
--   drop function private.check_grade_scale();
--   drop function private.replace_grade_scale(uuid, uuid, jsonb);
--   drop function private.lock_grading_set(uuid, uuid);
--   re-run create_standard_grading, grade_for and grading_problems from migration 08
--     (create or replace; create_standard_grading goes back to security invoker);
--   drop function private.grade_ranges_tile(numeric[], numeric[]);
--   alter table public.grade_boundaries
--     drop constraint grade_boundaries_min_whole, drop constraint grade_boundaries_max_whole,
--     drop constraint grade_boundaries_range, drop column max_percent,
--     add constraint grade_boundaries_threshold_range check (min_percent >= 0 and min_percent < 100);
--     (fails if a grade now starts at 100; delete or change it first)
--   re-create the three write policies and the insert/update/delete grants from migration 08.
