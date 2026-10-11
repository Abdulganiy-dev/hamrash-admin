-- Access test for migration 06 (subjects, per-arm curriculum, teaching
-- assignments, electives, and teachers' narrowed view).
--
-- How to run: paste the whole file into the Supabase SQL editor and run it.
-- It acts as several fake users, checks every rule, then raises an exception on
-- purpose so EVERYTHING is rolled back. The "error" at the end is the report.
--
-- Requires migrations 01–06 and the dummy platform admin 'user_dummy_platform_admin'.

do $test$
declare
  v_log  text := '';
  v_n    int;
  v_ok   boolean;
  v_org  uuid;  v_claim  text;
  v_org2 uuid;  v_claim2 text;
  -- staff
  v_ada uuid;   v_ada_code  text;   -- Mathematics, JSS 1A
  v_bisi uuid;  v_bisi_code text;   -- French (optional), JSS 1A
  v_chuka uuid; v_chuka_code text;  -- class teacher, JSS 1B
  v_dele uuid;  v_dele_code text;   -- no classes
  v_bayo uuid;  v_bayo_code text;   -- bursar
  -- structure
  v_jss1 uuid;  v_ss1 uuid;
  v_jss1a uuid; v_jss1b uuid; v_ss1a uuid;
  v_jss1c uuid; v_ss1b uuid;  -- created after the standard subjects
  v_sess1 uuid; v_sess2 uuid; v_term1 uuid;
  v_maths uuid; v_french uuid; v_physics uuid; v_dataproc uuid;
  -- students / parents
  v_s1 uuid; v_s2 uuid; v_s3 uuid; v_s4 uuid;
  v_p1 uuid; v_p3 uuid;
  v_p1_code text; v_s1_code text;
  v_r record;
begin
  -- ── setup ──────────────────────────────────────────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select c.organization_id, c.owner_claim_code into v_org,  v_claim  from public.create_organization('School A', 'SCA') c;
  select c.organization_id, c.owner_claim_code into v_org2, v_claim2 from public.create_organization('School B', 'SCB') c;

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner_b","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_claim2);

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_claim);

  -- structure, session, term
  perform public.create_standard_structure(v_org);
  select id into v_jss1 from public.classes where organization_id = v_org and name = 'JSS 1';
  select id into v_ss1  from public.classes where organization_id = v_org and name = 'SS 1';
  insert into public.class_arms (organization_id, class_id, name) values (v_org, v_jss1, 'A') returning id into v_jss1a;
  insert into public.class_arms (organization_id, class_id, name) values (v_org, v_jss1, 'B') returning id into v_jss1b;
  insert into public.class_arms (organization_id, class_id, name) values (v_org, v_ss1,  'A') returning id into v_ss1a;
  insert into public.academic_sessions (organization_id, name, starts_on, ends_on)
    values (v_org, '2026/2027', '2026-09-01', '2027-07-31') returning id into v_sess1;
  insert into public.academic_sessions (organization_id, name, starts_on, ends_on)
    values (v_org, '2027/2028', '2027-09-01', '2028-07-31') returning id into v_sess2;
  insert into public.academic_terms (organization_id, session_id, name, sequence, starts_on, ends_on)
    values (v_org, v_sess1, 'First Term', 1, '2026-09-07', '2026-12-18') returning id into v_term1;
  perform public.set_current_term(v_term1);

  -- 00a standard subjects: 41 subjects, and the standard curriculum on every existing arm
  v_n := public.create_standard_subjects(v_org);
  v_ok := v_n = 41
      and (select count(*) from public.arm_subjects where organization_id = v_org) = 58
      and (select count(*) from public.arm_subjects where arm_id = v_jss1a) = 17
      and (select count(*) from public.arm_subjects where arm_id = v_jss1a and is_compulsory) = 14
      and (select count(*) from public.arm_subjects where arm_id = v_ss1a) = 24
      and (select count(*) from public.arm_subjects where arm_id = v_ss1a and is_compulsory) = 3;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 00a standard subjects + curriculum on existing arms [' || v_n || ' subjects]';

  -- 00b only for a school with no subjects
  begin
    perform public.create_standard_subjects(v_org);
    v_log := v_log || E'\nFAIL 00b standard subjects added twice';
  exception when others then
    v_log := v_log || E'\n' || case when sqlerrm like '%already has subjects%' then 'PASS' else 'FAIL' end || ' 00b standard subjects only for a new school [' || sqlerrm || ']';
  end;

  select id into v_maths    from public.subjects where organization_id = v_org and name = 'Mathematics';
  select id into v_french   from public.subjects where organization_id = v_org and name = 'French';
  select id into v_physics  from public.subjects where organization_id = v_org and name = 'Physics';
  select id into v_dataproc from public.subjects where organization_id = v_org and name = 'Data Processing';

  -- 00c copy_arm_subjects: a new JSS 1C gets JSS 1A's list; copying again adds nothing
  insert into public.class_arms (organization_id, class_id, name) values (v_org, v_jss1, 'C') returning id into v_jss1c;
  v_n := public.copy_arm_subjects(v_jss1a, v_jss1c);
  v_ok := v_n = 17 and public.copy_arm_subjects(v_jss1a, v_jss1c) = 0;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 00c copy_arm_subjects copies once [' || v_n || ' added]';

  -- 00d an Arts arm: standard SS list, then the school tailors it (no sciences)
  insert into public.class_arms (organization_id, class_id, name) values (v_org, v_ss1, 'Arts') returning id into v_ss1b;
  v_n := public.apply_standard_curriculum(v_ss1b);
  delete from public.arm_subjects
    where arm_id = v_ss1b
      and subject_id in (select id from public.subjects where organization_id = v_org and name in ('Physics', 'Chemistry', 'Biology'));
  update public.arm_subjects set is_compulsory = true
    where arm_id = v_ss1b
      and subject_id in (select id from public.subjects where organization_id = v_org and name in ('Literature in English', 'Government'));
  v_ok := v_n = 24
      and (select count(*) from public.arm_subjects where arm_id = v_ss1b) = 21
      and (select count(*) from public.arm_subjects where arm_id = v_ss1b and is_compulsory) = 5
      and (select count(*) from public.arm_subjects where arm_id = v_ss1a) = 24;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 00d arms of one class can have different subjects (SS 1 Arts vs SS 1A)';

  -- 01 subject names and codes are unique per school (case-insensitive)
  begin
    insert into public.subjects (organization_id, name) values (v_org, 'mathematics');
    v_log := v_log || E'\nFAIL 01a duplicate subject name accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23505' then 'PASS' else 'FAIL' end || ' 01a subject name unique per school [' || sqlerrm || ']';
  end;
  begin
    insert into public.subjects (organization_id, name, code) values (v_org, 'Maths Two', 'mth');
    v_log := v_log || E'\nFAIL 01b duplicate subject code accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23505' then 'PASS' else 'FAIL' end || ' 01b subject code unique per school [' || sqlerrm || ']';
  end;

  -- 02 code format
  begin
    insert into public.subjects (organization_id, name, code) values (v_org, 'Odd Code', 'M-1');
    v_log := v_log || E'\nFAIL 02 bad subject code accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23514' then 'PASS' else 'FAIL' end || ' 02 subject code format checked [' || sqlerrm || ']';
  end;

  -- people
  insert into public.staff (organization_id, first_name, last_name) values (v_org, 'Ada',   'Maths')   returning id into v_ada;
  insert into public.staff (organization_id, first_name, last_name) values (v_org, 'Bisi',  'French')  returning id into v_bisi;
  insert into public.staff (organization_id, first_name, last_name) values (v_org, 'Chuka', 'Class')   returning id into v_chuka;
  insert into public.staff (organization_id, first_name, last_name) values (v_org, 'Dele',  'Nothing') returning id into v_dele;
  insert into public.staff (organization_id, first_name, last_name, staff_type) values (v_org, 'Bayo', 'Bursar', 'non_teaching') returning id into v_bayo;
  v_ada_code   := public.invite_staff(v_ada);
  v_bisi_code  := public.invite_staff(v_bisi);
  v_chuka_code := public.invite_staff(v_chuka);
  v_dele_code  := public.invite_staff(v_dele);
  v_bayo_code  := public.invite_staff(v_bayo, 'bursar');

  insert into public.students (organization_id, first_name, last_name) values (v_org, 'S1', 'JSS1A') returning id into v_s1;
  insert into public.students (organization_id, first_name, last_name) values (v_org, 'S2', 'JSS1A') returning id into v_s2;
  insert into public.students (organization_id, first_name, last_name) values (v_org, 'S3', 'JSS1B') returning id into v_s3;
  insert into public.students (organization_id, first_name, last_name) values (v_org, 'S4', 'SS1A')  returning id into v_s4;
  insert into public.student_placements (organization_id, student_id, session_id, arm_id) values
    (v_org, v_s1, v_sess1, v_jss1a), (v_org, v_s2, v_sess1, v_jss1a),
    (v_org, v_s3, v_sess1, v_jss1b), (v_org, v_s4, v_sess1, v_ss1a);
  insert into public.parents (organization_id, first_name, last_name, phone) values (v_org, 'P1', 'OfS1', '0801000001') returning id into v_p1;
  insert into public.parents (organization_id, first_name, last_name, phone) values (v_org, 'P3', 'OfS3', '0801000003') returning id into v_p3;
  insert into public.student_parents (organization_id, student_id, parent_id, relationship, is_primary_contact) values
    (v_org, v_s1, v_p1, 'mother', true), (v_org, v_s3, v_p3, 'father', true);
  v_p1_code := public.invite_parent(v_p1);
  v_s1_code := public.invite_student(v_s1);

  -- 03 assignments: Ada → Maths JSS 1A, Bisi → French JSS 1A, Chuka → class teacher JSS 1B
  insert into public.teaching_assignments (organization_id, session_id, arm_id, subject_id, staff_id) values
    (v_org, v_sess1, v_jss1a, v_maths,  v_ada),
    (v_org, v_sess1, v_jss1a, v_french, v_bisi);
  insert into public.class_teachers (organization_id, session_id, arm_id, staff_id, is_lead) values (v_org, v_sess1, v_jss1b, v_chuka, true);
  v_log := v_log || E'\nPASS 03 teaching assignments created';

  -- 04 one teacher per subject per arm per session
  begin
    insert into public.teaching_assignments (organization_id, session_id, arm_id, subject_id, staff_id) values (v_org, v_sess1, v_jss1a, v_maths, v_dele);
    v_log := v_log || E'\nFAIL 04 second Maths teacher for JSS 1A accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23505' then 'PASS' else 'FAIL' end || ' 04 one teacher per subject per arm per session [' || sqlerrm || ']';
  end;

  -- 05 can't assign a subject the class doesn't offer
  begin
    insert into public.teaching_assignments (organization_id, session_id, arm_id, subject_id, staff_id) values (v_org, v_sess1, v_jss1a, v_physics, v_dele);
    v_log := v_log || E'\nFAIL 05 Physics assigned to JSS 1A';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23514' then 'PASS' else 'FAIL' end || ' 05 subject must be on the arm''s curriculum [' || sqlerrm || ']';
  end;
  begin
    insert into public.teaching_assignments (organization_id, session_id, arm_id, subject_id, staff_id) values (v_org, v_sess1, v_ss1b, v_physics, v_dele);
    v_log := v_log || E'\nFAIL 05b Physics assigned to the Arts arm';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23514' then 'PASS' else 'FAIL' end || ' 05b Arts arm doesn''t take Physics even though SS 1A does [' || sqlerrm || ']';
  end;
  insert into public.teaching_assignments (organization_id, session_id, arm_id, subject_id, staff_id) values (v_org, v_sess1, v_ss1a, v_physics, v_dele);
  delete from public.teaching_assignments where session_id = v_sess1 and arm_id = v_ss1a and subject_id = v_physics;
  v_log := v_log || E'\nPASS 05c Physics can be assigned to the science arm';

  -- 06 changing the teacher updates the row
  update public.teaching_assignments set staff_id = v_dele where session_id = v_sess1 and arm_id = v_jss1a and subject_id = v_maths;
  update public.teaching_assignments set staff_id = v_ada  where session_id = v_sess1 and arm_id = v_jss1a and subject_id = v_maths;
  select count(*) into v_n from public.teaching_assignments where session_id = v_sess1 and arm_id = v_jss1a and subject_id = v_maths and staff_id = v_ada;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 06 teacher can be changed';

  -- 07 electives
  insert into public.student_subjects (organization_id, student_id, session_id, subject_id) values (v_org, v_s1, v_sess1, v_french);
  insert into public.student_subjects (organization_id, student_id, session_id, subject_id) values (v_org, v_s4, v_sess1, v_physics);
  v_log := v_log || E'\nPASS 07a optional subjects enrolled (S1 French, S4 Physics)';
  begin
    insert into public.student_subjects (organization_id, student_id, session_id, subject_id) values (v_org, v_s2, v_sess1, v_maths);
    v_log := v_log || E'\nFAIL 07b compulsory subject enrolled';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23514' then 'PASS' else 'FAIL' end || ' 07b compulsory subjects aren''t enrolled [' || sqlerrm || ']';
  end;
  begin
    insert into public.student_subjects (organization_id, student_id, session_id, subject_id) values (v_org, v_s3, v_sess1, v_physics);
    v_log := v_log || E'\nFAIL 07c subject not offered by class enrolled';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23514' then 'PASS' else 'FAIL' end || ' 07c only subjects the arm offers [' || sqlerrm || ']';
  end;
  begin
    insert into public.student_subjects (organization_id, student_id, session_id, subject_id) values (v_org, v_s1, v_sess2, v_french);
    v_log := v_log || E'\nFAIL 07d enrolled in a session without a placement';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23514' then 'PASS' else 'FAIL' end || ' 07d student must be placed that session [' || sqlerrm || ']';
  end;

  -- 07e session_readiness for 2026/2027: 1 term, 4 placed, 3 arms with students,
  --     2 without a lead class teacher (JSS 1A, SS 1A), 56 arm subjects without a teacher
  --     (JSS 1A 17-2, JSS 1B 17, SS 1A 24)
  select * into v_r from public.session_readiness(v_sess1);
  v_log := v_log || E'\n' || case when v_r.terms = 1 and v_r.students_placed = 4 and v_r.active_students_not_placed = 0
        and v_r.arms_with_students = 3 and v_r.arms_without_lead_teacher = 2 and v_r.subjects_without_teacher = 56
        then 'PASS' else 'FAIL' end || ' 07e session_readiness reports what''s missing ['
        || v_r.terms || '/' || v_r.students_placed || '/' || v_r.active_students_not_placed || '/'
        || v_r.arms_with_students || '/' || v_r.arms_without_lead_teacher || '/' || v_r.subjects_without_teacher || ']';

  -- ── Ada: compulsory Maths in JSS 1A → S1, S2 ───────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_ada","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_ada_code);
  select count(*) into v_n from public.students;
  v_log := v_log || E'\n' || case when v_n = 2 then 'PASS' else 'FAIL' end || ' 08a compulsory-subject teacher sees the whole arm [' || v_n || ']';
  select count(*) into v_n from public.parents;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 08b and only those students'' parents [' || v_n || ']';
  select count(*) into v_n from public.student_placements;
  v_log := v_log || E'\n' || case when v_n = 2 then 'PASS' else 'FAIL' end || ' 08c and only their placements [' || v_n || ']';
  begin
    insert into public.teaching_assignments (organization_id, session_id, arm_id, subject_id, staff_id) values (v_org, v_sess1, v_jss1b, v_maths, v_ada);
    v_log := v_log || E'\nFAIL 08d teacher assigned themselves';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 08d teachers can''t make assignments [' || sqlerrm || ']';
  end;
  begin
    perform public.create_standard_subjects(v_org2);
    v_log := v_log || E'\nFAIL 08e teacher ran standard subjects elsewhere';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 08e teachers can''t set up subjects [' || sqlerrm || ']';
  end;
  begin
    perform public.copy_arm_subjects(v_jss1a, v_jss1b);
    v_log := v_log || E'\nFAIL 08f teacher copied arm subjects';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 08f teachers can''t copy or apply curricula [' || sqlerrm || ']';
  end;
  begin
    perform public.copy_assignments_forward(v_sess1, v_sess2);
    v_log := v_log || E'\nFAIL 08g teacher copied assignments forward';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 08g teachers can''t copy assignments or check readiness [' || sqlerrm || ']';
  end;

  -- ── Bisi: optional French in JSS 1A → only S1 ──────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_bisi","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_bisi_code);
  select count(*) into v_n from public.students;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 09a optional-subject teacher sees only students taking it [' || v_n || ']';
  select count(*) into v_n from public.student_subjects;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 09b and their electives [' || v_n || ']';

  -- ── Chuka: class teacher of JSS 1B → S3 ────────────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_chuka","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_chuka_code);
  select count(*) into v_n from public.students;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 10a class teacher sees their arm [' || v_n || ']';
  select count(*) into v_n from public.parents;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 10b class teacher sees their pupils'' parents [' || v_n || ']';

  -- ── Dele: no classes → nobody ──────────────────────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_dele","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_dele_code);
  select (select count(*) from public.students) + (select count(*) from public.parents) into v_n;
  v_log := v_log || E'\n' || case when v_n = 0 then 'PASS' else 'FAIL' end || ' 11 teacher with no classes sees no students or parents [' || v_n || ']';
  select count(*) into v_n from public.subjects;
  v_log := v_log || E'\n' || case when v_n = 41 then 'PASS' else 'FAIL' end || ' 11b but still reads the subject list [' || v_n || ']';

  -- ── Bayo: bursar → whole school ────────────────────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_bayo","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_bayo_code);
  select count(*) into v_n from public.students;
  v_log := v_log || E'\n' || case when v_n = 4 then 'PASS' else 'FAIL' end || ' 12 bursar still sees every student [' || v_n || ']';

  -- ── parent P1 and student S1 ───────────────────────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_parent","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_p1_code);
  select count(*) into v_n from public.teaching_assignments;
  v_log := v_log || E'\n' || case when v_n = 2 then 'PASS' else 'FAIL' end || ' 13a parent sees who teaches what [' || v_n || ']';
  select count(*) into v_n from public.student_subjects;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 13b parent sees only own child''s electives [' || v_n || ']';
  begin
    insert into public.student_subjects (organization_id, student_id, session_id, subject_id)
      values (v_org, v_s1, v_sess1, (select id from public.subjects where organization_id = v_org and name = 'Christian Religious Studies'));
    v_log := v_log || E'\nFAIL 13c parent enrolled their child';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 13c parents can''t enrol subjects [' || sqlerrm || ']';
  end;

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_student","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_s1_code);
  select count(*) into v_n from public.student_subjects;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 14 student sees own electives [' || v_n || ']';

  -- ── other school ───────────────────────────────────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner_b","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select (select count(*) from public.subjects) + (select count(*) from public.teaching_assignments) into v_n;
  v_log := v_log || E'\n' || case when v_n = 0 then 'PASS' else 'FAIL' end || ' 15 other school sees none of School A''s subjects [' || v_n || ']';

  -- ── owner: deletes, then a new session ─────────────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    delete from public.subjects where id = v_maths;
    v_log := v_log || E'\nFAIL 16a taught subject deleted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23503' then 'PASS' else 'FAIL' end || ' 16a a subject with assignments can''t be deleted [' || sqlerrm || ']';
  end;
  -- Data Processing is on SS 1A and SS 1 Arts but taught by nobody: 96 links → 94
  delete from public.subjects where id = v_dataproc;
  select count(*) into v_n from public.arm_subjects where organization_id = v_org;
  v_log := v_log || E'\n' || case when v_n = 94 then 'PASS' else 'FAIL' end || ' 16b untaught subject deleted with its curriculum links [' || v_n || ' left]';

  -- 16c copy assignments into 2027/2028: Bisi has exited, so only Ada's Maths + Chuka's class
  --     copy across; a second run copies nothing; readiness for 2027/2028 reflects it
  update public.staff set status = 'exited' where id = v_bisi;
  select * into v_r from public.copy_assignments_forward(v_sess1, v_sess2);
  v_ok := v_r.class_teachers_copied = 1 and v_r.subject_teachers_copied = 1;
  select * into v_r from public.copy_assignments_forward(v_sess1, v_sess2);
  v_ok := v_ok and v_r.class_teachers_copied = 0 and v_r.subject_teachers_copied = 0
      and exists (select 1 from public.teaching_assignments where session_id = v_sess2 and arm_id = v_jss1a and subject_id = v_maths and staff_id = v_ada)
      and exists (select 1 from public.class_teachers where session_id = v_sess2 and arm_id = v_jss1b and staff_id = v_chuka and is_lead)
      and not exists (select 1 from public.teaching_assignments where session_id = v_sess2 and staff_id = v_bisi);
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 16c copy_assignments_forward copies once, skips exited staff';
  select * into v_r from public.session_readiness(v_sess2);
  v_log := v_log || E'\n' || case when v_r.terms = 0 and v_r.students_placed = 0 and v_r.active_students_not_placed = 4
        then 'PASS' else 'FAIL' end || ' 16d readiness flags an unprepared session [' || v_r.terms || ' terms, ' || v_r.active_students_not_placed || ' not placed]';

  -- 17 after the school moves to 2027/2028, teachers no longer see last session's students'
  --    full records (past results/assignments will stay reachable through the results tables)
  perform public.set_current_session(v_sess2);
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_ada","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select count(*) into v_n from public.students;
  v_log := v_log || E'\n' || case when v_n = 0 then 'PASS' else 'FAIL' end || ' 17 full student records follow the current session [' || v_n || ']';

  -- 18 platform admin reads every school's subjects
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select count(*) into v_n from public.subjects;
  v_log := v_log || E'\n' || case when v_n = 40 then 'PASS' else 'FAIL' end || ' 18 platform admin reads subjects in every school [' || v_n || ']';

  -- 19 anon has no access
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  execute 'set local role anon';
  begin
    perform count(*) from public.subjects;
    v_log := v_log || E'\nFAIL 19 anon read subjects';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 19 anon cannot read subjects [' || sqlerrm || ']';
  end;

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
