# Hamrash Admin — Feature Scope

The slice of the [Hamrash platform features](../FEATURES.md) that belongs to the **admin app**. This is a discussion document: each module lists what the admin does, what is left to the teacher app or the parent/student portal, what already exists, and the open questions to settle before building.

**Rule of thumb:** the admin app **configures, approves, oversees and reports**. The teacher app and the parent/student portal **do the daily work and consume the results**.

---

## Where we are today

| Layer | State |
|-------|-------|
| Supabase schema | Multi-school: schools, memberships and roles, claim codes, staff, students and parents (profiles + private details), sections, classes, arms, sessions and terms, class teachers, placements, subjects, curriculum per arm, teaching assignments, electives, and the grading setup. See [`docs/README.md`](docs/README.md). |
| Admin UI | Cleared out in `bf07068`. `lib/views/` only has a template, and the shared UI core came over from AgriTrack (`359b7d9`). Every screen below needs to be built. |
| Not in the schema yet | Gradebook, report cards and homework (planned in [`docs/results-design.md`](docs/results-design.md)), promotion, attendance, timetable, fees and payments, payroll, messaging, events, audit log, campuses. See [`TODO.md`](TODO.md). |

Status key used below: **Schema** = tables exist, UI not built · **New** = nothing exists yet.

---

## 1. Student Management

| Admin capability | Status |
|------------------|--------|
| **Admissions pipeline:** record applications, review them, accept or reject, convert to an enrolled student | New |
| **Registration:** create a student, assign class and section, enroll in subjects, link parents (relationship, primary contact), issue the claim code | Schema |
| **Student records:** profile, photo, admission number, medical notes, documents, class history | Schema (partly; no documents or history yet) |
| **Lifecycle:** promote, repeat, transfer, graduate, deactivate (soft delete) | New (only `is_active` exists) |
| **Attendance oversight:** view and correct the attendance teachers take, set the attendance policy, flag chronic absence | New |
| **Bulk import** of students and parents from CSV/Excel when a school onboards | New |

**Not admin:** teachers mark daily attendance in the teacher app, and parents view it in the portal.

**To discuss**
- Do we need an online admission form for prospective parents in v1, or does the admin enter applications by hand?
- How should admission numbers be formatted, and should the system generate them?
- Promotion at the end of the session: automatic based on results, manual, or automatic with an admin review step?

---

## 2. Academic Management

| Admin capability | Status |
|------------------|--------|
| **Academic calendar:** sessions (e.g. 2026/2027) and terms, with the current one marked active | New (**blocks results, fees and attendance**) |
| **School structure:** classes, sections/arms, subjects, which subjects each class takes | Schema |
| **Teacher assignments:** homeroom teacher, and who teaches which subject in which class | Schema |
| **Timetable builder:** periods, breaks, per-class weekly grid, clash detection (teacher or room double-booked) | New |
| **Syllabus / scheme of work:** receive the scheme of work from teachers, approve and publish it | New |
| **Assessment setup:** assessment types (CA1, CA2, exam…), weights, grading scale (A1–F9 or custom), pass mark | New |
| **Exam scheduling:** exam timetable per class | New |
| **Result processing:** compute totals, grades, class positions and averages; add principal remarks; approve and publish; generate report cards (PDF) | New |
| **Result controls:** lock score entry after a deadline, withhold individual results | New |

**Not admin:** teachers write schemes of work, enter scores and add their own remarks in the teacher app; students and parents view published results in the portal.

**To discuss**
- Is the grading scale one per school, or does it differ by level (nursery, primary, JSS, SSS)?
- Do report cards need psychomotor and affective (behaviour) ratings alongside scores?
- Who approves results: principal only, or vice principal first and then principal?
- Should result publishing be tied to fee clearance (withheld while fees are owed)? Many schools do this, but it needs a deliberate policy.

---

## 3. Finance and Fees Management

| Admin capability | Status |
|------------------|--------|
| **Fee structure:** fee items (tuition, PTA, uniform, transport…) per class and per term, mandatory or optional | New |
| **Discounts:** scholarships, sibling discounts, staff-child discounts, one-off waivers | New |
| **Invoicing:** generate invoices per student per term, in bulk or one at a time | New |
| **Payments:** record offline payments (cash, bank transfer), reconcile online payments, support part-payment | New |
| **Online payment integration:** gateway setup and webhook reconciliation | New |
| **Receipts:** automatic receipt on every payment, shareable as PDF | New |
| **Debtors:** outstanding balances by class and student, reminders to parents | New |
| **Financial reports:** collections by period, by class and by fee item; expected vs collected | New |

**Not admin:** parents view invoices, pay online and download receipts in the portal.

**To discuss**
- Which payment gateway (Paystack, Flutterwave, Remita, other)? Does each school bring its own merchant account?
- Should we also track school expenses (a basic ledger), or only fee income?
- ~~Should there be a dedicated **bursar/accountant** role?~~ Settled: `bursar` is an admin-app role. See the permission matrix in section 8.

---

## 4. Staff Management

| Admin capability | Status |
|------------------|--------|
| **Staff profiles:** create, edit, deactivate, issue claim codes | Schema (teachers only) |
| **Non-teaching staff:** bursar, admin officer, security, drivers… | New (`teachers` is the only staff table) |
| **Staff attendance:** daily register, lateness, absence reports | New |
| **Leave management:** leave requests and approvals | New (not in the original list; optional) |
| **Payroll:** salary structure, allowances, deductions (tax, pension, loans), monthly payroll run, payslips | New |
| **Workload:** periods per week per teacher (from the timetable), subjects and classes taught | New (needs the timetable) |
| **Performance evaluation:** appraisal cycles, criteria, ratings, history | New |

**Not admin:** staff clock in, view payslips and do self-appraisal in the teacher app (TBD).

**To discuss**
- Do we rename or generalise `teachers` into `staff` with a staff type, or add a separate table for non-teaching staff?
- Staff attendance: does the admin mark it, or do staff clock in themselves (geofenced, QR code at the gate)?
- Does payroll need to cover PAYE and pension remittance reports, or only payslips?

---

## 5. Communication & Administration

| Admin capability | Status |
|------------------|--------|
| **Announcements / notice board:** post to everyone, by role (staff, parents, students), or by class | New |
| **Internal messaging:** admin ↔ staff direct and group messages | New |
| **Parent–teacher communication:** oversight of parent–teacher threads, and the ability to step in | New |
| **Events & school calendar:** holidays, open days, PTA meetings, exam periods; RSVP for meetings | New |
| **Push / SMS / email notifications:** what triggers them and the templates | New |

**Not admin:** teachers and parents message each other in their own apps.

**To discuss**
- Should the admin be able to read parent–teacher messages (safeguarding), or only receive escalations?
- SMS matters in markets where many parents don't install apps. Is SMS in v1, and who pays for it?

---

## 6. Parent & Student Portal (admin's side of it)

The portal is a separate app. The admin app only controls what feeds it:

| Admin capability | Status |
|------------------|--------|
| Issue and reissue claim codes for parents and students | Schema |
| Link and unlink parents and students; set the primary contact | Schema |
| Decide what parents see and when (results publishing, fee visibility) | New |
| Send notifications that land in the portal | New |

---

## 7. Reporting & Analytics

| Admin capability | Status |
|------------------|--------|
| **Dashboard:** enrollment, today's attendance rate, fee collection rate, outstanding fees, upcoming events | New |
| **Academic reports:** performance by class, subject and teacher; term-on-term trends; broadsheets | New |
| **Financial reports:** see module 3 | New |
| **Staff reports:** attendance, workload, appraisal summaries | New |
| **Export:** PDF and Excel for every report | New |

**To discuss**
- Which three or four numbers should the home dashboard show first? Pick these before designing it.

---

## 8. Security & Access Control

| Admin capability | Status |
|------------------|--------|
| **Admin roles:** `owner`, `admin` (shown as "School administrator"), `principal`, `vice_principal`, `bursar` | Schema |
| **Permission matrix:** what each role can see and do, module by module | New |
| **Admin user management:** invite, change role, deactivate admin users | Schema (partly) |
| **Secure login:** Clerk sign-in, MFA for admins, session timeout | Partly (Clerk) |
| **Row-level security:** every table protected in Postgres | Schema (all tables have RLS) |
| **Audit log:** who changed what and when, especially for results, fees and payroll | New |
| **Backup & export:** scheduled backups (Supabase), on-demand data export for the school | New |

**Roles**

| Role | Who it is | In one line |
|------|-----------|-------------|
| `owner` | The proprietor | Owns the school: its details, and everyone's access. Created by Hamrash platform admin. |
| `admin` | School administrator (registrar, manager) | Runs operations and access for the owner: records, people, clean-up. Shown as "School administrator" so it isn't confused with the app's name. |
| `principal` | Head of the school | Runs academics: calendar, classes, subjects, grading, results. |
| `vice_principal` | Deputy head | Same as principal today. |
| `bursar` | Accounts | Runs fees; sees what fees work needs, changes nothing else. |

Several roles at one school add up (no role switcher). Teachers, staff, parents and students use the other apps.

**Permission matrix** (fixed roles; settled 2026-10-13)

Key: **Full** = add, edit, delete · **Edit** = add and edit, no delete · **View** = read only · **—** = no access · *italics* = proposed, no tables yet

| Module | owner | admin | principal | vice_principal | bursar |
|--------|:-:|:-:|:-:|:-:|:-:|
| School details (name, address, logo, number prefix; confirming them) | Edit | View | View | View | View |
| Academic setup (sessions, terms, sections, classes, arms, class teachers) | Full | Full | Full⁴ | Full⁴ | View |
| Subjects (subjects, which arms take them, student subjects) | Full | Full | Edit¹ | Edit¹ | View |
| Grading setup (score columns, grade boundaries) | Full | Full | Full | Full | View |
| Students and parents (records, placements, parent links) | Full | Full | Edit² | Edit² | View³ |
| Staff records | Full | Full | Edit | Edit | View |
| Results (approve, publish, report cards) | *View* | *View* | *Full* | *Edit* | *—* |
| Finance (fee structure, invoices, payments, debtors) | *Full* | *View* | *View* | *View* | *Full* |
| Payroll | *Full* | *—* | *—* | *—* | *Full* |
| Communication (announcements) | *Full* | *Full* | *Full* | *Full* | *Fees notices only* |
| Reports | *All* | *All but payroll* | *Academic* | *Academic* | *Finance* |
| Invite the team | Any role but owner | Any role but owner | Principal, VP, bursar, teacher, staff | Principal, VP, bursar, teacher, staff | — |
| Cancel an unclaimed invite | Any | Any | Roles they can invite | Roles they can invite | — |
| Change someone's role, suspend someone | Yes | Yes | — | — | — |

¹ Can also link and unlink subjects to arms and enrol or remove students from subjects; only deleting a subject is owner/admin.
² Can also move students between classes and link parents; only deleting a student or parent is owner/admin.
³ Bursars see parent private details (for fees) but not student private details.
⁴ Delete came with migration 18 (sessions and terms) and migration 21 (sections, classes and arms). For every role, removal still fails while something depends on it: a current term must be replaced first (migration 20), a section with classes stays, and an arm with students placed in it stays (switch it off instead). Removing an arm also removes its class teachers, subjects and teaching assignments.

When adding attendance, score, result or fee tables that reference terms or sessions, use `ON DELETE RESTRICT` or `NO ACTION` for those references. Historical records must prevent calendar deletion rather than disappear through `CASCADE`.

Rows in plain text are enforced by RLS and database guards today (migrations 03–08 and 17–20; tests in `supabase/tests`). Rows in italics are proposals to confirm when those modules get their tables.

**Setup checklist on Home:** owner, admin, principal and VP all get it; bursar sees how far it has got. Step 1 (school details) is the owner's alone.

**To discuss**
- Results: does the VP approve first and then the principal, or the principal only? (The italic row assumes the principal publishes.)
- Finance: should the admin be able to record payments, or only view them?
- Should the owner be able to hand over ownership, or have a second owner?

---

## 9. Integration & Accessibility

| Admin capability | Status |
|------------------|--------|
| **Multi-campus:** campus as a first-class entity; every record scoped to a campus; group-level reports across campuses | New |
| **LMS integration:** sync classes and rosters to an LMS | New |
| **Mobile-friendly admin:** Flutter app on phone and tablet, with a web build for desk work | Partly (Flutter + Realm offline cache) |
| **School settings:** name, logo, address, report card branding, contact details | New |

**To discuss**
- **Multi-campus needs a decision now, not later.** Adding a `campus_id` to every table after data exists is a painful migration. Is it in scope for v1's schema even if the UI comes later?
- Is this one school per deployment, or a multi-tenant SaaS hosting many schools? This is the biggest architectural decision in this document.
- Which LMS, if any: Google Classroom, Moodle, or our own?

---

## Suggested build order

A starting point for discussion. Each phase unlocks the next.

| Phase | Scope | Why this order |
|-------|-------|----------------|
| **0. Decisions** | Tenancy model, multi-campus, roles/permission matrix, sessions & terms | They change the schema of everything after |
| **1. Foundation** | Sign-in, admin profile, school settings, sessions & terms, classes, subjects, staff, students, parents, claim codes | Schema mostly exists; rebuilds the UI removed in `bf07068` |
| **2. Academics** | Timetable, assessment setup, result processing and report cards | The core value schools pay for |
| **3. Finance** | Fee structure, invoices, payments, receipts, debtors | Second core value; needs sessions/terms and students |
| **4. Engagement** | Announcements, events, notifications, attendance oversight | Needs the teacher app and portal to exist |
| **5. Depth** | Payroll, appraisal, analytics dashboard, audit log, LMS, multi-campus UI | Builds on data from earlier phases |

---

## Open questions summary

1. Single school or multi-tenant SaaS?
2. Multi-campus in the v1 schema?
3. Fixed roles or configurable permissions? Do we add a bursar role?
4. Payment gateway choice and merchant model.
5. One grading scale or one per level? Do report cards include behaviour ratings?
6. Generalise `teachers` into `staff`?
7. Should results be withheld while fees are owed?
8. SMS in v1?
9. Can admins read parent–teacher messages?
10. Online admission form in v1?
