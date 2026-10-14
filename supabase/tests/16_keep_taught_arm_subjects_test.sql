-- Access test for migration 24 (a subject stays on an arm while it's taught
-- or chosen there; deleting the arm itself still works).
--
-- How to run: paste the whole file into the Supabase SQL editor and run it.
-- It acts as several fake users (via request.jwt.claims + set role), checks every
-- rule, then raises an exception on purpose so EVERYTHING is rolled back.
-- The "error" you see at the end is the report: each line is PASS or FAIL.

do $test$
declare
  v_log    text := '';
  v_org    uuid;
  v_claim  text;
  v_principal_claim text;
  v_section uuid;
  v_class   uuid;
  v_arm_a   uuid;
  v_arm_b   uuid;
  v_session uuid;
  v_term    uuid;
  v_staff   uuid;
  v_student uuid;
  v_maths   uuid;
  v_french  uuid;
  v_art     uuid;
  v_n       int;
  v_teacher text;
  v_choices int;
begin
  execute 'reset role';
  insert into public.platform_admins (clerk_user_id, full_name)
  values ('user_dummy_platform_admin', 'Dummy Platform Admin')
  on conflict (clerk_user_id) do nothing;

  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select c.organization_id, c.owner_claim_code into v_org, v_claim
    from public.create_organization('Test School', 'TST') c;

  -- Owner sets up JSS 1A (taught Maths, a student who chose French, Art
  -- unused) and JSS 1B (taught Maths, no students)
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_claim, 'Olu', 'Owner');
  insert into public.organization_members (organization_id, role) values (v_org, 'principal')
    returning claim_code into v_principal_claim;
  insert into public.sections (organization_id, name) values (v_org, 'Secondary') returning id into v_section;
  insert into public.classes (organization_id, section_id, name) values (v_org, v_section, 'JSS 1') returning id into v_class;
  insert into public.class_arms (organization_id, class_id, name) values (v_org, v_class, 'A') returning id into v_arm_a;
  insert into public.class_arms (organization_id, class_id, name) values (v_org, v_class, 'B') returning id into v_arm_b;
  insert into public.academic_sessions (organization_id, name, starts_on, ends_on)
    values (v_org, '2026/2027', '2026-09-01', '2027-07-31') returning id into v_session;
  insert into public.academic_terms (organization_id, session_id, name, sequence, starts_on, ends_on)
    values (v_org, v_session, 'First Term', 1, '2026-09-07', '2026-12-18') returning id into v_term;
  perform public.set_current_term(v_term);
  insert into public.staff (organization_id, first_name, last_name) values (v_org, 'Ada', 'Bello') returning id into v_staff;
  insert into public.subjects (organization_id, name, code) values (v_org, 'Mathematics', 'MTH') returning id into v_maths;
  insert into public.subjects (organization_id, name, code) values (v_org, 'French', 'FRE') returning id into v_french;
  insert into public.subjects (organization_id, name, code) values (v_org, 'Art', 'ART') returning id into v_art;
  insert into public.arm_subjects (organization_id, arm_id, subject_id) values (v_org, v_arm_a, v_maths);
  insert into public.arm_subjects (organization_id, arm_id, subject_id, is_compulsory) values (v_org, v_arm_a, v_french, false);
  insert into public.arm_subjects (organization_id, arm_id, subject_id) values (v_org, v_arm_a, v_art);
  insert into public.arm_subjects (organization_id, arm_id, subject_id) values (v_org, v_arm_b, v_maths);
  insert into public.teaching_assignments (organization_id, session_id, arm_id, subject_id, staff_id)
    values (v_org, v_session, v_arm_a, v_maths, v_staff);
  insert into public.teaching_assignments (organization_id, session_id, arm_id, subject_id, staff_id)
    values (v_org, v_session, v_arm_b, v_maths, v_staff);
  insert into public.students (organization_id, first_name, last_name) values (v_org, 'Chidi', 'Eze') returning id into v_student;
  insert into public.student_placements (organization_id, student_id, session_id, arm_id) values (v_org, v_student, v_session, v_arm_a);
  insert into public.student_subjects (organization_id, student_id, session_id, subject_id) values (v_org, v_student, v_session, v_french);

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_principal","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_principal_claim);

  -- 01 a subject with a teacher stays on the arm, with the teacher named
  begin
    delete from public.arm_subjects where arm_id = v_arm_a and subject_id = v_maths;
    v_log := v_log || E'\nFAIL 01 removed a subject a teacher is assigned to';
  exception when raise_exception then
    v_log := v_log || E'\n' || case when sqlerrm like 'Ada Bello teaches Mathematics in JSS 1A%' then 'PASS' else 'FAIL' end
      || ' 01 a taught subject stays [' || sqlerrm || ']';
  end;

  -- 02 an optional subject students chose stays on the arm
  begin
    delete from public.arm_subjects where arm_id = v_arm_a and subject_id = v_french;
    v_log := v_log || E'\nFAIL 02 removed a subject students chose';
  exception when raise_exception then
    v_log := v_log || E'\n' || case when sqlerrm like '1 student in JSS 1A chose French%' then 'PASS' else 'FAIL' end
      || ' 02 a chosen subject stays [' || sqlerrm || ']';
  end;

  -- 03 an unused subject comes off the arm
  delete from public.arm_subjects where arm_id = v_arm_a and subject_id = v_art;
  get diagnostics v_n = row_count;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 03 an unused subject comes off the arm';

  -- 04 the app can see which links are in use
  select u.teacher_name, u.choices into v_teacher, v_choices
    from public.arm_subject_usage(v_org) u where u.arm_id = v_arm_a and u.subject_id = v_french;
  v_log := v_log || E'\n' || case when v_teacher is null and v_choices = 1 then 'PASS' else 'FAIL' end
    || ' 04 usage shows the choice on French';
  select u.teacher_name into v_teacher
    from public.arm_subject_usage(v_org) u where u.arm_id = v_arm_a and u.subject_id = v_maths;
  v_log := v_log || E'\n' || case when v_teacher = 'Ada Bello' then 'PASS' else 'FAIL' end
    || ' 05 usage names the Maths teacher';

  -- 06 deleting a whole arm still takes its subjects and teaching with it
  delete from public.class_arms where id = v_arm_b;
  get diagnostics v_n = row_count;
  v_log := v_log || E'\n' || case when v_n = 1
      and not exists (select 1 from public.arm_subjects where arm_id = v_arm_b)
    then 'PASS' else 'FAIL' end || ' 06 deleting an arm still removes its subjects';

  -- 07 another school can't read this school's usage
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_stranger","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    perform public.arm_subject_usage(v_org);
    v_log := v_log || E'\nFAIL 07 a stranger read the usage';
  exception when insufficient_privilege then
    v_log := v_log || E'\nPASS 07 a stranger cannot read the usage';
  end;

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
