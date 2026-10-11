-- 09 · Indexes for the two-column links Supabase's checker flagged
--
-- Supabase's "unindexed foreign key" check wants an index that starts with
-- the key's columns. NOTE: the two student_parents indexes below were created
-- in the wrong column order and are replaced by migration 10.
-- These five links were already served by single-column indexes, so this is
-- tidy-up, not a speed fix:
--   staff, students, parents   (organization_id, member_id) → organization_members
--   student_parents            (organization_id, student_id) → students
--   student_parents            (organization_id, parent_id)  → parents
--
-- student_parents_parent_idx (parent_id) stays; private.my_child_ids() uses it.
-- Guide: docs/rls-guide.md (§2)

create index staff_org_member_idx     on public.staff    (organization_id, member_id);
create index students_org_member_idx  on public.students (organization_id, member_id);
create index parents_org_member_idx   on public.parents  (organization_id, member_id);

create index student_parents_student_org_idx on public.student_parents (student_id, organization_id);
create index student_parents_parent_org_idx  on public.student_parents (parent_id, organization_id);
