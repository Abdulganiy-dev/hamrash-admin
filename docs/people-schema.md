# People Schema: staff, students, parents

> **Status:** applied to the live project on 2026-10-07 (migration `20261007210000`). All 38 checks in the access test pass. SQL: [`supabase/migrations/20261007210000_03_create_people.sql`](../supabase/migrations/20261007210000_03_create_people.sql). Test: [`supabase/tests/02_people_access_test.sql`](../supabase/tests/02_people_access_test.sql). Builds on [organization-schema.md](organization-schema.md).

---

## Records vs logins

A **people record** is what the school knows about someone. A **login** is an `organization_members` row. They are separate because most records never sign in, for example nursery pupils or a parent who only gets SMS.

```
staff ─────┐
students ──┼── member_id (optional) ──► organization_members ──► Clerk user
parents ───┘
```

To give someone a login, an owner or admin calls `invite_staff`, `invite_student` or `invite_parent`. The function creates the invite, links it to the record and returns the claim code. Calling it again before the code is used returns the **same code**, so the app can always show it again. Once redeemed, the person is linked. `member_id` can never be written by the app.

Permission is checked while the record is being looked up. Someone who can't issue logins for that school gets "record not found, or you can't issue logins for it", the same error as for an id that doesn't exist. The functions therefore reveal nothing about other schools' records.

A teacher whose child attends the school has two records (`staff` and `parents`) and two logins, one per role. Each is issued from its own record.

---

## Tables

### `staff`
Every employee, teaching and non-teaching.

| Column | Notes |
|--------|-------|
| `staff_number` | Generated when left blank (see [Numbering](#numbering)), unique within the school |
| `first_name`, `middle_name`, `last_name`, `gender`, `date_of_birth` | |
| `email`, `phone`, `address`, `state_of_origin` | |
| `photo_id`, `photo_url` | Cloudflare Images id (needed to replace or delete the photo) and its URL |
| `job_title` | Free text, e.g. "Maths Teacher", "Bursar" |
| `staff_type` | `teaching`, `non_teaching` |
| `employment_date` | |
| `status` | `active`, `on_leave`, `exited` |

The login role (teacher, bursar, principal…) is chosen when the login is issued. It is separate from `job_title`.

### `students`
| Column | Notes |
|--------|-------|
| `admission_number` | Generated when left blank (see [Numbering](#numbering)), unique within the school |
| `first_name`, `middle_name`, `last_name`, `gender`, `date_of_birth` | |
| `admission_date`, `address`, `state_of_origin`, `lga` | |
| `photo_id`, `photo_url` | Cloudflare Images id and URL |
| `blood_group` | `A+` … `O-` |
| `genotype` | `AA`, `AS`, `AC`, `SS`, `SC`, `CC` |
| `medical_notes` | |
| `status` | `active`, `graduated`, `transferred`, `withdrawn` |

Class enrollment comes with the classes migration.

### `parents`
| Column | Notes |
|--------|-------|
| `title` | Mr, Mrs, Dr, Chief… |
| `first_name`, `last_name`, `gender` | |
| `phone` | **Required**, indexed so a sibling's registration can find an existing parent |
| `alt_phone`, `email`, `occupation`, `address` | |
| `photo_id`, `photo_url` | Cloudflare Images id and URL |
| `is_active` | |

### `student_parents`
| Column | Notes |
|--------|-------|
| `student_id`, `parent_id` | Composite FKs, so both must be in the same school |
| `relationship` | `father`, `mother`, `guardian`, `other` |
| `is_primary_contact` | At most one per student. Setting a new primary automatically clears the old one. |

Deleting a student or parent removes their links. Nothing else cascades.

---

## Numbering

If the app leaves `admission_number` or `staff_number` blank, the database fills it in. Example for a school with prefix `KCL`:

| | Format |
|---|---|
| Admission number | `KCL/2026/0001` |
| Staff number | `KCL/STF/0001` |

- **Prefix.** `organizations.number_prefix` is required, 2–8 capital letters or digits. Hamrash enters it when creating the school (`create_organization(name, number_prefix, …)`), so every number has it from day one. The owner or admin can correct it later. Only new numbers use the new prefix; existing ones don't change.
- **Admission year.** Taken from `admission_date`, or today's date in Lagos if that's blank. The counter restarts each year. Staff numbers use one counter that never restarts.
- **Typed-in numbers** (for example when importing existing records) are kept. Generated numbers skip any value that's already taken, so the two never collide.
- **Editing.** Numbers can be changed after creation to correct mistakes, but they must stay unique within the school.
- **No gaps from failed saves.** Counters live in `private.number_sequences`, which the app can't see. They advance in the same transaction as the insert, so a failed save doesn't leave a gap.

---

## Who can do what

**Leaders** are owner, admin, principal and vice principal.

| | Leaders | Bursar | Teacher | Parent | Student | Platform admin |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| **staff**: read | all | all | own record | — | — | all |
| **students**: read | all | all | all* | own children | own record | all |
| **parents**: read | all | all | all* | self + their children's other parents/guardians | — | all |
| **links**: read | all | all | all* | all links of their children | own | all |
| Add and edit any of the above | ✓ | | | | | |
| Delete staff, students, parents | owner and admin only | | | | | |
| Add, edit and remove links | ✓ | | | | | |
| Issue logins | owner and admin only | | | | | ✓ |

\* Teachers see every student and parent in the school until classes exist. After that it narrows to their own classes.

When a school is suspended, everyone except platform admins loses access to its people.

---

## Deliberately left for later
- Self-editing and automatic login suspension are tracked in [TODO.md](../TODO.md).
- **Linking the owner's own staff record** to the login they got from Hamrash.
- **Extra roles for one staff member,** such as a principal who also teaches, without a second claim code.
