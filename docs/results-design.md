# Results & Assignments — Design for Discussion

> **Status:** phases 07 and 08 are **applied** (migrations `20261011144800` and `20261011144926`, 2026-10-11). Their access tests pass (last run 2026-10-11). Phases 09 to 11 are proposals.

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
| 09 | **Gradebook and workflow** | Scores, result sheets (draft → submitted), arm reviews, remarks, behaviour ratings. Row-level security follows role and workflow state. |
| 10 | **Publishing and report cards** | On publish, compute and **freeze** totals, grades, positions, class stats and the annual result. Parents and students see published results only. |
| 11 | **Homework** | Teachers post assignments to an arm and subject. Students submit, teachers mark. Marks can be pulled into a CA component. |

Each phase is usable on its own and gets its own access test.

---

## 08 · Grading setup

```
score_columns            CA 1 (20) · CA 2 (20) · Exam (60)                each with a max score, in order
grade_boundaries         A1 from 75% "Excellent" · B2 from 70% … F9 0%     each with a pass/fail flag
```

- **The school's setup and a section's own.** Score columns and grade boundaries with **no section** are the school's. Rows **with a section** are that section's own.
- **Fall-back:** an arm uses its section's score columns **if the section has any**, otherwise the school's. Grade boundaries work the same way, **independently**. So Secondary can keep the school's CA 1 / CA 2 / Exam and only change its grade boundaries to WAEC, with nothing copied.
  - `score_columns_for_arm(arm)` and `grade_boundaries_for_arm(arm)` return what an arm actually uses.
- **Percentages:** a subject's total is the sum of the student's score columns. The grade comes from the **percentage**, total ÷ (sum of max scores) × 100, so the columns don't have to add up to exactly 100.
- **Grade boundaries say where each grade starts.** A percentage gets the highest grade it reaches: `grade_for(arm, percent)`. Decimals like 74.5 can never fall into a gap.
  - `grading_problems(school, section)` lists anything missing, such as "No score columns yet" or "No grade boundary at 0%", taking the fall-back into account.
- **Changes after scores exist are restricted.** Once scores exist for a score column, its max score can't change and it can't be deleted. This is enforced in phase 09.
- **One-tap standard setup,** `create_standard_grading`:
  - The school's setup: CA 1 (20) + CA 2 (20) + Exam (60), graded A–F. Nursery and Primary use it.
  - Secondary gets only its own **WAEC grade boundaries** (A1–F9) and keeps the school's columns.
- **Behaviour traits are a fixed list,** not a table. The app shows them and their group. Phase 09 stores each rating with the trait as a Postgres **enum** (`behaviour_trait`), so the database accepts only these. Adding one later is a one-line migration.

  | Affective | Psychomotor |
  |---|---|
  | `punctuality` · `attendance` · `neatness` · `politeness` · `honesty` · `self_control` · `relationship_with_others` · `attentiveness` · `responsibility` | `handwriting` · `verbal_fluency` · `sports_and_games` · `drawing_and_painting` · `musical_skills` · `handling_of_tools` |

  Ratings are **1–5**, and the app shows the labels: 5 Excellent · 4 Very good · 3 Good · 2 Fair · 1 Poor.

## 09 · Gradebook and workflow

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
- Publishing freezes the report cards: see phase 10. To change a published result, a leader unpublishes the arm and the steps repeat.

### Who sees what
| | Scores and remarks | When |
|---|---|---|
| Subject teacher | their **subject + arm + session** | **permanently**, but they can only edit while the sheet is draft |
| Class teacher | **all subjects** of their arm for that session, since they review the whole report card | permanently |
| Leaders | everything in the school | always |
| Parents / students | **their own** child / themselves | **published results only**, never drafts |
| Bursar | none, unless we decide otherwise | — |

## 10 · Publishing and report cards

Publishing an arm for a term computes these and stores them as a **snapshot**, so later changes to grade boundaries or score columns never alter a published report card:

- **Per subject:** total, percentage, grade, grade remark, **position in subject**, and the class **average, highest and lowest**.
- **Per student:** grand total, average, **position in class** out of the number of students. Ties share a place, for example 1st, 2nd, 2nd, 4th.
- **Annual result,** when the session's **last term** is published:
  - each subject's average across the terms, plus the annual grade
  - the session average and the annual position
  - averages only count terms the student actually has scores for
- Behaviour ratings and remarks go on the same report card.

## 11 · Homework

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
- **Grade bands are thresholds,** not ranges: A1 from 75, B2 from 70 … F9 from 0. A score takes the highest band whose threshold it reaches, so decimals like 74.5 can never fall into a gap. The ranges shown on report cards ("70–74") are worked out from the thresholds. A policy is complete only when it has a band starting at 0.
- `admission_date` stays on the student profile, because the admission number generator reads it on insert.
