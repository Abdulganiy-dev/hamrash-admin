-- Access test for migration 11 (the owner gets a staff record on redeem).
--
-- How to run: paste the whole file into the Supabase SQL editor and run it.
-- It acts as several fake users, checks every rule, then raises an exception on
-- purpose so EVERYTHING is rolled back. The "error" at the end is the report.
--
-- Requires migrations 01–11.

do $test$
declare
  v_log    text := '';
  v_n      int;
  v_org    uuid;
  v_claim  text;
  v_member public.organization_members;
  v_staff  public.staff;
  v_ada    uuid;
  v_t_code text;
  v_owner2_code text;
  v_owner3_code text;
begin
  -- The test platform admin exists only inside this test; it's rolled back
  -- with everything else, so the live database needs no fake admin.
  execute 'reset role';
  insert into public.platform_admins (clerk_user_id, full_name)
  values ('user_dummy_platform_admin', 'Dummy Platform Admin')
  on conflict (clerk_user_id) do nothing;

  -- ── setup: one school ──────────────────────────────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select c.organization_id, c.owner_claim_code into v_org, v_claim from public.create_organization('Test School', 'TST') c;

  -- 01 an owner code needs a first and last name; blanks don't count
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    perform public.redeem_claim_code(v_claim);
    v_log := v_log || E'\nFAIL 01a owner redeemed without a name';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '22023' then 'PASS' else 'FAIL' end || ' 01a owner code needs a name [' || sqlerrm || ']';
  end;
  begin
    perform public.redeem_claim_code(v_claim, '  ', 'Owner');
    v_log := v_log || E'\nFAIL 01b owner redeemed with a blank first name';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '22023' then 'PASS' else 'FAIL' end || ' 01b blank name rejected [' || sqlerrm || ']';
  end;

  -- 02 the same code still works once a name is given; the staff record is linked
  v_member := public.redeem_claim_code(v_claim, ' Olu ', ' Owner ', 'olu@school.test', '0801234567');
  select s.* into v_staff from public.staff s where s.member_id = v_member.id;
  v_log := v_log || E'\n' || case when v_member.status = 'active' and v_member.role = 'owner'
        and v_staff.first_name = 'Olu' and v_staff.last_name = 'Owner'
        and v_staff.email = 'olu@school.test' and v_staff.phone = '0801234567'
        and v_staff.job_title = 'Owner' and v_staff.staff_type = 'non_teaching'
        and v_staff.staff_number = 'TST/STF/0001'
        then 'PASS' else 'FAIL' end || ' 02 owner redeems and gets a linked staff record [' || coalesce(v_staff.staff_number, 'none') || ']';

  -- 03 the record has its private details row, like every staff member
  select count(*) into v_n from public.staff_private_details where staff_id = v_staff.id;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 03 owner''s private details row created [' || v_n || ']';

  -- 04 the owner edits their own record like any other
  perform public.update_staff(v_staff.id, 'Olu', 'Owner', null, '', null, '0801234567', 'olu@school.test', null, null,
                              'Proprietor', 'teaching', 'active', null, null, null, null);
  select count(*) into v_n from public.staff s
    where s.id = v_staff.id and s.job_title = 'Proprietor' and s.staff_type = 'teaching' and s.staff_number = 'TST/STF/0001';
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 04 owner can edit own staff record';

  -- 05 a used owner code is still rejected, name or not (returns NULL since migration 13)
  begin
    v_member := public.redeem_claim_code(v_claim, 'Olu', 'Owner');
    v_log := v_log || E'\n' || case when v_member.id is null then 'PASS' else 'FAIL' end || ' 05 used owner code rejected';
  exception when others then
    v_log := v_log || E'\nFAIL 05 used owner code raised instead of returning NULL [' || sqlerrm || ']';
  end;

  -- 06 a teacher code needs no name and makes no extra staff record
  v_ada := (public.create_staff(p_organization_id => v_org, p_first_name => 'Ada', p_last_name => 'Teacher')).id;
  v_t_code := public.invite_staff(v_ada);

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_teacher","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_member := public.redeem_claim_code(v_t_code);

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select count(*) into v_n from public.staff where organization_id = v_org;
  v_log := v_log || E'\n' || case when v_member.role = 'teacher' and v_member.status = 'active' and v_n = 2
        then 'PASS' else 'FAIL' end || ' 06 teacher code needs no name, no extra staff record [' || v_n || ' staff]';

  -- 07 a second owner who is already on staff keeps their one record
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  insert into public.organization_members (organization_id, role) values (v_org, 'owner') returning claim_code into v_owner2_code;
  insert into public.organization_members (organization_id, role) values (v_org, 'owner') returning claim_code into v_owner3_code;

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_teacher","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_member := public.redeem_claim_code(v_owner2_code);
  select count(*) into v_n from public.staff where organization_id = v_org;
  v_log := v_log || E'\n' || case when v_member.role = 'owner' and v_n = 2
        then 'PASS' else 'FAIL' end || ' 07 existing staff member becomes owner without a second record [' || v_n || ' staff]';

  -- 08 a second owner who is new to the school gets their own record
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner_2","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_member := public.redeem_claim_code(v_owner3_code, 'Bimbo', 'Partner');
  select s.* into v_staff from public.staff s where s.member_id = v_member.id;
  select count(*) into v_n from public.staff where organization_id = v_org;
  v_log := v_log || E'\n' || case when v_n = 3 and v_staff.last_name = 'Partner' and v_staff.staff_number = 'TST/STF/0003'
        then 'PASS' else 'FAIL' end || ' 08 new co-owner gets own staff record [' || v_n || ' staff, ' || coalesce(v_staff.staff_number, 'none') || ']';

  -- 09 anon cannot redeem
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  execute 'set local role anon';
  begin
    perform public.redeem_claim_code('ABCD2345', 'Anon', 'User');
    v_log := v_log || E'\nFAIL 09 anon called redeem_claim_code';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 09 anon cannot redeem [' || sqlerrm || ']';
  end;

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
