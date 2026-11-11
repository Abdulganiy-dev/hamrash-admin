# Results & Assignments — Design for Discussion

> **Status:** phases 07 and 08 are **applied** (migrations `20261011144800` and `20261011144926`, 2026-10-11). Their access tests pass (last run 2026-10-11). The gradebook, publishing and homework phases are proposals; each gets the next free migration number when it's built.

Open work for results is tracked in [TODO.md](../TODO.md#with-results).

## Decided so far
- Grading setup (score columns and grade boundaries): a **school default**, which **each section** can override.
- "Assignments" means **both**: score components on the report card (CA, assignment, project, exam) **and** a homework module where teachers post work and students submit.
- **Three-step approval:** subject teacher submits → class teacher reviews the arm → principal approves and publishes.
- The report card carries **positions and class stats, remarks, behaviour ratings, and the annual result**.
- Every score records its **session, term, arm, subject and teacher**. Teachers keep seeing the scores they gave, **permanently**. Past students show only name, admission number and photo.

---

## Phases

| # | Migration | What |
|---|---|---|
| 07 | **Student profile split** | `students` keeps the profile (name, admission number, photo, gender, status). `student_private_details` takes date of birth, address, state of origin, LGA, blood group, genotype and medical notes. Adds one-call `create_student` / `update_student`, like staff. Past teachers can then see names next to old scores. Drops columns, so it goes through the SQL editor. |
| 08 | **Grading setup** | Score columns and grade boundaries for the school, with optional per-section overrides. One-tap standard setup. |
| 33 | **Reorder score columns** | `reorder_score_columns`: a set's new column order in one atomic call. |
| 34 | **Grade ranges and per-section grading** | `max_percent`; whole-number ranges covering 0 to 100; rounding before grading; grade rows written only through `set_grade_scale`, `apply_grade_system`, `copy_section_grading`, `remove_section_grade_scale`. In the repo, **not applied**: the app must switch to the RPCs first. |
| — | **Gradebook and workflow** | Scores, result sheets (draft → submitted), arm reviews, remarks, behaviour ratings. Row-level security follows role and workflow state. |
| — | **Publishing and report cards** | On publish, compute and **freeze** totals, grades, positions, class stats and the annual result. Parents and students see published results only. |
| — | **Homework** | Teachers post assignments to an arm and subject. Students submit, teachers mark. Marks can be pulled into a CA component. |

Each phase is usable on its own and gets its own access test. Planned phases (—) take the next free migration number when they're built. Migrations 09 and 10 were index tidy-ups.

---

## 08 · Grading setup

```
score_columns            CA 1 (20) · CA 2 (20) · Exam (60)                each with a max score, in order
grade_boundaries         A1 75–100 "Excellent" · B2 70–74 … F9 0–39        each with a pass/fail flag
```

> Migration 34 (in the repo, **not applied** until the app follows it) changes how grades are stored and written. The points below describe the rules after 34; where 08 differed, it says so.

- **The school's setup and a section's own.** Score columns and grade boundaries with **no section** are the school's. Rows **with a section** are that section's own.
- **Fall-back:** an arm uses its section's score columns **if the section has any**, otherwise the school's. Grade boundaries work the same way, **independently**. So Secondary can keep the school's CA 1 / CA 2 / Exam and only change its grade boundaries to WAEC, with nothing copied.
- **Per-section setup (the redesign, Paper "§ 8b · Grading by section"):** every section is meant to have its own columns and grade scale. The school-level set (no section) stays as the legacy default and the fall-back.
  - `copy_section_grading(school, from, to, columns, grades)` copies columns and/or grades from the school-level set (from = null, "Give Primary its own setup") or another section into a section, **replacing** that section's own rows of each kind, in one transaction. Once the gradebook exists, replacing columns that already have scores is refused by the scores foreign key, and nothing changes.
  - `apply_grade_system(school, section, 'waec' | 'standard')` puts a preset on a section: WAEC A1 75–100, B2 70–74, B3 65–69, C4 60–64, C5 55–59, C6 50–54, D7 45–49, E8 40–44, F9 0–39 (fail); standard A 70–100, B 60–69, C 50–59, D 45–49, E 40–44, F 0–39 (fail).
  - `remove_section_grade_scale(school, section)` deletes a section's own grades, so it uses the school-level scale again.
  - `score_columns_for_arm(arm)` and `grade_boundaries_for_arm(arm)` return what an arm actually uses.
- **Percentages:** a subject's total is the sum of the student's score columns. The grade comes from the **percentage**, total ÷ (sum of max scores) × 100, so the columns don't have to add up to exactly 100.
- **Grades are whole-number ranges (migration 34).** Each grade has a From (`min_percent`) and a To (`max_percent`), both whole numbers, 0 <= From <= To <= 100. In a set the ranges **tile 0 to 100 exactly**: the lowest starts at 0, each starts at the grade below's To + 1, the top ends at 100. No gaps, no overlaps. Decimal starts like 69.5 are no longer allowed.
  - **Rounding first:** `grade_for(arm, percent)` rounds the percentage **half-up to a whole number** (69.5 → 70, 69.4 → 69, 99.5 → 100), then gives the grade whose range holds it. So nothing falls between 69 and 70.
  - Before 34, only the start was stored and a percentage took the highest start it reached. Migration 34 filled in each To as the next grade's start − 1 (100 for the top), per set, and stopped instead if any start was a decimal.
  - **Writes only through RPCs:** clients can't insert, update or delete grade rows. `set_grade_scale(school, section or null, grades)` replaces one whole set with a list of `{grade, min_percent, max_percent, remark, is_pass}`; every grade edit (add, edit, remove, moving a neighbour's start) sends the whole new list. It refuses, with a readable message and no change, a list with a gap, an overlap, a decimal, a duplicate or blank name, or more than 20 grades.
  - A **deferred check** (constraint trigger, at commit) refuses any transaction that leaves a set it touched not covering 0 to 100. An empty set is fine (it means "use the school's"), so deleting a section still cascades. A legacy set nobody touches isn't checked.
  - `grading_problems(school, section)` lists anything missing, taking the fall-back into account: "No score columns yet", "No grade boundary at 0%", and "Grades don't cover 0% to 100% yet" for a legacy set that doesn't tile.
- **Order:** each column has a `sort_order` (report-card order; no unique index). `reorder_score_columns(school, column ids)` takes one set's complete new order (the school's, or one section's) and writes `sort_order` 1..n in one statement, after locking the set. Ids from two sets, a missing or repeated id, or a column left out are refused and nothing changes (migration 33).
- **Changes after scores exist are restricted.** Once scores exist for a score column, its max score can't change and it can't be deleted. This is enforced in the gradebook migration.
- **One-tap standard setup,** `create_standard_grading` (school with no setup; writes `max_percent` from 34):
  - The school's setup: CA 1 (20) + CA 2 (20) + Exam (60), graded A 70–100 … F 0–39. Nursery and Primary use it.
  - Senior Secondary (or a pre-39 "Secondary" section) gets only its own **WAEC grade boundaries** (A1 75–100 … F9 0–39) and keeps the school's columns. Junior Secondary uses the school's A–F.
- **Behaviour traits are a fixed list,** not a table. The app shows them and their group. The gradebook stores each rating with the trait as a Postgres **enum** (`behaviour_trait`), so the database accepts only these. Adding one later is a one-line migration.

  | Affective | Psychomotor |
  |---|---|
  | `punctuality` · `attendance` · `neatness` · `politeness` · `honesty` · `self_control` · `relationship_with_others` · `attentiveness` · `responsibility` | `handwriting` · `verbal_fluency` · `sports_and_games` · `drawing_and_painting` · `musical_skills` · `handling_of_tools` |

  Ratings are **1–5**, and the app shows the labels: 5 Excellent · 4 Very good · 3 Good · 2 Fair · 1 Poor.

## Gradebook and workflow (next)

```
scores                  student × subject × component × term → score       (+ arm, teacher, when)
subject_result_sheets   term × arm × subject → draft | submitted            (one per subject teacher's class)
arm_reviews             term × arm → open | reviewed | published           (the class teacher, then the principal)
subject_remarks         term × subject × student → subject teacher's remark
term_remarks            term × student → class teacher's remark, principal's remark
behaviour_ratings       term × student × trait (fixed list, enum) → 1–5
```

### The three steps

```
Subject teacher                    Class teacher                        Principal / leaders
───────────────                    ─────────────                        ───────────────────
enters scores + remarks            sees every subject for the arm       sees everything
for (arm, subject) while draft     returns a sheet → back to draft      returns a sheet → back to draft
        │                          enters class-teacher remarks
        ▼                          and behaviour ratings
submits the sheet ───────────────► all sheets submitted?
(locked: read-only)                        │
                                           ▼
                                   marks the arm reviewed ──────────────► approves & PUBLISHES the arm
                                                                          (results frozen, parents see them)
                                                                          can unpublish → reviewed
```

- Scores can be edited only while the subject's sheet is **draft** and the arm isn't yet reviewed.
- Publishing freezes the report cards: see *Publishing and report cards* below. To change a published result, a leader unpublishes the arm and the steps repeat.

### Who sees what
| | Scores and remarks | When |
|---|---|---|
| Subject teacher | their **subject + arm + session** | **permanently**, but they can only edit while the sheet is draft |
| Class teacher | **all subjects** of their arm for that session, since they review the whole report card | permanently |
| Leaders | everything in the school | always |
| Parents / students | **their own** child / themselves | **published results only**, never drafts |
| Bursar | none, unless we decide otherwise | — |

## Publishing and report cards

Publishing an arm for a term computes these and stores them as a **snapshot**, so later changes to grade boundaries or score columns never alter a published report card:

- **Per subject:** total, percentage, grade, grade remark, **position in subject**, and the class **average, highest and lowest**.
- **Per student:** grand total, average, **position in class** out of the number of students. Ties share a place, for example 1st, 2nd, 2nd, 4th.
- **Annual result,** when the session's **last term** is published:
  - each subject's average across the terms, plus the annual grade
  - the session average and the annual position
  - averages only count terms the student actually has scores for
- Behaviour ratings and remarks go on the same report card.

## Homework

```
assignments              posted by the subject teacher to an arm + subject: title, instructions, due date,
                         max score, attachments, and optionally the CA component it counts toward
assignment_submissions   one per student: submitted text/attachments, score, feedback, marked by/when
```

- **Who sees an assignment:** students in the arm who take the subject, and their parents.
- **Students without a login** (most young pupils): the teacher records their mark directly, with no online submission.
- **Counting toward CA:** "pull into CA" turns the linked assignments' average percentage into that component's score, for example 85% of a 20-mark CA = 17. The teacher reviews it before submitting the sheet.
- **Teachers see their own assignments permanently,** in line with the rule above.

---

## Decisions (round 2)
1. **Positions:** ranked **within the arm** (JSS 1A against JSS 1A).
2. **Class teachers:** the lead **and** the assistants can enter class-teacher remarks and behaviour ratings. **Only the lead** marks the arm reviewed.
3. **Bursar:** no access to results for now. Revisit with fees, for example withholding report cards when fees are unpaid.
4. **Scores:** decimals allowed, up to 2 places (12.5, 17.25).
5. **Homework attachments:** **images and documents**. Images use Cloudflare Images; PDF and Word files use Supabase Storage with access rules.
6. **Phase order:** start with **07 (student and parent split) + 08 (grading setup)**.

### Implementation notes
- **Grade bands are whole-number ranges** (changed by migration 34; before it they were thresholds only): A1 75–100, B2 70–74 … F9 0–39, covering 0 to 100 with no gaps or overlaps. A percentage is rounded half-up to a whole number first (74.5 → 75), so nothing falls between bands. The ranges shown on report cards ("70–74") are the stored From and To.
- `admission_date` stays on the student profile, because the admission number generator reads it on insert.
