# To Do

The single list of open work. The design docs explain how things work; anything still to build or decide lives here, with a link back to the doc that explains it.

---

## Next

- [ ] **Run the outstanding access tests** in the Supabase SQL editor (see [supabase/README.md](supabase/README.md)). None of these have been run against migrations 06, 07 and 08:
  - `02_people_access_test.sql`
  - `03_academic_structure_access_test.sql`
  - `04_subjects_access_test.sql`
  - `05_grading_setup_access_test.sql`
- [ ] **Retire the old docs.** The README links `docs/supabase-database-schema.md`, the single-school schema that was never deployed. `docs/RLS_Approach_Guide.md` describes the old patterns (`clerk_id` on each table, `service_role` writes). Replace or remove both, and point the README at the current design docs.
- [ ] **Two-column indexes for Supabase's five "unindexed foreign key" notices.** They cover the `member_id` links on `staff`, `students` and `parents`, and both links on `student_parents`. The existing single-column indexes already cover these lookups, so this is cosmetic at this size.

## With results

Plan and decisions: [docs/results-design.md](docs/results-design.md).

- [ ] **Phase 09, gradebook and workflow:**
  - scores
  - result sheets (draft → submitted)
  - arm reviews (lead class teacher)
  - remarks, and behaviour ratings: a fixed trait list stored as a `behaviour_trait` enum, rated 1–5 (see docs/results-design.md)
  - row-level security that follows role and workflow state
- [ ] **Phase 10, publishing and report cards:** freeze totals, grades, positions within the arm, class stats and the annual result on publish. Parents and students see published results only.
- [ ] **Phase 11, homework:** assignments posted to an arm and subject, submissions and marking, and pulling marks into a CA component. Attachments are images via Cloudflare and documents via Supabase Storage.
- [ ] **Teachers keep their past work.** A teacher can always see the work rows (results, assignments, projects…) for the **subject + arm + session they taught**, even after the student is promoted or graduates.
  - Grant this from `teaching_assignments` in **any** session, not the current one. This also covers late results after the session changes.
  - The student profile split it needs, so past teachers see names only, is in migration 07. See [docs/subjects.md](docs/subjects.md).
- [ ] **Each result stores the arm the student was in at the time.** Placements are kept per session, and a mid-year class move edits the placement, so report cards and class positions need their own record of the class.
  - Store the **subject** too, so past report cards don't depend on today's curriculum (`arm_subjects` is current only). See [docs/academic-structure.md](docs/academic-structure.md).
- [ ] **Protect score columns once scores exist.** Their max score can't change and they can't be deleted. This is enforced in the gradebook migration.

## With promotion

Decisions so far: [docs/academic-structure.md → Promotion](docs/academic-structure.md#promotion-decided-not-built-yet).

- [ ] **Build promotion:**
  - each child's outcome (promote, repeat, graduate, leave) is suggested from results, and the admin can override it
  - the admin picks the destination arm
  - students promoted out of a graduating class graduate
  - the next session must already exist
  - outcomes are recorded
- [ ] **Make class order unique within a section,** so "the next class" is never ambiguous.
- [ ] **"Follow the class up" when copying assignments:** an option for `copy_assignments_forward` where class teachers move up with their pupils instead of staying with the arm. See [docs/subjects.md](docs/subjects.md).
- [ ] **Check placements:** only `active` students, and only active arms.
- [ ] **Stop overlapping sessions** in the same school.

## With the parent/staff apps

- [ ] **Self-editing.** Let people update a safe set of fields on their own record, for example a parent updating their phone number. It needs a rule for which fields each person can change, since admins can edit everything.
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
- [ ] **Hide a parent from other parents (custody cases).** Migration 07 already stops co-parents seeing each other's email, occupation or address. Still to decide: should a school be able to hide a parent from other parents **entirely**, including name and phone? See [docs/people-schema.md](docs/people-schema.md).
- [ ] **Link the owner's own staff record** to the login they got from Hamrash.
- [ ] **Extra roles for one staff member,** such as a principal who also teaches, without a second claim code.

## Later

- [ ] **Claim codes:** expiry, and re-issuing a code that may have leaked. See [docs/organization-schema.md](docs/organization-schema.md).
- [ ] **Rate limiting on `redeem_claim_code`.** Codes have about 1.1 trillion combinations, so this isn't urgent.
- [ ] **Campuses** as a sub-scope on a few tables (classes, staff, students).
- [ ] **Where the Hamrash team's platform screens live:** inside the admin app behind `platform_admins`, or a separate console.
- [ ] **Bursar access to results,** for example withholding report cards when fees are unpaid. Decide with fees.
- [ ] **Head-of-section access** to every student in their section. Not wanted for now; listed so it isn't forgotten.
