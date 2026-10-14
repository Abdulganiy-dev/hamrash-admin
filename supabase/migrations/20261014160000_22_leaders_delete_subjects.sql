-- 22 · Principals and vice principals can delete subjects
--
-- They already add and edit subjects and decide which arms take them, and
-- since migration 21 they remove sections, classes and arms too. Deleting a
-- subject still fails while it's in use (on delete restrict): a teacher is
-- assigned to it, or students chose it as an optional subject. Those get
-- switched off (is_active = false). Deleting an unused subject also takes it
-- off every arm (arm_subjects, on delete cascade), which these roles can
-- already change.

drop policy "subjects: owners and admins can delete" on public.subjects;
create policy "subjects: leaders can delete"
  on public.subjects for delete to authenticated
  using (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
