-- Test for migration 37 (list_staff filtered by the subject a teacher teaches,
-- and where).
--
-- How to run: paste the whole file into the Supabase SQL editor and run it.
-- It acts as several fake users, checks every rule, then raises an exception on
-- purpose so EVERYTHING is rolled back. The "error" at the end is the report.
--
-- Requires migrations 01–37.
--
-- School "Test School" (prefix TST), session 2026/2027 (current):
--   classes   JSS 1 (arms A, B), JSS 2 (arm A)
--   subjects  Mathematics (every arm), Art (offered in 1A)
--   teaching  Ada:  Mathematics in 1A and in 2A   (two classes, ONE person)
--             Bayo: Mathematics in 1B, Art in 1A  (two subjects)
--             Cleo: a teacher with no assignment at all
--   plus the owner's own staff record (Olu). Name order: Olu, Ada, Bayo, Cleo.

do $test$
declare
  v_log     text := '';
  v_org     uuid;
  v_org2    uuid;
  v_claim   text;
  v_claim2  text;
  v_section uuid;
  v_jss1    uuid;
  v_jss2    uuid;
  v_arm_1a  uuid;
  v_arm_1b  uuid;
  v_arm_2a  uuid;
  v_session uuid;
  v_term    uuid;
  v_ada     uuid;
  v_bayo    uuid;
  v_cleo    uuid;
  v_maths   uuid;
  v_art     uuid;
  v_res     jsonb;
  v_row     jsonb;
  v_got     text;
  v_seen    text;
  v_cursor  text;
  v_pages   int;
  v_ok      boolean;
begin
  execute 'reset role';
  insert into public.platform_admins (clerk_user_id, full_name)
  values ('user_dummy_platform_admin', 'Dummy Platform Admin')
  on conflict (clerk_user_id) do nothing;

  create function pg_temp.names(p jsonb) returns text language sql immutable as $f$
    select coalesce(string_agg(r ->> 'first_name', ',' order by o), '')
    from jsonb_array_elements(p -> 'rows') with ordinality as t(r, o);
  $f$;

  -- "JSS 1 A:Mathematics" for each entry of a row's teaching list
  create function pg_temp.teaching(p jsonb, p_first text) returns text language sql immutable as $f$
    select coalesce(string_agg((a ->> 'class_name') || ' ' || (a ->> 'arm_name') || ':' || (a ->> 'subject_name'), ',' order by o), 'none')
    from jsonb_array_elements(p -> 'rows') r,
         jsonb_array_elements(r -> 'teaching') with ordinality as t(a, o)
    where r ->> 'first_name' = p_first;
  $f$;

  -- ── setup ──
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
  perform public.redeem_claim_code(v_claim, 'Olu', 'Owner');

  insert into public.sections (organization_id, name) values (v_org, 'Secondary') returning id into v_section;
  insert into public.classes (organization_id, section_id, name, sort_order) values (v_org, v_section, 'JSS 1', 1) returning id into v_jss1;
  insert into public.classes (organization_id, section_id, name, sort_order) values (v_org, v_section, 'JSS 2', 2) returning id into v_jss2;
  insert into public.class_arms (organization_id, class_id, name) values (v_org, v_jss1, 'A') returning id into v_arm_1a;
  insert into public.class_arms (organization_id, class_id, name) values (v_org, v_jss1, 'B') returning id into v_arm_1b;
  insert into public.class_arms (organization_id, class_id, name) values (v_org, v_jss2, 'A') returning id into v_arm_2a;
  insert into public.academic_sessions (organization_id, name, starts_on, ends_on)
    values (v_org, '2026/2027', '2026-09-01', '2027-07-31') returning id into v_session;
  insert into public.academic_terms (organization_id, session_id, name, sequence, starts_on, ends_on)
    values (v_org, v_session, 'First Term', 1, '2026-09-07', '2026-12-18') returning id into v_term;
  perform public.set_current_term(v_term);

  insert into public.staff (organization_id, first_name, last_name, job_title, staff_type)
    values (v_org, 'Ada', 'Bello', 'Teacher', 'teaching') returning id into v_ada;
  insert into public.staff (organization_id, first_name, last_name, job_title, staff_type)
    values (v_org, 'Bayo', 'Cole', 'Teacher', 'teaching') returning id into v_bayo;
  insert into public.staff (organization_id, first_name, last_name, job_title, staff_type)
    values (v_org, 'Cleo', 'Dada', 'Teacher', 'teaching') returning id into v_cleo;

  insert into public.subjects (organization_id, name, code) values (v_org, 'Mathematics', 'MTH') returning id into v_maths;
  insert into public.subjects (organization_id, name, code) values (v_org, 'Art', 'ART') returning id into v_art;
  insert into public.arm_subjects (organization_id, arm_id, subject_id)
    values (v_org, v_arm_1a, v_maths), (v_org, v_arm_1b, v_maths), (v_org, v_arm_2a, v_maths), (v_org, v_arm_1a, v_art);
  insert into public.teaching_assignments (organization_id, session_id, arm_id, subject_id, staff_id)
    values (v_org, v_session, v_arm_1a, v_maths, v_ada),
           (v_org, v_session, v_arm_2a, v_maths, v_ada),
           (v_org, v_session, v_arm_1b, v_maths, v_bayo),
           (v_org, v_session, v_arm_1a, v_art,   v_bayo);

  -- 01 Mathematics: both teachers, once each; every call that worked before still works
  v_res := public.list_staff(v_org, p_subject_id => v_maths);
  v_log := v_log || E'\n' || case when pg_temp.names(v_res) = 'Ada,Bayo' and (v_res ->> 'total')::int = 2
                                    and (v_res -> 'counts' ->> 'all')::int = 2
                                  then 'PASS' else 'FAIL' end || ' 01 teachers of Mathematics [' || pg_temp.names(v_res) || ']';

  -- 02 each teacher shows the classes where they teach Mathematics, and only that
  v_got := pg_temp.teaching(v_res, 'Ada') || ' | ' || pg_temp.teaching(v_res, 'Bayo');
  v_log := v_log || E'\n' || case when v_got = 'JSS 1 A:Mathematics,JSS 2 A:Mathematics | JSS 1 B:Mathematics'
                                  then 'PASS' else 'FAIL' end || ' 02 teacher, subject and class [' || v_got || ']';

  -- 03 Art: Bayo, with the one class (not his Mathematics)
  v_res := public.list_staff(v_org, p_subject_id => v_art);
  v_log := v_log || E'\n' || case when pg_temp.names(v_res) = 'Bayo' and pg_temp.teaching(v_res, 'Bayo') = 'JSS 1 A:Art'
                                  then 'PASS' else 'FAIL' end || ' 03 a teacher of two subjects shows the one asked for';

  -- 04 class and section: the same assignment must match both
  v_ok := pg_temp.names(public.list_staff(v_org, p_class_id => v_jss2)) = 'Ada';
  v_ok := v_ok and pg_temp.names(public.list_staff(v_org, p_subject_id => v_maths, p_class_id => v_jss2)) = 'Ada';
  v_ok := v_ok and pg_temp.names(public.list_staff(v_org, p_subject_id => v_art, p_class_id => v_jss2)) = '';
  v_ok := v_ok and pg_temp.names(public.list_staff(v_org, p_subject_id => v_art, p_class_id => v_jss1)) = 'Bayo';
  v_ok := v_ok and pg_temp.names(public.list_staff(v_org, p_section_id => v_section)) = 'Ada,Bayo';
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 04 class and section filters';

  -- 05 a class alone lists every subject they teach there
  v_res := public.list_staff(v_org, p_class_id => v_jss1);
  v_log := v_log || E'\n' || case when pg_temp.teaching(v_res, 'Bayo') = 'JSS 1 A:Art,JSS 1 B:Mathematics'
                                  then 'PASS' else 'FAIL' end || ' 05 class only [' || pg_temp.teaching(v_res, 'Bayo') || ']';

  -- 06 no teaching filter: nothing changes, `teaching` is null, Cleo and Olu list
  v_res := public.list_staff(v_org);
  v_log := v_log || E'\n' || case when pg_temp.names(v_res) = 'Olu,Ada,Bayo,Cleo' and (v_res ->> 'total')::int = 4
                                    and (v_res -> 'rows' -> 1 -> 'teaching') = 'null'::jsonb
                                  then 'PASS' else 'FAIL' end || ' 06 unfiltered, teaching is null [' || pg_temp.names(v_res) || ']';

  -- 07 a teacher with no assignment never matches a teaching filter
  v_ok := position('Cleo' in pg_temp.names(public.list_staff(v_org, p_subject_id => v_maths))) = 0
      and position('Cleo' in pg_temp.names(public.list_staff(v_org, p_section_id => v_section))) = 0;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 07 no assignment, no match';

  -- 08 combines with the search, type, status and login filters
  v_ok := pg_temp.names(public.list_staff(v_org, p_subject_id => v_maths, p_search => 'bay')) = 'Bayo';
  v_ok := v_ok and pg_temp.names(public.list_staff(v_org, p_subject_id => v_maths, p_staff_type => 'teaching')) = 'Ada,Bayo';
  v_ok := v_ok and pg_temp.names(public.list_staff(v_org, p_subject_id => v_maths, p_login => 'on_app')) = '';
  v_ok := v_ok and pg_temp.names(public.list_staff(v_org, p_subject_id => v_maths, p_login => 'not_on_app')) = 'Ada,Bayo';
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 08 combined with the other filters';

  -- 09 pages with the filter: Ada then Bayo, same total, no repeats
  v_cursor := null; v_seen := ''; v_pages := 0; v_ok := true;
  loop
    v_res := public.list_staff(v_org, p_subject_id => v_maths, p_limit => 1, p_cursor => v_cursor);
    v_pages := v_pages + 1;
    v_ok := v_ok and (v_res ->> 'total')::int = 2;
    v_seen := v_seen || case when v_seen = '' then '' else ',' end || pg_temp.names(v_res);
    v_cursor := v_res ->> 'next_cursor';
    exit when v_cursor is null or v_pages > 5;
  end loop;
  v_log := v_log || E'\n' || case when v_ok and v_seen = 'Ada,Bayo' and v_pages = 2 then 'PASS' else 'FAIL' end
           || ' 09 paging keeps the filter [' || v_seen || ']';

  -- 10 another session, an unknown subject, or another school's subject match nobody
  v_ok := (public.list_staff(v_org, p_subject_id => v_maths, p_session_id => gen_random_uuid()) ->> 'total')::int = 0;
  v_ok := v_ok and (public.list_staff(v_org, p_subject_id => gen_random_uuid()) ->> 'total')::int = 0;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 10 other session or subject';

  -- 11 school boundaries and privileges
  v_ok := (public.list_staff(v_org2, p_subject_id => v_maths) ->> 'total')::int = 0;
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_stranger","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_ok := v_ok and (public.list_staff(v_org, p_subject_id => v_maths) ->> 'total')::int = 0;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 11 other school and strangers see nothing';

  execute 'reset role';
  execute 'set local role anon';
  begin
    perform public.list_staff(v_org, p_subject_id => v_maths);
    v_log := v_log || E'\nFAIL 12 anon called list_staff';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 12 anon refused [' || sqlerrm || ']';
  end;

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
