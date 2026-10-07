# Supabase (Hamrash)

Database for the Hamrash platform. Project ref: `ccvyhbyrtobdsecqvhcr`. Design notes: [`docs/organization-schema.md`](../docs/organization-schema.md).

## Migrations

Applied in filename order. Each filename's timestamp matches the version recorded in the project's migration history.

| # | File | What it does |
|---|------|--------------|
| 01 | `20261007182933_01_create_organizations_and_members.sql` | `organizations`, `organization_members`, `platform_admins`; RLS helpers in `private`; claim codes; owner guard; RPCs `create_organization`, `set_organization_status`, `redeem_claim_code` |
| 02 | `20261007185331_02_tidy_rls_initplan_and_rls_auto_enable.sql` | Rewrites two policies to the form the advisor recognises; revokes API execute on `rls_auto_enable()` |

Before writing a new migration, follow the checklist under "Rules every future school table follows" in the design notes.

## Tests

| File | What it checks |
|------|----------------|
| `tests/01_organizations_access_test.sql` | 28 access rules for migration 01: who can read, invite, edit and suspend, and that schools are kept apart |

To run a test, paste the file into the SQL editor. It acts as several fake users, then raises an exception on purpose so every change is rolled back. The error message is the PASS/FAIL report. It needs the dummy platform admin `user_dummy_platform_admin` to exist.

## Adding a platform admin

Hamrash team members are added by hand in the SQL editor:

```sql
insert into public.platform_admins (clerk_user_id, full_name, email)
values ('<Clerk user id>', '<name>', '<email>');
```
