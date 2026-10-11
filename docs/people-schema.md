# People Schema: staff, students, parents

> **Status:** applied to the live project. Migration `20261007210000` (2026-10-07) created the tables, and migration `20261011130000` (2026-10-11) split staff into a public profile and private details. All 48 checks in the access test pass. SQL: [`…03_create_people.sql`](../supabase/migrations/20261007210000_03_create_people.sql), [`…05_split_staff_private_details.sql`](../supabase/migrations/20261011130000_05_split_staff_private_details.sql). Test: [`supabase/tests/02_people_access_test.sql`](../supabase/tests/02_people_access_test.sql). Builds on [organization-schema.md](organization-schema.md).

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

### `staff`: public profile
Every employee, teaching and non-teaching. **Everyone in the school can read this table**, including parents and students, so they can see and contact the teachers.

| Column | Notes |
|--------|-------|
| `staff_number` | Generated when left blank (see [Numbering](#numbering)), unique within the school |
| `first_name`, `middle_name`, `last_name`, `gender` | |
| `phone`, `email` | Visible to everyone in the school, so parents can contact teachers |
| `photo_id`, `photo_url` | Cloudflare Images id (needed to replace or delete the photo) and its URL |
| `job_title` | Free text, e.g. "Maths Teacher", "Bursar" |
| `staff_type` | `teaching`, `non_teaching` |
| `status` | `active`, `on_leave`, `exited` |

The login role (teacher, bursar, principal…) is chosen when the login is issued. It is separate from `job_title`.

### `staff_private_details`: personal details
Exactly one row per staff member. It's **created automatically** with the staff record and removed with it, so the app only ever updates it. Only leaders, the bursar, the staff member themselves and platform admins can read it. Only leaders can edit it.

| Column | Notes |
|--------|-------|
| `staff_id` | The staff member (primary key) |
| `date_of_birth`, `address`, `state_of_origin`, `employment_date` | |

Splitting the table is how parents can see a teacher's name, phone and email without seeing their home address or date of birth. Row-level security shows or hides whole rows, so the private columns had to move to a table with stricter rules.

### Saving the staff form: one call
The Add and Edit staff forms send every field at once, public and private. Use these functions, not separate table writes. Each saves both tables in **one transaction**, so the form is saved completely or not at all.

| Form | Call | Notes |
|---|---|---|
| Add staff | `create_staff(organization_id, first_name, last_name, …optional fields)` | Leave `staff_number` blank to generate it. Returns the new staff row. |
| Edit staff | `update_staff(staff_id, …every field)` | **All arguments are required.** Send the whole form, and `null` clears a field. A blank staff number keeps the current one. |

```dart
final staff = await supabase.rpc('create_staff', params: {
  'p_organization_id': orgId,
  'p_first_name': 'Ada', 'p_last_name': 'Okafor',
  'p_job_title': 'Maths Teacher', 'p_phone': '0807777777',
  'p_date_of_birth': '1990-05-01', 'p_address': '1 School Road',
});
```

They run with the caller's own permissions, so the usual rules apply: only leaders can add or edit staff.

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
| **staff** (profile): read | all | all | all | all | all | all |
| **staff_private_details**: read | all | all | own | — | — | all |
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
