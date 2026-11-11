-- Test for migration 30 (list_staff: search, filters, counts and pages).
--
-- How to run: paste the whole file into the Supabase SQL editor and run it.
-- It acts as several fake users, checks every rule, then raises an exception on
-- purpose so EVERYTHING is rolled back. The "error" at the end is the report.
--
-- Requires migrations 01–30.
--
-- School "Test School" (prefix TST), seen by its owner:
--   name        login                  role       type          status    phone (as saved)
--   Olu Owner   active (owner)         owner      non_teaching  active    –
--   Pat Principal active               principal  non_teaching  active    08035550142
--   Ada Ngozi Teacher  invited          teacher    teaching      active    –        SPECIAL-42, ada@school.ng
--   Bola Nologin  none                  –          non_teaching  active    +234 803 555 0143
--   Tee Teacher   suspended             teacher    teaching      active    803-555-0144
--   Lola Leave    none                  –          teaching      on_leave  –
--   Eze Exited    none                  –          non_teaching  exited    –
-- Name order: Olu (owner first), Ada, Bola, Eze, Lola, Pat, Tee.
-- created_at is spread over 7 days so "newest" is Eze, Lola, Tee, Bola, Ada, Pat, Olu.

do $test$
declare
  v_log    text := '';
  v_org    uuid;
  v_org2   uuid;
  v_claim  text;
  v_claim2 text;
  v_code   text;
  v_member public.organization_members;
  v_owner_staff uuid;
  v_pat    uuid;
  v_ada    uuid;
  v_bola   uuid;
  v_tee    uuid;
  v_lola   uuid;
  v_eze    uuid;
  v_parent uuid;
  v_res    jsonb;
  v_row    jsonb;
  v_got    text;
  v_cursor text;
  v_pages  int;
  v_ok     boolean;
  v_phone  record;
begin
  execute 'reset role';
  insert into public.platform_admins (clerk_user_id, full_name)
  values ('user_dummy_platform_admin', 'Dummy Platform Admin')
  on conflict (clerk_user_id) do nothing;

  -- first names of a list_staff result, in order, comma separated
  create function pg_temp.names(p jsonb) returns text language sql immutable as $f$
    select coalesce(string_agg(r ->> 'first_name', ',' order by o), '')
    from jsonb_array_elements(p -> 'rows') with ordinality as t(r, o);
  $f$;

  -- ── setup: two schools ──
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select c.organization_id, c.owner_claim_code into v_org,  v_claim  from public.create_organization('Test School', 'TST') c;
  select c.organization_id, c.owner_claim_code into v_org2, v_claim2 from public.create_organization('Other School', 'OTH') c;

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner_b","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_claim2, 'Bee', 'Otherowner');

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_member := public.redeem_claim_code(v_claim, 'Olu', 'Owner');
  select s.id into v_owner_staff from public.staff s where s.member_id = v_member.id;

  insert into public.staff (organization_id, first_name, last_name, job_title, staff_type, phone)
    values (v_org, 'Pat', 'Principal', 'Principal', 'non_teaching', '08035550142') returning id into v_pat;
  insert into public.staff (organization_id, first_name, middle_name, last_name, job_title, staff_number, email)
    values (v_org, 'Ada', 'Ngozi', 'Teacher', 'Teacher', 'SPECIAL-42', 'ada@school.ng') returning id into v_ada;
  insert into public.staff (organization_id, first_name, last_name, staff_type, phone)
    values (v_org, 'Bola', 'Nologin', 'non_teaching', '+234 803 555 0143') returning id into v_bola;
  insert into public.staff (organization_id, first_name, last_name, job_title, phone)
    values (v_org, 'Tee', 'Teacher', 'Teacher', '803-555-0144') returning id into v_tee;
  insert into public.staff (organization_id, first_name, last_name, status)
    values (v_org, 'Lola', 'Leave', 'on_leave') returning id into v_lola;
  insert into public.staff (organization_id, first_name, last_name, staff_type, status)
    values (v_org, 'Eze', 'Exited', 'non_teaching', 'exited') returning id into v_eze;
  insert into public.parents (organization_id, first_name, last_name, phone)
    values (v_org, 'Pam', 'Parent', '08030000000') returning id into v_parent;

  -- Pat: principal on the app
  v_code := public.invite_staff(v_pat, 'principal');
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_principal","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_code);

  -- Tee: teacher who joined, then was suspended
  execute 'reset role';
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
  update public.organization_members set status = 'suspended' where id = v_member.id;

  -- Ada: teacher invite nobody has used (code ready)
  perform public.invite_staff(v_ada, 'teacher');

  -- Pam: a parent on the app
  v_code := public.invite_parent(v_parent);
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_parent","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_code);

  -- distinct created_at (inserts in one transaction share now())
  execute 'reset role';
  update public.staff s set created_at = now() - make_interval(days => x.d)
  from (values (v_owner_staff, 7), (v_pat, 6), (v_ada, 5), (v_bola, 4), (v_tee, 3), (v_lola, 2), (v_eze, 1)) as x(id, d)
  where s.id = x.id;

  -- everything below runs as the owner unless it says otherwise
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';

  -- 01 no filters: everyone, owner first, then by name; one page
  v_res := public.list_staff(v_org);
  v_got := pg_temp.names(v_res);
  v_log := v_log || E'\n' || case when v_got = 'Olu,Ada,Bola,Eze,Lola,Pat,Tee'
                                    and (v_res ->> 'total')::int = 7
                                    and v_res -> 'next_cursor' = 'null'::jsonb
                                  then 'PASS' else 'FAIL' end || ' 01 unfiltered, owner first then name [' || v_got || ']';

  -- 02 newest first
  v_got := pg_temp.names(public.list_staff(v_org, p_sort => 'newest'));
  v_log := v_log || E'\n' || case when v_got = 'Eze,Lola,Tee,Bola,Ada,Pat,Olu' then 'PASS' else 'FAIL' end
           || ' 02 newest first [' || v_got || ']';

  -- 03 search: name part, middle name, two words, case
  v_got := pg_temp.names(public.list_staff(v_org, p_search => 'TEACH'));
  v_ok := v_got = 'Ada,Tee';
  v_got := pg_temp.names(public.list_staff(v_org, p_search => 'ngoz'));
  v_ok := v_ok and v_got = 'Ada';
  v_got := pg_temp.names(public.list_staff(v_org, p_search => '  ada   teacher '));
  v_ok := v_ok and v_got = 'Ada';
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 03 search by name part, middle name, words';

  -- 04 search: phone in every format finds the same person, however it was saved
  v_ok := true;
  for v_phone in
    select * from (values
      ('0803 555 0142', 'Pat'), ('8035550142', 'Pat'), ('+2348035550142', 'Pat'),
      ('0803 555 0143', 'Bola'), ('8035550143', 'Bola'), ('+2348035550143', 'Bola'),
      ('0803 555 0144', 'Tee'), ('8035550144', 'Tee'), ('+234 803 555 0144', 'Tee'),
      ('555 014', 'Bola,Pat,Tee'), ('0144', 'Tee')
    ) as t(term, expect)
  loop
    v_got := pg_temp.names(public.list_staff(v_org, p_search => v_phone.term));
    if v_got <> v_phone.expect then
      v_ok := false;
      v_log := v_log || E'\n   phone "' || v_phone.term || '" gave [' || v_got || ']';
    end if;
  end loop;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 04 phone variants match';

  -- 05 search: staff number, generated number, email; LIKE wildcards are literal
  v_ok := pg_temp.names(public.list_staff(v_org, p_search => 'special-4')) = 'Ada';
  v_ok := v_ok and pg_temp.names(public.list_staff(v_org, p_search => 'ADA@SCHOOL')) = 'Ada';
  v_ok := v_ok and (public.list_staff(v_org, p_search => 'tst/stf/') ->> 'total')::int = 6;
  v_ok := v_ok and (public.list_staff(v_org, p_search => '%') ->> 'total')::int = 0;
  v_ok := v_ok and (public.list_staff(v_org, p_search => '_') ->> 'total')::int = 0;
  v_ok := v_ok and (public.list_staff(v_org, p_search => '   ') ->> 'total')::int = 7;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 05 staff number, email, literal % and _, blank search';

  -- 06 each login filter
  v_ok := pg_temp.names(public.list_staff(v_org, p_login => 'on_app')) = 'Olu,Pat';
  v_ok := v_ok and pg_temp.names(public.list_staff(v_org, p_login => 'code_ready')) = 'Ada';
  v_ok := v_ok and pg_temp.names(public.list_staff(v_org, p_login => 'not_on_app')) = 'Bola,Eze,Lola';
  v_ok := v_ok and pg_temp.names(public.list_staff(v_org, p_login => 'suspended')) = 'Tee';
  v_ok := v_ok and (public.list_staff(v_org, p_login => 'all') ->> 'total')::int = 7;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 06 login filters';

  -- 07 roles: only people with a login, any login status
  v_ok := pg_temp.names(public.list_staff(v_org, p_roles => array['teacher']::public.member_role[])) = 'Ada,Tee';
  v_ok := v_ok and pg_temp.names(public.list_staff(v_org, p_roles => array['owner', 'principal']::public.member_role[])) = 'Olu,Pat';
  v_ok := v_ok and (public.list_staff(v_org, p_roles => array['bursar']::public.member_role[]) ->> 'total')::int = 0;
  v_ok := v_ok and (public.list_staff(v_org, p_roles => array[]::public.member_role[]) ->> 'total')::int = 7;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 07 roles filter';

  -- 08 staff type
  v_ok := pg_temp.names(public.list_staff(v_org, p_staff_type => 'non_teaching')) = 'Olu,Bola,Eze,Pat';
  v_ok := v_ok and pg_temp.names(public.list_staff(v_org, p_staff_type => 'teaching')) = 'Ada,Lola,Tee';
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 08 staff type';

  -- 09 record statuses: null and {} are all
  v_ok := pg_temp.names(public.list_staff(v_org, p_statuses => array['active']::public.staff_status[])) = 'Olu,Ada,Bola,Pat,Tee';
  v_ok := v_ok and pg_temp.names(public.list_staff(v_org, p_statuses => array['on_leave', 'exited']::public.staff_status[])) = 'Eze,Lola';
  v_ok := v_ok and (public.list_staff(v_org, p_statuses => array[]::public.staff_status[]) ->> 'total')::int = 7;
  v_ok := v_ok and (public.list_staff(v_org, p_statuses => null) ->> 'total')::int = 7;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 09 record statuses';

  -- 10 pages of 2 by name: no duplicates or gaps, cursor null at the end
  v_got := '';
  v_cursor := null;
  v_pages := 0;
  loop
    v_res := public.list_staff(v_org, p_limit => 2, p_cursor => v_cursor);
    v_pages := v_pages + 1;
    v_got := v_got || case when v_got = '' then '' else ',' end || pg_temp.names(v_res);
    v_cursor := v_res ->> 'next_cursor';
    exit when v_cursor is null or v_pages > 10;
  end loop;
  v_log := v_log || E'\n' || case when v_got = 'Olu,Ada,Bola,Eze,Lola,Pat,Tee' and v_pages = 4 then 'PASS' else 'FAIL' end
           || ' 10 name pages of 2 [' || v_got || ' in ' || v_pages || ' pages]';

  -- 11 pages of 3, newest, with a filter; a full last page still ends with null
  v_got := '';
  v_cursor := null;
  v_pages := 0;
  loop
    v_res := public.list_staff(v_org, p_sort => 'newest', p_limit => 3, p_cursor => v_cursor);
    v_pages := v_pages + 1;
    v_got := v_got || case when v_got = '' then '' else ',' end || pg_temp.names(v_res);
    v_cursor := v_res ->> 'next_cursor';
    exit when v_cursor is null or v_pages > 10;
  end loop;
  v_ok := v_got = 'Eze,Lola,Tee,Bola,Ada,Pat,Olu' and v_pages = 3;
  v_res := public.list_staff(v_org, p_statuses => array['active']::public.staff_status[], p_limit => 5);
  v_ok := v_ok and jsonb_array_length(v_res -> 'rows') = 5 and v_res -> 'next_cursor' = 'null'::jsonb;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 11 newest pages of 3, exact last page [' || v_got || ']';

  -- 12 counts ignore the login filter but follow status; total follows everything
  v_res := public.list_staff(v_org, p_login => 'suspended', p_statuses => array['active']::public.staff_status[]);
  v_log := v_log || E'\n' || case when pg_temp.names(v_res) = 'Tee'
                                    and (v_res ->> 'total')::int = 1
                                    and v_res -> 'counts' = '{"all":5,"on_app":2,"code_ready":1,"not_on_app":1,"suspended":1}'::jsonb
                                  then 'PASS' else 'FAIL' end || ' 12 counts ignore login filter ' || (v_res -> 'counts')::text;

  -- 13 counts follow search, type and roles
  v_res := public.list_staff(v_org, p_search => 'teacher', p_login => 'on_app');
  v_ok := (v_res ->> 'total')::int = 0
      and v_res -> 'counts' = '{"all":2,"on_app":0,"code_ready":1,"not_on_app":0,"suspended":1}'::jsonb;
  v_res := public.list_staff(v_org, p_staff_type => 'non_teaching', p_roles => array['owner', 'principal']::public.member_role[]);
  v_ok := v_ok and v_res -> 'counts' = '{"all":2,"on_app":2,"code_ready":0,"not_on_app":0,"suspended":0}'::jsonb;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 13 counts follow search, type and roles';

  -- 14 row shape: what StaffMember.fromJson reads, no private details (and, since
  -- migration 37, a null `teaching` key)
  v_res := public.list_staff(v_org, p_search => 'ngozi');
  v_row := v_res -> 'rows' -> 0;
  v_ok := (select array_agg(k order by k) from jsonb_object_keys(v_row) k)
          = array['created_at', 'email', 'first_name', 'gender', 'id', 'job_title', 'last_name', 'member', 'member_id',
                  'middle_name', 'phone', 'photo_url', 'staff_number', 'staff_type', 'status', 'teaching']
      -- migration 37: `teaching` is there but null unless a subject or class filter is on
      and v_row -> 'teaching' = 'null'::jsonb
      and (select array_agg(k order by k) from jsonb_object_keys(v_row -> 'member') k)
          = array['claim_code', 'clerk_user_id', 'created_at', 'id', 'joined_at', 'role', 'status']
      and v_row ->> 'id' = v_ada::text
      and v_row -> 'member' ->> 'role' = 'teacher'
      and v_row -> 'member' ->> 'status' = 'invited'
      and length(v_row -> 'member' ->> 'claim_code') = 8
      and v_row ->> 'member_id' = v_row -> 'member' ->> 'id';
  v_row := (public.list_staff(v_org, p_search => 'bola') -> 'rows' -> 0);
  v_ok := v_ok and v_row -> 'member' = 'null'::jsonb;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 14 row keys, member embedded or null';

  -- 15 limit is clamped to 1..100
  v_res := public.list_staff(v_org, p_limit => 0);
  v_ok := jsonb_array_length(v_res -> 'rows') = 1 and v_res ->> 'next_cursor' is not null;
  v_res := public.list_staff(v_org, p_limit => -5);
  v_ok := v_ok and jsonb_array_length(v_res -> 'rows') = 1;
  v_res := public.list_staff(v_org, p_limit => 1000);
  v_ok := v_ok and jsonb_array_length(v_res -> 'rows') = 7 and v_res -> 'next_cursor' = 'null'::jsonb;
  v_res := public.list_staff(v_org, p_limit => null);
  v_ok := v_ok and jsonb_array_length(v_res -> 'rows') = 7;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 15 limit clamped';

  -- 16 bad arguments are refused with 22023
  v_ok := true;
  begin
    perform public.list_staff(v_org, p_login => 'everyone');
    v_ok := false;
  exception when others then
    v_ok := v_ok and sqlstate = '22023';
  end;
  begin
    perform public.list_staff(v_org, p_sort => 'oldest');
    v_ok := false;
  exception when others then
    v_ok := v_ok and sqlstate = '22023';
  end;
  begin
    perform public.list_staff(v_org, p_cursor => 'not a cursor!');
    v_ok := false;
  exception when others then
    v_ok := v_ok and sqlstate = '22023';
  end;
  begin
    -- a name cursor used with the newest sort
    v_cursor := public.list_staff(v_org, p_limit => 2) ->> 'next_cursor';
    perform public.list_staff(v_org, p_sort => 'newest', p_cursor => v_cursor);
    v_ok := false;
  exception when others then
    v_ok := v_ok and sqlstate = '22023';
  end;
  begin
    perform public.list_staff(null);
    v_ok := false;
  exception when others then
    v_ok := v_ok and sqlstate = '22023';
  end;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 16 bad login, sort, cursor and school refused';

  -- 17 a parent sees every profile but no one's login
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_parent","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_res := public.list_staff(v_org);
  v_log := v_log || E'\n' || case when (v_res ->> 'total')::int = 7
                                    and not exists (select 1 from jsonb_array_elements(v_res -> 'rows') r
                                                    where r -> 'member' <> 'null'::jsonb)
                                    and (v_res -> 'counts' ->> 'not_on_app')::int = 7
                                  then 'PASS' else 'FAIL' end || ' 17 parent sees staff, member null [' || pg_temp.names(v_res) || ']';

  -- 18 another school's owner, a stranger and the suspended teacher get nothing
  v_ok := true;
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner_b","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_res := public.list_staff(v_org);
  v_ok := (v_res ->> 'total')::int = 0 and v_res -> 'rows' = '[]'::jsonb and (v_res -> 'counts' ->> 'all')::int = 0;
  v_ok := v_ok and pg_temp.names(public.list_staff(v_org2)) = 'Bee';
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_stranger","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_ok := v_ok and (public.list_staff(v_org) ->> 'total')::int = 0;
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_teacher","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_ok := v_ok and (public.list_staff(v_org) ->> 'total')::int = 0;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 18 other school, stranger and suspended login see nothing';

  -- 19 anon can't call it
  execute 'reset role';
  execute 'set local role anon';
  begin
    perform public.list_staff(v_org);
    v_log := v_log || E'\nFAIL 19 anon called list_staff';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 19 anon refused [' || sqlerrm || ']';
  end;

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
