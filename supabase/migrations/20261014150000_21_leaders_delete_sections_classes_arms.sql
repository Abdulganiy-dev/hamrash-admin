-- 21 · Principals and vice principals can delete sections, classes and arms
--
-- They already add and edit the school's structure; removing a mistake is
-- part of the same job. Deleting still fails while anything depends on it
-- (on delete restrict): a section with classes, a class with arms, an arm
-- with student placements. Those get switched off (is_active = false).
-- Deleting an arm still removes its class teachers, its subjects and its
-- teaching assignments (on delete cascade), all of which these roles can
-- already change.

drop policy "sections: owners and admins can delete" on public.sections;
create policy "sections: leaders can delete"
  on public.sections for delete to authenticated
  using (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));

drop policy "classes: owners and admins can delete" on public.classes;
create policy "classes: leaders can delete"
  on public.classes for delete to authenticated
  using (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));

drop policy "class_arms: owners and admins can delete" on public.class_arms;
create policy "class_arms: leaders can delete"
  on public.class_arms for delete to authenticated
  using (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
