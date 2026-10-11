-- 10 · Fix the student_parents indexes from migration 09
--
-- Supabase's "unindexed foreign key" check needs an index that starts with
-- the key's columns IN THE KEY'S ORDER. Migration 09 created them reversed
-- ((student_id, organization_id) and (parent_id, organization_id)), so the
-- two student_parents notices stayed. Replace them with the right order.
--
-- student_parents_parent_idx (parent_id) stays: private.my_child_ids()
-- looks links up by parent_id alone. Lookups by student_id use the primary
-- key (student_id, parent_id).
--
-- Contains DROP INDEX, so the Supabase connector won't run it: apply it in
-- the SQL editor and record it in supabase_migrations.schema_migrations.
-- Guide: docs/rls-guide.md (§2)

drop index public.student_parents_student_org_idx;
drop index public.student_parents_parent_org_idx;

create index student_parents_org_student_idx on public.student_parents (organization_id, student_id);
create index student_parents_org_parent_idx  on public.student_parents (organization_id, parent_id);
