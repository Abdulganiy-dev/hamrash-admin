# Hamrash Admin

Admin app for the Hamrash school management system. Built in Flutter; backed by Supabase (Postgres + RLS) with Realm as the offline cache. Identity is handled by Clerk; profile images live in Cloudflare Images.

---

## Tech stack

| Layer | Choice |
|-------|--------|
| UI | Flutter (Material 3) |
| State | [stacked](https://pub.dev/packages/stacked) — `ViewModelBuilder.reactive` + `BaseViewModel` |
| DI | [get_it](https://pub.dev/packages/get_it) (`locator<T>()`) |
| Backend | Supabase (Postgres, RLS, Storage, RPC) |
| Auth | Clerk (`clerk_id` mapped to Supabase JWT `sub`) |
| Offline cache | Realm (hand-written `.realm.dart` companions) |
| Images | Cloudflare Images |
| Icons | [hugeicons](https://pub.dev/packages/hugeicons) |
| Bottom sheets | [stupid_simple_sheet](https://pub.dev/packages/stupid_simple_sheet) |

---

## Architecture at a glance

```
┌──────────────────────────────────────────────────────────────────┐
│  Views (lib/views/<feature>/…)                                   │
│   └─ ViewModelBuilder<XViewModel>.reactive                       │
├──────────────────────────────────────────────────────────────────┤
│  ViewModels (lib/viewModel/…) extend BaseViewModel               │
│   └─ talk to services via locator<T>()                           │
├──────────────────────────────────────────────────────────────────┤
│  Services (lib/api/services/supabase_services/…)                 │
│   ├─ online-first → Supabase / Postgres                          │
│   └─ write-through → Realm cache (offline fallback)              │
├──────────────────────────────────────────────────────────────────┤
│  Realm cache (lib/database/…)                                    │
│   └─ schemas registered in realm_config.dart                     │
└──────────────────────────────────────────────────────────────────┘
```

**Service patterns:**

- **Pattern 2** (list reads) — fetch from Supabase first; on failure return the Realm-cached list.
- **Pattern 3** (mutations) — write to Supabase, then mirror the server response into Realm.
- **Pagination** — keyset cursor on `(last_name, id)` via RPCs (`fetch_teachers_page`, `fetch_students_page`, `fetch_parents_page`).
- **Hybrid search** — view models filter the cached list immediately, then debounce a server search and merge non-cached results in.

---

## Feature areas

| Area | Folder |
|------|--------|
| Admin onboarding / profile | `lib/views/create_account/`, `lib/views/admin_profile/` |
| Teachers (CRUD, homeroom, teach assignments, claim codes) | `lib/views/staff/` |
| Students (CRUD, class, subjects, parents, claim codes) | `lib/views/students/` |
| Parents (managed inline from student detail) | `lib/views/students/` (parent steps + view) |
| Classes & sections | `lib/views/classes/` |
| Subjects | `lib/views/subjects/` |
| Home / shell / tabs | `lib/views/home/`, `lib/views/main_tab/` |

---

## Domain model (high level)

- `roles`, `admin_profiles` — admin authorization
- `classes`, `sections`, `subjects`, `class_subjects` — school structure
- `teachers`, `teacher_class_subjects`, `teacher_claim_codes`, `teacher_clerk_bindings`
- `students`, `student_subjects`, `student_claim_codes`, `student_clerk_bindings`
- `parents`, `parent_claim_codes`, `parent_clerk_bindings`
- `student_parents` — many-to-many with `relationship` + `is_primary`

All tables have RLS on. Claim codes and clerk bindings are admin-only SELECT; bindings can additionally be read by the owning Clerk identity. People rows (students/parents) allow owner self-update on a fixed set of "safe" columns, enforced by a `BEFORE UPDATE` trigger.

**Delete philosophy.** Assignment-style relationships (`students.class_id`, `admin_profiles.role`) are `ON DELETE RESTRICT` to prevent silent data loss. Satellite data (claim codes, bindings, link rows) is `CASCADE`. The app surfaces RESTRICT failures with full-screen **resolution views** that let the admin clean up dependencies — or soft-delete via `is_active = false`.

---

## Notable workflows

### Claim & bind
Admin creates a person → DB trigger generates a `Hamrash-{TCH|STD|PAR}-XXXXXX` claim code → user redeems via `bind_{teacher|student|parent}_claim_code(code, clerk_id)` RPC → binding row created, claim code marked used. All three RPCs share the same signature; conflicts raise `P0001` with a friendly message and bubble up as `ClaimRedemptionFailure` on the Dart side.

### Delete-with-dependencies
Class and subject deletes pre-flight via a single RPC (`preflight_class_delete`, `preflight_subject_delete`) that returns a structured snapshot of every blocker. The UI walks the admin through clearing each section (reassign students, clear homeroom, remove from curriculum, unenroll students…) before unlocking the destructive button. A prominent **"Deactivate instead"** alternative is always offered.

### Family graph offline
`StudentService` and `ParentService` share one Realm cache (`FamilyRealmService`) that owns students + parents + the `student_parents` link rows in one place. Methods like `parentsOf(studentId)` and `studentsOf(parentId)` return `(link, person)` tuples so the UI gets the relationship metadata alongside the entity — same shape online and offline.

---

## Getting started

The Flutter SDK is pinned to **3.44.8** (Dart 3.12.2) via [FVM](https://fvm.app) in `.fvmrc`.

```bash
fvm install                     # installs the pinned SDK if missing
fvm flutter pub get
fvm flutter run --flavor dev    # see lib/env_config for flavor wiring
```

Point your IDE at `.fvm/versions/3.44.8` (VS Code: `"dart.flutterSdkPath"`).

### Required environment

- A Supabase project with the schema and RPCs deployed.
- Cloudflare Images credentials (set via the `SecretService` flow).
- Clerk publishable + secret keys configured for the admin app.

---

## Conventions

- **No magic strings for roles.** Use the constants in `HomeroomRole` and `StudentParentRelationship`.
- **`copyWith` can't null fields.** When clearing optional columns (homeroom, class assignment), construct a fresh model instead.
- **`AppText.canCopyValue` doesn't exist** — copy-to-clipboard lives on `_InfoRow` / `DetailInfoRow`.
- **`flutter analyze` should be clean** on any branch you merge.

---

## Project layout

```
lib/
├── api/
│   ├── models/supabase_models/    # plain Dart models
│   └── services/                  # supabase_services + cloudflare_services
├── database/                      # Realm models + per-feature Realm services
├── viewModel/                     # BaseViewModel subclasses (one per screen-ish)
├── views/                         # Feature-grouped UI
├── widgets/                       # Shared widgets (app_text, app_cards, …)
├── resources/                     # Colors, spacing, scaffold, utils
├── services/                      # Navigation, error logging
└── singleton_locator/locator.dart # GetIt wiring
```
