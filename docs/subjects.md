# Subjects and Teaching Assignments

> **Status:** applied to the live project on 2026-10-11 (migration `20261011134957`). The access test passes (48 checks, last run 2026-10-11). SQL: [`supabase/migrations/20261011134957_06_create_subjects.sql`](../supabase/migrations/20261011134957_06_create_subjects.sql). Test: [`supabase/tests/04_subjects_access_test.sql`](../supabase/tests/04_subjects_access_test.sql). Builds on [academic-structure.md](academic-structure.md).

---

## The model

```
Subject              Mathematics · English · Physics …                 the school's catalogue, in report-card order
Arm subjects         SS 1 Science offers Physics, SS 1 Arts offers Literature   the curriculum, per arm
Teaching assignment  Mr Bayo teaches Mathematics to JSS 1A in 2026/2027          one teacher per subject per arm per session
Student subjects     Chidi takes French in 2026/2027                            optional subjects only, per session
```

- **Subjects** have a name, an optional short **code** (MTH, ENG…) and a **sort order** for report cards. Names and codes are unique per school, ignoring case.
- **Arm subjects** are the curriculum, **per arm**: what each arm offers, and whether each subject is **compulsory** or **optional**. Arms of the same class can differ, so an arm reserved for Arts students doesn't need Physics. To avoid re-entering identical lists:
  - `copy_arm_subjects(from_arm, to_arm)` copies one arm's list to another, for example JSS 1A → JSS 1B.
  - `apply_standard_curriculum(arm)` gives one arm the standard list for its level.

  Both only add what's missing and return how many subjects they added.
- **Teaching assignments:** exactly **one teacher** per subject, per arm, per session. Changing the teacher updates the row. A subject can only be assigned to an arm that offers it.
- **Student subjects** list who takes each **optional** subject, per session. Compulsory subjects aren't listed, because everyone in the arm takes them. The student must be placed that session in an arm that offers the subject, and the database refuses compulsory subjects here.

### What can be deleted
| Deleting… | Result |
|---|---|
| a subject that is taught (has assignments) or chosen as an elective | **Blocked.** Deactivate it instead (`is_active = false`). |
| a subject that's only on the curriculum | Allowed, and its curriculum links go with it |
| an arm or subject | Its curriculum links are removed |
| an arm, session or staff member | Their teaching assignments are removed |
| a student | Their electives are removed |

---

## Teachers see only the students they teach

From this migration, a teacher sees a student's **full record** only if, **in the current session**, the student is placed in an arm where the teacher:

| The teacher… | They see |
|---|---|
| is a **class teacher** (lead or assistant) of that arm | everyone in that arm |
| teaches a **compulsory** subject to that arm | everyone in that arm |
| teaches an **optional** subject to that arm | only the students **who take that subject** |

The same rule covers those students' **parents**, parent links, **placements** and electives. A teacher with no classes sees no students. Leaders and the bursar keep whole-school access, and parents and students are unchanged.

### Past students: your subject's work stays visible (built with results)
If you taught Chidi **Maths in 2026/2027**, you'll **always** be able to see **Chidi's Maths work from that session**: results, assignments, projects and the like. That holds even after he's promoted or graduates. You'll see his name, admission number and photo next to it, but **not** his current record, medical details or parents once you no longer teach him.

This is built with the results tables, where every row carries its own session, subject and arm. Students will be split into a small **profile** (name, admission number, photo) and **private details**, the same way staff were split, so past teachers can see names without anything else. Late results after the session changes work the same way: the work rows for that session stay open to the teacher who taught them.

### Preparing a new session: no gap for teachers
`set_current_session` is just a switch. Leaders prepare the next session **while the old one is still current**, then flip it:

1. Create the session and its terms.
2. Promote or place students into the new session's arms.
3. `copy_assignments_forward(old_session, new_session)` copies class teachers and subject teachers onto the **same arms**. Then adjust: for example, where teachers move up with their pupils, or new staff arrive.
   - Class teachers are copied only for arms that have none in the new session yet.
   - A subject teacher is copied only where the new session has none for that arm and subject.
   - Staff who have exited, inactive arms, and subjects an arm no longer offers are skipped.
   - It returns how many class teachers and subject teachers were copied.
4. `session_readiness(new_session)` reports what's missing: terms, students placed, active students not yet placed, arms without a lead class teacher, and arm subjects without a teacher. The app shows this and warns before flipping.
5. `set_current_session(new_session)`: teachers see their new classes immediately.

---

## One-tap standard subjects

`create_standard_subjects(school_id)` creates **41 common Nigerian subjects** and gives **every existing arm** of a standard-named class (Nursery *n*, Primary *n*, JSS *n*, SS *n*) the standard list for its level. **Create the arms first:** the app's setup order is structure → arms → subjects. Arms added later use `apply_standard_curriculum` or `copy_arm_subjects`.

| Level | Compulsory | Optional |
|---|---|---|
| Nursery | Numeracy, Literacy, Phonics, Basic Science, Social Habits, Health Habits, Cultural and Creative Arts, Rhymes, Handwriting | — |
| Primary | English Language, Mathematics, Basic Science, Basic Technology, Social Studies, Civic Education, Cultural and Creative Arts, Physical and Health Education, Agricultural Science, Home Economics, Computer Studies, Nigerian Language, Verbal Reasoning, Quantitative Reasoning | Christian Religious Studies, Islamic Religious Studies, French |
| JSS | English Language, Mathematics, Basic Science, Basic Technology, Social Studies, Civic Education, Security Education, Cultural and Creative Arts, Physical and Health Education, Agricultural Science, Home Economics, Business Studies, Computer Studies, Nigerian Language | Christian Religious Studies, Islamic Religious Studies, French |
| SS | English Language, Mathematics, Civic Education | Physics, Chemistry, Biology, Further Mathematics, Agricultural Science, Geography, Economics, Government, Literature in English, Christian Religious Studies, Islamic Religious Studies, History, Financial Accounting, Commerce, Technical Drawing, Food and Nutrition, Visual Arts, Computer Studies, Data Processing, Nigerian Language, French |

- It's a **starting point**. Each school should review it against its own curriculum, and everything stays editable. For example, after applying it to SS 1 Arts, remove the sciences and make Literature and Government compulsory.
- Arms of classes with other names get no curriculum. The admin adds subjects or copies them from another arm.
- It only works for a school with **no subjects yet**, and only leaders can run it.

---

## Who can do what

**Leaders** are owner, admin, principal and vice principal.

| | Read | Add / edit | Delete |
|---|---|---|---|
| subjects, arm subjects, teaching assignments | **every member of the school**, including parents, who see who teaches their child, plus platform admins | leaders | subjects: owner and admin. Curriculum links and assignments: leaders. |
| student subjects (electives) | leaders, the bursar, the student's teachers, the child's parents, the student, platform admins | leaders | leaders |

---

## Open work

Open work for this area is tracked in [TODO.md](../TODO.md).
