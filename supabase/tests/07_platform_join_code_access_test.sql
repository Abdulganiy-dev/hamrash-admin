-- Access test for migration 26 (the shared Hamrash team join code).
--
-- How to run: paste the whole file into the Supabase SQL editor and run it.
-- It acts as several fake users, checks every rule, then raises an exception on
-- purpose so EVERYTHING is rolled back. The "error" at the end is the report.
--
-- Requires migrations 01–26.

do $test$
declare
  v_log    text := '';
  v_n      int;
  v_code   text;
  v_code2  text;
  v_hint   text;
  v_admin  public.platform_admins;
  v_s      record;
begin
  -- The test platform admin exists only inside this test; it's rolled back
  -- with everything else, so the live database needs no fake admin.
  execute 'reset role';
  insert into public.platform_admins (clerk_user_id, full_name)
  values ('user_dummy_platform_admin', 'Dummy Platform Admin')
  on conflict (clerk_user_id) do nothing;

  -- any real team code is set aside inside this test, so the checks start clean
  delete from private.platform_join_code;

  -- 01 with no code yet, status says so and a join returns null
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select * into v_s from public.platform_join_code_status();
  v_log := v_log || E'\n' || case when v_s.has_code = false and v_s.is_enabled = false and v_s.code_hint is null
        then 'PASS' else 'FAIL' end || ' 01a status with no code yet';
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_newcomer","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_admin := public.redeem_platform_join_code('ABCD-EFGH-2345', 'New Person');
  v_log := v_log || E'\n' || case when v_admin.clerk_user_id is null then 'PASS' else 'FAIL' end || ' 01b no code yet → null';

  -- 02 an admin creates the code: 12 allowed characters, only the hash stored
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select r.code, r.code_hint into v_code, v_hint from public.rotate_platform_join_code() r;
  execute 'reset role';
  select count(*) into v_n from private.platform_join_code c
    where c.code_hash = private.platform_code_hash(v_code) and c.code_hash <> v_code
      and c.code_hint = right(v_code, 4) and c.is_enabled and c.changed_by = 'user_dummy_platform_admin';
  v_log := v_log || E'\n' || case when v_code ~ '^[A-HJ-NP-Z2-9]{12}$' and v_hint = right(v_code, 4) and v_n = 1
        then 'PASS' else 'FAIL' end || ' 02 code shape, hash stored not the code';

  -- 03 status shows the live code to an admin
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select * into v_s from public.platform_join_code_status();
  v_log := v_log || E'\n' || case when v_s.has_code and v_s.is_enabled and v_s.code_hint = v_hint
        and v_s.changed_by_name = 'Dummy Platform Admin' then 'PASS' else 'FAIL' end || ' 03 status shows hint and who changed it';

  -- 04 a non-admin can't rotate, switch, or see the status
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_newcomer","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    perform public.rotate_platform_join_code();
    v_log := v_log || E'\nFAIL 04a non-admin rotated the code';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 04a non-admin cannot rotate [' || sqlerrm || ']';
  end;
  begin
    perform public.set_platform_join_enabled(false);
    v_log := v_log || E'\nFAIL 04b non-admin switched the code off';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 04b non-admin cannot switch [' || sqlerrm || ']';
  end;
  begin
    perform public.platform_join_code_status();
    v_log := v_log || E'\nFAIL 04c non-admin read the status';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 04c non-admin cannot see status [' || sqlerrm || ']';
  end;

  -- 05 clients can't read the code table directly
  begin
    select count(*) into v_n from private.platform_join_code;
    v_log := v_log || E'\nFAIL 05 authenticated read private.platform_join_code';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 05 code table not readable [' || sqlerrm || ']';
  end;

  -- 06 a name is required
  begin
    perform public.redeem_platform_join_code(v_code, '   ');
    v_log := v_log || E'\nFAIL 06 joined without a name';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '22023' then 'PASS' else 'FAIL' end || ' 06 name required [' || sqlerrm || ']';
  end;

  -- 07 a wrong code returns null and makes no admin
  v_admin := public.redeem_platform_join_code('WRONG-CODE-0000', 'New Person');
  execute 'reset role';
  select count(*) into v_n from public.platform_admins where clerk_user_id = 'test_newcomer';
  v_log := v_log || E'\n' || case when v_admin.clerk_user_id is null and v_n = 0
        then 'PASS' else 'FAIL' end || ' 07 wrong code → null, no admin made';

  -- 08 the right code, typed loosely, makes the caller an active admin
  perform set_config('request.jwt.claims', '{"sub":"test_newcomer","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_admin := public.redeem_platform_join_code(
    lower(substr(v_code, 1, 4) || '-' || substr(v_code, 5, 4) || ' ' || substr(v_code, 9, 4)),
    ' New Person ', ' new@hamrash.test ');
  v_log := v_log || E'\n' || case when v_admin.clerk_user_id = 'test_newcomer' and v_admin.is_active
        and v_admin.full_name = 'New Person' and v_admin.email = 'new@hamrash.test' and v_admin.joined_at is not null
        then 'PASS' else 'FAIL' end || ' 08 code accepted, caller is an admin with joined_at';
  select count(*) into v_n from public.organizations;  -- reads all schools without error
  v_log := v_log || E'\n' || case when private.is_platform_admin() then 'PASS' else 'FAIL' end || ' 08b newcomer passes the platform-admin check';

  -- 09 the code is reusable: a second person joins with the same code
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_other","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_admin := public.redeem_platform_join_code(v_code, 'Other Person');
  v_log := v_log || E'\n' || case when v_admin.clerk_user_id = 'test_other' and v_admin.is_active
        then 'PASS' else 'FAIL' end || ' 09 same code works for a second person';

  -- 10 an existing admin redeeming just gets their row back
  v_admin := public.redeem_platform_join_code('NOT-THE-CODE', 'Other Person');
  v_log := v_log || E'\n' || case when v_admin.clerk_user_id = 'test_other'
        then 'PASS' else 'FAIL' end || ' 10 existing admin gets their row back';

  -- 11 rotating stops the old code and starts a new one
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select r.code into v_code2 from public.rotate_platform_join_code() r;
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_third","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_admin := public.redeem_platform_join_code(v_code, 'Third Person');
  v_log := v_log || E'\n' || case when v_code2 <> v_code and v_admin.clerk_user_id is null
        then 'PASS' else 'FAIL' end || ' 11a old code rejected after rotating';
  v_admin := public.redeem_platform_join_code(v_code2, 'Third Person');
  v_log := v_log || E'\n' || case when v_admin.clerk_user_id = 'test_third'
        then 'PASS' else 'FAIL' end || ' 11b new code accepted';

  -- 12 switched off: the code is refused; switched on: it works again
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.set_platform_join_enabled(false);
  select * into v_s from public.platform_join_code_status();
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_fourth","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_admin := public.redeem_platform_join_code(v_code2, 'Fourth Person');
  v_log := v_log || E'\n' || case when v_s.is_enabled = false and v_admin.clerk_user_id is null
        then 'PASS' else 'FAIL' end || ' 12a switched-off code rejected';
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.set_platform_join_enabled(true);
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_fourth","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_admin := public.redeem_platform_join_code(v_code2, 'Fourth Person');
  v_log := v_log || E'\n' || case when v_admin.clerk_user_id = 'test_fourth'
        then 'PASS' else 'FAIL' end || ' 12b switched back on, code works';

  -- 13 rotating while switched off turns joining back on
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.set_platform_join_enabled(false);
  perform public.rotate_platform_join_code();
  select * into v_s from public.platform_join_code_status();
  v_log := v_log || E'\n' || case when v_s.is_enabled then 'PASS' else 'FAIL' end || ' 13 rotating switches joining on';

  -- 14 a turned-off admin can't use the code to get back in
  execute 'reset role';
  update public.platform_admins set is_active = false where clerk_user_id = 'test_newcomer';
  perform set_config('request.jwt.claims', '{"sub":"test_newcomer","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    perform public.redeem_platform_join_code('ANYTHING', 'New Person');
    v_log := v_log || E'\nFAIL 14 turned-off admin rejoined';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 14 turned-off admin refused [' || sqlerrm || ']';
  end;

  -- 15 anon can't join
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  execute 'set local role anon';
  begin
    perform public.redeem_platform_join_code('ABCD-EFGH-2345', 'Anon');
    v_log := v_log || E'\nFAIL 15 anon called redeem_platform_join_code';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 15 anon cannot join [' || sqlerrm || ']';
  end;

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
