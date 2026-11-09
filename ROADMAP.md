# Hamrash Roadmap

What is left to build across the three apps that serve a school. Product scope is in the platform [`FEATURES.md`](../FEATURES.md), the admin slice is in [`ADMIN_FEATURES.md`](ADMIN_FEATURES.md), and the detailed admin to-do list is in [`TODO.md`](TODO.md). The Hamrash team's own app (`hamrash-platform-admin`) has its own `TODO.md` and is not covered here.

Status as of 2026-11-09. Every app is mobile only (iOS and Android).

---

## Suggested order

1. **Finish the student side of admin:** students list and detail, parent screens, then promotion.
2. **Grading setup UI and the gradebook.** This unlocks the teacher app's main job and results for parents.
3. **Attendance.** Shared by admin, teacher and parent.
4. **Fees.**
5. **Teacher app**, then **Parent & Student app**.

Several items need a new table or RPC. Per the working rules in `CLAUDE.md`, ask which agent should write a big migration before starting it.

---

## 1. Admin app (`hamrash-admin`)

**Already built:** sign-in and join, school pick, confirm and paused screens, academic calendar (sessions and terms), classes, sections and arms, subjects and class subjects, team (staff list, add, detail, teaching setup), add-student flow.

### Student management
- [ ] Students list, student detail and edit screens (only "add student" exists today)
- [ ] Parent screens: view, edit, link and unlink, set primary contact
- [ ] Admissions pipeline: record, review, accept or reject, convert to an enrolled student
- [ ] Lifecycle: promote, repeat, transfer, graduate, deactivate
  - [ ] Unique class order within a section
  - [ ] Placement checks (active students and arms only)
  - [ ] Stop overlapping sessions in the same school
- [ ] Attendance oversight: view and correct, attendance policy, chronic-absence flags
- [ ] Bulk import of students and parents from CSV or Excel
- [ ] Medical notes, documents and class history on the student record

### Academic management
- [ ] Grading setup UI (score columns, grade boundaries). The tables exist, no screen yet
- [ ] Gradebook and result workflow: scores, result sheets (draft → submitted), arm reviews, remarks, behaviour ratings. Design: [`docs/results-design.md`](docs/results-design.md)
- [ ] Publishing, report-card PDFs, result locks, withholding results
- [ ] Timetable builder with clash detection
- [ ] Exam scheduling
- [ ] Syllabus / scheme of work: approve and publish
- [ ] Homework (admin visibility, if any)

### Finance and fees (nothing exists yet)
- [ ] Fee structure per class and term, discounts and waivers
- [ ] Invoicing, in bulk or one at a time
- [ ] Offline payments and part-payment
- [ ] Online payments: gateway setup and webhook reconciliation
- [ ] Receipts (PDF), debtors and parent reminders
- [ ] Financial reports
- [ ] Bursar access to results (withholding report cards over unpaid fees)

### Staff management
- [ ] Non-teaching staff
- [ ] Staff attendance and leave
- [ ] Payroll: salary structure, runs, payslips
- [ ] Workload (needs the timetable)
- [ ] Performance appraisals

### Communication and administration
- [ ] Announcements and notice board
- [ ] Internal messaging and parent–teacher oversight
- [ ] Events and school calendar
- [ ] Push, SMS and email notifications

### Reporting and analytics
- [ ] Home dashboard (today it shows setup cards only)
- [ ] Academic, financial and staff reports
- [ ] PDF and Excel export for every report

### Security and access
- [ ] Permission-matrix enforcement for results, finance and payroll
- [ ] Audit log
- [ ] Data export and backup
- [ ] MFA and session timeout for admins
- [ ] Self-editing of a safe set of fields by people on their own record
- [ ] Auto-suspend logins when staff or student status changes
- [ ] Claim codes: expiry, re-issue, rate limiting
- [ ] Extra roles for one staff member
- [ ] Campuses (multi-campus)

---

## 2. Staff / Teacher app (not started)

- [ ] Onboarding with `Hamrash-TCH-…` claim codes
- [ ] My classes and subjects, with a student list for classes I teach and history of past classes
- [ ] Daily attendance marking
- [ ] Gradebook: score entry, remarks, behaviour ratings. A lead class teacher also reviews the arm
- [ ] Scheme of work authoring, submitted for admin approval
- [ ] Homework: post, collect submissions, mark, feed marks into CA
- [ ] Timetable view
- [ ] Messaging: admin chat and parent–teacher threads
- [ ] Announcements: receive, and post to own classes (TBD)
- [ ] Events calendar and notifications
- [ ] Own profile and payslips; clock in/out and self-appraisal (both TBD)
- [ ] Class-level reports

---

## 3. Parent & Student app (not started)

- [ ] Onboarding with `Hamrash-PAR-…` and `Hamrash-STD-…` claim codes, and a switcher for parents with several children
- [ ] Student profile, and self-editing of safe fields (for example a parent's phone number)
- [ ] Timetable and syllabus view
- [ ] Attendance view
- [ ] Published results and report cards
- [ ] Homework and submissions (student)
- [ ] Fees: invoices, online payment, receipts, balance
- [ ] Parent–teacher messaging
- [ ] Announcements, events and push notifications
- [ ] Online admission application (TBD)

---

## Open decisions that block work

- Payment gateway (Paystack, Flutterwave, Remita) and whether each school brings its own merchant account
- Whether results are withheld while fees are owed
- Grading scale: one per school, or per level
- Result approval: principal only, or vice principal then principal
- Staff attendance: admin-marked or self clock-in
- SMS in v1, and who pays for it
- Whether admin can read parent–teacher messages, or only receive escalations
- Which three or four numbers the home dashboard shows first
