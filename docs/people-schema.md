# People Schema: staff, students, parents

> **Status:** applied to the live project through migration 31 (`register_student`). Migration `20261109150000` (32, the switched-off section check in `register_student`) is in the repo but **not yet applied**. Migration `20261108120000` (2026-11-08) added staff residence state and LGA. Migration `20261007210000` (2026-10-07) created the tables, and migration `20261011130000` (2026-10-11) split staff into a public profile and private details. SQL: [`…03_create_people.sql`](../supabase/migrations/20261007210000_03_create_people.sql), [`…05_split_staff_private_details.sql`](../supabase/migrations/20261011130000_05_split_staff_private_details.sql). Test: [`supabase/tests/02_people_access_test.sql`](../supabase/tests/02_people_access_test.sql). Builds on [organization-schema.md](organization-schema.md).

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
| `residence_state`, `residence_lga` | Where the person lives now, beside the home address. Private like `address`. |

Splitting the table is how parents can see a teacher's name, phone and email without seeing their home address or date of birth. Row-level security shows or hides whole rows, so the private columns had to move to a table with stricter rules.

### Saving the staff form: one call
The Add and Edit staff forms send every field at once, public and private. Use these functions, not separate table writes. Each saves both tables in **one transaction**, so the form is saved completely or not at all.

| Form | Call | Notes |
|---|---|---|
| Add staff | `create_staff(organization_id, first_name, last_name, …optional fields)` | Leave `staff_number` blank to generate it. `middle_name`, `gender`, `address`, `residence_state` and `residence_lga` are optional. Returns the new staff row. |
| Edit staff | `update_staff(staff_id, …every field)` | **All arguments are required.** Send the whole form, including `middle_name`, `gender`, `address`, `residence_state` and `residence_lga`; `null` clears a field. A blank staff number keeps the current one. |

```dart
final staff = await supabase.rpc('create_staff', params: {
  'p_organization_id': orgId,
  'p_first_name': 'Ada', 'p_last_name': 'Okafor',
  'p_job_title': 'Maths Teacher', 'p_phone': '0807777777',
  'p_date_of_birth': '1990-05-01', 'p_address': '1 School Road',
  'p_residence_state': 'Lagos', 'p_residence_lga': 'Ikeja',
});
```

They run with the caller's own permissions, so the usual rules apply: only leaders can add or edit staff.

### Listing staff *(migration 30)*
The Staffs list (8.1) and its filter sheet (8.17) read one page at a time through `list_staff`. Search, filters, sorting, chip counts and paging all happen in the database. It returns the staff profile and its login only, never private details.

```dart
final result = await supabase.rpc('list_staff', params: {
  'p_organization_id': orgId,
  'p_search': '0803 555 0142',
  'p_login': null,                       // all
  'p_roles': <String>[],                 // every role
  'p_staff_type': null,                  // both
  'p_statuses': ['active'],
  'p_sort': 'name',
  'p_limit': 30,
  'p_cursor': null,                      // first page
}) as Map<String, dynamic>;
// { rows: [...], next_cursor: '…' | null, total: 12,
//   counts: { all, on_app, code_ready, not_on_app, suspended } }
```

| Param | Default | Meaning |
|---|---|---|
| `p_organization_id` | required | The school. Null is refused (`22023`). |
| `p_search` | null | Case-insensitive, partial. Every word must match the first, middle or last name, staff number, email or phone. Phones are compared by their digits without spaces, a leading `0` or `+234`, so `0803 555 0142`, `8035550142` and `+2348035550142` find the same number however it was saved. A phone match needs at least 3 digits. |
| `p_login` | null (= `all`) | `on_app` (active login, owner included), `code_ready` (unclaimed invite), `not_on_app` (no login), `suspended`. |
| `p_roles` | null | The login's role (`owner`, `admin`, `principal`, `vice_principal`, `bursar`, `teacher`, `staff`). **People without a login have no role**, so a role filter only matches people with a login, whatever its status. Null or `[]` = every role. |
| `p_staff_type` | null | `teaching` or `non_teaching`; null = both. |
| `p_statuses` | null | Record status (`active`, `on_leave`, `exited`). Null or `[]` = all. The app sends `['active']` by default. |
| `p_sort` | `name` | `name`: the active owner first, then first name, last name, id. `newest`: `created_at` newest first, then id. |
| `p_limit` | 30 | Page size, clamped to 1–100. |
| `p_cursor` | null | `next_cursor` from the previous page. Start again with null whenever a filter, the search or the sort changes. |

- **Rows** have the same keys as `StaffMember.columns`, with the login embedded as `member` (null when there is none), so `StaffMember.fromJson` reads them unchanged.
- **`counts`** apply the search, staff type, statuses and roles but **ignore `p_login`**, so each login chip shows how many it would list. **`total`** is the number of rows matching every filter.
- **Paging is keyset**, not offset. The opaque cursor holds the last row's sort key and id, so adding or removing someone while the user scrolls never repeats or skips a row. `next_cursor` is null on the last page. A cursor from the other sort, or a damaged one, is refused (`22023`), as are an unknown `p_login` or `p_sort`.
- **Security.** It runs as the caller, so RLS decides: every active member of the school sees the profiles, and only leaders see other people's logins. For a teacher, bursar, parent or student, `member` is null except on their own row, so the login filter and counts treat everyone else as not on the app. Someone outside the school gets no rows and zero counts.

### `students`: profile
| Column | Notes |
|--------|-------|
| `admission_number` | Generated when left blank (see [Numbering](#numbering)), unique within the school |
| `first_name`, `middle_name`, `last_name`, `gender` | |
| `admission_date` | Stays here because the admission-number generator reads it |
| `photo_id`, `photo_url` | Cloudflare Images id and URL |
| `status` | `active`, `graduated`, `transferred`, `withdrawn` |

Class placement is in `student_placements` (see [academic-structure.md](academic-structure.md)).

### `student_private_details`: personal and medical *(migration 07)*
Exactly one row per student. It's **created automatically** with the student and removed with them.

| Column | Notes |
|--------|-------|
| `student_id` | The student (primary key) |
| `date_of_birth`, `address`, `state_of_origin`, `lga` | |
| `blood_group` | `A+` … `O-` |
| `genotype` | `AA`, `AS`, `AC`, `SS`, `SC`, `CC` |
| `medical_notes` | |

**Why the split:** a teacher keeps seeing the work they marked, permanently (see [results-design.md](results-design.md)), so past students need to show a name. The split lets **past teachers see the profile only**: name, admission number and photo. Medical and personal details are only for the student's **current** teachers, leaders, their parents and the student. The **bursar** sees profiles but not private details.

**Saving the student form:** `create_student(...)` and `update_student(student_id, …every field)` save both tables in one transaction, the same way `create_staff` / `update_staff` work.

### `parents`: profile
What co-parents and the child's teachers may see.

| Column | Notes |
|--------|-------|
| `title` | Mr, Mrs, Dr, Chief… |
| `first_name`, `last_name`, `gender` | |
| `phone` | **Required**, indexed so a sibling's registration can find an existing parent |
| `alt_phone` | |
| `photo_id`, `photo_url` | Cloudflare Images id and URL |
| `is_active` | |

### `parent_private_details` *(migration 07)*
Exactly one row per parent, **created automatically** with the parent and removed with them.

| Column | Notes |
|--------|-------|
| `parent_id` | The parent (primary key) |
| `email`, `occupation`, `address` | |

**Who sees it:** leaders, the **bursar** (for fees and invoices), the **parent themselves** and platform admins. **Not co-parents**, so separated parents can't see each other's email or address, and **not teachers**, who have the parent's name and phone on the profile.

**Saving the parent form:** `create_parent(...)` and `update_parent(parent_id, …every field)` save both tables in one transaction.

### `student_parents`
| Column | Notes |
|--------|-------|
| `student_id`, `parent_id` | Composite FKs, so both must be in the same school |
| `relationship` | `father`, `mother`, `guardian`, `other` |
| `is_primary_contact` | At most one per student. Setting a new primary automatically clears the old one. |

Deleting a student or parent removes their links. Nothing else cascades.

### Registering a student: one call *(migration 31; section check in migration 32, not yet applied)*
The Add Student wizard (student → parents → class and arm → optional subjects → review) saves everything with `register_student`, in **one transaction**: the student and their private details, any new parents, the links, the placement for the session and the optional subjects. A refusal keeps nothing. SQL: [`…31_register_student_rpc.sql`](../supabase/migrations/20261109120000_31_register_student_rpc.sql). Test: [`supabase/tests/19_register_student_access_test.sql`](../supabase/tests/19_register_student_access_test.sql).

```dart
final result = await supabase.rpc('register_student', params: {
  'p_organization_id': orgId,
  'p_first_name': 'Chidi', 'p_last_name': 'Okafor',
  'p_gender': 'male', 'p_date_of_birth': '2014-03-02',
  'p_parents': [
    // an existing parent, e.g. a sibling's (found by phone first)
    {'parent_id': motherId, 'relationship': 'mother', 'is_primary_contact': true},
    // a new parent: the same fields as create_parent
    {'first_name': 'Emeka', 'last_name': 'Okafor', 'phone': '08035550143',
     'title': 'Mr', 'gender': 'male', 'email': 'emeka@example.ng',
     'relationship': 'father', 'is_primary_contact': false},
  ],
  'p_arm_id': armId,
  'p_session_id': null,               // the school's current session
  'p_optional_subject_ids': [frenchId],
}) as Map<String, dynamic>;
// { student: {students row}, parent_ids: [...], placement: {session_id, arm_id}, subject_ids: [...] }
```

| Param | Default | Meaning |
|---|---|---|
| `p_organization_id` | required | The school. |
| `p_first_name`, `p_last_name` | required | |
| `p_parents` | required | jsonb array, at least one item. An item with `parent_id` reuses that parent (its other fields are ignored); otherwise it creates one from `first_name`, `last_name`, `phone` (required), `title`, `gender`, `alt_phone`, `email`, `occupation`, `address`, `photo_id`, `photo_url`. Every item has `relationship` (`father`, `mother`, `guardian`, `other`) and `is_primary_contact` (a JSON boolean; missing = false). |
| `p_arm_id` | required | The class arm. |
| `p_session_id` | null | null = the school's current session. |
| `p_optional_subject_ids` | `{}` | Optional subjects of the arm. Duplicates are dropped. |
| `p_middle_name`, `p_admission_number`, `p_gender`, `p_admission_date`, `p_photo_id`, `p_photo_url`, `p_date_of_birth`, `p_address`, `p_state_of_origin`, `p_lga`, `p_blood_group`, `p_genotype`, `p_medical_notes` | null | The same student fields as `create_student`. A blank admission number is generated. The student is always saved as `active`. |

Every rule is checked before anything is written, so the wizard gets one readable message:

| Refused when | Code | Message |
|---|---|---|
| The caller isn't a leader of the school (or the school is suspended) | `42501` | Only the school's leaders can register students |
| Blank student name | `22023` | Enter the student's first and last name |
| Admission number already used | `23505` | Admission number … is already used in this school. Leave it blank to generate one |
| No parents | `22023` | Add at least one parent or guardian |
| Bad relationship | `22023` | Choose how each parent is related to the student: father, mother, guardian or other |
| Same `parent_id` twice | `22023` | The same parent is listed twice. Add each parent once |
| Two new parents with the same phone | `22023` | Two new parents have the same phone number …. Add each parent once |
| `parent_id` not in this school | `P0002` | That parent isn't in this school. Search for them again, or add them as a new parent |
| New parent missing name or phone | `22023` | Enter each new parent's first name, last name and phone number |
| New parent's phone matches a parent in the school | `23505` | {name} is already a parent in this school with phone …. Choose them as an existing parent instead of adding them again |
| No primary contact / more than one | `22023` | Choose one parent as the primary contact / Only one parent can be the primary contact |
| Arm not in the school | `P0002` | Choose a class and arm in this school |
| Section switched off *(migration 32)* | `P0001` | The {Junior} section is switched off. Choose a class in another section, or switch it back on first |
| Arm or its class switched off | `P0001` | {JSS 1 A} is switched off. Choose another arm, or switch it back on first |
| No current session (when `p_session_id` is null) | `P0001` | This school has no current session. Set one up in the calendar first |
| Session not in the school | `P0002` | Session not found in this school |
| Session closed | `P0001` | That session is closed. Nothing new can be added to it; use the current session. |
| Subject not offered by the arm | `23514` | {Subject} isn't offered to {JSS 1 A}. Choose from the arm's optional subjects |
| Subject compulsory on the arm | `23514` | {Subject} is compulsory for {JSS 1 A}, so every student already takes it |

- **New parents are never merged.** Phones are compared by their digits (`0803…`, `803…` and `+234803…` match), and a match is refused so the app reuses the existing parent. The app searches by phone before offering "Add a new parent".
- **Security.** It runs as the caller (security invoker) and writes through `create_student`, `create_parent` and the normal tables, so RLS and the column grants still decide. No grant was widened. `private.check_student_subject` and the closed-session triggers still run as a backstop.

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
| **students** (profile): read | all | all | students they teach now **or taught before** | own children | own record | all |
| **student_private_details**: read | all | — | students they teach **now*** | own children | own record | all |
| **parents** (profile): read | all | all | parents of students they teach* | self + their children's other parents/guardians | — | all |
| **parent_private_details**: read | all | all | — | **own only** | — | all |
| **links**: read | all | all | links of students they teach* | all links of their children | own | all |
| Add and edit any of the above | ✓ | | | | | |
| Delete staff, students, parents | owner and admin only | | | | | |
| Add, edit and remove links | ✓ | | | | | |
| Issue logins | owner and admin only | | | | | ✓ |

\* *Since migration 06:* students the teacher teaches **in the current session**: placed in an arm where they're a class teacher or teach a subject. For an optional subject, only the students who take it. Past students' work for the teacher's subject stays visible permanently once results exist. See [subjects.md](subjects.md).

When a school is suspended, everyone except platform admins loses access to its people.

---

## Open work

Open work for this area is tracked in [TODO.md](../TODO.md).
