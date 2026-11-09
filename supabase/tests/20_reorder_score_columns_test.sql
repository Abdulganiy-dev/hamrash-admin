-- Access test for migration 33 (reorder_score_columns: a set of score columns in one call).
--
-- How to run: paste the whole file into the Supabase SQL editor and run it.
-- It acts as several fake users (via request.jwt.claims + set role), checks every
-- rule, then raises an exception on purpose so EVERYTHING is rolled back.
-- The "error" you see at the end is the report: each line is PASS or FAIL.
--
-- Requires migrations 01–33.
--
-- School "Test School" (TST): owner Olu, an admin, a principal, a VP, a bursar
-- and a teacher on the app, the standard structure and the standard grading
-- (the school's set: CA 1 · CA 2 · Exam), plus Nursery's own set
-- (Observation · Rhymes · Drawing, all added with sort_order 0).
-- "Other School" (OTH) has the standard grading too.

do $test$
declare
  v_log     text := '';
  v_ok      boolean;
  v_org     uuid;  v_claim  text;
  v_org2    uuid;  v_claim2 text;
  v_admin_claim     text;
  v_principal_claim text;
  v_vp_claim        text;
  v_bursar_claim    text;
  v_teacher_claim   text;
  v_nursery uuid;
  v_ca1     uuid;
  v_ca2     uuid;
  v_exam    uuid;
  v_obs     uuid;
  v_rhymes  uuid;
  v_drawing uuid;
  v_other_ca1 uuid;
  v_before  text;
  v_after   text;
  v_txt     text;
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
  perform set_config('request.jwt.claims', '{"sub":"test_owner_b","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_claim2, 'Bee', 'Otherowner');
  perform public.create_standard_grading(v_org2);
  select id into v_other_ca1 from public.score_columns where organization_id = v_org2 and section_id is null and name = 'CA 1';

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
  insert into public.organization_members (organization_id, role) values (v_org, 'bursar')
    returning claim_code into v_bursar_claim;
  insert into public.organization_members (organization_id, role) values (v_org, 'teacher')
    returning claim_code into v_teacher_claim;

  perform public.create_standard_structure(v_org);
  perform public.create_standard_grading(v_org);
  select id into v_nursery from public.sections where organization_id = v_org and name = 'Nursery';
  select id into v_ca1  from public.score_columns where organization_id = v_org and section_id is null and name = 'CA 1';
  select id into v_ca2  from public.score_columns where organization_id = v_org and section_id is null and name = 'CA 2';
  select id into v_exam from public.score_columns where organization_id = v_org and section_id is null and name = 'Exam';
  insert into public.score_columns (organization_id, section_id, name, max_score) values (v_org, v_nursery, 'Observation', 40) returning id into v_obs;
  insert into public.score_columns (organization_id, section_id, name, max_score) values (v_org, v_nursery, 'Rhymes', 30) returning id into v_rhymes;
  insert into public.score_columns (organization_id, section_id, name, max_score) values (v_org, v_nursery, 'Drawing', 30) returning id into v_drawing;

  -- everyone else joins
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_admin_claim);
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_principal","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_principal_claim);
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_vp","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_vp_claim);
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_bursar","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_bursar_claim);
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_teacher","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_teacher_claim);

  -- everything below runs as the owner unless it says otherwise
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';

  -- 01 owner reorders the school's set; it becomes exactly 1..n in the order given
  perform public.reorder_score_columns(v_org, array[v_exam, v_ca1, v_ca2]);
  select string_agg(name || '=' || sort_order, ',' order by sort_order, name) into v_txt
    from public.score_columns where organization_id = v_org and section_id is null;
  v_log := v_log || E'\n' || case when v_txt = 'Exam=1,CA 1=2,CA 2=3' then 'PASS' else 'FAIL' end || ' 01 owner reorders the school''s set to 1..n [' || coalesce(v_txt, 'null') || ']';

  -- 02 no gaps or repeats left behind
  v_ok := (select array_agg(sort_order order by sort_order) from public.score_columns
             where organization_id = v_org and section_id is null) = array[1, 2, 3];
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 02 sort_order has no gaps or repeats';

  -- 03 admin, principal and VP can each reorder it
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.reorder_score_columns(v_org, array[v_ca2, v_exam, v_ca1]);
  select string_agg(name, ',' order by sort_order) into v_txt from public.score_columns where organization_id = v_org and section_id is null;
  v_ok := v_txt = 'CA 2,Exam,CA 1';

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_principal","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.reorder_score_columns(v_org, array[v_ca1, v_exam, v_ca2]);
  select string_agg(name, ',' order by sort_order) into v_txt from public.score_columns where organization_id = v_org and section_id is null;
  v_ok := v_ok and v_txt = 'CA 1,Exam,CA 2';

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_vp","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.reorder_score_columns(v_org, array[v_ca1, v_ca2, v_exam]);
  select string_agg(name || '=' || sort_order, ',' order by sort_order) into v_txt from public.score_columns where organization_id = v_org and section_id is null;
  v_ok := v_ok and v_txt = 'CA 1=1,CA 2=2,Exam=3';
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 03 admin, principal and VP each reorder the school''s set [' || coalesce(v_txt, 'null') || ']';

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';

  -- 04 Nursery's own set (all 0 to start) is reordered on its own; the school's set is untouched
  perform public.reorder_score_columns(v_org, array[v_drawing, v_obs, v_rhymes]);
  select string_agg(name || '=' || sort_order, ',' order by sort_order) into v_txt
    from public.score_columns where section_id = v_nursery;
  v_ok := v_txt = 'Drawing=1,Observation=2,Rhymes=3'
      and (select string_agg(name || '=' || sort_order, ',' order by sort_order) from public.score_columns
             where organization_id = v_org and section_id is null) = 'CA 1=1,CA 2=2,Exam=3';
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 04 a section''s set reorders independently of the school''s [' || coalesce(v_txt, 'null') || ']';

  -- snapshot of every column in both schools for the "nothing changed" checks below
  execute 'reset role';
  select string_agg(id::text || ':' || sort_order, ',' order by id) into v_before
    from public.score_columns where organization_id in (v_org, v_org2);

  -- 05 bursar refused
  perform set_config('request.jwt.claims', '{"sub":"test_bursar","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    perform public.reorder_score_columns(v_org, array[v_exam, v_ca2, v_ca1]);
    v_log := v_log || E'\nFAIL 05 bursar reordered score columns';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 05 bursar refused [' || sqlerrm || ']';
  end;

  -- 06 teacher refused
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_teacher","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    perform public.reorder_score_columns(v_org, array[v_exam, v_ca2, v_ca1]);
    v_log := v_log || E'\nFAIL 06 teacher reordered score columns';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 06 teacher refused [' || sqlerrm || ']';
  end;

  -- 07 another school's owner refused
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner_b","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    perform public.reorder_score_columns(v_org, array[v_exam, v_ca2, v_ca1]);
    v_log := v_log || E'\nFAIL 07 other school''s owner reordered score columns';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 07 other school''s owner refused [' || sqlerrm || ']';
  end;

  -- 08 anon can't call it
  execute 'reset role';
  execute 'set local role anon';
  begin
    perform public.reorder_score_columns(v_org, array[v_exam, v_ca2, v_ca1]);
    v_log := v_log || E'\nFAIL 08 anon called reorder_score_columns';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 08 anon refused [' || sqlerrm || ']';
  end;

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';

  -- 09 a column that doesn't exist refused
  begin
    perform public.reorder_score_columns(v_org, array[v_exam, v_ca2, gen_random_uuid()]);
    v_log := v_log || E'\nFAIL 09 unknown column accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = 'P0001' and sqlerrm like '%no longer exists%' then 'PASS' else 'FAIL' end || ' 09 unknown column refused [' || sqlerrm || ']';
  end;

  -- 10 the same column twice refused
  begin
    perform public.reorder_score_columns(v_org, array[v_exam, v_ca2, v_ca2, v_ca1]);
    v_log := v_log || E'\nFAIL 10 column listed twice accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = 'P0001' and sqlerrm like '%listed twice%' then 'PASS' else 'FAIL' end || ' 10 duplicate column refused [' || sqlerrm || ']';
  end;

  -- 11 another school's column refused, with the same message as an unknown one
  begin
    perform public.reorder_score_columns(v_org, array[v_exam, v_ca2, v_ca1, v_other_ca1]);
    v_log := v_log || E'\nFAIL 11 other school''s column accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = 'P0001' and sqlerrm like '%no longer exists%' then 'PASS' else 'FAIL' end || ' 11 other school''s column refused [' || sqlerrm || ']';
  end;

  -- 12 the school's and Nursery's columns mixed refused
  begin
    perform public.reorder_score_columns(v_org, array[v_exam, v_ca2, v_ca1, v_obs]);
    v_log := v_log || E'\nFAIL 12 columns from two sets accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = 'P0001' and sqlerrm like '%different sets%' then 'PASS' else 'FAIL' end || ' 12 mixed sets refused [' || sqlerrm || ']';
  end;

  -- 13 a list that leaves a column out refused
  begin
    perform public.reorder_score_columns(v_org, array[v_exam, v_ca1]);
    v_log := v_log || E'\nFAIL 13 incomplete list accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = 'P0001' and sqlerrm like '%missing from the new order%' then 'PASS' else 'FAIL' end || ' 13 column left out refused [' || sqlerrm || ']';
  end;

  -- 14 an empty list (and no list) refused
  v_ok := true;
  begin
    perform public.reorder_score_columns(v_org, '{}'::uuid[]);
    v_ok := false;
  exception when others then
    v_ok := sqlstate = 'P0001' and sqlerrm like '%no score columns to put in order%';
  end;
  begin
    perform public.reorder_score_columns(v_org, null);
    v_ok := false;
  exception when others then
    v_ok := v_ok and sqlstate = 'P0001' and sqlerrm like '%no score columns to put in order%';
  end;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 14 empty or null list refused';

  -- 15 a null id in the list refused
  begin
    perform public.reorder_score_columns(v_org, array[v_exam, v_ca2, null]);
    v_log := v_log || E'\nFAIL 15 null id accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = 'P0001' and sqlerrm like '%no longer exists%' then 'PASS' else 'FAIL' end || ' 15 null id refused [' || sqlerrm || ']';
  end;

  -- 16 none of the refusals above changed any sort_order, in either school
  execute 'reset role';
  select string_agg(id::text || ':' || sort_order, ',' order by id) into v_after
    from public.score_columns where organization_id in (v_org, v_org2);
  v_log := v_log || E'\n' || case when v_after = v_before then 'PASS' else 'FAIL' end || ' 16 refused calls left every sort_order untouched';

  -- 17 sending the order it already has is fine and changes nothing
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.reorder_score_columns(v_org, array[v_ca1, v_ca2, v_exam]);
  execute 'reset role';
  select string_agg(id::text || ':' || sort_order, ',' order by id) into v_after
    from public.score_columns where organization_id in (v_org, v_org2);
  v_log := v_log || E'\n' || case when v_after = v_before then 'PASS' else 'FAIL' end || ' 17 the current order again is accepted and changes nothing';

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
