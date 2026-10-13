-- Access test for migration 08 (score columns and grade boundaries).
--
-- How to run: paste the whole file into the Supabase SQL editor and run it.
-- It acts as several fake users, checks every rule, then raises an exception on
-- purpose so EVERYTHING is rolled back. The "error" at the end is the report.
--
-- Requires migrations 01–08.

do $test$
declare
  v_log  text := '';
  v_n    int;
  v_ok   boolean;
  v_txt  text;
  v_org  uuid;  v_claim  text;
  v_org2 uuid;  v_claim2 text;
  v_nursery uuid; v_secondary uuid;
  v_nur1a uuid; v_pry1a uuid; v_jss1a uuid;
  v_teacher uuid; v_t_code text;
  v_s1 uuid; v_p1 uuid; v_p_code text;
begin
  -- The test platform admin exists only inside this test; it's rolled back
  -- with everything else, so the live database needs no fake admin.
  execute 'reset role';
  insert into public.platform_admins (clerk_user_id, full_name)
  values ('user_dummy_platform_admin', 'Dummy Platform Admin')
  on conflict (clerk_user_id) do nothing;

  -- ── setup ──────────────────────────────────────────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select c.organization_id, c.owner_claim_code into v_org,  v_claim  from public.create_organization('School A', 'SCA') c;
  select c.organization_id, c.owner_claim_code into v_org2, v_claim2 from public.create_organization('School B', 'SCB') c;

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner_b","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_claim2, 'Bimbo', 'Owner');

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_claim, 'Olu', 'Owner');
  perform public.create_standard_structure(v_org);
  select id into v_nursery   from public.sections where organization_id = v_org and name = 'Nursery';
  select id into v_secondary from public.sections where organization_id = v_org and name = 'Secondary';
  insert into public.class_arms (organization_id, class_id, name)
    select v_org, id, 'A' from public.classes where organization_id = v_org and name = 'Nursery 1' returning id into v_nur1a;
  insert into public.class_arms (organization_id, class_id, name)
    select v_org, id, 'A' from public.classes where organization_id = v_org and name = 'Primary 1' returning id into v_pry1a;
  insert into public.class_arms (organization_id, class_id, name)
    select v_org, id, 'A' from public.classes where organization_id = v_org and name = 'JSS 1' returning id into v_jss1a;

  insert into public.staff (organization_id, first_name, last_name) values (v_org, 'Ada', 'Teacher') returning id into v_teacher;
  v_t_code := public.invite_staff(v_teacher);
  insert into public.students (organization_id, first_name, last_name) values (v_org, 'Chidi', 'Pupil') returning id into v_s1;
  insert into public.parents (organization_id, first_name, last_name, phone) values (v_org, 'Ngozi', 'Pupil', '0801111111') returning id into v_p1;
  insert into public.student_parents (organization_id, student_id, parent_id, relationship, is_primary_contact) values (v_org, v_s1, v_p1, 'mother', true);
  v_p_code := public.invite_parent(v_p1);

  -- 00a standard setup: the school's columns + A–F, Secondary's own WAEC boundaries only
  perform public.create_standard_grading(v_org);
  v_ok := (select count(*) from public.score_columns    where organization_id = v_org and section_id is null) = 3
      and (select sum(max_score) from public.score_columns where organization_id = v_org and section_id is null) = 100
      and (select count(*) from public.grade_boundaries where organization_id = v_org and section_id is null) = 6
      and (select count(*) from public.score_columns    where section_id = v_secondary) = 0
      and (select count(*) from public.grade_boundaries where section_id = v_secondary) = 9;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 00a standard grading setup created';

  -- 00b only for a new school
  begin
    perform public.create_standard_grading(v_org);
    v_log := v_log || E'\nFAIL 00b standard grading created twice';
  exception when others then
    v_log := v_log || E'\n' || case when sqlerrm like '%already has a grading setup%' then 'PASS' else 'FAIL' end || ' 00b standard setup only for a new school [' || sqlerrm || ']';
  end;

  -- 01 fall-back: JSS 1A uses the school's columns but Secondary's grade boundaries;
  --    Primary 1A uses the school's for both
  select string_agg(name, ',' order by sort_order) into v_txt from public.score_columns_for_arm(v_jss1a);
  v_ok := v_txt = 'CA 1,CA 2,Exam'
      and (select count(*) from public.grade_boundaries_for_arm(v_jss1a)) = 9
      and (select count(*) from public.grade_boundaries_for_arm(v_pry1a)) = 6;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 01 columns and boundaries each fall back to the school''s';

  -- 02 grades come from boundaries, including decimals between them
  v_txt := (public.grade_for(v_jss1a, 74.5)).grade || ',' || (public.grade_for(v_jss1a, 75)).grade || ','
        || (public.grade_for(v_jss1a, 39.99)).grade || ',' || (public.grade_for(v_pry1a, 69.99)).grade || ','
        || (public.grade_for(v_pry1a, 0)).grade || ',' || (public.grade_for(v_pry1a, 100)).grade;
  v_log := v_log || E'\n' || case when v_txt = 'B2,A1,F9,B,F,A' then 'PASS' else 'FAIL' end || ' 02 grades come from boundaries [' || coalesce(v_txt, 'null') || ']';
  v_ok := not (public.grade_for(v_jss1a, 30)).is_pass and (public.grade_for(v_jss1a, 45)).is_pass;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 02b pass/fail flag comes with the grade';

  -- 03 Nursery gets its own single column; it still uses the school's grade boundaries
  insert into public.score_columns (organization_id, section_id, name, max_score) values (v_org, v_nursery, 'Observation', 100);
  select string_agg(name, ',') into v_txt from public.score_columns_for_arm(v_nur1a);
  v_ok := v_txt = 'Observation'
      and (public.grade_for(v_nur1a, 72)).grade = 'A'
      and cardinality(public.grading_problems(v_org, v_nursery)) = 0
      and cardinality(public.grading_problems(v_org)) = 0
      and cardinality(public.grading_problems(v_org2)) = 2;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 03 a section can override just its columns; problems reported for an unset school';

  -- 04 uniqueness is per set (the school's, or one section's)
  begin
    insert into public.score_columns (organization_id, name, max_score) values (v_org, 'ca 1', 10);
    v_log := v_log || E'\nFAIL 04a duplicate column in the school''s set accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23505' then 'PASS' else 'FAIL' end || ' 04a column names unique within a set [' || sqlerrm || ']';
  end;
  insert into public.score_columns (organization_id, section_id, name, max_score) values (v_org, v_nursery, 'CA 1', 10);
  v_log := v_log || E'\nPASS 04b the same column name is fine in another set (Nursery CA 1)';
  begin
    insert into public.grade_boundaries (organization_id, section_id, grade, min_percent) values (v_org, v_secondary, 'X', 75);
    v_log := v_log || E'\nFAIL 04c duplicate starting point accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23505' then 'PASS' else 'FAIL' end || ' 04c one grade per starting point within a set [' || sqlerrm || ']';
  end;

  -- 05 validation
  begin
    insert into public.grade_boundaries (organization_id, grade, min_percent) values (v_org, 'Z', 100);
    v_log := v_log || E'\nFAIL 05a boundary at 100% accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23514' then 'PASS' else 'FAIL' end || ' 05a boundaries must be below 100% [' || sqlerrm || ']';
  end;
  begin
    insert into public.score_columns (organization_id, name, max_score) values (v_org, 'Project', 0);
    v_log := v_log || E'\nFAIL 05b zero max score accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23514' then 'PASS' else 'FAIL' end || ' 05b max score must be positive [' || sqlerrm || ']';
  end;
  insert into public.score_columns (organization_id, name, max_score, sort_order) values (v_org, 'Project', 12.5, 4);
  v_log := v_log || E'\nPASS 05c decimal max scores allowed (12.5)';

  -- ── teacher: reads the setup, can't change it ──────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_teacher","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_t_code);
  select count(*) into v_n from public.score_columns;
  v_log := v_log || E'\n' || case when v_n = 6 then 'PASS' else 'FAIL' end || ' 06a teacher reads the grading setup [' || v_n || ' score columns]';
  begin
    insert into public.score_columns (organization_id, name, max_score) values (v_org, 'Quiz', 5);
    v_log := v_log || E'\nFAIL 06b teacher added a score column';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 06b teachers can''t change the setup [' || sqlerrm || ']';
  end;
  update public.grade_boundaries set min_percent = 50 where organization_id = v_org and section_id is null and grade = 'A';
  get diagnostics v_n = row_count;
  v_log := v_log || E'\n' || case when v_n = 0 then 'PASS' else 'FAIL' end || ' 06c teachers can''t edit grade boundaries';
  begin
    perform public.create_standard_grading(v_org2);
    v_log := v_log || E'\nFAIL 06d teacher set up another school';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 06d teachers can''t run the standard setup [' || sqlerrm || ']';
  end;

  -- ── parent: reads grade boundaries (for the report card) ─
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_parent","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_p_code);
  select count(*) into v_n from public.grade_boundaries;
  v_log := v_log || E'\n' || case when v_n = 15 then 'PASS' else 'FAIL' end || ' 07 parent reads grade boundaries [' || v_n || ']';

  -- ── other school ───────────────────────────────────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner_b","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select (select count(*) from public.score_columns) + (select count(*) from public.grade_boundaries) into v_n;
  v_log := v_log || E'\n' || case when v_n = 0 then 'PASS' else 'FAIL' end || ' 08 other school sees none of School A''s setup [' || v_n || ']';

  -- ── owner: removing Secondary's boundaries falls back to the school's ─
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  delete from public.grade_boundaries where section_id = v_secondary;
  v_ok := (public.grade_for(v_jss1a, 74.5)).grade = 'A'
      and (select count(*) from public.grade_boundaries_for_arm(v_jss1a)) = 6;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 09 without its own boundaries, Secondary uses the school''s';

  -- 10 anon has no access
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  execute 'set local role anon';
  begin
    perform count(*) from public.grade_boundaries;
    v_log := v_log || E'\nFAIL 10 anon read grade boundaries';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 10 anon cannot read grade boundaries [' || sqlerrm || ']';
  end;

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
