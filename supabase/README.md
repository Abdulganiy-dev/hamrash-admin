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
| 09 | `20261011145904_09_add_foreign_key_indexes.sql` | Indexes for the two-column `member_id` links on `staff`, `students`, `parents` (and two `student_parents` indexes created in the wrong order, see 10) |
| 10 | `20261011150634_10_fix_student_parents_indexes.sql` | Replaces those two with `(organization_id, student_id)` and `(organization_id, parent_id)`. Supabase's checker now has no unindexed-foreign-key notices. |
| 11 | `20261012100000_11_owner_staff_record_on_redeem.sql` | `redeem_claim_code(code, first_name, last_name, email, phone)`: redeeming an owner code also creates the owner's staff record. The name is required for owner codes only. |
| 12 | `20261013120000_12_platform_invite_codes.sql` | Platform invite codes: `private.platform_invite_codes` and `private.platform_invite_attempts`; RPCs `create_platform_invite`, `list_platform_invites`, `revoke_platform_invite`, `redeem_platform_invite`. One-time, 7-day, hash-only codes with a 5-per-hour attempt limit, so new Hamrash team members can join from Hamrash Platform Admin. |
| 13 | `20261013140000_13_check_claim_code_and_limit_attempts.sql` | `check_claim_code(code)`: look a code up without using it (school, role, which app it's for, whether an owner name is needed). 5 wrong codes per account per hour across check and redeem, in `private.claim_code_attempts`. `redeem_claim_code` now returns NULL for a wrong or used code instead of raising. |

Migration 02's revoke on `rls_auto_enable()` is guarded, since that function exists only on hosted Supabase; this lets the migrations run on a local database.

Migrations 03, 05, 07, 10 and 11 contain `drop` statements, which the Supabase connector refuses to run. They were applied in the SQL editor and then recorded in `supabase_migrations.schema_migrations` by hand. Any future migration that drops something needs the same treatment.

Before writing a new migration, read [`docs/rls-guide.md`](../docs/rls-guide.md).

## Edge functions

Server-side code for every Hamrash app lives here, next to the migrations.

| Function | What it does | Allowed apps |
|----------|--------------|--------------|
| `media-upload` | Checks the caller's Clerk login, then reserves a one-time, labelled Cloudflare Images or Stream upload URL, so no app holds a Cloudflare token. All uploads go through it. | `hamrash-platform`, `hamrash-admin` (the allow-list is `ALLOWED_KINDS` in `functions/_shared/media_upload.mjs`) |
| `media-delete` | Deletes one Cloudflare image by its id (`POST {"id": "<app>/<env>/<kind>/<uuid>"}`). Only for the person who uploaded it, only for our own ids, and only in this project's environment. Needs no new secrets. | any app that uploads |

Layout: `functions/_shared/media_upload.mjs` and `media_delete.mjs` (the logic), `functions/_shared/http.mjs` (the login check both use), `functions/media-upload/index.ts` (wiring and secrets only), the two `*.test.mjs` files (in `media-upload/` and `media-delete/`), and `secrets.env.example`. Hamrash Admin's `test/api/media_kind_test.dart` reads the allow-list and fails if the app's `MediaKind` drifts from it. Both apps upload through it: `MediaUploadService` / `ImageService` in `lib/api/services/cloudflare_services/` (Hamrash Admin's school logo is the first user). Neither app holds a Cloudflare token.

**Deploy:** needs `--no-verify-jwt`, because Supabase's gateway only recognises tokens Supabase signed and ours are Clerk's. The function rejects anything without a valid Clerk token itself.

```bash
supabase secrets set --env-file supabase/functions/media-upload/secrets.env --project-ref ccvyhbyrtobdsecqvhcr
supabase functions deploy media-upload --no-verify-jwt --project-ref ccvyhbyrtobdsecqvhcr
supabase functions deploy media-delete --no-verify-jwt --project-ref ccvyhbyrtobdsecqvhcr
```

`secrets.env` is git-ignored (copy it from `secrets.env.example`). Use a Cloudflare token with only *Images Edit* and *Stream Edit*. A missing secret stops the function at start-up and names it. More: [Hamrash Platform Admin's docs/media-uploads.md](../../hamrash-platform-admin/docs/media-uploads.md).

**Test** (from this folder, no packages needed):

```bash
node --test supabase/functions/media-upload/media_upload.test.mjs supabase/functions/media-delete/media_delete.test.mjs
```

## Tests

| File | What it checks |
|------|----------------|
| `tests/01_organizations_access_test.sql` | 28 access rules for schools and memberships: who can read, invite, edit and suspend, and that schools are kept apart. Uses the `create_organization(name, prefix, …)` signature from migration 03. |
| `tests/02_people_access_test.sql` | 60 checks for staff, students and parents (profiles + private details) and links: who can read and edit what, issuing logins, numbering, co-parents, `create_staff` / `update_staff`, cross-school isolation, suspension. Needs migrations 03, 05, 06 and 07. |
| `tests/03_academic_structure_access_test.sql` | 47 checks for sections, classes, arms, sessions, terms, class teachers and placements: the standard structure, uniqueness, current session/term, lead and assistant limits, who can place students, cross-school isolation, suspension. Needs migrations 04 and 06. |
| `tests/04_subjects_access_test.sql` | 48 checks for subjects, per-arm curriculum, teaching assignments and electives: standard subjects, copy/apply helpers, one teacher per subject, teachers seeing only their own students, copying assignments forward, session readiness. Needs migrations 01–07. |
| `tests/05_grading_setup_access_test.sql` | 20 checks for score columns and grade boundaries: the standard setup, section fall-back, grading between boundaries, uniqueness per set, who can change what. Needs migrations 01–08. |
| `tests/06_owner_staff_record_test.sql` | 10 checks for the owner's staff record: owner codes need a name, the record is linked and numbered `STF/0001`, the owner can edit it, other codes need no name, a staff member made co-owner keeps one record. Needs migrations 01–11. |
| `tests/07_platform_invites_access_test.sql` | 19 checks for platform invite codes: code shape, 7-day expiry and hash-only storage; non-admins can't create, list or cancel; the tables aren't readable; name required; wrong, used, cancelled and expired codes rejected; a valid code makes the caller a platform admin; existing admins don't use up a code; the 5-per-hour limit; turned-off admins refused; anon can't redeem. Needs migrations 01–12. |
| `tests/08_check_claim_code_test.sql` | 18 checks for checking a code first and the wrong-code limit: owner, principal and teacher codes report the right app and stay unused; half-typed codes don't count; wrong checks and wrong redeems both count; the 5th wrong try locks for an hour and hides the school; locked redeems are refused; the lock is per account and lifts after an hour; a good redeem clears the count; `already_member` and `school_inactive`; the attempts table is private; anon can't check. Needs migrations 01–13. |

**Run the tests locally (preferred).** Needs Docker (Docker Desktop or OrbStack) and the Supabase CLI.

```bash
supabase start                 # once per session; first run downloads the images
supabase/tests/run_local.sh    # rebuilds the local db from migrations/, runs every test
```

It prints one line per test plus every FAIL/ERROR line, and exits 1 if anything failed. `--no-reset` skips the rebuild. It only ever connects to the local database (`127.0.0.1:54322`); it refuses any other `DB_URL`. Run it before applying a new migration to the hosted project. `supabase stop` shuts the stack down.

Tests count only the schools they create, so real schools on the hosted project don't affect results.

**On the hosted project,** paste `tests/run_all.sql` into the SQL editor and run it. You get one row per test with pass and fail counts and the full report, and nothing is kept. It's generated by `tests/build_run_all.py`, so rerun `python3 supabase/tests/build_run_all.py` after changing a test.

To run a single test, paste the file into the SQL editor. It acts as several fake users, then raises an exception on purpose so every change is rolled back. The error message is the PASS/FAIL report. Each test creates its own test platform admin (`user_dummy_platform_admin`) and rolls it back too, so the live database keeps no fake admin.

## Adding a platform admin

Since migration 12, new Hamrash team members join with a one-time platform code: an existing admin creates it on Hamrash Platform Admin's Team tab, and the new person enters it after signing in. Only the **first** admin is added by hand in the SQL editor:

```sql
insert into public.platform_admins (clerk_user_id, full_name, email)
values ('<Clerk user id>', '<name>', '<email>');
```
