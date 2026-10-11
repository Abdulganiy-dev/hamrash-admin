# To Do

## Database

- [ ] **When building results, assignments and projects: teachers keep their past work.** A teacher can always see the work rows (results, assignments, projects…) for the **subject + arm + session they taught**, even after the student is promoted or graduates. Grant this from `teaching_assignments` (any session), not from the current session. To show names next to that work, split `students` into a profile (name, admission number, photo, gender, status) and private details, like staff in migration 05. Past teachers see only the profile. This also covers late results after the session changes.
- [ ] **When building results:** each result row must store the `arm_id` the student was in at the time (a snapshot). Placements are kept per session, and a mid-year class move edits the placement, so report cards and class positions need their own record of the class.

- [ ] **Self-editing.** Let people update a safe set of fields on their own record, for example a parent updating their phone number. This comes with the parent and staff apps. It needs a rule for which fields each person can change, since admins can edit everything.
- [ ] **Suspend logins automatically** when a staff member's status becomes `exited`, or a student's becomes `graduated`, `transferred` or `withdrawn`. Restore the login if the status is changed back.
- [ ] **Review the employment status vs login status flow.** Today they are separate:
  - `staff.status` (`active`, `on_leave`, `exited`) is employment.
  - `organization_members.status` (`invited`, `active`, `suspended`) is app access.

  Suspending a teacher means updating both. Questions to decide:
  - Should changing `staff.status` drive the login automatically (see the item above), or stay manual?
  - Does `staff` need its own `suspended` value, separate from `on_leave` and `exited`?
  - Should staff who are `on_leave` keep their login?
  - Do parents (`is_active`) and students need the same treatment?
  - What should the admin UI show: one "Suspend" action that does both, or two separate controls?
- [ ] **Limit what co-parents can see about each other.** Parents can read the full `parents` record of their children's other parents and guardians, because RLS works on whole rows. That includes address, email and occupation, which can be a problem with separated parents. Use the same pattern as staff (migration 05): move address, email and occupation into a `parent_private_details` table with stricter RLS, and keep names, relationship and phone on `parents`.
  - A plain `security_invoker` view does **not** work here: it can only show rows the base table's policy already allows, so it can't show co-parents once the policy is narrowed.
  - Decide whether the school can mark a parent as "hidden from other parents" (for example in custody cases).
