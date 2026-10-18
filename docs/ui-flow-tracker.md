# UI Flow Tracker

Which screens are **designed** (Paper, file "Hamrash", page "Hmarash Admin") and **built** (Flutter). Section numbers match the Paper artboards (`4.2 · Calendar · Edit a term`), so a number means the same thing here, in the design and in the code comments.

Admin roles: owner, admin, principal, vice_principal, bursar. Permissions: [ADMIN_FEATURES.md](../ADMIN_FEATURES.md#8-security--access-control). Open work behind each area: [TODO.md](../TODO.md).

**Status:** ✅ designed and built · 🎨 designed, not built · 📝 flow outlined, screens not designed · ⬜ not started · ❓ needs a check

Update this file when an artboard is added or a screen ships.

---

## Done: designed and built

| § | Area | Screens | Status |
|---|------|---------|--------|
| 1 | Onboarding | 1.1 Sign in · 1.2 Enter code · 1.3 Confirm (staff) · 1.4 Confirm (owner) · 1.5 Pick a school · 1.6 Confirm school details | ✅ |
| 2 | Home | 2.1 Setup checklist · 2.2 Setup in progress (bursar) | ✅ |
| 3 | Join scenarios | 3.1 Wrong code · 3.2 Too many tries · 3.6 School paused | ✅ |
| 3 | Join scenarios | 3.3 Add a role · 3.4 Code for another app · 3.5 Role already covered | ❓ error mapping exists in `join_view_model.dart`; confirm each has its own screen or message as designed |
| 4 | Academic sessions | 4.0 List · 4.0a Empty · 4.1 Details · 4.2 Edit a term · 4.4 Edit the session · 4.5 Dates leave a term out · 4.6 Last year to close · 4.7 Confirm close · 4.8 Closed session | ✅ |
| 4 | Academic sessions | 4.3 Terms overlap | ❓ no overlap check found in the code (also in TODO: "Stop overlapping sessions") |
| 5 | More | 5.1 More (owner) | ✅ only the owner variant is designed |
| 6 | Classes and arms | 6.1 Start · 6.2 Overview · 6.3 Edit a class · 6.3a Class in use · 6.4 Arms for every class | ✅ |
| 7 | Subjects | 7.1 Start · 7.2 By class · 7.3 A class · 7.4 A subject's actions · 7.4a Subject in use · 7.5 Add subjects to a class · 7.6 All subjects · 7.7 Edit a subject · 7.8 Arms differ | ✅ |

Gaps inside finished sections:
- [ ] ❓ Check 3.3, 3.4 and 4.3 in the simulator (see above).
- [ ] ⬜ More tab for the other roles (admin, principal, VP, bursar): the tab shows different areas per role, but only the owner is designed.
- [ ] ⬜ Home after setup is finished: 2.1 and 2.2 are the setup checklist only. Decide the dashboard's first three or four numbers, then design it ([ADMIN_FEATURES.md §7](../ADMIN_FEATURES.md#7-reporting--analytics)).

---

## To design, in build order

### 8 · Grading setup 📝
Schema is done (`score_columns`, `grade_boundaries`, `create_standard_grading`, `grading_problems`). Needed before the gradebook. Design: [results-design.md → 08](results-design.md).
- [ ] 8.1 Start: one-tap standard setup (CA 1/CA 2/Exam, A–F; Secondary gets WAEC boundaries)
- [ ] 8.2 Overview: the school's setup, and which sections use their own
- [ ] 8.3 Score columns: add, edit, reorder; max score
- [ ] 8.3a Column in use: max score locked and can't be deleted once scores exist
- [ ] 8.4 Grade boundaries: threshold list with pass/fail, and a "starts at 0%" check
- [ ] 8.5 A section's own setup: override columns and boundaries independently, or fall back to the school's
- [ ] 8.6 Problems list (from `grading_problems`: "No score columns yet", "No boundary at 0%")

### 9 · Gradebook and workflow 📝
Plan: [results-design.md → Gradebook](results-design.md). Admin side is oversight: the teacher app enters scores.
- [ ] 9.1 Results home: terms and arms, with status (draft, submitted, reviewed, published)
- [ ] 9.2 An arm: every subject's sheet and its status, who hasn't submitted
- [ ] 9.3 A subject sheet (read-only): scores, remarks
- [ ] 9.4 Return a sheet to draft, with a reason
- [ ] 9.5 Class-teacher remarks and behaviour ratings (affective and psychomotor, 1–5) ⚠ decide if this lives in the admin app or only in the teacher app
- [ ] 9.6 Mark an arm reviewed (lead class teacher only)
- [ ] 9.7 Approve and publish an arm (confirm: results freeze, parents see them)
- [ ] 9.8 Unpublish, with a confirm and what it undoes
- [ ] 9.9 Role views: principal full, VP edit, others view or none

### 10 · Publishing and report cards 📝
- [ ] 10.1 Report card preview (per student): subjects, grades, positions, class stats, behaviour, remarks
- [ ] 10.2 Annual result (shown once the last term is published)
- [ ] 10.3 Broadsheet for an arm
- [ ] 10.4 Export / share report card PDF
- [ ] 10.5 Withhold one student's result

### 11 · People ⬜
Schema exists (`staff`, `students`, `parents`, `student_parents`). See [people-schema.md](people-schema.md). Nothing is designed yet.
- [ ] 11.1 Students: list, search, filter by class and arm
- [ ] 11.2 Student profile: details, class history, parents, claim code
- [ ] 11.3 Register a student: details, class and arm, subjects, parents, primary contact
- [ ] 11.4 Move a student to another arm
- [ ] 11.5 Parents: list, a parent's profile, link and unlink
- [ ] 11.6 Staff: list, profile, class and subject assignments, status (active, on leave, exited)
- [ ] 11.7 Add staff, issue and re-issue a claim code
- [ ] 11.8 Class teachers and teaching assignments: who teaches what, in which arm
- [ ] 11.9 Student subjects: electives
- [ ] 11.10 Team and invites: invite, cancel an unclaimed invite, change a role, suspend ❓ the More tab has team management in code but no Paper artboard; check what shipped and design it properly

### 12 · Promotion ⬜
Decisions: [academic-structure.md → Promotion](academic-structure.md#promotion-decided-not-built-yet). Needs results first.
- [ ] 12.1 Start: pick the session and class
- [ ] 12.2 Suggested outcomes per child (promote, repeat, graduate, leave), with override
- [ ] 12.3 Pick destination arms
- [ ] 12.4 Review and confirm
- [ ] 12.5 Blocked: next session doesn't exist yet

### 13 · Homework 📝
Plan: [results-design.md → Homework](results-design.md). Mostly teacher and parent apps; admin oversight screens only.
- [ ] 13.1 Assignments overview by arm and subject (read-only)

---

## Later: not designed, and not scheduled

Listed in [ADMIN_FEATURES.md](../ADMIN_FEATURES.md). Pick a flow and move it up when it's next.

- ⬜ Admissions pipeline and student bulk import
- ⬜ Attendance oversight and policy
- ⬜ Timetable builder and exam scheduling
- ⬜ Fees: fee structure, invoices, payments, receipts, debtors (bursar's main area)
- ⬜ Payroll and staff attendance
- ⬜ Announcements, messaging, events calendar
- ⬜ Reports and exports
- ⬜ Audit log
- ⬜ Platform admin screens (separate app: `hamrash-platform-admin`)

---

## How we design a flow

1. Outline the flow in a doc or here: who, from where, the happy path, and the failure states.
2. Design the screens in Paper, numbered `§.n · Area · Screen`, error and edge states as `n.na` or in the § 3-style scenarios row.
3. Follow the design system page: light mode only, Nunito, 16px gutter.
4. Build it as service, then view model, then view, and mark the row ✅.
