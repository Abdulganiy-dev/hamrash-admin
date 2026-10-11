# Supabase (Hamrash)

Database for the Hamrash platform. Project ref: `ccvyhbyrtobdsecqvhcr`. Design notes: [`docs/organization-schema.md`](../docs/organization-schema.md), [`docs/people-schema.md`](../docs/people-schema.md), [`docs/academic-structure.md`](../docs/academic-structure.md), [`docs/subjects.md`](../docs/subjects.md), [`docs/results-design.md`](../docs/results-design.md).

## Migrations

Applied in filename order. Each filename's timestamp matches the version recorded in the project's migration history.

| # | File | What it does |
|---|------|--------------|
| 01 | `20261007182933_01_create_organizations_and_members.sql` | `organizations`, `organization_members`, `platform_admins`; RLS helpers in `private`; claim codes; owner guard; RPCs `create_organization`, `set_organization_status`, `redeem_claim_code` |
| 02 | `20261007185331_02_tidy_rls_initplan_and_rls_auto_enable.sql` | Rewrites two policies to the form the advisor recognises; revokes API execute on `rls_auto_enable()` |
| 03 | `20261007210000_03_create_people.sql` | `staff`, `students`, `parents`, `student_parents`; generated admission/staff numbers; `organizations.number_prefix` + `logo_id`; `create_organization` now takes the prefix; RPCs `invite_staff`, `invite_student`, `invite_parent` |
| 04 | `20261011123753_04_create_academic_structure.sql` | `sections`, `classes`, `class_arms`, `academic_sessions`, `academic_terms`, `class_teachers`, `student_placements`; RPCs `set_current_session`, `set_current_term`, `create_standard_structure` |
| 05 | `20261011130000_05_split_staff_private_details.sql` | Splits staff into a public profile (readable by everyone in the school) and `staff_private_details`; RPCs `create_staff`, `update_staff` |
| 06 | `20261011134957_06_create_subjects.sql` | `subjects`, `arm_subjects` (curriculum per arm), `teaching_assignments`, `student_subjects` (electives); teachers now see only the students they teach in the current session; RPCs `create_standard_subjects`, `apply_standard_curriculum`, `copy_arm_subjects`, `copy_assignments_forward`, `session_readiness` |
| 07 | `20261011144800_07_split_student_and_parent_private_details.sql` | Splits students into a profile (past teachers can see it) and `student_private_details`, and parents into a profile and `parent_private_details` (co-parents can't see each other's email, occupation, address); RPCs `create_student`, `update_student`, `create_parent`, `update_parent` |
| 08 | `20261011144926_08_create_grading_setup.sql` | `score_columns` and `grade_boundaries` (the school's, or a section's own, with fall-back); `score_columns_for_arm`, `grade_boundaries_for_arm`, `grade_for`, `grading_problems`, `create_standard_grading` |

Migrations 03, 05 and 07 contain `drop` statements, which the Supabase connector refuses to run. They were applied in the SQL editor and then recorded in `supabase_migrations.schema_migrations` by hand. Any future migration that drops something needs the same treatment.

Before writing a new migration, follow the checklist under "Rules every future school table follows" in the design notes.

## Tests

| File | What it checks |
|------|----------------|
| `tests/01_organizations_access_test.sql` | 28 access rules for schools and memberships: who can read, invite, edit and suspend, and that schools are kept apart. Uses the `create_organization(name, prefix, …)` signature from migration 03. |
| `tests/02_people_access_test.sql` | 60 checks for staff, students and parents (profiles + private details) and links: who can read and edit what, issuing logins, numbering, co-parents, `create_staff` / `update_staff`, cross-school isolation, suspension. Needs migrations 03, 05, 06 and 07. |
| `tests/03_academic_structure_access_test.sql` | 47 checks for sections, classes, arms, sessions, terms, class teachers and placements: the standard structure, uniqueness, current session/term, lead and assistant limits, who can place students, cross-school isolation, suspension. Needs migrations 04 and 06. |
| `tests/04_subjects_access_test.sql` | 48 checks for subjects, per-arm curriculum, teaching assignments and electives: standard subjects, copy/apply helpers, one teacher per subject, teachers seeing only their own students, copying assignments forward, session readiness. Needs migrations 01–07. |
| `tests/05_grading_setup_access_test.sql` | 20 checks for score columns and grade boundaries: the standard setup, section fall-back, grading between boundaries, uniqueness per set, who can change what. Needs migrations 01–08. |

To run a test, paste the file into the SQL editor. It acts as several fake users, then raises an exception on purpose so every change is rolled back. The error message is the PASS/FAIL report. It needs the dummy platform admin `user_dummy_platform_admin` to exist.

## Adding a platform admin

Hamrash team members are added by hand in the SQL editor:

```sql
insert into public.platform_admins (clerk_user_id, full_name, email)
values ('<Clerk user id>', '<name>', '<email>');
```
