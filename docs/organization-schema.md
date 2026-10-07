# Organization (Tenant) Schema

> **Status:** applied to the live project on 2026-10-07 (migrations `20261007182933` and `20261007185331`). All 28 checks in [`supabase/tests/01_organizations_access_test.sql`](../supabase/tests/01_organizations_access_test.sql) pass. SQL: [`supabase/migrations/20261007182933_01_create_organizations_and_members.sql`](../supabase/migrations/20261007182933_01_create_organizations_and_members.sql). The live Supabase project (`ccvyhbyrtobdsecqvhcr`) was empty when this was written. The older docs (`supabase-database-schema.md`, `RLS_Approach_Guide.md`, `supabase/README.md`) describe a single-school schema that was never deployed.

---

## The idea in one sentence

Every school is an **organization**. Every row of school data carries an `organization_id`, and Postgres row-level security only returns rows from organizations the signed-in Clerk user is a member of.

```mermaid
erDiagram
    organizations ||--o{ organization_members : "who can sign in, and as what"
    organizations ||--o{ "every school table (classes, students, staff, fees…)" : "organization_id"
    organization_members |o--o| "people tables (staff, students, parents)" : "member_id (optional)"
    platform_admins }o..o{ organizations : "Hamrash team: creates and reads all"
```

| Layer | Answers | Example |
|-------|---------|---------|
| `organizations` | Which school? | "Kings College", code `HMR-7K2Q9P` |
| `organization_members` | Who can **sign in** to this school, and with what role? | Clerk user `user_2ab…` is a `teacher` at Kings College |
| People tables (next: `staff`, `students`, `parents`) | What does the school **know** about this person? | Name, class, admission number, photo |
| `platform_admins` | Who on the Hamrash team runs the platform? | Support staff who onboard schools |

Membership is kept separate from the people tables because not every person record signs in. A nursery pupil has a `students` row but no membership.

---

## Decisions

| Question | Decision |
|----------|----------|
| Who creates schools? | **Hamrash team**, through `create_organization`. Schools don't sign themselves up. |
| Where do memberships live? | **Postgres** (`organization_members`), not Clerk Organizations |
| Hamrash support access? | **Yes.** `platform_admins` can read every school and create and suspend schools. |
| Short school code? | **Yes:** `HMR-XXXXXX`, generated automatically and unique |
| Campuses? | **Later add-on.** The organization is the only tenant boundary for now. |
| Roles | `owner`, `admin`, `principal`, `vice_principal`, `bursar`, `teacher`, `staff`, `parent`, `student` |

---

## Tables

### `platform_admins`

| Column | Notes |
|--------|-------|
| `clerk_user_id` | PK, Clerk JWT `sub` |
| `full_name`, `email` | |
| `is_active` | Turn off instead of deleting |

Managed only by Hamrash through the SQL editor or service role. Clients can read it, so the app can ask "am I a platform admin?".

### `organizations`

| Column | Notes |
|--------|-------|
| `id` | `uuid` PK. The organization id. |
| `code` | `HMR-XXXXXX`, unique, generated |
| `name`, `email`, `phone`, `address`, `state`, `logo_url` | Editable by the school's owner or admin |
| `logo_id` | Cloudflare Images id of the logo, needed to replace or delete it. Editable by the owner or admin. *(added in migration 03)* |
| `number_prefix` | Required, 2–8 letters or digits (e.g. `KCL`). Entered by Hamrash at creation; goes in front of admission and staff numbers. Owner or admin can correct it. *(added in migration 03)* |
| `status` | `trial`, `active`, `suspended`, `archived`. Only platform admins change it. Schools are never deleted. |
| `created_by` | Clerk id of the platform admin who created it |

### `organization_members`

| Column | Notes |
|--------|-------|
| `id` | `uuid` PK |
| `organization_id` | FK → `organizations`, `ON DELETE RESTRICT` |
| `clerk_user_id` | `null` until the invite is claimed |
| `role` | `member_role` |
| `status` | `invited` → `active` → `suspended` |
| `claim_code` | 8 chars, generated on invite, cleared once redeemed. Shown to users as `XXXX-XXXX`. |
| `invited_by`, `joined_at` | |

- One row per (school, person, role). A teacher who is also a parent at the same school has two rows. Someone at two schools has rows in both.
- `unique (organization_id, id)` lets the people tables point at a membership with a composite FK, so a membership can't be attached to the wrong school.

---

## How a school is onboarded

```
Hamrash platform admin              School owner                      Owner's staff
──────────────────────              ────────────                      ─────────────
create_organization("Kings College", "KCL")
  → org created (code HMR-7K2Q9P, status trial)
  → owner invite created (claim code ABCD-2345)
gives the code to the owner  ──►    signs in with Clerk
                                    redeem_claim_code("ABCD-2345")
                                      → membership active, role owner
                                    invites admins/teachers  ──►      sign in, redeem their codes
```

Later, `set_organization_status(org, 'active' | 'suspended' | 'archived')` is platform-admin only.

**What suspension does.** Members of a suspended or archived school can still see their membership and the school's row, so the app can show "this school is suspended, contact Hamrash". All other school data is hidden, and claim codes for that school stop working.

---

## How access control works

Two helpers in a `private` schema, which the Data API doesn't expose:

- `private.my_org_ids(roles)`: the schools where the caller is an **active member** and the school is **active or trial**, optionally limited to certain roles.
- `private.is_platform_admin()`: whether the caller is an active Hamrash platform admin.

Every policy is built from them:

```sql
-- members of the school (and Hamrash support) can read
using (organization_id in (select private.my_org_ids()) or (select private.is_platform_admin()))

-- only the school's owners and admins can write
with check (organization_id in (select private.my_org_ids(array['owner','admin']::public.member_role[])))
```

- **`in (select …)` runs once per query, not per row**, then uses the `organization_id` index.
- **Both helpers are `security definer`**, so policies on the tables they read don't recurse. They only ever look up the caller's own JWT `sub`.

### Who can do what (core tables)

| Action | Owner | Admin | Principal / VP | Other members | Platform admin |
|--------|:-----:|:-----:|:--------------:|:-------------:|:--------------:|
| Read own school | ✓ | ✓ | ✓ | ✓ | ✓ (all schools) |
| Edit school details | ✓ | ✓ | | | ✓ |
| Change school status | | | | | ✓ (RPC) |
| See all members of the school | ✓ | ✓ | ✓ | own rows only | ✓ |
| Invite members (not owners) | ✓ | ✓ | | | ✓ |
| Invite owners | | | | | ✓ |
| Change role or status of members | ✓ | ✓ | | | ✓ |
| Change or remove an owner | ✓ | | | | ✓ |
| Delete unclaimed invites | ✓ | ✓ | | | ✓ |

**Guards enforced by the database:**
- An admin can't promote anyone, including themselves, to owner, and can't demote or suspend an owner.
- A school can never lose its last active owner.
- Clients can never write `status`/`code` on schools, or `clerk_user_id`/`claim_code` on members. Column-level grants block it, and only the RPCs set them.
- An `active` member must have a Clerk id, and an `invited` member must have a claim code.

---

## Rules every future school table follows

```
[ ] organization_id uuid not null references organizations(id) on delete restrict
[ ] unique (organization_id, id)  ← lets child tables use composite FKs
[ ] FKs to other school tables are composite: (organization_id, x_id) → x(organization_id, id)
[ ] indexes lead with organization_id
[ ] RLS enabled; policies use private.my_org_ids(...) and include platform-admin read
[ ] revoke all from anon, authenticated; then grant only what's needed
    (this project's defaults grant ALL to anon/authenticated on new tables)
[ ] update policies have both USING and WITH CHECK; organization_id is never client-updatable
```

"Members can read" suits school-wide reference data (classes, subjects, timetable, announcements). People and finance tables need narrower rules, for example a parent sees only their own children. We design those table by table.

---

## Prerequisites to check

- The Supabase project has the **Clerk third-party auth integration** enabled (Dashboard → Authentication → Third-party).
- Clerk session tokens include `"role": "authenticated"`, otherwise Supabase treats requests as `anon`.
- After applying, the first platform admin is added by hand in the SQL editor:
  ```sql
  insert into public.platform_admins (clerk_user_id, full_name, email)
  values ('<your Clerk user id>', '<name>', '<email>');
  ```

## Later

- Expiring and re-issuing claim codes.
- Rate limiting on `redeem_claim_code` (codes have about 1.1 trillion combinations, so this isn't urgent).
- Campuses as a sub-scope on a few tables.
- Where the Hamrash team's platform screens live: inside the admin app behind `platform_admins`, or a separate console.
