# Supabase RLS — How We Create Tables and Write Policies

This is our working reference. Every new table goes through this document. Follow it top to bottom when creating any new table.

---

## The golden rule: always add `clerk_id` to user-owned tables

When Clerk authenticates a user it puts a stable id inside the JWT under the claim `sub`. In Postgres/Supabase you read it with:

```sql
auth.jwt() ->> 'sub'
```

For **any table that belongs to a user** (a profile, a post, a submission, anything the user creates and owns), you must store that `sub` value in a column called **`clerk_id`**. That column is the bridge between Supabase RLS and Clerk auth.

```sql
clerk_id text null,
constraint your_table_clerk_id_key unique (clerk_id)  -- unique so one Clerk user = one row (if 1-to-1)
```

Without `clerk_id` in the table, you cannot write a policy that says "this row belongs to the currently logged-in user."

---

## Table types and their RLS template

Every table we create fits into one of three categories. Pick the right one and copy the template.

---

### Type 1 — User profile table

**What it is:** one row per user, created when they sign up. The user owns their row entirely.

**Must have:** `clerk_id text unique not null` (or nullable before the user completes onboarding).

**Example:**

```sql
create table public.user_profiles (
  id          uuid primary key default gen_random_uuid(),
  clerk_id    text not null unique,     -- <-- always here
  full_name   text not null,
  email       text not null,
  created_at  timestamptz default now()
);
```

**RLS policies:**

```sql
-- Step 1: enable RLS (do this for every table, no exceptions)
alter table public.user_profiles enable row level security;

-- SELECT: any signed-in user can read all profiles
-- (common for a directory-style app; tighten if profiles are private)
create policy select_user_profiles on public.user_profiles
  for select to authenticated
  using (auth.jwt() is not null);

-- INSERT: you can only insert a row where clerk_id matches your JWT sub
create policy insert_own_profile on public.user_profiles
  for insert to authenticated
  with check (clerk_id = (auth.jwt() ->> 'sub'));

-- UPDATE: you can only update your own row
create policy update_own_profile on public.user_profiles
  for update to authenticated
  using  (clerk_id = (auth.jwt() ->> 'sub'))
  with check (clerk_id = (auth.jwt() ->> 'sub'));

-- DELETE: you can only delete your own row
create policy delete_own_profile on public.user_profiles
  for delete to authenticated
  using (clerk_id = (auth.jwt() ->> 'sub'));
```

> **Why both `using` and `with check` on UPDATE?**
> `using` filters which rows you are allowed to touch. `with check` makes sure the row after the update is still valid (e.g. you cannot change `clerk_id` to someone else's).

---

### Type 2 — Content/activity table (owned by a user, but `clerk_id` is resolved via a join)

**What it is:** rows like posts, submissions, or work history that are linked to a user **indirectly** through a foreign key to the profile table. The content table does not store `clerk_id` itself — instead it stores a `uuid` that points to the profile row.

**Why no direct `clerk_id`?** The profile table already has it. You resolve ownership with an `EXISTS` subquery that joins the profile table and checks its `clerk_id`.

**Example:**

```sql
create table public.posts (
  id          uuid primary key default gen_random_uuid(),
  belongs_to  uuid not null references public.user_profiles (id) on delete no action,
  title       text not null,
  body        text,
  created_at  timestamptz default now()
);
```

**RLS policies:**

```sql
alter table public.posts enable row level security;

-- SELECT: any authenticated user can see all posts
create policy select_all_posts on public.posts
  for select to authenticated
  using (auth.jwt() is not null);

-- INSERT: any signed-in user can create a post
-- (the app is responsible for setting belongs_to = the user's profile id)
create policy insert_post_by_authenticated on public.posts
  for insert to authenticated
  with check (auth.jwt() is not null);

-- UPDATE: only the owner can update — resolved via join to user_profiles
create policy update_own_post on public.posts
  for update to authenticated
  using (
    exists (
      select 1 from public.user_profiles up
      where up.id = posts.belongs_to
        and up.clerk_id = (auth.jwt() ->> 'sub')
    )
  )
  with check (
    -- also prevent re-assigning belongs_to to another user
    belongs_to = (
      select p.belongs_to from public.posts p where p.id = posts.id
    )
    and exists (
      select 1 from public.user_profiles up
      where up.id = posts.belongs_to
        and up.clerk_id = (auth.jwt() ->> 'sub')
    )
  );

-- DELETE: no one can delete (permanent record)
-- use this pattern when rows are an audit trail
create policy no_delete_posts on public.posts
  for delete to authenticated
  using (false);
```

> **The `belongs_to = (select ... where id = posts.id)` trick:**
> This is how you lock a column on UPDATE so the user cannot reassign the row to a different user. The `with check` compares the new value of `belongs_to` to the original value stored in the database. If they differ, the update is rejected.

---

### Type 3 — Reference / lookup table

**What it is:** shared data that the app reads but users do not create — categories, states, skill lists, etc. Only your backend/admin (via `service_role`) should write to it.

**No `clerk_id` needed** — rows do not belong to any one user.

**Example:**

```sql
create table public.categories (
  id    uuid primary key default gen_random_uuid(),
  name  text not null,
  slug  text not null unique
);
```

**RLS policies:**

```sql
alter table public.categories enable row level security;

-- SELECT: any signed-in user can read
create policy select_categories on public.categories
  for select to authenticated
  using ((auth.jwt() ->> 'sub') is not null);

-- INSERT / UPDATE / DELETE: service_role only (your backend / admin script)
create policy service_role_insert_categories on public.categories
  for insert to service_role
  with check (true);

create policy service_role_update_categories on public.categories
  for update to service_role
  using (true) with check (true);

create policy service_role_delete_categories on public.categories
  for delete to service_role
  using (true);
```

> **`service_role` bypasses RLS entirely in Supabase** — so you technically only need these policies as a safeguard and for clarity. The important thing is that you do NOT give `anon` or `authenticated` write access.

---

## Quick policy decision guide

| Question | Answer |
|----------|--------|
| Is this table user-owned (one user = one row)? | Type 1. Add `clerk_id`, compare with `auth.jwt() ->> 'sub'` directly. |
| Is this table user-created content (one user = many rows)? | Type 1 for INSERT/UPDATE/DELETE (with `clerk_id` check), Type 2 for SELECT (broad read). |
| Does this table link to a profile by `uuid` instead of `clerk_id`? | Type 2. Resolve ownership with `EXISTS` + join to the profile table that has `clerk_id`. |
| Is this a shared lookup / reference table? | Type 3. Authenticated users read; service_role writes. |
| Should rows ever be permanently deleted by users? | If no: `using (false)` on `DELETE` policy (append-only). |

---

## Checklist — creating any new table

Copy this every time:

```
[ ] Decide: Type 1 / Type 2 / Type 3
[ ] Add clerk_id column if Type 1 (and add unique constraint if one row per user)
[ ] Enable RLS: alter table public.<name> enable row level security;
[ ] Write SELECT policy
[ ] Write INSERT policy (with check, not using)
[ ] Write UPDATE policy (both using AND with check)
[ ] Write DELETE policy — or use (false) if append-only
[ ] Test with two different Clerk users — user A must not be able to write user B's rows
```

---

## RPC functions — how to gate them

When you write an SQL function (RPC) that the client calls directly, guard it at the top of the function body the same way policies do:

```sql
create or replace function public.do_something(...)
returns ...
language plpgsql
as $$
declare
  caller_clerk_id text;
begin
  -- 1. Pull the Clerk user id from the JWT
  caller_clerk_id := auth.jwt() ->> 'sub';

  -- 2. Reject if no JWT
  if caller_clerk_id is null or caller_clerk_id = '' then
    raise exception 'Not authenticated';
  end if;

  -- 3. Verify the user actually exists in our profiles table
  if not exists (
    select 1 from public.user_profiles
    where clerk_id = caller_clerk_id
  ) then
    raise exception 'User not found';
  end if;

  -- 4. Now do the real work...
end;
$$;
```

> Always validate `sub` AND confirm the profile row exists. Someone can have a valid Clerk JWT but not yet have completed sign-up; the second check catches that.

---

## Indexes — add them alongside RLS

RLS policies often run `EXISTS` or equality checks on `clerk_id` or `belongs_to`. Without an index those checks scan the whole table. Add these when you create the table:

```sql
-- Type 1 tables: clerk_id is already indexed via UNIQUE constraint
-- Type 2 tables: index the foreign key column + anything you ORDER/FILTER by
create index if not exists idx_posts_belongs_to
  on public.posts (belongs_to);

-- If you paginate by created_at (common pattern):
create index if not exists idx_posts_belongs_to_created_at_id
  on public.posts (belongs_to, created_at desc, id desc);
```

---

## Full migration file layout

Every migration file follows this order:

```sql
-- 1. Create table
create table public.<name> ( ... );

-- 2. Enable RLS immediately (never leave a table without it)
alter table public.<name> enable row level security;

-- 3. Policies (select → insert → update → delete)
create policy ...

-- 4. Indexes
create index if not exists ...

-- 5. Triggers / functions if needed
create or replace function ...
create trigger ...
```

---

## Things we never do

- **Never skip `enable row level security`** — an unsecured table is visible to everyone with your anon key.
- **Never use `to public`** on write policies — that includes unauthenticated users. Use `to authenticated`.
- **Never put `service_role` logic in the mobile app** — service_role bypasses all RLS; only use it on the server.
- **Never let a user change `clerk_id` on their own row** — always include `clerk_id` in the `with check` of an UPDATE so it cannot drift.
- **Never forget `with check` on UPDATE** — `using` only governs which rows you can start touching; `with check` enforces what the row looks like after.
