-- Test for migration 36 (list_students: search, class, section and subject
-- filters, the teacher of each subject, counts and pages).
--
-- How to run: paste the whole file into the Supabase SQL editor and run it.
-- It acts as several fake users, checks every rule, then raises an exception on
-- purpose so EVERYTHING is rolled back. The "error" at the end is the report.
--
-- Requires migrations 01–36.
--
-- School "Test School" (prefix TST), session 2026/2027 (current):
--   classes   JSS 1 (arms A, B), JSS 2 (arm A)
--   subjects  Mathematics (compulsory in 1A, 1B and 2A), French (OPTIONAL in 1A),
--             Art (compulsory in 1A)
--   teachers  Ada: Mathematics in 1A and 2A.  Bayo: Mathematics in 1B.
--             Nobody teaches French or Art.
--   students (surname first as the list sorts them)
--     Chidi Eze     1A  takes French (optional)
--     Dara Obi      1A
--     Ebi Yusuf     1B
--     Femi Zaki     2A
--     Hope Zed      1A  withdrawn
--     Gina Zubair   no placement
-- Class order: Chidi, Dara, Hope (1A), Ebi (1B), Femi (2A), Gina (no arm).
-- Name order:  Chidi, Dara, Ebi, Femi, Hope, Gina.

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
  v_maths   uuid;
  v_french  uuid;
  v_art     uuid;
  v_chidi   uuid;
  v_dara    uuid;
  v_ebi     uuid;
  v_femi    uuid;
  v_hope    uuid;
  v_gina    uuid;
  v_res     jsonb;
  v_row     jsonb;
  v_got     text;
  v_cursor  text;
  v_seen    text;
  v_pages   int;
  v_ok      boolean;
  v_active  public.student_status[] := array['active']::public.student_status[];
begin
  execute 'reset role';
  insert into public.platform_admins (clerk_user_id, full_name)
  values ('user_dummy_platform_admin', 'Dummy Platform Admin')
  on conflict (clerk_user_id) do nothing;

  -- first names of a list_students result, in order, comma separated
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
  insert into public.students (organization_id, first_name, last_name) values (v_org2, 'Bee', 'Student');

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

  insert into public.subjects (organization_id, name, code) values (v_org, 'Mathematics', 'MTH') returning id into v_maths;
  insert into public.subjects (organization_id, name, code) values (v_org, 'French', 'FRE') returning id into v_french;
  insert into public.subjects (organization_id, name, code) values (v_org, 'Art', 'ART') returning id into v_art;
  insert into public.arm_subjects (organization_id, arm_id, subject_id) values (v_org, v_arm_1a, v_maths);
  insert into public.arm_subjects (organization_id, arm_id, subject_id) values (v_org, v_arm_1b, v_maths);
  insert into public.arm_subjects (organization_id, arm_id, subject_id) values (v_org, v_arm_2a, v_maths);
  insert into public.arm_subjects (organization_id, arm_id, subject_id, is_compulsory) values (v_org, v_arm_1a, v_french, false);
  insert into public.arm_subjects (organization_id, arm_id, subject_id) values (v_org, v_arm_1a, v_art);
  insert into public.teaching_assignments (organization_id, session_id, arm_id, subject_id, staff_id)
    values (v_org, v_session, v_arm_1a, v_maths, v_ada),
           (v_org, v_session, v_arm_2a, v_maths, v_ada),
           (v_org, v_session, v_arm_1b, v_maths, v_bayo);

  insert into public.students (organization_id, first_name, last_name) values (v_org, 'Chidi', 'Eze')    returning id into v_chidi;
  insert into public.students (organization_id, first_name, last_name) values (v_org, 'Dara',  'Obi')    returning id into v_dara;
  insert into public.students (organization_id, first_name, last_name) values (v_org, 'Ebi',   'Yusuf')  returning id into v_ebi;
  insert into public.students (organization_id, first_name, last_name) values (v_org, 'Femi',  'Zaki')   returning id into v_femi;
  insert into public.students (organization_id, first_name, last_name, status)
    values (v_org, 'Hope', 'Zed', 'withdrawn') returning id into v_hope;
  insert into public.students (organization_id, first_name, last_name) values (v_org, 'Gina',  'Zubair') returning id into v_gina;
  insert into public.student_placements (organization_id, student_id, session_id, arm_id)
    values (v_org, v_chidi, v_session, v_arm_1a), (v_org, v_dara, v_session, v_arm_1a),
           (v_org, v_hope,  v_session, v_arm_1a), (v_org, v_ebi,  v_session, v_arm_1b),
           (v_org, v_femi,  v_session, v_arm_2a);
  insert into public.student_subjects (organization_id, student_id, session_id, subject_id)
    values (v_org, v_chidi, v_session, v_french);

  -- 01 every student, in class order, one page; total and groups agree
  v_res := public.list_students(v_org);
  v_got := pg_temp.names(v_res);
  v_log := v_log || E'\n' || case when v_got = 'Chidi,Dara,Hope,Ebi,Femi,Gina'
                                    and (v_res ->> 'total')::int = 6
                                    and v_res -> 'next_cursor' = 'null'::jsonb
                                    and (select sum((g ->> 'count')::int) from jsonb_array_elements(v_res -> 'groups') g) = 6
                                  then 'PASS' else 'FAIL' end || ' 01 unfiltered, class order [' || v_got || ']';

  -- 02 name order, and the default status list the app sends
  v_got := pg_temp.names(public.list_students(v_org, p_sort => 'name'));
  v_ok := v_got = 'Chidi,Dara,Ebi,Femi,Hope,Gina';
  v_got := pg_temp.names(public.list_students(v_org, p_statuses => v_active));
  v_ok := v_ok and v_got = 'Chidi,Dara,Ebi,Femi,Gina';
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 02 name sort and active-only [' || v_got || ']';

  -- 03 pages: 2 at a time in both sorts, nobody repeated or missed, same total
  for v_got in select unnest(array['class', 'name']) loop
    v_cursor := null; v_seen := ''; v_pages := 0; v_ok := true;
    loop
      v_res := public.list_students(v_org, p_sort => v_got, p_limit => 2, p_cursor => v_cursor);
      v_pages := v_pages + 1;
      v_ok := v_ok and (v_res ->> 'total')::int = 6 and jsonb_array_length(v_res -> 'rows') <= 2;
      v_seen := v_seen || case when v_seen = '' then '' else ',' end || pg_temp.names(v_res);
      v_cursor := v_res ->> 'next_cursor';
      exit when v_cursor is null or v_pages > 10;
    end loop;
    v_ok := v_ok and v_pages = 3
            and v_seen = case v_got when 'class' then 'Chidi,Dara,Hope,Ebi,Femi,Gina'
                                    else 'Chidi,Dara,Ebi,Femi,Hope,Gina' end;
    v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 03 paging by ' || v_got || ' [' || v_seen || ', ' || v_pages || ' pages]';
  end loop;

  -- 04 pages with a filter: total and rows come from the same filtered set
  v_res := public.list_students(v_org, p_subject_id => v_maths, p_statuses => v_active, p_limit => 3);
  v_ok := (v_res ->> 'total')::int = 4 and jsonb_array_length(v_res -> 'rows') = 3 and v_res ->> 'next_cursor' is not null;
  v_res := public.list_students(v_org, p_subject_id => v_maths, p_statuses => v_active, p_limit => 3,
                                p_cursor => v_res ->> 'next_cursor');
  v_ok := v_ok and (v_res ->> 'total')::int = 4 and pg_temp.names(v_res) = 'Femi' and v_res -> 'next_cursor' = 'null'::jsonb;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 04 paging keeps the filter';

  -- 05 search: name part, two words, case, admission number, literal wildcards
  v_ok := pg_temp.names(public.list_students(v_org, p_search => 'EZE')) = 'Chidi';
  v_ok := v_ok and pg_temp.names(public.list_students(v_org, p_search => '  chi   eze ')) = 'Chidi';
  v_ok := v_ok and (public.list_students(v_org, p_search => 'tst/') ->> 'total')::int = 6;
  v_ok := v_ok and (public.list_students(v_org, p_search => '%') ->> 'total')::int = 0;
  v_ok := v_ok and (public.list_students(v_org, p_search => '   ') ->> 'total')::int = 6;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 05 search';

  -- 06 section, class and arm filters; students with no arm never match them
  v_ok := pg_temp.names(public.list_students(v_org, p_class_id => v_jss1, p_statuses => v_active)) = 'Chidi,Dara,Ebi';
  v_ok := v_ok and pg_temp.names(public.list_students(v_org, p_arm_id => v_arm_1a, p_statuses => v_active)) = 'Chidi,Dara';
  v_ok := v_ok and pg_temp.names(public.list_students(v_org, p_class_id => v_jss2)) = 'Femi';
  v_ok := v_ok and (public.list_students(v_org, p_section_id => v_section, p_statuses => v_active) ->> 'total')::int = 4;
  v_ok := v_ok and (public.list_students(v_org, p_class_id => v_jss1, p_arm_id => v_arm_2a) ->> 'total')::int = 0;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 06 section, class, arm';

  -- 07 Mathematics: compulsory everywhere, so every placed active student;
  -- each carries the teacher of THEIR arm (Ada in 1A and 2A, Bayo in 1B)
  v_res := public.list_students(v_org, p_subject_id => v_maths, p_statuses => v_active);
  select string_agg((r ->> 'first_name') || ':' || (r -> 'subject' -> 'teacher' ->> 'first_name'), ',' order by o)
    into v_got
  from jsonb_array_elements(v_res -> 'rows') with ordinality as t(r, o);
  v_log := v_log || E'\n' || case when v_got = 'Chidi:Ada,Dara:Ada,Ebi:Bayo,Femi:Ada'
                                    and (v_res ->> 'total')::int = 4
                                  then 'PASS' else 'FAIL' end || ' 07 maths with the arm''s teacher [' || coalesce(v_got, '') || ']';

  -- 08 French is optional in 1A: only the student who chose it; nobody teaches it
  v_res := public.list_students(v_org, p_subject_id => v_french);
  v_row := v_res -> 'rows' -> 0;
  v_log := v_log || E'\n' || case when pg_temp.names(v_res) = 'Chidi'
                                    and (v_row -> 'subject' ->> 'is_compulsory')::boolean = false
                                    and v_row -> 'subject' -> 'teacher' = 'null'::jsonb
                                    and v_row -> 'subject' ->> 'name' = 'French'
                                  then 'PASS' else 'FAIL' end || ' 08 optional subject, no teacher is null [' || pg_temp.names(v_res) || ']';

  -- 09 Art is compulsory in 1A only, with no teacher: both 1A students, no error
  v_res := public.list_students(v_org, p_subject_id => v_art, p_statuses => v_active);
  v_log := v_log || E'\n' || case when pg_temp.names(v_res) = 'Chidi,Dara'
                                    and not exists (select 1 from jsonb_array_elements(v_res -> 'rows') r
                                                    where r -> 'subject' -> 'teacher' <> 'null'::jsonb)
                                  then 'PASS' else 'FAIL' end || ' 09 subject nobody teaches';

  -- 10 subject with class and arm: the subject must be offered where they sit
  v_ok := pg_temp.names(public.list_students(v_org, p_subject_id => v_maths, p_class_id => v_jss2)) = 'Femi';
  v_ok := v_ok and pg_temp.names(public.list_students(v_org, p_subject_id => v_maths, p_arm_id => v_arm_1b)) = 'Ebi';
  v_ok := v_ok and (public.list_students(v_org, p_subject_id => v_french, p_arm_id => v_arm_1b) ->> 'total')::int = 0;
  v_ok := v_ok and (public.list_students(v_org, p_subject_id => gen_random_uuid()) ->> 'total')::int = 0;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 10 subject combined with class and arm';

  -- 11 nobody is listed twice, whatever the joins
  v_res := public.list_students(v_org, p_subject_id => v_maths);
  v_log := v_log || E'\n' || case when (select count(distinct r ->> 'id') from jsonb_array_elements(v_res -> 'rows') r)
                                       = jsonb_array_length(v_res -> 'rows')
                                  then 'PASS' else 'FAIL' end || ' 11 no duplicates';

  -- 12 the arm's group counts follow the filters
  v_res := public.list_students(v_org, p_statuses => v_active);
  select (g ->> 'count')::int into v_got
  from jsonb_array_elements(v_res -> 'groups') g where (g ->> 'arm_id')::uuid = v_arm_1a;
  v_ok := v_got = '2';
  select (g ->> 'count')::int into v_got
  from jsonb_array_elements(v_res -> 'groups') g where g -> 'arm_id' = 'null'::jsonb;
  v_ok := v_ok and v_got = '1';
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 12 group counts (1A has 2 active, 1 student has no arm)';

  -- 13 another session has no placements: nobody has an arm there
  v_res := public.list_students(v_org, p_session_id => gen_random_uuid(), p_statuses => v_active);
  v_log := v_log || E'\n' || case when (v_res ->> 'total')::int = 5
                                    and not exists (select 1 from jsonb_array_elements(v_res -> 'rows') r where r -> 'arm' <> 'null'::jsonb)
                                    and (public.list_students(v_org, p_session_id => gen_random_uuid(), p_arm_id => v_arm_1a) ->> 'total')::int = 0
                                  then 'PASS' else 'FAIL' end || ' 13 other session';

  -- 14 bad arguments and cursors are refused with a readable message
  v_ok := true;
  begin perform public.list_students(v_org, p_sort => 'newest'); v_ok := false;
  exception when others then v_ok := v_ok and sqlstate = '22023'; end;
  begin perform public.list_students(null); v_ok := false;
  exception when others then v_ok := v_ok and sqlstate = '22023'; end;
  begin perform public.list_students(v_org, p_cursor => 'not-a-cursor'); v_ok := false;
  exception when others then v_ok := v_ok and sqlstate = '22023'; end;
  v_cursor := public.list_students(v_org, p_sort => 'name', p_limit => 1) ->> 'next_cursor';
  begin perform public.list_students(v_org, p_sort => 'class', p_cursor => v_cursor); v_ok := false;
  exception when others then v_ok := v_ok and sqlstate = '22023'; end;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 14 bad sort, school and cursors refused';

  -- 15 school boundaries: the other school's student never shows, and the
  -- other school's list is empty for this owner
  v_ok := position('Bee' in pg_temp.names(public.list_students(v_org))) = 0;
  v_ok := v_ok and (public.list_students(v_org2) ->> 'total')::int = 0;
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_stranger","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_ok := v_ok and (public.list_students(v_org) ->> 'total')::int = 0
              and public.list_students(v_org) -> 'rows' = '[]'::jsonb;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 15 other school and strangers see nothing';

  -- 16 anon can't call it
  execute 'reset role';
  execute 'set local role anon';
  begin
    perform public.list_students(v_org);
    v_log := v_log || E'\nFAIL 16 anon called list_students';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 16 anon refused [' || sqlerrm || ']';
  end;

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
