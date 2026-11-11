-- Access test for migration 35 (add_member_role: a second role for a staff
-- member already on the app, with no new code).
--
-- How to run: paste the whole file into the Supabase SQL editor and run it.
-- It acts as several fake users, checks every rule, then raises an exception on
-- purpose so EVERYTHING is rolled back. The "error" at the end is the report.
--
-- Requires migrations 01–35.
--
-- School "Test School" (TST): owner Olu, principal Pat, teacher Tee and
-- teacher Sue on the app; bursar Bea invited but not joined.
-- "Other School" (OTH): owner Oma on the app.

do $test$
declare
  v_log     text := '';
  v_n       int;
  v_org     uuid;  v_claim  text;
  v_org2    uuid;  v_claim2 text;
  v_code    text;
  v_owner   public.organization_members;
  v_owner2  public.organization_members;
  v_pat_m   public.organization_members;
  v_tee_m   public.organization_members;
  v_sue_m   public.organization_members;
  v_new     public.organization_members;
  v_pat     uuid;
  v_tee     uuid;
  v_sue     uuid;
  v_bea     uuid;
  v_bea_m   uuid;
begin
  execute 'reset role';
  insert into public.platform_admins (clerk_user_id, full_name)
  values ('user_dummy_platform_admin', 'Dummy Platform Admin')
  on conflict (clerk_user_id) do nothing;

  -- ── setup: two schools ──
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select c.organization_id, c.owner_claim_code into v_org,  v_claim  from public.create_organization('Test School', 'TST') c;
  select c.organization_id, c.owner_claim_code into v_org2, v_claim2 from public.create_organization('Other School', 'OTH') c;

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner2","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_owner2 := public.redeem_claim_code(v_claim2, 'Oma', 'Owner');

  -- ── setup: Test School's team ──
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_owner := public.redeem_claim_code(v_claim, 'Olu', 'Owner');
  insert into public.staff (organization_id, first_name, last_name) values (v_org, 'Pat', 'Principal') returning id into v_pat;
  insert into public.staff (organization_id, first_name, last_name) values (v_org, 'Tee', 'Teacher')   returning id into v_tee;
  insert into public.staff (organization_id, first_name, last_name) values (v_org, 'Sue', 'Teacher')   returning id into v_sue;
  insert into public.staff (organization_id, first_name, last_name) values (v_org, 'Bea', 'Bursar')    returning id into v_bea;

  v_code := public.invite_staff(v_pat, 'principal');
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_principal","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_pat_m := public.redeem_claim_code(v_code);

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_code := public.invite_staff(v_tee, 'teacher');
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_teacher","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_tee_m := public.redeem_claim_code(v_code);

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_code := public.invite_staff(v_sue, 'teacher');
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_sue","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_sue_m := public.redeem_claim_code(v_code);

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.invite_staff(v_bea, 'bursar');
  execute 'reset role';
  select s.member_id into v_bea_m from public.staff s where s.id = v_bea;

  -- 01 the owner gives the principal a teacher role
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_new := public.add_member_role(v_pat_m.id, 'teacher');
  execute 'reset role';
  select count(*) into v_n from public.organization_members m
    where m.id = v_new.id
      and m.organization_id = v_org
      and m.clerk_user_id = 'test_principal'
      and m.role = 'teacher'
      and m.status = 'active'
      and m.claim_code is null
      and m.joined_at = v_pat_m.joined_at
      and m.invited_by = 'test_owner';
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 01 owner adds a teacher role to the principal';

  -- 02 staff.member_id still points at the principal row
  select count(*) into v_n from public.staff s where s.id = v_pat and s.member_id = v_pat_m.id;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 02 staff record keeps its member_id';

  -- 03 the new role is live: the principal's teacher membership counts
  perform set_config('request.jwt.claims', '{"sub":"test_principal","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select count(*) into v_n from private.my_org_ids(array['teacher']::public.member_role[]) o where o = v_org;
  execute 'reset role';
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 03 the added role is active for the person';

  -- 04 a principal adds a bursar role to a teacher (within their tier)
  perform set_config('request.jwt.claims', '{"sub":"test_principal","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    v_new := public.add_member_role(v_tee_m.id, 'bursar');
    execute 'reset role';
    select count(*) into v_n from public.organization_members m
      where m.id = v_new.id and m.clerk_user_id = 'test_teacher' and m.role = 'bursar' and m.status = 'active'
        and m.invited_by = 'test_principal';
    v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 04 principal adds a bursar role';
  exception when others then
    execute 'reset role';
    v_log := v_log || E'\nFAIL 04 principal adds a bursar role [' || sqlerrm || ']';
  end;

  -- 05 a principal can't add an admin role
  perform set_config('request.jwt.claims', '{"sub":"test_principal","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    perform public.add_member_role(v_tee_m.id, 'admin');
    v_log := v_log || E'\nFAIL 05 principal added an admin role';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 05 principal cannot add admin [' || sqlerrm || ']';
  end;
  execute 'reset role';

  -- 06 a teacher can't add roles at all
  perform set_config('request.jwt.claims', '{"sub":"test_teacher","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    perform public.add_member_role(v_sue_m.id, 'staff');
    v_log := v_log || E'\nFAIL 06 teacher added a role';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 06 teacher cannot add roles [' || sqlerrm || ']';
  end;
  execute 'reset role';

  -- 07 someone not on the app yet (an unclaimed invite) is refused
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    perform public.add_member_role(v_bea_m, 'teacher');
    v_log := v_log || E'\nFAIL 07 added a role to an invite';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = 'P0001' and sqlerrm like '%isn''t on the app yet%' then 'PASS' else 'FAIL' end
      || ' 07 not-yet-active source refused [' || sqlerrm || ']';
  end;

  -- 08 a role they already hold is refused readably
  begin
    perform public.add_member_role(v_pat_m.id, 'teacher');
    v_log := v_log || E'\nFAIL 08 added a duplicate role';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = 'P0001' and sqlerrm like '%already have the teacher role at%' then 'PASS' else 'FAIL' end
      || ' 08 duplicate role refused [' || sqlerrm || ']';
  end;

  -- 09 the same, asked from the other membership row
  begin
    perform public.add_member_role(v_new.id, 'teacher');  -- v_new is Tee's bursar row
    v_log := v_log || E'\nFAIL 09 added a duplicate role from the second row';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = 'P0001' then 'PASS' else 'FAIL' end || ' 09 duplicate from the other row refused [' || sqlerrm || ']';
  end;

  -- 10 owner is never added
  begin
    perform public.add_member_role(v_pat_m.id, 'owner');
    v_log := v_log || E'\nFAIL 10 added the owner role';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 10 owner role refused [' || sqlerrm || ']';
  end;

  -- 11 parent and student aren't staff roles
  begin
    perform public.add_member_role(v_pat_m.id, 'parent');
    v_log := v_log || E'\nFAIL 11 added a parent role';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '22023' then 'PASS' else 'FAIL' end || ' 11 parent role refused [' || sqlerrm || ']';
  end;

  -- 12 a suspended source is refused
  update public.organization_members set status = 'suspended' where id = v_sue_m.id;
  begin
    perform public.add_member_role(v_sue_m.id, 'staff');
    v_log := v_log || E'\nFAIL 12 added a role to a suspended login';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = 'P0001' and sqlerrm like '%suspended%' then 'PASS' else 'FAIL' end
      || ' 12 suspended source refused [' || sqlerrm || ']';
  end;

  -- 13 a role they hold but is suspended: restore it instead
  update public.organization_members set status = 'suspended'
    where clerk_user_id = 'test_principal' and organization_id = v_org and role = 'teacher';
  begin
    perform public.add_member_role(v_pat_m.id, 'teacher');
    v_log := v_log || E'\nFAIL 13 re-added a suspended role';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = 'P0001' and sqlerrm like '%Restore%' then 'PASS' else 'FAIL' end
      || ' 13 suspended existing role refused [' || sqlerrm || ']';
  end;
  execute 'reset role';

  -- 14 another school's owner can't add a role at this school
  perform set_config('request.jwt.claims', '{"sub":"test_owner2","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    perform public.add_member_role(v_tee_m.id, 'staff');
    v_log := v_log || E'\nFAIL 14 another school added a role here';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 14 cross-school refused [' || sqlerrm || ']';
  end;
  execute 'reset role';

  -- 15 nor can this school's owner add one at the other school
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    perform public.add_member_role(v_owner2.id, 'teacher');
    v_log := v_log || E'\nFAIL 15 added a role at another school';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 15 cross-school refused (other way) [' || sqlerrm || ']';
  end;
  execute 'reset role';

  -- 16 Hamrash platform admins aren't school members, so they're refused too
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    perform public.add_member_role(v_tee_m.id, 'staff');
    v_log := v_log || E'\nFAIL 16 platform admin added a role';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 16 platform admin refused [' || sqlerrm || ']';
  end;
  execute 'reset role';

  -- 17 the owner can add a role to their own login
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    v_new := public.add_member_role(v_owner.id, 'teacher');
    v_log := v_log || E'\n' || case when v_new.role = 'teacher' and v_new.clerk_user_id = 'test_owner' then 'PASS' else 'FAIL' end
      || ' 17 owner adds a teacher role to themselves';
  exception when others then
    v_log := v_log || E'\nFAIL 17 owner adds a teacher role to themselves [' || sqlerrm || ']';
  end;
  execute 'reset role';

  -- 18 a staff member who has left is refused
  update public.staff set status = 'exited' where id = v_tee;
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    perform public.add_member_role(v_tee_m.id, 'staff');
    v_log := v_log || E'\nFAIL 18 added a role to someone who left';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = 'P0001' and sqlerrm like '%left the school%' then 'PASS' else 'FAIL' end
      || ' 18 exited staff refused [' || sqlerrm || ']';
  end;
  execute 'reset role';

  -- 19 anon can't call it
  execute 'set local role anon';
  begin
    perform public.add_member_role(v_tee_m.id, 'staff');
    v_log := v_log || E'\nFAIL 19 anon called add_member_role';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 19 anon has no execute [' || sqlerrm || ']';
  end;

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
