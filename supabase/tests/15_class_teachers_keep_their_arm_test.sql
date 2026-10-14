-- Access test for migration 23 (an arm with a class teacher can't be
-- deleted; once unassigned, it can).
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
  v_arm     uuid;
  v_session uuid;
  v_term    uuid;
  v_staff   uuid;
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

  -- Owner sets up an arm with a class teacher
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_claim, 'Olu', 'Owner');
  insert into public.organization_members (organization_id, role) values (v_org, 'principal')
    returning claim_code into v_principal_claim;
  insert into public.sections (organization_id, name) values (v_org, 'Primary') returning id into v_section;
  insert into public.classes (organization_id, section_id, name) values (v_org, v_section, 'Primary 1') returning id into v_class;
  insert into public.class_arms (organization_id, class_id, name) values (v_org, v_class, 'A') returning id into v_arm;
  insert into public.academic_sessions (organization_id, name, starts_on, ends_on)
    values (v_org, '2026/2027', '2026-09-01', '2027-07-31') returning id into v_session;
  insert into public.academic_terms (organization_id, session_id, name, sequence, starts_on, ends_on)
    values (v_org, v_session, 'First Term', 1, '2026-09-07', '2026-12-18') returning id into v_term;
  perform public.set_current_term(v_term);
  insert into public.staff (organization_id, first_name, last_name) values (v_org, 'Ada', 'Class') returning id into v_staff;
  insert into public.class_teachers (organization_id, session_id, arm_id, staff_id) values (v_org, v_session, v_arm, v_staff);

  -- 01 the arm stays while it has a class teacher
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_principal","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_principal_claim);
  begin
    delete from public.class_arms where id = v_arm;
    v_log := v_log || E'\nFAIL 01 deleted an arm that has a class teacher';
  exception when foreign_key_violation then
    v_log := v_log || E'\nPASS 01 an arm with a class teacher is kept [' || sqlerrm || ']';
  end;
  select count(*) into v_n from public.class_teachers where arm_id = v_arm;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 02 its class teacher is still assigned';

  -- 03 once unassigned, the arm can go
  delete from public.class_teachers where arm_id = v_arm;
  delete from public.class_arms where id = v_arm;
  get diagnostics v_n = row_count;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 03 after unassigning, the principal deletes the arm';

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
