# To Do

## Database

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
- [ ] **Limit what co-parents can see about each other.** Parents can read the full `parents` record of their children's other parents and guardians, because RLS works on whole rows. That includes address, email and occupation, which can be a problem with separated parents. Build a restricted view for the parent portal that exposes only name, relationship and phone, and have the portal read that instead of `parents`. Then narrow the `parents` select policy so co-parents see only their own row.
  - The view must use `security_invoker = true`, or it will bypass RLS.
  - Decide whether the school can mark a parent as "hidden from other parents" (for example in custody cases).
