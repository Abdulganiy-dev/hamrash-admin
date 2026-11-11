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
| 3 | Join scenarios | 3.1 Wrong code · 3.6 School paused | ✅ |
| 3 | Join scenarios | 3.3 Add a role · 3.4 Code for another app · 3.5 Role already covered | ❓ error mapping exists in `join_view_model.dart`; confirm each has its own screen or message as designed |
| 4 | Academic sessions | 4.0 List · 4.0a Empty · 4.1 Details · 4.2 Edit a term · 4.4 Edit the session · 4.5 Dates leave a term out · 4.6 Last year to close · 4.7 Confirm close · 4.8 Closed session | ✅ |
| 4 | Academic sessions | 4.3 Terms overlap | ❓ no overlap check found in the code (also in TODO: "Stop overlapping sessions") |
| 5 | More | 5.1 More (owner) | ✅ only the owner variant is designed |
| 6 | Classes and arms | 6.1 Start · 6.2 Overview · 6.3 Edit a class · 6.3a Class in use · 6.4 Arms for every class | ✅ |
| 7 | Subjects | 7.1 Start · 7.2 By class · 7.3 A class · 7.4 A subject's actions · 7.4a Subject in use · 7.5 Add subjects to a class · 7.6 All subjects · 7.7 Edit a subject · 7.8 Arms differ | ✅ |
| 9 | People · Add student | 9.5 Student (photo optional) · 9.5a Photo options · 9.5b Photo field states · 9.6 Personal details · 9.7 Parents, none yet · 9.7a Parents added · 9.7b Find a parent by phone · 9.7c New parent · 9.8 Class and arm · 9.8a No current session · 9.9 Optional subjects · 9.9a None chosen · 9.10 Review · 9.11 Registered | ✅ built (`lib/views/students/add_student/`); Register calls `register_student` (migration 31), which isn't applied to the live project yet. 9.11's "Open profile" is left out until the student profile (9.12) is built |
| 9 | People · Staff | 9.3–9.4a staff list, filters and empty states · 9.25–9.28 add and invite · 9.29–9.30 staff page and change details · 9.31–9.41 teaching setup | ✅ built, except the list is still a page opened from More with a pinned Add button; the designs now put it on the People tab (9.3) |

Gaps inside finished sections:
- [ ] ❓ Check 3.3, 3.4 and 4.3 in the simulator (see above).
- [ ] ⬜ More tab for the other roles (admin, principal, VP, bursar): the tab shows different areas per role, but only the owner is designed.
- [ ] ⬜ Home after setup is finished: 2.1 and 2.2 are the setup checklist only. Decide the dashboard's first three or four numbers, then design it ([ADMIN_FEATURES.md §7](../ADMIN_FEATURES.md#7-reporting--analytics)).

---

## To design, in build order

### 8 · Grading (Paper § 8 and § 8b) 📝
Schema is done (`score_columns`, `grade_boundaries`, `create_standard_grading`, `grading_problems`; `reorder_score_columns` in migration 33). Migration 34 (in the repo, **not applied** until the app follows it): grades get a stored `max_percent` (whole-number From/To ranges covering 0 to 100, percentages rounded before grading), and grade rows are written only through `set_grade_scale`, `apply_grade_system`, `copy_section_grading` and `remove_section_grade_scale` (per-section setup, Paper § 9b). Needed before the gradebook. Design: [results-design.md → 08](results-design.md).
- [ ] 8.1 Start: one-tap standard setup (CA 1/CA 2/Exam, A–F; Secondary gets WAEC boundaries)
- [ ] 8.2 Overview: the school's setup, and which sections use their own
- [ ] 8.3 Score columns: add, edit, reorder; max score
- [ ] 8.3a Column in use: max score locked and can't be deleted once scores exist
- [ ] 8.4 Grade boundaries: threshold list with pass/fail, and a "starts at 0%" check
- [ ] 8.5 A section's own setup: override columns and boundaries independently, or fall back to the school's
- [ ] 8.6 Problems list (from `grading_problems`: "No score columns yet", "No boundary at 0%")

### 9 · People 🎨 (Paper § 9)
Schema exists (`staff`, `students`, `parents`, `student_parents`). See [people-schema.md](people-schema.md). Paper § 9 holds every people screen: the People tab, Add student, a student's page, parents, and the whole staff flow. The standalone Staffs and Add student sections are gone.
- [ ] 🎨 People tab · Students (9.1–9.2): replaces the "coming soon" People tab. "People" title, a Students | Staff switch (`AppSegmentedControl`) opening on Students, filter and + in the app bar. Students are grouped by class and arm. States: no students yet, filtered, no match, Students only for the bursar (9.1d). Filter sheet (9.2): search by name or admission number, class, arm (once one class is picked), status (default Active), sort.
- [ ] 🎨 People tab · Staff (9.3–9.4a): the staff list on the tab, with filtered, no match, just you and the filter sheet. The Staffs card is gone from More in Paper (5.1); the app still has it until the tab is built.
- [x] Add student (9.5–9.11): built, see the table above.
- [ ] 🎨 Student profile (9.12–9.16, 9.12a): class and arm with lead teacher, subjects, parents with a chevron into the parent's profile, details, personal (leaders and their teachers), access (student app, change status, remove). More actions, change details, move to another arm (results keep their arm), optional subjects. The bursar's view is read-only without personal details.
- [ ] 🎨 Parents (9.17–9.20): a parent's actions, the parent profile (children, details, parent app login), add a parent by phone (not found opens 9.7c), confirm unlink. A student's only parent can't be unlinked.
- [ ] 🎨 Student status and access (9.21–9.24): change status (active, graduated, transferred, withdrawn), the withdrawn state, the student app code (`invite_student`), confirm remove (owner and admin only).
- [x] Staff (9.25–9.41): add staff, invite, staff page, change details, teaching setup. Built.
  - Class and subject assignments, on-leave/exited status changes, and editing photos or private details are still open. The staff page reads `staff_number`, `staff_type` and `status` and shows the record status read-only. Add staff and Change details now collect middle name, gender, date of birth, home address and residence state/LGA. Editing details ships through `update_staff`, which sends every unchanged hidden field back (photo, status, date of birth, state of origin and employment date).
- Backend not checked yet for the 🎨 rows: a paged and grouped students list, and updating placement, status, subjects and links. Some may need new RPCs, which count as big database changes, so ask who handles them.

### 10 · Gradebook and workflow 📝
Plan: [results-design.md → Gradebook](results-design.md). Admin side is oversight: the teacher app enters scores.
- [ ] 10.1 Results home: terms and arms, with status (draft, submitted, reviewed, published)
- [ ] 10.2 An arm: every subject's sheet and its status, who hasn't submitted
- [ ] 10.3 A subject sheet (read-only): scores, remarks
- [ ] 10.4 Return a sheet to draft, with a reason
- [ ] 10.5 Class-teacher remarks and behaviour ratings (affective and psychomotor, 1–5) ⚠ decide if this lives in the admin app or only in the teacher app
- [ ] 10.6 Mark an arm reviewed (lead class teacher only)
- [ ] 10.7 Approve and publish an arm (confirm: results freeze, parents see them)
- [ ] 10.8 Unpublish, with a confirm and what it undoes
- [ ] 10.9 Role views: principal full, VP edit, others view or none

### 11 · Publishing and report cards 📝
- [ ] 11.1 Report card preview (per student): subjects, grades, positions, class stats, behaviour, remarks
- [ ] 11.2 Annual result (shown once the last term is published)
- [ ] 11.3 Broadsheet for an arm
- [ ] 11.4 Export / share report card PDF
- [ ] 11.5 Withhold one student's result

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
