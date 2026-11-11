# To Do

The single list of open work. The design docs explain how things work; anything still to build or decide lives here, with a link back to the doc that explains it.

---

## Next

- [ ] **Build the gradebook,** the first item under *With results* below. Design: [docs/results-design.md](docs/results-design.md).

## Grading: come back to this

Built 2026-11-09 and **not signed off**. The screens exist (`lib/views/grading/`, Paper section § 9 · Grading), but the owner isn't satisfied with how it works yet. This is everything known to be missing or unreviewed, so nothing is lost when we return to it.

**Start here**
- [ ] **Say what feels wrong.** The reasons for the dissatisfaction aren't written down yet. Add them here before redesigning, for example: is the setup too heavy, are the two sheets the wrong shape, is the section scale confusing, or is the whole thing better as a guided flow?
- [ ] **Walk it on a real phone.** Nothing here has been run on a device or compared screen-by-screen with Paper. Check every artboard 9.1 to 9.11 against the app, including the keyboard on the number fields.

**App must follow migration 34** (applied to the live project 2026-11-09)
- [x] **Urgent: grade edits in the current app now fail.** Migration 34 revoked the direct `grade_boundaries` writes today's Grading screen makes, so adding, editing or removing a grade returns "permission denied" until the switch below ships. Reading still works.
- [x] **Switch `GradingService` to the RPCs** (all through `runRefusable`; messages are written to be shown as they are):
  - add, edit and remove a grade → `set_grade_scale(p_organization_id, p_section_id, p_grades)` with the **whole new list** for that set (`p_section_id` null = the school-level scale). The sheets send the full list, including a neighbour whose range moved.
  - section presets → `apply_grade_system(…, 'waec' | 'standard')`.
  - "Give Primary its own setup" and copying between sections → `copy_section_grading(p_organization_id, p_from_section_id, p_to_section_id, p_columns, p_grades)` (replaces the target's own rows).
  - "Use the school's scale instead" → `remove_section_grade_scale(p_organization_id, p_section_id)`.
  - Drop `addGradeBoundary`, `updateGradeBoundary`, `deleteGradeBoundary`, `copyScaleToSection` and `deleteSectionScale` as direct table writes.
- [x] **From and To fields** on the grade sheet (`max_percent` is now stored; read it in the model). Whole numbers only: **decimals are no longer allowed**, so the percentage keyboard and validation change.
- [x] **The "gap" / "Not covered" state becomes legacy-only.** The database refuses any set that doesn't cover 0 to 100, so new edits can't create one; keep the state only for a school whose old scale didn't start at 0 (until it is replaced).

**Designed but not built**
- [ ] **A score column that has scores** (Paper 9.4a): "Out of" read-only with the reason, no Remove, rename still allowed.
- [ ] **"Published report cards keep their grades…"** note on the grade sheet (Paper 9.6a).
- [ ] Both need the gradebook migration (a way to know a column has scores, and report-card snapshots). See *Gradebook and workflow* below. Ask which agent writes it first.

**Built differently from the design, or only partly**
- [ ] **Position row** shows only with two or more columns. Paper 9.4 doesn't show it either; decide whether that's right.
- [ ] **Dividers** use `AppDivider` (stone-50), which is fainter than the stone-100 lines drawn in Paper.
- [ ] **Home checklist** step 4 now opens Grading. It was added without being asked; confirm it's wanted.
- [ ] **Unused `grading_problems` RPC.** Coverage is computed from the loaded rows instead.

**Ideas from the UX critique that were skipped**
- [ ] **Place a new column before Exam** by default when an Exam column exists, instead of always last.
- [ ] **Fill the remark from the standard set** when a grade name matches ("A" → "Excellent") and Remark is empty.
- [ ] **Say why Save is disabled** when nothing is visibly wrong ("Add a name to save.").
- [ ] **Plainer remove-grade message** when the grade is the one at 0%: "Report cards can't be made until another grade starts at 0."
- [ ] **iOS decimal pad has no return key,** so "next" does nothing on the percentage and marks fields. Check the flow on a device.
- [ ] **Accessibility and tap-target pass** on the chips, the position buttons and the sheets.
- [ ] **Start the standard setup automatically** (for example at first school confirmation) so most schools never see an empty Grading screen.

**Wording nobody has reviewed**
- [ ] Copy the agent wrote because the designs didn't have it: the remove confirmations, the read-only empty states, the extra validation messages, the copy sheet and its toasts, and the “Give {Section} its own setup” copy. Add it to Paper and check it reads well.
- [ ] **Section load failure** shows the full-screen error view. Decide whether a partial page is better.

**Tests**
- [ ] Widget tests cover the main states, but not every sheet (the grade sheet's warning and preview, the section sheet, the confirm sheets) end to end.

## With results

Plan and decisions: [docs/results-design.md](docs/results-design.md).

- [ ] **Gradebook and workflow** (next):
  - scores
  - result sheets (draft → submitted)
  - arm reviews (lead class teacher)
  - remarks, and behaviour ratings: a fixed trait list stored as a `behaviour_trait` enum, rated 1–5 (see docs/results-design.md)
  - row-level security that follows role and workflow state
  - **What the Grading designs need from it.** Each needs a database change, so it belongs in the gradebook migration (nothing is written yet):
    - A score column that has scores shows **Out of** read-only with the reason, and no **Remove** (Paper 9.4a).
    - The grade sheet shows "Published report cards keep their grades. Results not yet published use the new scale." (Paper 9.6a).
    - Published report cards snapshot the column names and max scores as well as the grades, so changing the setup later never rewrites a published card.
- [ ] **Publishing and report cards:** freeze totals, grades, positions within the arm, class stats and the annual result on publish. Parents and students see published results only.
- [ ] **Homework:** assignments posted to an arm and subject, submissions and marking, and pulling marks into a CA component. Attachments are images via Cloudflare and documents via Supabase Storage.
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
- [ ] **Extra roles for one staff member,** such as a principal who also teaches, without a second claim code. Database side written: `add_member_role` (migration 35, not applied yet). Still to do: the app action on the staff page.

## Later

- [ ] **Claim codes:** expiry, and re-issuing a code that may have leaked. See [docs/organization-schema.md](docs/organization-schema.md).
- [ ] **Rate limiting on claim-code and platform-invite redemption.** The 5-per-hour limit was removed in migration 25. Claim codes have about 1.1 trillion combinations, but nothing slows down guessing now.
- [ ] **Campuses** as a sub-scope on a few tables (classes, staff, students).
- [ ] **Where the Hamrash team's platform screens live:** inside the admin app behind `platform_admins`, or a separate console.
- [ ] **Bursar access to results,** for example withholding report cards when fees are unpaid. Decide with fees.
- [ ] **Head-of-section access** to every student in their section. Not wanted for now; listed so it isn't forgotten.
