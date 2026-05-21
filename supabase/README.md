# Supabase migrations (Hamrash admin)

SQL migrations live in `migrations/`. Supabase applies them in **lexicographic (filename) order** — the timestamp prefix is what defines order.

> `migrations/` is listed in `.gitignore`. These files stay on your machine unless you remove that line.

## Where to start

| Situation | What to do |
|-----------|------------|
| **Brand-new database** (local `supabase start` or empty remote) | Run all files in order, starting at `01` below. |
| **Existing Hamrash Supabase project** (migrations already applied) | Do **not** re-run renamed files. Supabase tracks migration **filenames** in `supabase_migrations.schema_migrations`. After a rename, either keep the old names on that project or use `supabase migration repair` — see [Repairing migration history](https://supabase.com/docs/guides/cli/local-development#repair-migration-history). |
| **New environment, same schema as prod** | `supabase db pull` from prod, or run `supabase db push` / `migration up` only for migrations not yet recorded on that project. |

## Migration order (run top → bottom)

| # | File | Creates / changes |
|---|------|-------------------|
| 01 | `20260409120000_01_create_states.sql` | `states` lookup + seed (36 NG states) |
| 02 | `20260410120000_02_create_admin_profiles.sql` | `admin_profiles` (no `roles` FK yet) |
| 03 | `20260410120100_03_create_roles_and_link_admin_profiles.sql` | `roles` + FK `admin_profiles.role` → `roles.name` |
| 04 | `20260410120200_04_admin_profiles_role_on_delete_set_null.sql` | `role` nullable; FK `ON DELETE SET NULL` |
| 05 | `20260517120000_05_create_sections.sql` | `sections` lookup |
| 06 | `20260517120100_06_create_classes_subjects_and_is_admin.sql` | `is_admin()`, `classes`, `subjects`, `class_subjects` |
| 07 | `20260518120000_07_create_teachers_and_assignments.sql` | `teachers`, claim codes/bindings, `teacher_class_subjects` |
| 08 | `20260519120000_08_create_students_parents_and_enrollments.sql` | `students`, `parents`, `student_parents`, `student_subjects`, claim tables + RLS |
| 09 | `20260519130100_09_create_bind_claim_code_functions.sql` | `bind_student_claim_code`, `bind_parent_claim_code`, `bind_teacher_claim_code` |
| 10 | `20260521120000_10_fk_hardening_and_primary_parent_guard.sql` | FK `ON DELETE RESTRICT` hardening; `parents_block_primary_delete` trigger |
| 11 | `20260521130100_11_create_preflight_class_delete.sql` | `preflight_class_delete(uuid)` RPC for admin class-delete UI |
| 12 | `20260521130200_12_create_preflight_subject_delete.sql` | `preflight_subject_delete(uuid)` RPC for admin subject-delete UI |

**Dependency highlights**

- `03` must run after `02` (adds FK to `admin_profiles`).
- `05` (sections) must run before `06` (classes) — both used by the admin app.
- `06` must run before `07`–`08` (`is_admin()`, `classes`, `subjects`).
- `07` must run before `09` (teacher bind RPC references teacher tables).
- `08` must run before `09` (student/parent bind RPCs reference their tables).
- `10` must run after `02`–`08` (alters FKs on `students`, `teachers`, `admin_profiles`, `class_subjects`, `teacher_class_subjects`, `student_subjects`; adds trigger on `parents`).
- `11` must run after `06`–`08` and ideally after `10` (reads `students`, `teachers`, `class_subjects`, `teacher_class_subjects`).
- `12` must run after `06`–`08` and ideally after `10` (reads `class_subjects`, `teacher_class_subjects`, `student_subjects`, `classes`, `teachers`).

## Folders

| Path | Purpose |
|------|---------|
| `migrations/` | Active migration SQL (Supabase CLI reads this) |
| `migrated/` | Optional: move files here after they are applied to a specific project (manual bookkeeping) |
| `needs_to_be_migrated/` | Optional: draft SQL before you assign a timestamp and move into `migrations/` |

## Related docs

- [`docs/supabase-database-schema.md`](../docs/supabase-database-schema.md) — live table relationships and delete behavior
- [`docs/RLS_Approach_Guide.md`](../docs/RLS_Approach_Guide.md) — policy patterns used inside these files
- [`docs/Supabase_Realm_Architecture_Guide.md`](../docs/Supabase_Realm_Architecture_Guide.md) — how the Flutter app caches Supabase data in Realm

## CLI quick reference

```bash
# Local stack
supabase start
supabase migration up

# Check what the linked remote has applied
supabase migration list
```
