# Academic Structure: sections, classes, arms, sessions

> **Status:** applied to the live project on 2026-10-11 (migrations `20261011123753` and `20261011130000`). All 47 checks in the access test pass. SQL: [`supabase/migrations/20261011123753_04_create_academic_structure.sql`](../supabase/migrations/20261011123753_04_create_academic_structure.sql), plus [`…05_split_staff_private_details.sql`](../supabase/migrations/20261011130000_05_split_staff_private_details.sql) so parents can see teachers' names. Test: [`supabase/tests/03_academic_structure_access_test.sql`](../supabase/tests/03_academic_structure_access_test.sql). Builds on [people-schema.md](people-schema.md).

---

## The model

```
School
 └─ Section     Nursery · Primary · Secondary            created by the school, ordered
     └─ Class   Primary 1 … Primary 6 · JSS 1 … SS 3     ordered within its section
         └─ Arm A · B · Gold · Science  →  "JSS 1A"      created by the school admin

Session  2026/2027
 └─ Term  First · Second · Third                         (or semesters: up to 6)

Placement  student → arm, for one session                 keeps class history
Class teacher  staff → arm, for one session               up to one lead + two assistants
```

- **Sections** are the school's divisions. Each can have a head (`head_staff_id`). Later, each can have its own grading, report card and fees.
- **Classes** are levels. Promotion order is the section's order, then the class's order within it, so *Primary 6 → JSS 1* follows naturally across sections. The admin marks **graduating classes** (`is_graduating_class`). Students promoted out of one graduate, for example SS 3, or Primary 6 in a school that ends there.
- **Arms** are the actual groups of pupils. A class with one group still has one arm, so everything (placements, class teachers, timetables later) always points at an arm. `capacity` is informational only; the app can warn, but the database doesn't block.
- **Sessions and terms.** A session has terms, and each term must fall inside its session's dates. Each school has at most one **current** session and one **current** term, and the current term always belongs to the current session.
- **Placements** say which arm a student is in for a session: one per student per session. Moving a pupil mid-session updates the row. Earlier sessions stay as history, which promotion and report cards need.
- **Class teachers** are assigned per session: **at most one lead and at most two assistants** per arm, and neither is required. An arm can have just a lead, a lead and one assistant, or a lead and two. Making someone the lead automatically makes the previous lead an assistant. If that would create a third assistant, it's refused: remove an assistant first.

### Starting structure

`create_standard_structure(school_id)` sets up a typical Nigerian school in one call:

| Section | Classes |
|---|---|
| Nursery | Nursery 1, Nursery 2, Nursery 3 |
| Primary | Primary 1 … Primary 6 |
| Secondary | JSS 1, JSS 2, JSS 3, SS 1, SS 2, SS 3 (SS 3 marked as the graduating class) |

- It only works for a school with **no sections yet**, so it can't duplicate anything.
- Everything it creates can be renamed, reordered or deactivated afterwards.
- It doesn't create arms; the admin adds those.
- It runs with the caller's own permissions, so only leaders can use it.

---

## Tables

| Table | Key columns | Notes |
|-------|-------------|-------|
| `sections` | `name`, `sort_order`, `head_staff_id`, `is_active` | Name unique per school (case-insensitive) |
| `classes` | `section_id`, `name`, `sort_order`, `is_graduating_class`, `is_active` | Name unique per school (case-insensitive) |
| `class_arms` | `class_id`, `name`, `capacity`, `is_active` | Name unique per class. **Can't be moved to another class**: its placements would silently change class. |
| `academic_sessions` | `name`, `starts_on`, `ends_on`, `is_current` | Name unique per school |
| `academic_terms` | `session_id`, `name`, `sequence` (1–6), `starts_on`, `ends_on`, `is_current` | Dates inside the session; sequence and name unique per session |
| `class_teachers` | `session_id`, `arm_id`, `staff_id`, `is_lead` | Per arm per session: at most 1 lead, at most 2 assistants |
| `student_placements` | `student_id`, `session_id`, `arm_id` | One per student per session |

Every link uses the two-column `(organization_id, id)` pattern, so nothing can point across schools.

### What can be deleted
| Deleting… | Result |
|---|---|
| a section that has classes, a class that has arms, or an arm that has placements | **Blocked.** Deactivate it instead (`is_active = false`). |
| a session that has terms or placements | **Blocked** |
| an arm, a staff member or a session | That arm's or person's **class-teacher assignments** are removed with it |
| a student | Their placements are removed with them |
| a staff member who heads a section | The section stays and its head is cleared |

---

## Current session and term

`is_current` can't be written by the app. Two functions change it and keep everything consistent:

| Function | Does |
|---|---|
| `set_current_session(session_id)` | Makes that session current and clears the current flag on every other session. Clears any current term from another session. |
| `set_current_term(term_id)` | Makes that term current **and its session current**, clearing the others |

Only leaders of the school can call them. Anyone else gets the same "not found, or you can't manage this school's calendar" error, so nothing is revealed.

---

## Who can do what

**Leaders** are owner, admin, principal and vice principal.

| | Read | Add / edit | Delete |
|---|---|---|---|
| sections, classes, arms, sessions, terms, class teachers | **every member of the school**, including parents and students (they need class names and the current term), plus platform admins | leaders | owner and admin. Class teachers: leaders. |
| student placements | leaders, the bursar, **the student's teachers** (current session), **the child's parents**, the student, platform admins | leaders | leaders |

Since migration 06, teachers see only the students they teach in the current session. See [subjects.md](subjects.md).

When a school is suspended, everyone except platform admins loses access.

---

## Promotion: decided, not built yet
- Each child's outcome (promote, repeat, graduate, leave) is **suggested from their results** once results exist, and the admin can override it.
- **No default arm.** The admin picks the destination arm; nothing is assumed from the arm letter.
- Students promoted out of a class the admin marked `is_graduating_class` graduate.
- The **next session must already exist** before promoting into it.
- **Class changes happen once a year, at promotion.** A rare mid-year move (for example Primary 3 → Primary 4 in second term) just edits the placement. History is kept per session, not per term.
- **Results record the arm the child was in when the result was recorded,** so a mid-year move never changes an old report card's class or class position.

## Open work

Open work for this area is tracked in [TODO.md](../TODO.md).
