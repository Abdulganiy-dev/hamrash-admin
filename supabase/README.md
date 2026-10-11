# Supabase (Hamrash)

Database for the Hamrash platform. Project ref: `ccvyhbyrtobdsecqvhcr`. Design notes: [`docs/organization-schema.md`](../docs/organization-schema.md), [`docs/people-schema.md`](../docs/people-schema.md), [`docs/academic-structure.md`](../docs/academic-structure.md).

## Migrations

Applied in filename order. Each filename's timestamp matches the version recorded in the project's migration history.

| # | File | What it does |
|---|------|--------------|
| 01 | `20261007182933_01_create_organizations_and_members.sql` | `organizations`, `organization_members`, `platform_admins`; RLS helpers in `private`; claim codes; owner guard; RPCs `create_organization`, `set_organization_status`, `redeem_claim_code` |
| 02 | `20261007185331_02_tidy_rls_initplan_and_rls_auto_enable.sql` | Rewrites two policies to the form the advisor recognises; revokes API execute on `rls_auto_enable()` |
| 03 | `20261007210000_03_create_people.sql` | `staff`, `students`, `parents`, `student_parents`; generated admission/staff numbers; `organizations.number_prefix` + `logo_id`; `create_organization` now takes the prefix; RPCs `invite_staff`, `invite_student`, `invite_parent` |
| 04 | `20261011123753_04_create_academic_structure.sql` | `sections`, `classes`, `class_arms`, `academic_sessions`, `academic_terms`, `class_teachers`, `student_placements`; RPCs `set_current_session`, `set_current_term`, `create_standard_structure` |
| 05 | `20261011130000_05_split_staff_private_details.sql` | Splits staff into a public profile (readable by everyone in the school) and `staff_private_details`; RPCs `create_staff`, `update_staff` |

Migrations 03 and 05 contain `drop` statements, which the Supabase connector refuses to run. They were applied in the SQL editor and then recorded in `supabase_migrations.schema_migrations` by hand. Any future migration that drops something needs the same treatment.

Before writing a new migration, follow the checklist under "Rules every future school table follows" in the design notes.

## Tests

| File | What it checks |
|------|----------------|
| `tests/01_organizations_access_test.sql` | 28 access rules for schools and memberships: who can read, invite, edit and suspend, and that schools are kept apart. Uses the `create_organization(name, prefix, …)` signature from migration 03. |
| `tests/02_people_access_test.sql` | 48 checks for staff (profile + private details), students, parents and links: who can read and edit what, issuing logins, numbering, co-parents, `create_staff` / `update_staff`, cross-school isolation, suspension. Needs migrations 03 and 05. |
| `tests/03_academic_structure_access_test.sql` | 47 checks for sections, classes, arms, sessions, terms, class teachers and placements: the standard structure, uniqueness, current session/term, lead and assistant limits, who can place students, cross-school isolation, suspension. Needs migration 04. |

To run a test, paste the file into the SQL editor. It acts as several fake users, then raises an exception on purpose so every change is rolled back. The error message is the PASS/FAIL report. It needs the dummy platform admin `user_dummy_platform_admin` to exist.

## Adding a platform admin

Hamrash team members are added by hand in the SQL editor:

```sql
insert into public.platform_admins (clerk_user_id, full_name, email)
values ('<Clerk user id>', '<name>', '<email>');
```
