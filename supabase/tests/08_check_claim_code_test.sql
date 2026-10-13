-- Access test for migration 13 (check a claim code first, limit wrong codes).
--
-- How to run: paste the whole file into the Supabase SQL editor and run it.
-- It acts as several fake users, checks every rule, then raises an exception on
-- purpose so EVERYTHING is rolled back. The "error" at the end is the report.
--
-- now() is fixed inside one transaction, so every attempt here has the same
-- time; test 11 moves them back an hour by hand.
--
-- Requires migrations 01–13.

do $test$
declare
  v_log         text := '';
  v_n           int;
  v_org         uuid;
  v_org2        uuid;
  v_owner_claim text;
  v_claim2      text;
  v_ada         uuid;
  v_pat         uuid;
  v_pam         uuid;
  v_t_code      text;
  v_p_code      text;
  v_pam_code    text;
  v_r           record;
  v_member      public.organization_members;
begin
  -- The test platform admin exists only inside this test; it's rolled back
  -- with everything else, so the live database needs no fake admin.
  execute 'reset role';
  insert into public.platform_admins (clerk_user_id, full_name)
  values ('user_dummy_platform_admin', 'Dummy Platform Admin')
  on conflict (clerk_user_id) do nothing;

  -- ── setup: two schools ─────────────────────────────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select c.organization_id, c.owner_claim_code into v_org, v_owner_claim from public.create_organization('Test School', 'TST') c;
  select c.organization_id, c.owner_claim_code into v_org2, v_claim2 from public.create_organization('Other School', 'OTH') c;

  -- 01 an owner code checks as ok, for the admin app, and needs a name; nothing is used up
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select * into v_r from public.check_claim_code(v_owner_claim);
  v_log := v_log || E'\n' || case when v_r.status = 'ok' and v_r.organization_id = v_org and v_r.school_name = 'Test School'
        and v_r.school_code ~ '^HMR-' and v_r.role = 'owner' and v_r.app = 'admin' and v_r.needs_name
        and v_r.tries_left = 5 and v_r.retry_at is null
        then 'PASS' else 'FAIL' end || ' 01a owner code checks ok [' || coalesce(v_r.status, 'null') || ']';
  execute 'reset role';
  select count(*) into v_n from public.organization_members m where m.claim_code = v_owner_claim and m.status = 'invited';
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 01b checking does not use the code';

  -- the owner joins and invites a teacher and a principal
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_owner_claim, 'Olu', 'Owner');
  insert into public.staff (organization_id, first_name, last_name, job_title)
    values (v_org, 'Ada', 'Teacher', 'Maths Teacher') returning id into v_ada;
  insert into public.staff (organization_id, first_name, last_name, job_title, staff_type)
    values (v_org, 'Pat', 'Principal', 'Principal', 'non_teaching') returning id into v_pat;
  v_t_code := public.invite_staff(v_ada, 'teacher');
  v_p_code := public.invite_staff(v_pat, 'principal');

  -- 02 a principal code (lowercase, with a dash) is for the admin app and needs no name
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_newcomer","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select * into v_r from public.check_claim_code(lower(substr(v_p_code, 1, 4) || '-' || substr(v_p_code, 5, 4)));
  v_log := v_log || E'\n' || case when v_r.status = 'ok' and v_r.role = 'principal' and v_r.app = 'admin' and not v_r.needs_name
        then 'PASS' else 'FAIL' end || ' 02 principal code checks ok for the admin app [' || coalesce(v_r.app, 'null') || ']';

  -- 03 a teacher code says app = staff and stays unused
  select * into v_r from public.check_claim_code(v_t_code);
  execute 'reset role';
  select count(*) into v_n from public.organization_members m where m.claim_code = v_t_code and m.status = 'invited';
  v_log := v_log || E'\n' || case when v_r.status = 'ok' and v_r.role = 'teacher' and v_r.app = 'staff' and v_n = 1
        then 'PASS' else 'FAIL' end || ' 03 teacher code is for the staff app and stays unused [' || coalesce(v_r.app, 'null') || ']';

  -- 04 a half-typed code is not found but doesn't count as a wrong try
  perform set_config('request.jwt.claims', '{"sub":"test_newcomer","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select * into v_r from public.check_claim_code('KQ7');
  v_log := v_log || E'\n' || case when v_r.status = 'not_found' and v_r.tries_left = 5 and v_r.school_name is null
        then 'PASS' else 'FAIL' end || ' 04 malformed code not counted [' || coalesce(v_r.tries_left::text, 'null') || ' left]';

  -- 05 a wrong code is not found and counts
  select * into v_r from public.check_claim_code('ZZZZ-ZZZZ');
  v_log := v_log || E'\n' || case when v_r.status = 'not_found' and v_r.tries_left = 4 and v_r.retry_at is null
        then 'PASS' else 'FAIL' end || ' 05 wrong code counts [' || coalesce(v_r.tries_left::text, 'null') || ' left]';

  -- 06 redeeming a wrong code returns NULL (no error) and also counts
  v_member := public.redeem_claim_code('ZZZZ-ZZZY');
  select * into v_r from public.check_claim_code('KQ7');
  v_log := v_log || E'\n' || case when v_member.id is null and v_r.tries_left = 3
        then 'PASS' else 'FAIL' end || ' 06 wrong redeem returns NULL and counts [' || coalesce(v_r.tries_left::text, 'null') || ' left]';

  -- 07 the 5th wrong try locks the account for an hour
  perform public.check_claim_code('ZZZZ-ZZZX');
  perform public.check_claim_code('ZZZZ-ZZZW');
  select * into v_r from public.check_claim_code('ZZZZ-ZZZV');
  v_log := v_log || E'\n' || case when v_r.status = 'locked' and v_r.tries_left = 0 and v_r.retry_at = now() + interval '1 hour'
        then 'PASS' else 'FAIL' end || ' 07 5th wrong try locks [' || coalesce(v_r.status, 'null') || ']';

  -- 08 while locked, even a good code says locked and shows no school
  select * into v_r from public.check_claim_code(v_p_code);
  v_log := v_log || E'\n' || case when v_r.status = 'locked' and v_r.school_name is null and v_r.role is null
        then 'PASS' else 'FAIL' end || ' 08 locked check hides the school [' || coalesce(v_r.status, 'null') || ']';

  -- 09 while locked, redeem refuses and the code stays unused
  begin
    perform public.redeem_claim_code(v_p_code);
    v_log := v_log || E'\nFAIL 09 redeemed while locked';
  exception when others then
    v_log := v_log || E'\n' || case when sqlerrm like 'Too many wrong codes. Try again in 60 minutes.' then 'PASS' else 'FAIL' end
          || ' 09 locked redeem refused [' || sqlerrm || ']';
  end;
  execute 'reset role';
  select count(*) into v_n from public.organization_members m where m.claim_code = v_p_code and m.status = 'invited';
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 09b code still unused after locked redeem';

  -- 10 the lock is per account: someone else can still check
  perform set_config('request.jwt.claims', '{"sub":"test_other","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select * into v_r from public.check_claim_code(v_p_code);
  v_log := v_log || E'\n' || case when v_r.status = 'ok' and v_r.tries_left = 5
        then 'PASS' else 'FAIL' end || ' 10 other accounts not locked [' || coalesce(v_r.status, 'null') || ']';

  -- 11 tries older than an hour don't count
  execute 'reset role';
  update private.claim_code_attempts a set attempted_at = now() - interval '61 minutes'
  where a.clerk_user_id = 'test_newcomer';
  perform set_config('request.jwt.claims', '{"sub":"test_newcomer","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select * into v_r from public.check_claim_code(v_p_code);
  v_log := v_log || E'\n' || case when v_r.status = 'ok' and v_r.tries_left = 5
        then 'PASS' else 'FAIL' end || ' 11 lock lifts after an hour [' || coalesce(v_r.status, 'null') || ']';

  -- 12 a successful redeem clears the wrong tries
  perform public.check_claim_code('ZZZZ-ZZZU');
  v_member := public.redeem_claim_code(v_p_code);
  execute 'reset role';
  select count(*) into v_n from private.claim_code_attempts a where a.clerk_user_id = 'test_newcomer';
  v_log := v_log || E'\n' || case when v_member.role = 'principal' and v_member.status = 'active' and v_n = 0
        then 'PASS' else 'FAIL' end || ' 12 redeem works and clears wrong tries [' || v_n || ' left over]';

  -- 13 a second principal code at the same school says already_member
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  insert into public.staff (organization_id, first_name, last_name, job_title, staff_type)
    values (v_org, 'Pam', 'Principal', 'Principal', 'non_teaching') returning id into v_pam;
  v_pam_code := public.invite_staff(v_pam, 'principal');
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_newcomer","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select * into v_r from public.check_claim_code(v_pam_code);
  v_log := v_log || E'\n' || case when v_r.status = 'already_member' and v_r.school_name = 'Test School'
        then 'PASS' else 'FAIL' end || ' 13 same role twice says already_member [' || coalesce(v_r.status, 'null') || ']';

  -- 14 a suspended school's code says school_inactive and isn't a wrong try
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.set_organization_status(v_org2, 'suspended');
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_newcomer","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select * into v_r from public.check_claim_code(v_claim2);
  v_log := v_log || E'\n' || case when v_r.status = 'school_inactive' and v_r.school_name = 'Other School' and v_r.tries_left = 5
        then 'PASS' else 'FAIL' end || ' 14 suspended school says school_inactive [' || coalesce(v_r.status, 'null') || ']';

  -- 15 signed-in users can't read the attempts table
  begin
    select count(*) into v_n from private.claim_code_attempts;
    v_log := v_log || E'\nFAIL 15 authenticated read claim_code_attempts';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 15 attempts table is private [' || sqlerrm || ']';
  end;

  -- 16 anon can't check a code
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  execute 'set local role anon';
  begin
    perform public.check_claim_code('ABCD-2345');
    v_log := v_log || E'\nFAIL 16 anon called check_claim_code';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 16 anon cannot check [' || sqlerrm || ']';
  end;

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
