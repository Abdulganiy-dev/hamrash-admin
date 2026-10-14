-- Access test for migration 22 (principals and VPs delete subjects; a
-- subject in use stays).
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
  v_bursar_claim    text;
  v_section uuid;
  v_class   uuid;
  v_arm     uuid;
  v_session uuid;
  v_term    uuid;
  v_staff   uuid;
  v_maths   uuid;
  v_french  uuid;
  v_latin   uuid;
  v_n      int;
begin
  execute 'reset role';
  insert into public.platform_admins (clerk_user_id, full_name)
  values ('user_dummy_platform_admin', 'Dummy Platform Admin')
  on conflict (clerk_user_id) do nothing;

  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select c.organization_id, c.owner_claim_code into v_org, v_claim
    from public.create_organization('Test School', 'TST') c;

  -- Owner sets up an arm, a session, a teacher and three subjects
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_claim, 'Olu', 'Owner');
  insert into public.organization_members (organization_id, role) values (v_org, 'principal')
    returning claim_code into v_principal_claim;
  insert into public.organization_members (organization_id, role) values (v_org, 'bursar')
    returning claim_code into v_bursar_claim;
  insert into public.sections (organization_id, name) values (v_org, 'Secondary') returning id into v_section;
  insert into public.classes (organization_id, section_id, name) values (v_org, v_section, 'JSS 1') returning id into v_class;
  insert into public.class_arms (organization_id, class_id, name) values (v_org, v_class, 'A') returning id into v_arm;
  insert into public.academic_sessions (organization_id, name, starts_on, ends_on)
    values (v_org, '2026/2027', '2026-09-01', '2027-07-31') returning id into v_session;
  insert into public.academic_terms (organization_id, session_id, name, sequence, starts_on, ends_on)
    values (v_org, v_session, 'First Term', 1, '2026-09-07', '2026-12-18') returning id into v_term;
  perform public.set_current_term(v_term);
  insert into public.staff (organization_id, first_name, last_name) values (v_org, 'Ada', 'Maths') returning id into v_staff;
  insert into public.subjects (organization_id, name, code) values (v_org, 'Mathematics', 'MTH') returning id into v_maths;
  insert into public.subjects (organization_id, name, code) values (v_org, 'French', 'FRE') returning id into v_french;
  insert into public.subjects (organization_id, name, code) values (v_org, 'Latin', 'LAT') returning id into v_latin;
  insert into public.arm_subjects (organization_id, arm_id, subject_id) values (v_org, v_arm, v_maths);
  insert into public.arm_subjects (organization_id, arm_id, subject_id) values (v_org, v_arm, v_french);
  insert into public.teaching_assignments (organization_id, session_id, arm_id, subject_id, staff_id)
    values (v_org, v_session, v_arm, v_maths, v_staff);

  -- 01 bursar cannot delete a subject
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_bursar","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_bursar_claim);
  delete from public.subjects where id = v_latin;
  get diagnostics v_n = row_count;
  v_log := v_log || E'\n' || case when v_n = 0 then 'PASS' else 'FAIL' end || ' 01 bursar cannot delete a subject [' || v_n || ' rows]';

  -- 02 principal deletes a subject no arm takes
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_principal","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_principal_claim);
  delete from public.subjects where id = v_latin;
  get diagnostics v_n = row_count;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 02 principal deletes an unused subject';

  -- 03 principal deletes a subject an arm takes; its arm link goes with it
  delete from public.subjects where id = v_french;
  get diagnostics v_n = row_count;
  v_log := v_log || E'\n' || case when v_n = 1
      and not exists (select 1 from public.arm_subjects where subject_id = v_french)
    then 'PASS' else 'FAIL' end || ' 03 principal deletes a subject only on the curriculum, its arm link goes too';

  -- 04 a subject with a teacher assigned is kept
  begin
    delete from public.subjects where id = v_maths;
    v_log := v_log || E'\nFAIL 04 deleted a subject that is taught';
  exception when foreign_key_violation then
    v_log := v_log || E'\nPASS 04 a taught subject is kept [' || sqlerrm || ']';
  end;

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
