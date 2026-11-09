-- 33 · Reorder a set of score columns in one call
--
-- The Grading screen lets a leader move a score column up or down. The app
-- did it as two separate updates (swap two columns' sort_order) and put the
-- first back if the second failed, so a dropped connection could leave two
-- columns with the same place, or a half-finished swap. reorder_score_columns
-- takes the complete new order of ONE set and writes it in a single UPDATE,
-- so the order changes completely or not at all.
--
-- A set is the school's columns (section_id null) or one section's own
-- columns (migration 08). p_column_ids is that whole set in its new order.
-- Every rule is checked BEFORE the write, and any refusal changes nothing:
--   * the caller must be a leader of the school (owner, admin, principal,
--     vice principal), via private.can_manage_academics (42501);
--   * the list is not empty (P0001, "There are no score columns to put in
--     order");
--   * no column is listed twice (P0001, "… listed twice …");
--   * every id is a score column of this school (P0001, "… no longer
--     exists …"). An id from another school gets the same message, so it
--     reveals nothing about that school;
--   * every column is in the same set (P0001, "… different sets …");
--   * no column of that set is left out (P0001, "… missing from the new
--     order …"), e.g. another leader added one since the screen loaded.
-- Then sort_order becomes 1..n in the order given. Only rows whose place
-- actually changes are written, so updated_at moves only on those.
--
-- Locking: the whole set's rows are locked (select … for update, in id
-- order) before the "nothing left out" check and the write. Two leaders
-- reordering the same set at once queue one behind the other, and the
-- second is checked against the first's result; locking in id order means
-- they can't deadlock. A column inserted into the set by someone else after
-- the lock is not blocked (row locks don't stop inserts); it simply keeps
-- the sort_order it was added with, as before.
--
-- Security: security invoker, search_path = ''. The lock and the write go
-- through the existing RLS policies and the update (name, max_score,
-- sort_order) column grant as the caller; no grant is widened. The up-front
-- leader check only gives a clearer message than RLS would.
--
-- No DROP: a new function. Requires migration 08.
-- Test: supabase/tests/20_reorder_score_columns_test.sql
-- Design notes: docs/results-design.md (Grading setup)

-- ─────────────────────────────────────────────────────────────
-- reorder_score_columns
-- ─────────────────────────────────────────────────────────────
create function public.reorder_score_columns(p_organization_id uuid, p_column_ids uuid[])
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_n        int;
  v_sets     int;
  v_found    int;
  v_section  uuid;
  v_in_set   int;
  v_matched  int;
begin
  -- ── who ─────────────────────────────────────────────────────
  if p_organization_id is null or not private.can_manage_academics(p_organization_id) then
    raise exception 'Only the school''s leaders can reorder score columns' using errcode = '42501';
  end if;

  -- ── the list ────────────────────────────────────────────────
  v_n := coalesce(cardinality(p_column_ids), 0);
  if v_n = 0 then
    raise exception 'There are no score columns to put in order' using errcode = 'P0001';
  end if;

  if array_position(p_column_ids, null) is not null then
    raise exception 'One of these score columns no longer exists; refresh and try again' using errcode = 'P0001';
  end if;

  if (select count(distinct u.id) from unnest(p_column_ids) as u (id)) <> v_n then
    raise exception 'A score column is listed twice in the new order; refresh and try again' using errcode = 'P0001';
  end if;

  -- ── which set ───────────────────────────────────────────────
  select count(*), count(distinct coalesce(sc.section_id::text, 'school')), min(sc.section_id::text)::uuid
    into v_found, v_sets, v_section
  from public.score_columns sc
  where sc.organization_id = p_organization_id
    and sc.id = any (p_column_ids);

  if v_found <> v_n then
    raise exception 'One of these score columns no longer exists; refresh and try again' using errcode = 'P0001';
  end if;

  if v_sets <> 1 then
    raise exception 'These score columns are from different sets; put the school''s columns and each section''s columns in order separately' using errcode = 'P0001';
  end if;

  -- ── lock the whole set, then check nothing is left out ──────
  -- (v_section is null for the school's set)
  select count(*), count(*) filter (where l.id = any (p_column_ids))
    into v_in_set, v_matched
  from (
    select sc.id
    from public.score_columns sc
    where sc.organization_id = p_organization_id
      and sc.section_id is not distinct from v_section
    order by sc.id
    for update
  ) l;

  if v_matched <> v_n then
    -- deleted by someone else while this call waited for the lock
    raise exception 'One of these score columns no longer exists; refresh and try again' using errcode = 'P0001';
  end if;

  if v_in_set <> v_n then
    raise exception 'A score column is missing from the new order; refresh and try again' using errcode = 'P0001';
  end if;

  -- ── the write: 1..n in the order given, in one statement ────
  update public.score_columns sc
  set sort_order = o.pos::int
  from unnest(p_column_ids) with ordinality as o (id, pos)
  where sc.id = o.id
    and sc.organization_id = p_organization_id
    and sc.sort_order is distinct from o.pos::int;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- Privileges (the same as the other grading functions)
-- ─────────────────────────────────────────────────────────────
revoke execute on function public.reorder_score_columns(uuid, uuid[]) from public, anon;
grant  execute on function public.reorder_score_columns(uuid, uuid[]) to authenticated;

-- ─────────────────────────────────────────────────────────────
-- Using it from the app (Grading → move a score column up or down)
-- ─────────────────────────────────────────────────────────────
--   // the set as it is on screen, with the moved column in its new place
--   await _supabase.rpc('reorder_score_columns', params: {
--     'p_organization_id': organizationId,
--     'p_column_ids': [ca1Id, examId, ca2Id],
--   });
--
-- Wrap it in runRefusable: the P0001 refusals above are shown as they are,
-- and 42501 becomes the screen's own "only leaders" message.

-- Down (manual):
--   drop function public.reorder_score_columns(uuid, uuid[]);
