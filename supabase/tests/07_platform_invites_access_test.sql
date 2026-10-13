-- Access test for migration 12 (platform invite codes).
--
-- How to run: paste the whole file into the Supabase SQL editor and run it.
-- It acts as several fake users, checks every rule, then raises an exception on
-- purpose so EVERYTHING is rolled back. The "error" at the end is the report.
--
-- Requires migrations 01–12.

do $test$
declare
  v_log     text := '';
  v_n       int;
  v_code    text;
  v_code2   text;
  v_invite  uuid;
  v_invite2 uuid;
  v_expires timestamptz;
  v_admin   public.platform_admins;
  v_status  text;
begin
  -- The test platform admin exists only inside this test; it's rolled back
  -- with everything else, so the live database needs no fake admin.
  execute 'reset role';
  insert into public.platform_admins (clerk_user_id, full_name)
  values ('user_dummy_platform_admin', 'Dummy Platform Admin')
  on conflict (clerk_user_id) do nothing;

  -- ── setup: the dummy platform admin creates a code ─────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select c.invite_id, c.code, c.expires_at into v_invite, v_code, v_expires
  from public.create_platform_invite(' Amina, support ') c;

  -- 01 a code is 12 allowed characters, expires in 7 days, and only its hash is stored
  execute 'reset role';
  select count(*) into v_n from private.platform_invite_codes c
    where c.id = v_invite and c.code_hash = private.platform_code_hash(v_code)
      and c.code_hash <> v_code and c.code_hint = right(v_code, 4) and c.note = 'Amina, support';
  v_log := v_log || E'\n' || case when v_code ~ '^[A-HJ-NP-Z2-9]{12}$' and v_n = 1
        and v_expires between now() + interval '6 days 23 hours' and now() + interval '7 days 1 minute'
        then 'PASS' else 'FAIL' end || ' 01 code shape, 7-day expiry, hash stored not the code';

  -- 02 a non-admin can't create, list or cancel codes
  perform set_config('request.jwt.claims', '{"sub":"test_newcomer","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    perform public.create_platform_invite('sneaky');
    v_log := v_log || E'\nFAIL 02a non-admin created a code';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 02a non-admin cannot create [' || sqlerrm || ']';
  end;
  begin
    perform public.list_platform_invites();
    v_log := v_log || E'\nFAIL 02b non-admin listed codes';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 02b non-admin cannot list [' || sqlerrm || ']';
  end;
  begin
    perform public.revoke_platform_invite(v_invite);
    v_log := v_log || E'\nFAIL 02c non-admin cancelled a code';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 02c non-admin cannot cancel [' || sqlerrm || ']';
  end;

  -- 03 clients can't read the code tables directly
  begin
    select count(*) into v_n from private.platform_invite_codes;
    v_log := v_log || E'\nFAIL 03 authenticated read private.platform_invite_codes';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 03 code table not readable [' || sqlerrm || ']';
  end;

  -- 04 a name is required; the code still works afterwards
  begin
    perform public.redeem_platform_invite(v_code, '   ');
    v_log := v_log || E'\nFAIL 04 redeemed without a name';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '22023' then 'PASS' else 'FAIL' end || ' 04 name required [' || sqlerrm || ']';
  end;

  -- 05 a wrong code returns null and counts as an attempt
  v_admin := public.redeem_platform_invite('WRONG-CODE-0000', 'New Person');
  execute 'reset role';
  select count(*) into v_n from private.platform_invite_attempts where clerk_user_id = 'test_newcomer';
  v_log := v_log || E'\n' || case when v_admin.clerk_user_id is null and v_n = 1
        then 'PASS' else 'FAIL' end || ' 05 wrong code → null, attempt recorded [' || v_n || ']';

  -- 06 the right code, typed loosely, makes the caller a platform admin
  perform set_config('request.jwt.claims', '{"sub":"test_newcomer","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_admin := public.redeem_platform_invite(
    lower(substr(v_code, 1, 4) || '-' || substr(v_code, 5, 4) || ' ' || substr(v_code, 9, 4)),
    ' New Person ', ' new@hamrash.test ');
  v_log := v_log || E'\n' || case when v_admin.clerk_user_id = 'test_newcomer' and v_admin.is_active
        and v_admin.full_name = 'New Person' and v_admin.email = 'new@hamrash.test'
        then 'PASS' else 'FAIL' end || ' 06 code redeemed, caller is now a platform admin';

  -- 07 the newcomer now passes the platform-admin check
  select count(*) into v_n from public.organizations;  -- reads all schools without error
  v_log := v_log || E'\n' || case when private.is_platform_admin() then 'PASS' else 'FAIL' end || ' 07 newcomer is a platform admin';

  -- 08 the code is used up, and attempts were cleared
  execute 'reset role';
  select count(*) into v_n from private.platform_invite_codes
    where id = v_invite and redeemed_by = 'test_newcomer' and redeemed_at is not null;
  select v_n + count(*) * 100 into v_n from private.platform_invite_attempts where clerk_user_id = 'test_newcomer';
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 08 code marked used, attempts cleared [' || v_n || ']';

  -- 09 someone else can't reuse it
  perform set_config('request.jwt.claims', '{"sub":"test_other","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_admin := public.redeem_platform_invite(v_code, 'Other Person');
  v_log := v_log || E'\n' || case when v_admin.clerk_user_id is null then 'PASS' else 'FAIL' end || ' 09 used code rejected';

  -- 10 an existing admin redeeming gets their row back and doesn't use up a code
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select c.invite_id, c.code into v_invite2, v_code2 from public.create_platform_invite(null) c;
  v_admin := public.redeem_platform_invite(v_code2, 'Dummy Admin');
  execute 'reset role';
  select count(*) into v_n from private.platform_invite_codes where id = v_invite2 and redeemed_at is null;
  v_log := v_log || E'\n' || case when v_admin.clerk_user_id = 'user_dummy_platform_admin' and v_n = 1
        then 'PASS' else 'FAIL' end || ' 10 existing admin keeps their row; code stays unused';

  -- 11 a cancelled code doesn't work, and can't be cancelled twice
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.revoke_platform_invite(v_invite2);
  begin
    perform public.revoke_platform_invite(v_invite2);
    v_log := v_log || E'\nFAIL 11a cancelled twice';
  exception when others then
    v_log := v_log || E'\n' || case when sqlerrm like '%already been used or cancelled%' then 'PASS' else 'FAIL' end || ' 11a cannot cancel twice [' || sqlerrm || ']';
  end;
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_other","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_admin := public.redeem_platform_invite(v_code2, 'Other Person');
  v_log := v_log || E'\n' || case when v_admin.clerk_user_id is null then 'PASS' else 'FAIL' end || ' 11b cancelled code rejected';

  -- 12 an expired code doesn't work
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select c.invite_id, c.code into v_invite2, v_code2 from public.create_platform_invite('to expire') c;
  execute 'reset role';
  update private.platform_invite_codes set expires_at = now() - interval '1 minute' where id = v_invite2;
  perform set_config('request.jwt.claims', '{"sub":"test_other","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_admin := public.redeem_platform_invite(v_code2, 'Other Person');
  v_log := v_log || E'\n' || case when v_admin.clerk_user_id is null then 'PASS' else 'FAIL' end || ' 12 expired code rejected';

  -- 13 the list shows each code's status and who made or used it
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select l.status into v_status from public.list_platform_invites() l where l.invite_id = v_invite;
  select count(*) into v_n from public.list_platform_invites() l
    where (l.invite_id = v_invite and l.status = 'used' and l.redeemed_by_name = 'New Person' and l.created_by_name is not null)
       or (l.invite_id = v_invite2 and l.status = 'expired');
  v_log := v_log || E'\n' || case when v_n = 2 then 'PASS' else 'FAIL' end || ' 13 list shows used and expired [' || coalesce(v_status, 'none') || ']';

  -- 14 after 5 wrong codes in an hour, redeeming is blocked (test_other has 3 so far)
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_other","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_platform_invite('NOPE-NOPE-NOP1', 'Other Person');
  perform public.redeem_platform_invite('NOPE-NOPE-NOP2', 'Other Person');
  begin
    perform public.redeem_platform_invite('NOPE-NOPE-NOP3', 'Other Person');
    v_log := v_log || E'\nFAIL 14 sixth try allowed';
  exception when others then
    v_log := v_log || E'\n' || case when sqlerrm like 'Too many wrong codes%' then 'PASS' else 'FAIL' end || ' 14 blocked after 5 wrong codes [' || sqlerrm || ']';
  end;

  -- 15 a turned-off admin can't use a code to get back in
  execute 'reset role';
  update public.platform_admins set is_active = false where clerk_user_id = 'test_newcomer';
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select c.code into v_code2 from public.create_platform_invite('rejoin') c;
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_newcomer","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    perform public.redeem_platform_invite(v_code2, 'New Person');
    v_log := v_log || E'\nFAIL 15 turned-off admin rejoined with a code';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 15 turned-off admin refused [' || sqlerrm || ']';
  end;

  -- 16 anon can't redeem
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  execute 'set local role anon';
  begin
    perform public.redeem_platform_invite('ABCD-EFGH-2345', 'Anon');
    v_log := v_log || E'\nFAIL 16 anon called redeem_platform_invite';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 16 anon cannot redeem [' || sqlerrm || ']';
  end;

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
