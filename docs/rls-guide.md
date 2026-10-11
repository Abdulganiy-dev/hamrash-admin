# How We Write Tables and Access Rules

The working reference for every new migration. It replaces the old single-school `RLS_Approach_Guide.md`. The reasoning behind each piece is in the design docs listed in [README.md](README.md).

---

## 1. Who is calling

- Clerk signs the user in. Supabase verifies the Clerk token and exposes it as `auth.jwt()`. The caller's id is `auth.jwt() ->> 'sub'`.
- **Never use `auth.uid()`.** It's Supabase Auth's id, not Clerk's.
- **School tables don't store `clerk_id`.** Identity flows through one place: `organization_members.clerk_user_id`, set only by `redeem_claim_code`. People records point at a membership with `member_id`, set only by `invite_staff`, `invite_student` and `invite_parent`.

## 2. Every school table

```sql
create table public.things (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete restrict,
  other_id         uuid not null,
  …
  constraint things_org_id_key unique (organization_id, id),              -- lets others point here safely
  constraint things_other_fkey foreign key (organization_id, other_id)    -- two-column links keep
    references public.others (organization_id, id) on delete restrict      --   everything in one school
);
alter table public.things enable row level security;
create index … on public.things (organization_id, …);                     -- lead with organization_id
```

- Every link to another school table uses the pair `(organization_id, x_id)`, so a row can never point into another school.
- Every foreign key needs an index that **starts with the key's columns, in the key's order**. For `(organization_id, other_id)` that means an index on `(organization_id, other_id, …)`. Supabase's checker flags any that don't. Migration 09 got this wrong, and migration 10 fixed it.
- `updated_at` gets the trigger `private.set_updated_at()`.

## 3. The helper functions

They live in `private`, which the app can't call directly. They're `security definer`, so policies can use them without looping back into themselves, and each one only ever looks up the caller's own `sub`.

| Helper | Returns |
|---|---|
| `my_org_ids(roles, include_inactive)` | Schools where I'm an **active** member, optionally only in certain roles. Suspended and archived schools are excluded unless asked for. |
| `is_platform_admin()` | Am I on the Hamrash team? |
| `my_member_ids()` | My active memberships, in active schools |
| `my_staff_ids()` · `my_parent_ids()` · `my_student_ids()` | The people records that are me |
| `my_child_ids()` | Students I'm a parent of |
| `my_childrens_parent_ids()` | All parents of my children, me included |
| `my_taught_student_ids()` | Students I teach **this session** (class teacher, compulsory subject, or optional subject they take) |
| `my_ever_taught_student_ids()` | Students I've taught in **any** session. Used for profiles only. |
| `my_taught_students_parent_ids()` | Parents of the students I teach this session |
| `can_manage_academics(org)` · `can_issue_logins(org)` | Am I a leader? Am I owner, admin or a platform admin? |

**Role groups used everywhere:**
- **Leaders:** `owner`, `admin`, `principal`, `vice_principal`
- **Whole-school readers of people data:** leaders + `bursar`
- **Deletes:** usually `owner`, `admin` only

## 4. Policy patterns

Always write a policy as `organization_id in (select private.my_org_ids(...))`, never as a per-row function call. The list is worked out once per query.

**School-wide reference data** (sections, classes, subjects, grading…):
```sql
-- read:   every member, plus platform admins
using (organization_id in (select private.my_org_ids()) or (select private.is_platform_admin()))
-- insert / update: leaders
with check (organization_id in (select private.my_org_ids(array['owner','admin','principal','vice_principal']::public.member_role[])))
-- delete: owner and admin
```

**Data about a student** (placements, electives, and later results):
```sql
using (
  organization_id in (select private.my_org_ids(array['owner','admin','principal','vice_principal','bursar']::public.member_role[]))
  or student_id in (select private.my_taught_student_ids())
  or student_id in (select private.my_child_ids())
  or student_id in (select private.my_student_ids())
  or (select private.is_platform_admin())
)
```

**Public profile + private details.** Row-level security shows or hides **whole rows**, so columns that need stricter rules move to a `*_private_details` table:
- one row per record, created by an `after insert` trigger
- removed with the record by `on delete cascade`
- read by fewer people than the profile
- saved together with the profile through `create_*` / `update_*` functions running as the caller, so a form saves completely or not at all

This pattern is used for `staff`, `students` and `parents`.

**Policy names:** keep them under **63 characters**, because Postgres silently cuts longer ones. Use the form `"table: who can do what"`.

## 5. Permissions

Supabase's defaults give `anon` and `authenticated` **all** rights on new tables and functions. So every migration does this:

```sql
revoke all on public.things from anon, authenticated;
grant select, delete on public.things to authenticated;                 -- the policies still decide which rows
grant insert (id, organization_id, name, …) on public.things to authenticated;
grant update (name, …) on public.things to authenticated;               -- never organization_id
revoke execute on function public.some_rpc(…) from public, anon;
grant  execute on function public.some_rpc(…) to authenticated;
```

- **Column lists are the second layer.** The app can never write `organization_id` after insert, or `member_id`, `clerk_user_id`, `claim_code`, `is_current`, or a school's `status` and `code`. Those change only through functions.
- `anon` (not signed in) gets nothing.

## 6. Functions

- **Run as the caller (`security invoker`) by default.** Row-level security then applies as normal. `create_staff`, `create_standard_structure` and `copy_assignments_forward` work this way.
- **Use `security definer` only when needed:**
  - helpers called from policies
  - functions that must write protected columns (`invite_*`, `redeem_claim_code`, `set_current_term`…)
  - triggers that must see across row-level security (number generation, private-details rows)
- **Definer functions must check permission inside the record lookup** (`where id = $1 and private.can_…(organization_id)`). An unauthorised caller then gets the **same** error as for an id that doesn't exist, so nothing about other schools leaks.
- **Every function:** `set search_path = ''`, fully qualified names (`public.x`, `private.y`), and `revoke execute … from public, anon`.

## 7. Applying migrations

- **The Supabase connector refuses any statement that drops something.** Migrations with `drop` are run in the **SQL editor**, then recorded:
  ```sql
  insert into supabase_migrations.schema_migrations (version, name) values ('<version>', '<name>');
  ```
- **Version order:** a version set by hand must be **earlier** than the next one the connector will stamp, which is the current time. Rename the local file to the recorded version.
- **Before applying,** check that the stored names of any policies you alter match. Long names were cut off at 63 characters when they were created.

## 8. Tests

- **Each migration gets an access test** in `supabase/tests/`. It acts as fake users through `request.jwt.claims` + `set local role`, checks every rule, and rolls everything back.
- **To run them all,** paste `supabase/tests/run_all.sql` into the SQL editor. You get one row per test.
- **After changing a test,** rebuild the runner with `python3 supabase/tests/build_run_all.py`.
