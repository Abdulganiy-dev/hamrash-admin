-- Access test for migration 21 (principals and VPs delete sections, classes
-- and arms; anything still in use stays).
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
  v_arm2    uuid;
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

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_claim, 'Olu', 'Owner');
  insert into public.organization_members (organization_id, role) values (v_org, 'principal')
    returning claim_code into v_principal_claim;
  insert into public.organization_members (organization_id, role) values (v_org, 'bursar')
    returning claim_code into v_bursar_claim;

  -- Principal builds a section, a class and two arms
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_principal","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_principal_claim);
  insert into public.sections (organization_id, name) values (v_org, 'Primary') returning id into v_section;
  insert into public.classes (organization_id, section_id, name) values (v_org, v_section, 'Primary 1') returning id into v_class;
  insert into public.class_arms (organization_id, class_id, name) values (v_org, v_class, 'A') returning id into v_arm;
  insert into public.class_arms (organization_id, class_id, name) values (v_org, v_class, 'B') returning id into v_arm2;

  -- 01 bursar cannot delete an arm
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_bursar","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_bursar_claim);
  delete from public.class_arms where id = v_arm2;
  get diagnostics v_n = row_count;
  v_log := v_log || E'\n' || case when v_n = 0 then 'PASS' else 'FAIL' end || ' 01 bursar cannot delete an arm [' || v_n || ' rows]';

  -- 02 principal deletes an arm
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_principal","role":"authenticated"}', true);
  execute 'set local role authenticated';
  delete from public.class_arms where id = v_arm2;
  get diagnostics v_n = row_count;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 02 principal deletes an arm';

  -- 03 a class that still has an arm is kept
  begin
    delete from public.classes where id = v_class;
    v_log := v_log || E'\nFAIL 03 deleted a class that still has arms';
  exception when foreign_key_violation then
    v_log := v_log || E'\nPASS 03 a class with arms is kept [' || sqlerrm || ']';
  end;

  -- 04 a section that still has a class is kept
  begin
    delete from public.sections where id = v_section;
    v_log := v_log || E'\nFAIL 04 deleted a section that still has classes';
  exception when foreign_key_violation then
    v_log := v_log || E'\nPASS 04 a section with classes is kept [' || sqlerrm || ']';
  end;

  -- 05 principal empties and removes the whole structure
  delete from public.class_arms where id = v_arm;
  delete from public.classes where id = v_class;
  delete from public.sections where id = v_section;
  get diagnostics v_n = row_count;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 05 principal removes an arm, its class and its section';

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
