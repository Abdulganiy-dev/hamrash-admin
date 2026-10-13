-- Access test for migration 17 (only the owner edits the school; principals
-- and VPs invite the team up to their own level).
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
  v_admin_claim     text;
  v_principal_claim text;
  v_vp_claim        text;
  v_extra_claim     text;
  v_admin_invite    text;
  v_member public.organization_members;
  v_n      int;
begin
  execute 'reset role';
  insert into public.platform_admins (clerk_user_id, full_name)
  values ('user_dummy_platform_admin', 'Dummy Platform Admin')
  on conflict (clerk_user_id) do nothing;

  -- Setup: a school with an owner, an admin, a principal and a VP
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select c.organization_id, c.owner_claim_code into v_org, v_claim
    from public.create_organization('Test School', 'TST') c;

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_claim, 'Olu', 'Owner');
  insert into public.organization_members (organization_id, role) values (v_org, 'admin')
    returning claim_code into v_admin_claim;
  insert into public.organization_members (organization_id, role) values (v_org, 'principal')
    returning claim_code into v_principal_claim;
  insert into public.organization_members (organization_id, role) values (v_org, 'vice_principal')
    returning claim_code into v_vp_claim;

  -- 01 owner edits school details
  update public.organizations set name = 'Renamed School' where id = v_org;
  get diagnostics v_n = row_count;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 01 owner can edit school details';

  -- 02 admin cannot edit school details
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_admin_claim);
  update public.organizations set name = 'Admin Was Here' where id = v_org;
  get diagnostics v_n = row_count;
  v_log := v_log || E'\n' || case when v_n = 0 then 'PASS' else 'FAIL' end || ' 02 admin cannot edit school details [' || v_n || ' rows]';

  -- 03 admin still invites any role except owner
  insert into public.organization_members (organization_id, role) values (v_org, 'admin')
    returning claim_code into v_admin_invite;
  v_log := v_log || E'\n' || case when v_admin_invite is not null then 'PASS' else 'FAIL' end || ' 03 admin can still invite an admin';

  -- 04 principal cannot edit school details
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_principal","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_principal_claim);
  update public.organizations set name = 'Principal Was Here' where id = v_org;
  get diagnostics v_n = row_count;
  v_log := v_log || E'\n' || case when v_n = 0 then 'PASS' else 'FAIL' end || ' 04 principal cannot edit school details [' || v_n || ' rows]';

  -- 05 principal invites principal, VP, bursar, teacher and staff
  begin
    insert into public.organization_members (organization_id, role) values
      (v_org, 'principal'), (v_org, 'vice_principal'), (v_org, 'bursar'), (v_org, 'teacher'), (v_org, 'staff');
    v_log := v_log || E'\nPASS 05 principal invites principal, VP, bursar, teacher, staff';
  exception when others then
    v_log := v_log || E'\nFAIL 05 principal could not invite up to their level [' || sqlerrm || ']';
  end;

  -- 06 principal cannot invite an admin
  begin
    insert into public.organization_members (organization_id, role) values (v_org, 'admin');
    v_log := v_log || E'\nFAIL 06 principal invited an admin';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 06 principal cannot invite an admin [' || sqlerrm || ']';
  end;

  -- 07 principal cannot invite an owner
  begin
    insert into public.organization_members (organization_id, role) values (v_org, 'owner');
    v_log := v_log || E'\nFAIL 07 principal invited an owner';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 07 principal cannot invite an owner [' || sqlerrm || ']';
  end;

  -- 08 principal cancels an unclaimed teacher invite
  insert into public.organization_members (organization_id, role) values (v_org, 'teacher')
    returning claim_code into v_extra_claim;
  delete from public.organization_members where claim_code = v_extra_claim;
  get diagnostics v_n = row_count;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 08 principal cancels an unclaimed teacher invite';

  -- 09 principal cannot cancel an unclaimed admin invite
  delete from public.organization_members where claim_code = v_admin_invite;
  get diagnostics v_n = row_count;
  v_log := v_log || E'\n' || case when v_n = 0 then 'PASS' else 'FAIL' end || ' 09 principal cannot cancel an admin invite [' || v_n || ' rows]';

  -- 10 principal cannot change anyone's role
  update public.organization_members set role = 'admin' where clerk_user_id = 'test_principal';
  get diagnostics v_n = row_count;
  v_log := v_log || E'\n' || case when v_n = 0 then 'PASS' else 'FAIL' end || ' 10 principal cannot change roles [' || v_n || ' rows]';

  -- 11 VP invites a bursar but not an admin
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_vp","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_vp_claim);
  begin
    insert into public.organization_members (organization_id, role) values (v_org, 'bursar');
    v_log := v_log || E'\nPASS 11a VP invites a bursar';
  exception when others then
    v_log := v_log || E'\nFAIL 11a VP could not invite a bursar [' || sqlerrm || ']';
  end;
  begin
    insert into public.organization_members (organization_id, role) values (v_org, 'admin');
    v_log := v_log || E'\nFAIL 11b VP invited an admin';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 11b VP cannot invite an admin [' || sqlerrm || ']';
  end;

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
