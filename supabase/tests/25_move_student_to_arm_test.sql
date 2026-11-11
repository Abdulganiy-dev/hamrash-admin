-- Test for migration 38 (move_student_to_arm: move a placement and drop the
-- optional subjects the new arm doesn't offer).
--
-- How to run: paste the whole file into the Supabase SQL editor and run it.
-- It acts as several fake users, checks every rule, then raises an exception on
-- purpose so EVERYTHING is rolled back. The "error" at the end is the report.
--
-- Requires migrations 01–38.
--
-- School "Test School": JSS 1 has arms A, B, C and D (D switched off); JSS 2
-- has arm A. Subjects: Mathematics (compulsory everywhere), French (optional
-- in 1A and 1B), Art (optional in 1A), Music (compulsory in 1C).
-- Chidi is in 1A and chose French and Art.

do $test$
declare
  v_log     text := '';
  v_org     uuid;
  v_org2    uuid;
  v_claim   text;
  v_claim2  text;
  v_bursar_claim text;
  v_section uuid;
  v_jss1    uuid;
  v_jss2    uuid;
  v_1a      uuid;
  v_1b      uuid;
  v_1c      uuid;
  v_1d      uuid;
  v_2a      uuid;
  v_session uuid;
  v_term    uuid;
  v_maths   uuid;
  v_french  uuid;
  v_art     uuid;
  v_music   uuid;
  v_chidi   uuid;
  v_other   uuid;
  v_n       integer;
  v_arm     uuid;
  v_subjects text;
  v_ok      boolean;
begin
  execute 'reset role';
  insert into public.platform_admins (clerk_user_id, full_name)
  values ('user_dummy_platform_admin', 'Dummy Platform Admin')
  on conflict (clerk_user_id) do nothing;

  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select c.organization_id, c.owner_claim_code into v_org,  v_claim  from public.create_organization('Test School', 'TST') c;
  select c.organization_id, c.owner_claim_code into v_org2, v_claim2 from public.create_organization('Other School', 'OTH') c;

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner_b","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_claim2, 'Bee', 'Otherowner');
  insert into public.students (organization_id, first_name, last_name) values (v_org2, 'Bee', 'Student') returning id into v_other;

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_claim, 'Olu', 'Owner');
  insert into public.organization_members (organization_id, role) values (v_org, 'bursar')
    returning claim_code into v_bursar_claim;

  insert into public.sections (organization_id, name) values (v_org, 'Secondary') returning id into v_section;
  insert into public.classes (organization_id, section_id, name, sort_order) values (v_org, v_section, 'JSS 1', 1) returning id into v_jss1;
  insert into public.classes (organization_id, section_id, name, sort_order) values (v_org, v_section, 'JSS 2', 2) returning id into v_jss2;
  insert into public.class_arms (organization_id, class_id, name) values (v_org, v_jss1, 'A') returning id into v_1a;
  insert into public.class_arms (organization_id, class_id, name) values (v_org, v_jss1, 'B') returning id into v_1b;
  insert into public.class_arms (organization_id, class_id, name) values (v_org, v_jss1, 'C') returning id into v_1c;
  insert into public.class_arms (organization_id, class_id, name, is_active) values (v_org, v_jss1, 'D', false) returning id into v_1d;
  insert into public.class_arms (organization_id, class_id, name) values (v_org, v_jss2, 'A') returning id into v_2a;
  insert into public.academic_sessions (organization_id, name, starts_on, ends_on)
    values (v_org, '2026/2027', '2026-09-01', '2027-07-31') returning id into v_session;
  insert into public.academic_terms (organization_id, session_id, name, sequence, starts_on, ends_on)
    values (v_org, v_session, 'First Term', 1, '2026-09-07', '2026-12-18') returning id into v_term;
  perform public.set_current_term(v_term);

  insert into public.subjects (organization_id, name, code) values (v_org, 'Mathematics', 'MTH') returning id into v_maths;
  insert into public.subjects (organization_id, name, code) values (v_org, 'French', 'FRE') returning id into v_french;
  insert into public.subjects (organization_id, name, code) values (v_org, 'Art', 'ART') returning id into v_art;
  insert into public.subjects (organization_id, name, code) values (v_org, 'Music', 'MUS') returning id into v_music;
  insert into public.arm_subjects (organization_id, arm_id, subject_id)
    values (v_org, v_1a, v_maths), (v_org, v_1b, v_maths), (v_org, v_1c, v_maths), (v_org, v_2a, v_maths), (v_org, v_1d, v_maths);
  insert into public.arm_subjects (organization_id, arm_id, subject_id, is_compulsory)
    values (v_org, v_1a, v_french, false), (v_org, v_1b, v_french, false), (v_org, v_1a, v_art, false);
  insert into public.arm_subjects (organization_id, arm_id, subject_id) values (v_org, v_1c, v_music);

  insert into public.students (organization_id, first_name, last_name) values (v_org, 'Chidi', 'Eze') returning id into v_chidi;
  insert into public.student_placements (organization_id, student_id, session_id, arm_id) values (v_org, v_chidi, v_session, v_1a);
  insert into public.student_subjects (organization_id, student_id, session_id, subject_id)
    values (v_org, v_chidi, v_session, v_french), (v_org, v_chidi, v_session, v_art);

  -- 01 into 1B: French is optional there and stays, Art isn't offered and goes
  v_n := public.move_student_to_arm(v_chidi, v_1b);
  select arm_id into v_arm from public.student_placements where student_id = v_chidi and session_id = v_session;
  select string_agg(s.name, ',' order by s.name) into v_subjects
  from public.student_subjects ss join public.subjects s on s.id = ss.subject_id
  where ss.student_id = v_chidi and ss.session_id = v_session;
  v_log := v_log || E'\n' || case when v_n = 1 and v_arm = v_1b and v_subjects = 'French' then 'PASS' else 'FAIL' end
           || ' 01 move to 1B keeps French, drops Art [' || v_n || ', ' || coalesce(v_subjects, '') || ']';

  -- 02 into 1C: French isn't offered there, so it goes too; the move still counts
  v_n := public.move_student_to_arm(v_chidi, v_1c);
  select count(*) into v_n from public.student_subjects where student_id = v_chidi and session_id = v_session;
  select arm_id into v_arm from public.student_placements where student_id = v_chidi and session_id = v_session;
  v_log := v_log || E'\n' || case when v_n = 0 and v_arm = v_1c then 'PASS' else 'FAIL' end || ' 02 move to 1C drops the rest';

  -- 03 a student with no optional choices moves and removes nothing
  v_ok := public.move_student_to_arm(v_chidi, v_2a) = 0;
  select arm_id into v_arm from public.student_placements where student_id = v_chidi and session_id = v_session;
  v_log := v_log || E'\n' || case when v_ok and v_arm = v_2a then 'PASS' else 'FAIL' end || ' 03 plain move, nothing removed';

  -- 04 refusals: same arm, switched-off arm, another school's arm, unknown arm
  v_ok := true;
  begin perform public.move_student_to_arm(v_chidi, v_2a); v_ok := false;
  exception when others then v_ok := v_ok and sqlstate = 'P0001' and sqlerrm like 'They are already%'; end;
  begin perform public.move_student_to_arm(v_chidi, v_1d); v_ok := false;
  exception when others then v_ok := v_ok and sqlstate = 'P0001' and sqlerrm like 'That arm is switched off%'; end;
  begin perform public.move_student_to_arm(v_chidi, gen_random_uuid()); v_ok := false;
  exception when others then v_ok := v_ok and sqlstate = '42501'; end;
  select arm_id into v_arm from public.student_placements where student_id = v_chidi and session_id = v_session;
  v_ok := v_ok and v_arm = v_2a;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 04 refusals leave the placement alone';

  -- 05 a student with no placement this session has nothing to move
  insert into public.students (organization_id, first_name, last_name) values (v_org, 'Gina', 'Zubair') returning id into v_other;
  begin
    perform public.move_student_to_arm(v_other, v_1a);
    v_log := v_log || E'\nFAIL 05 moved a student with no placement';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = 'P0001' then 'PASS' else 'FAIL' end || ' 05 not in a class yet [' || sqlerrm || ']';
  end;

  -- 06 a student of another school is not found
  select id into v_other from public.students where organization_id = v_org2 limit 1;
  begin
    perform public.move_student_to_arm(v_other, v_1a);
    v_log := v_log || E'\nFAIL 06 moved another school''s student';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 06 other school refused';
  end;

  -- 07 a bursar can look but not move
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_bursar","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_bursar_claim);
  begin
    perform public.move_student_to_arm(v_chidi, v_1a);
    v_log := v_log || E'\nFAIL 07 a bursar moved a student';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate in ('42501', 'P0001') then 'PASS' else 'FAIL' end || ' 07 bursar refused [' || sqlerrm || ']';
  end;
  execute 'reset role';
  select arm_id into v_arm from public.student_placements where student_id = v_chidi and session_id = v_session;
  v_log := v_log || E'\n' || case when v_arm = v_2a then 'PASS' else 'FAIL' end || ' 07b the bursar changed nothing';

  -- 08 a stranger and anon
  perform set_config('request.jwt.claims', '{"sub":"test_stranger","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    perform public.move_student_to_arm(v_chidi, v_1a);
    v_log := v_log || E'\nFAIL 08 a stranger moved a student';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 08 stranger refused';
  end;
  execute 'reset role';
  execute 'set local role anon';
  begin
    perform public.move_student_to_arm(v_chidi, v_1a);
    v_log := v_log || E'\nFAIL 09 anon called move_student_to_arm';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 09 anon refused [' || sqlerrm || ']';
  end;

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
