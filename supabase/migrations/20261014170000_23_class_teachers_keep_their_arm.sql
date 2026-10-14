-- 23 · An arm with a class teacher can't be deleted
--
-- Deleting an arm used to remove its class teachers with it (on delete
-- cascade), so a slip in the app could quietly unassign them. Now it's
-- refused, like an arm with students placed in it: unassign the class
-- teachers first, or switch the arm or class off instead. Deleting a class
-- deletes its arms, so a class whose arms have class teachers stays too.
--
-- Deleting a staff member or a session still removes their class teacher
-- rows; only the arm side changes.

alter table public.class_teachers
  drop constraint class_teachers_arm_fkey,
  add constraint class_teachers_arm_fkey foreign key (organization_id, arm_id)
    references public.class_arms (organization_id, id) on delete restrict;
