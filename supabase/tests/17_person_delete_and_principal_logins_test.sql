-- Access test for migration 28 (deleting a person revokes their login;
-- principals and vice principals issue logins for their tier).
--
-- How to run: paste the whole file into the Supabase SQL editor and run it.
-- It acts as several fake users, checks every rule, then raises an exception on
-- purpose so EVERYTHING is rolled back. The "error" at the end is the report.
--
-- Requires migrations 01–28.

do $test$
declare
  v_log     text := '';
  v_n       int;
  v_org     uuid;
  v_claim   text;
  v_code    text;
  v_status  text;
  v_owner   public.organization_members;
  v_member  public.organization_members;
  v_owner_staff uuid;
  v_pat     uuid;
  v_ada     uuid;
  v_bea     uuid;
  v_tee     uuid;
  v_stu     uuid;
begin
  execute 'reset role';
  insert into public.platform_admins (clerk_user_id, full_name)
  values ('user_dummy_platform_admin', 'Dummy Platform Admin')
  on conflict (clerk_user_id) do nothing;

  -- ── setup: a school, its owner, a principal and three staff ──
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select c.organization_id, c.owner_claim_code into v_org, v_claim from public.create_organization('Test School', 'TST') c;

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_owner := public.redeem_claim_code(v_claim, 'Olu', 'Owner');
  select s.id into v_owner_staff from public.staff s where s.member_id = v_owner.id;
  insert into public.staff (organization_id, first_name, last_name, job_title) values (v_org, 'Pat', 'Principal', 'Principal') returning id into v_pat;
  insert into public.staff (organization_id, first_name, last_name) values (v_org, 'Ada', 'Teacher') returning id into v_ada;
  insert into public.staff (organization_id, first_name, last_name) values (v_org, 'Bea', 'Bursar') returning id into v_bea;
  insert into public.staff (organization_id, first_name, last_name) values (v_org, 'Tee', 'Teacher') returning id into v_tee;
  insert into public.students (organization_id, first_name, last_name) values (v_org, 'Sam', 'Student') returning id into v_stu;
  v_code := public.invite_staff(v_pat, 'principal');

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_principal","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_code);

  -- 01 a principal issues a teacher login and it links the staff record
  v_code := public.invite_staff(v_ada, 'teacher');
  execute 'reset role';
  select count(*) into v_n from public.staff s join public.organization_members m on m.id = s.member_id
    where s.id = v_ada and m.role = 'teacher' and m.status = 'invited' and m.claim_code = v_code;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 01 principal issues a teacher login';

  -- 02 a principal can't issue an admin login
  perform set_config('request.jwt.claims', '{"sub":"test_principal","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    perform public.invite_staff(v_tee, 'admin');
    v_log := v_log || E'\nFAIL 02 principal issued an admin login';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 02 principal cannot issue admin [' || sqlerrm || ']';
  end;

  -- 03 a principal can't turn the owner's admin invite into something else
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.invite_staff(v_bea, 'admin');
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_principal","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    perform public.invite_staff(v_bea, 'bursar');
    v_log := v_log || E'\nFAIL 03 principal changed an admin invite';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 03 principal cannot change an admin invite [' || sqlerrm || ']';
  end;

  -- 04 principals still can't issue student logins
  begin
    perform public.invite_student(v_stu);
    v_log := v_log || E'\nFAIL 04 principal issued a student login';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 04 principal cannot issue student logins [' || sqlerrm || ']';
  end;

  -- 05 deleting a staff record with an unclaimed invite deletes the invite
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  delete from public.staff where id = v_ada;
  execute 'reset role';
  select count(*) into v_n from public.organization_members where claim_code = v_code;
  v_log := v_log || E'\n' || case when v_n = 0 then 'PASS' else 'FAIL' end || ' 05 unclaimed invite removed with the record [' || v_n || ' left]';

  -- 06 deleting a staff record with an active login suspends the login
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_code := public.invite_staff(v_tee, 'teacher');
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_teacher","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_member := public.redeem_claim_code(v_code);
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  delete from public.staff where id = v_tee;
  execute 'reset role';
  select m.status::text into v_status from public.organization_members m where m.id = v_member.id;
  v_log := v_log || E'\n' || case when v_status = 'suspended' then 'PASS' else 'FAIL' end || ' 06 active login suspended [' || coalesce(v_status, 'gone') || ']';

  -- 07 the suspended teacher no longer sees the school's data
  perform set_config('request.jwt.claims', '{"sub":"test_teacher","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select count(*) into v_n from public.staff where organization_id = v_org;
  v_log := v_log || E'\n' || case when v_n = 0 then 'PASS' else 'FAIL' end || ' 07 suspended login sees no staff [' || v_n || ']';

  -- 08 deleting a student with an active login suspends it
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_code := public.invite_student(v_stu);
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_student","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_member := public.redeem_claim_code(v_code);
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  delete from public.students where id = v_stu;
  execute 'reset role';
  select m.status::text into v_status from public.organization_members m where m.id = v_member.id;
  v_log := v_log || E'\n' || case when v_status = 'suspended' then 'PASS' else 'FAIL' end || ' 08 student login suspended [' || coalesce(v_status, 'gone') || ']';

  -- 09 the owner's own staff record can't be deleted
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    delete from public.staff where id = v_owner_staff;
    v_log := v_log || E'\nFAIL 09 owner staff record deleted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = 'P0001' then 'PASS' else 'FAIL' end || ' 09 owner staff record kept [' || sqlerrm || ']';
  end;

  -- 10 a record with no login deletes as before
  insert into public.staff (organization_id, first_name, last_name) values (v_org, 'No', 'Login') returning id into v_pat;
  delete from public.staff where id = v_pat;
  execute 'reset role';
  select count(*) into v_n from public.staff where id = v_pat;
  v_log := v_log || E'\n' || case when v_n = 0 then 'PASS' else 'FAIL' end || ' 10 record without a login deletes';

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
