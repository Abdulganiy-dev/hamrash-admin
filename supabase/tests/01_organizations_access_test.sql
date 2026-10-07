-- Access test for migration 01 (organizations, members, platform admins).
--
-- How to run: paste the whole file into the Supabase SQL editor and run it.
-- It acts as several fake users (via request.jwt.claims + set role), checks every
-- rule, then raises an exception on purpose so EVERYTHING is rolled back.
-- The "error" you see at the end is the report: each line is PASS or FAIL.
--
-- Uses create_organization(name, number_prefix, ...) as changed in migration 03.
--
-- Requires the dummy platform admin row:
--   insert into public.platform_admins (clerk_user_id, full_name, email)
--   values ('user_dummy_platform_admin', 'Dummy Platform Admin', 'dummy-platform-admin@example.com');

do $test$
declare
  v_log    text := '';
  v_org    uuid;
  v_code   text;
  v_claim  text;
  v_org2   uuid;
  v_claim2 text;
  v_admin_claim   text;
  v_teacher_claim text;
  v_extra_claim   text;
  v_invited_by    text;
  v_member public.organization_members;
  v_n      int;
begin
  -- 01 outsider cannot create a school
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_outsider","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    perform public.create_organization('Nope School', 'NOP');
    v_log := v_log || E'\nFAIL 01 outsider created a school';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 01 outsider cannot create school [' || sqlerrm || ']';
  end;

  -- 02 platform admin creates two schools
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select c.organization_id, c.organization_code, c.owner_claim_code into v_org, v_code, v_claim
    from public.create_organization('Test School', 'TST', 'a@b.c') c;
  select c.organization_id, c.owner_claim_code into v_org2, v_claim2
    from public.create_organization('Other School', 'OTH') c;
  v_log := v_log || E'\n' || case when v_code ~ '^HMR-[A-Z0-9]{6}$' and v_claim ~ '^[A-Z0-9]{8}$' then 'PASS' else 'FAIL' end
        || ' 02 platform admin creates school [code ' || v_code || ', owner claim ' || v_claim || ']';

  -- 03 owner redeems (lowercase + dash accepted)
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_member := public.redeem_claim_code(lower(substr(v_claim, 1, 4) || '-' || substr(v_claim, 5, 4)));
  v_log := v_log || E'\n' || case when v_member.status = 'active' and v_member.role = 'owner'
        and v_member.clerk_user_id = 'test_owner' and v_member.claim_code is null and v_member.joined_at is not null
        then 'PASS' else 'FAIL' end || ' 03 owner redeems claim code (lowercase, with dash)';

  -- 04 code cannot be reused
  begin
    perform public.redeem_claim_code(v_claim);
    v_log := v_log || E'\nFAIL 04 claim code reused';
  exception when others then
    v_log := v_log || E'\n' || case when sqlerrm like '%invalid or has already been used%' then 'PASS' else 'FAIL' end || ' 04 claim code cannot be reused [' || sqlerrm || ']';
  end;

  -- 05 owner sees only their own school
  select count(*) into v_n from public.organizations;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 05 owner sees only own school [' || v_n || ' rows]';

  -- 06 owner renames school
  update public.organizations set name = 'Renamed School' where id = v_org;
  get diagnostics v_n = row_count;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 06 owner can edit school details';

  -- 07 owner cannot change status
  begin
    update public.organizations set status = 'active' where id = v_org;
    v_log := v_log || E'\nFAIL 07 owner changed school status';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 07 owner cannot change school status [' || sqlerrm || ']';
  end;

  -- 08 owner invites an admin; claim code + invited_by filled in
  insert into public.organization_members (organization_id, role) values (v_org, 'admin')
    returning claim_code, invited_by into v_admin_claim, v_invited_by;
  v_log := v_log || E'\n' || case when v_admin_claim ~ '^[A-Z0-9]{8}$' and v_invited_by = 'test_owner' then 'PASS' else 'FAIL' end
        || ' 08 owner invites admin [claim ' || coalesce(v_admin_claim, 'null') || ', invited_by ' || coalesce(v_invited_by, 'null') || ']';

  -- 09 owner cannot create an owner invite
  begin
    insert into public.organization_members (organization_id, role) values (v_org, 'owner');
    v_log := v_log || E'\nFAIL 09 owner created owner invite';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 09 only platform admins invite owners [' || sqlerrm || ']';
  end;

  -- 10 owner cannot invite into another school
  begin
    insert into public.organization_members (organization_id, role) values (v_org2, 'teacher');
    v_log := v_log || E'\nFAIL 10 owner invited into another school';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 10 cannot invite into another school [' || sqlerrm || ']';
  end;

  -- 11 clients cannot write clerk_user_id
  begin
    update public.organization_members set clerk_user_id = 'someone_else' where organization_id = v_org;
    v_log := v_log || E'\nFAIL 11 client wrote clerk_user_id';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 11 clients cannot write clerk_user_id [' || sqlerrm || ']';
  end;

  -- 12 admin redeems, then invites a teacher
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_member := public.redeem_claim_code(v_admin_claim);
  insert into public.organization_members (organization_id, role) values (v_org, 'teacher')
    returning claim_code into v_teacher_claim;
  v_log := v_log || E'\n' || case when v_member.role = 'admin' and v_member.status = 'active' and v_teacher_claim is not null then 'PASS' else 'FAIL' end
        || ' 12 admin redeems and invites a teacher';

  -- 13 admin cannot promote self to owner
  begin
    update public.organization_members set role = 'owner' where clerk_user_id = 'test_admin';
    v_log := v_log || E'\nFAIL 13 admin promoted self to owner';
  exception when others then
    v_log := v_log || E'\n' || case when sqlerrm like 'Only an owner%' then 'PASS' else 'FAIL' end || ' 13 admin cannot promote self to owner [' || sqlerrm || ']';
  end;

  -- 14 admin cannot suspend the owner
  begin
    update public.organization_members set status = 'suspended' where clerk_user_id = 'test_owner';
    v_log := v_log || E'\nFAIL 14 admin suspended owner';
  exception when others then
    v_log := v_log || E'\n' || case when sqlerrm like 'Only an owner%' then 'PASS' else 'FAIL' end || ' 14 admin cannot suspend owner [' || sqlerrm || ']';
  end;

  -- 15 last owner cannot demote self
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    update public.organization_members set role = 'admin' where clerk_user_id = 'test_owner';
    v_log := v_log || E'\nFAIL 15 last owner demoted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlerrm like '%at least one active owner%' then 'PASS' else 'FAIL' end || ' 15 school keeps its last owner [' || sqlerrm || ']';
  end;

  -- 16 owner deletes an unclaimed invite, but not an active member
  insert into public.organization_members (organization_id, role) values (v_org, 'staff') returning claim_code into v_extra_claim;
  delete from public.organization_members where claim_code = v_extra_claim;
  get diagnostics v_n = row_count;
  delete from public.organization_members where clerk_user_id = 'test_admin';
  v_log := v_log || E'\n' || case when v_n = 1 and exists (select 1 from public.organization_members where clerk_user_id = 'test_admin') then 'PASS' else 'FAIL' end
        || ' 16 delete works on unclaimed invites only';

  -- 17 owner invites a second teacher (used in 19 and 23)
  insert into public.organization_members (organization_id, role) values (v_org, 'teacher') returning claim_code into v_extra_claim;

  -- 18 teacher redeems; sees own membership only; reads school; cannot edit it
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_teacher","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_member := public.redeem_claim_code(v_teacher_claim);
  select count(*) into v_n from public.organization_members;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 18a teacher sees only own membership [' || v_n || ' rows]';
  select count(*) into v_n from public.organizations;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 18b teacher can read own school [' || v_n || ' rows]';
  update public.organizations set name = 'Hacked' where id = v_org;
  get diagnostics v_n = row_count;
  v_log := v_log || E'\n' || case when v_n = 0 then 'PASS' else 'FAIL' end || ' 18c teacher cannot edit school';

  -- 19 same person cannot claim the same role twice in one school
  begin
    perform public.redeem_claim_code(v_extra_claim);
    v_log := v_log || E'\nFAIL 19 same role claimed twice';
  exception when others then
    v_log := v_log || E'\n' || case when sqlerrm like '%already have this role%' then 'PASS' else 'FAIL' end || ' 19 cannot hold same role twice [' || sqlerrm || ']';
  end;

  -- 20 platform admin sees every school, then suspends Test School
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select count(*) into v_n from public.organizations;
  v_log := v_log || E'\n' || case when v_n = 2 then 'PASS' else 'FAIL' end || ' 20a platform admin sees all schools [' || v_n || ' rows]';
  perform public.set_organization_status(v_org, 'suspended');
  v_log := v_log || E'\nPASS 20b platform admin suspends school';

  -- 21 suspended school: teacher still sees the school row, but no data access
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_teacher","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select count(*) into v_n from public.organizations;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 21a suspended school row still visible to member';
  select count(*) into v_n from private.my_org_ids();
  v_log := v_log || E'\n' || case when v_n = 0 then 'PASS' else 'FAIL' end || ' 21b suspended school grants no data access [' || v_n || ' orgs]';

  -- 22 owner of suspended school cannot edit it
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  update public.organizations set name = 'X' where id = v_org;
  get diagnostics v_n = row_count;
  v_log := v_log || E'\n' || case when v_n = 0 then 'PASS' else 'FAIL' end || ' 22 suspended school cannot be edited';

  -- 23 claim codes for a suspended school don't work
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_outsider","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    perform public.redeem_claim_code(v_extra_claim);
    v_log := v_log || E'\nFAIL 23 redeemed into suspended school';
  exception when others then
    v_log := v_log || E'\n' || case when sqlerrm like '%not currently active%' then 'PASS' else 'FAIL' end || ' 23 suspended school codes rejected [' || sqlerrm || ']';
  end;

  -- 24 anon has no access
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  execute 'set local role anon';
  begin
    perform count(*) from public.organizations;
    v_log := v_log || E'\nFAIL 24a anon read organizations';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 24a anon cannot read organizations [' || sqlerrm || ']';
  end;
  begin
    perform public.create_organization('Anon School', 'ANO');
    v_log := v_log || E'\nFAIL 24b anon called create_organization';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 24b anon cannot call RPCs [' || sqlerrm || ']';
  end;

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
