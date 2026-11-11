-- Access test for migration 34 (grade ranges with a maximum; grade scales
-- written only through set_grade_scale, apply_grade_system,
-- copy_section_grading and remove_section_grade_scale).
--
-- How to run: paste the whole file into the Supabase SQL editor and run it.
-- It acts as several fake users (via request.jwt.claims + set role), checks every
-- rule, then raises an exception on purpose so EVERYTHING is rolled back.
-- The "error" you see at the end is the report: each line is PASS or FAIL.
--
-- Requires migrations 01–39 (39 named the WAEC section Senior Secondary).
--
-- The deferred scale trigger normally runs at COMMIT, which a rolled-back test
-- never reaches. Where a case needs it, the test runs
-- `set constraints all immediate` to fire it on the spot, then sets it back
-- to deferred. Cases that build a legacy (pre-34) set write it as the table
-- owner inside an inner block that is undone on purpose, so the bad set and
-- its pending trigger events never leak into later cases.
--
-- Backfill: the table is already migrated when this runs, so case 19 runs
-- migration 34's backfill statement (and its decimal check) on a temp table
-- shaped like the pre-34 grade_boundaries.
--
-- School "Test School" (TST): owner Olu, an admin, a principal, a VP, a bursar
-- and a teacher on the app, the standard structure (Nursery, Primary, Junior
-- and Senior Secondary) with one arm in Nursery 1, Primary 1 and SS 1, and the standard
-- grading (the school's A–F, Senior Secondary's own WAEC). "Other School" (OTH) has
-- the standard structure and grading too.

do $test$
declare
  v_log     text := '';
  v_ok      boolean;
  v_n       int;
  v_org     uuid;  v_claim  text;
  v_org2    uuid;  v_claim2 text;
  v_admin_claim     text;
  v_principal_claim text;
  v_vp_claim        text;
  v_bursar_claim    text;
  v_teacher_claim   text;
  v_nursery   uuid;
  v_primary   uuid;
  v_secondary uuid;
  v_other_primary uuid;
  v_extra     uuid;
  v_nur1a uuid; v_pry1a uuid; v_ss1a uuid;
  v_before  text;
  v_after   text;
  v_txt     text;
  v_msg1    text;
  v_msg2    text;
  v_case    record;
  v_four    constant jsonb := '[
      {"grade": "A", "min_percent": 70, "max_percent": 100, "remark": "Excellent", "is_pass": true},
      {"grade": "B", "min_percent": 55, "max_percent": 69,  "remark": "Good",      "is_pass": true},
      {"grade": "C", "min_percent": 40, "max_percent": 54,  "remark": null,        "is_pass": true},
      {"grade": "F", "min_percent": 0,  "max_percent": 39,  "remark": "Fail",      "is_pass": false}
    ]';
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
  perform public.create_standard_structure(v_org2);
  perform public.create_standard_grading(v_org2);
  select id into v_other_primary from public.sections where organization_id = v_org2 and name = 'Primary';

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_claim, 'Olu', 'Owner');
  insert into public.organization_members (organization_id, role) values (v_org, 'admin')          returning claim_code into v_admin_claim;
  insert into public.organization_members (organization_id, role) values (v_org, 'principal')      returning claim_code into v_principal_claim;
  insert into public.organization_members (organization_id, role) values (v_org, 'vice_principal') returning claim_code into v_vp_claim;
  insert into public.organization_members (organization_id, role) values (v_org, 'bursar')         returning claim_code into v_bursar_claim;
  insert into public.organization_members (organization_id, role) values (v_org, 'teacher')        returning claim_code into v_teacher_claim;

  perform public.create_standard_structure(v_org);
  select id into v_nursery   from public.sections where organization_id = v_org and name = 'Nursery';
  select id into v_primary   from public.sections where organization_id = v_org and name = 'Primary';
  select id into v_secondary from public.sections where organization_id = v_org and name = 'Senior Secondary';
  insert into public.class_arms (organization_id, class_id, name)
    select v_org, id, 'A' from public.classes where organization_id = v_org and name = 'Nursery 1' returning id into v_nur1a;
  insert into public.class_arms (organization_id, class_id, name)
    select v_org, id, 'A' from public.classes where organization_id = v_org and name = 'Primary 1' returning id into v_pry1a;
  insert into public.class_arms (organization_id, class_id, name)
    select v_org, id, 'A' from public.classes where organization_id = v_org and name = 'SS 1' returning id into v_ss1a;

  -- 01 create_standard_grading still works and writes max_percent
  perform public.create_standard_grading(v_org);
  select string_agg(grade || ' ' || min_percent::int || '-' || max_percent::int, ',' order by min_percent desc) into v_txt
    from public.grade_boundaries where organization_id = v_org and section_id is null;
  v_ok := v_txt = 'A 70-100,B 60-69,C 50-59,D 45-49,E 40-44,F 0-39';
  select string_agg(grade || ' ' || min_percent::int || '-' || max_percent::int, ',' order by min_percent desc) into v_txt
    from public.grade_boundaries where section_id = v_secondary;
  v_ok := v_ok and v_txt = 'A1 75-100,B2 70-74,B3 65-69,C4 60-64,C5 55-59,C6 50-54,D7 45-49,E8 40-44,F9 0-39';
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 01 create_standard_grading writes whole-number ranges (school A–F, Senior Secondary WAEC) [' || coalesce(v_txt, 'null') || ']';

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

  -- ── privileges ──
  execute 'reset role';

  -- 02 authenticated keeps SELECT only; no write policy is left
  v_ok := has_table_privilege('authenticated', 'public.grade_boundaries', 'SELECT')
      and not has_table_privilege('authenticated', 'public.grade_boundaries', 'INSERT')
      and not has_table_privilege('authenticated', 'public.grade_boundaries', 'UPDATE')
      and not has_table_privilege('authenticated', 'public.grade_boundaries', 'DELETE')
      and not has_column_privilege('authenticated', 'public.grade_boundaries', 'min_percent', 'INSERT')
      and not has_column_privilege('authenticated', 'public.grade_boundaries', 'min_percent', 'UPDATE')
      and not has_table_privilege('anon', 'public.grade_boundaries', 'SELECT')
      and (select count(*) from pg_policies where schemaname = 'public' and tablename = 'grade_boundaries' and cmd <> 'SELECT') = 0;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 02 grade_boundaries: authenticated can only read; no write policies remain';

  -- 03 only authenticated can execute the new functions; the private writers can't be called by clients
  v_ok := has_function_privilege('authenticated', 'public.set_grade_scale(uuid, uuid, jsonb)', 'EXECUTE')
      and has_function_privilege('authenticated', 'public.apply_grade_system(uuid, uuid, text)', 'EXECUTE')
      and has_function_privilege('authenticated', 'public.copy_section_grading(uuid, uuid, uuid, boolean, boolean)', 'EXECUTE')
      and has_function_privilege('authenticated', 'public.remove_section_grade_scale(uuid, uuid)', 'EXECUTE')
      and not has_function_privilege('anon', 'public.set_grade_scale(uuid, uuid, jsonb)', 'EXECUTE')
      and not has_function_privilege('anon', 'public.apply_grade_system(uuid, uuid, text)', 'EXECUTE')
      and not has_function_privilege('anon', 'public.copy_section_grading(uuid, uuid, uuid, boolean, boolean)', 'EXECUTE')
      and not has_function_privilege('anon', 'public.remove_section_grade_scale(uuid, uuid)', 'EXECUTE')
      and not has_function_privilege('authenticated', 'private.replace_grade_scale(uuid, uuid, jsonb)', 'EXECUTE')
      and not has_function_privilege('authenticated', 'private.lock_grading_set(uuid, uuid)', 'EXECUTE')
      and not has_function_privilege('authenticated', 'private.check_grade_scale()', 'EXECUTE');
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 03 execute: authenticated only; private writers not callable by clients';

  -- 04 direct INSERT, UPDATE and DELETE are refused even for the owner
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_ok := true;
  begin
    insert into public.grade_boundaries (organization_id, section_id, grade, min_percent, max_percent, is_pass)
    values (v_org, v_nursery, 'A', 0, 100, true);
    v_ok := false;
  exception when others then v_ok := v_ok and sqlstate = '42501';
  end;
  begin
    update public.grade_boundaries set remark = 'Top' where organization_id = v_org and section_id is null and grade = 'A';
    v_ok := false;
  exception when others then v_ok := v_ok and sqlstate = '42501';
  end;
  begin
    delete from public.grade_boundaries where organization_id = v_org and section_id = v_secondary;
    v_ok := false;
  exception when others then v_ok := v_ok and sqlstate = '42501';
  end;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 04 owner can''t insert, update or delete grade rows directly';

  -- ── set_grade_scale ──

  -- 05 owner gives Nursery its own scale; names and remarks are trimmed, a blank remark is null
  perform public.set_grade_scale(v_org, v_nursery, '[
      {"grade": "  A ", "min_percent": 70, "max_percent": 100, "remark": " Excellent ", "is_pass": true},
      {"grade": "B",    "min_percent": 55, "max_percent": 69,  "remark": "  ",          "is_pass": true},
      {"grade": "C",    "min_percent": 40, "max_percent": 54,                            "is_pass": true, "id": "ignored"},
      {"grade": "F",    "min_percent": 0,  "max_percent": 39,  "remark": "Fail",        "is_pass": false}
    ]'::jsonb);
  select string_agg(grade || ' ' || min_percent::int || '-' || max_percent::int || ' ' || coalesce(remark, '-') || ' '
                    || case when is_pass then 'pass' else 'fail' end, ',' order by min_percent desc) into v_txt
    from public.grade_boundaries where section_id = v_nursery;
  v_log := v_log || E'\n' || case when v_txt = 'A 70-100 Excellent pass,B 55-69 - pass,C 40-54 - pass,F 0-39 Fail fail' then 'PASS' else 'FAIL' end
        || ' 05 owner sets Nursery''s scale [' || coalesce(v_txt, 'null') || ']';

  -- 06 sending a new list replaces the whole set (fewer grades, new names)
  perform public.set_grade_scale(v_org, v_nursery, '[
      {"grade": "Pass", "min_percent": 50, "max_percent": 100, "remark": null, "is_pass": true},
      {"grade": "Fail", "min_percent": 0,  "max_percent": 49,  "remark": null, "is_pass": false}
    ]'::jsonb);
  select string_agg(grade || ' ' || min_percent::int || '-' || max_percent::int, ',' order by min_percent desc) into v_txt
    from public.grade_boundaries where section_id = v_nursery;
  v_log := v_log || E'\n' || case when v_txt = 'Pass 50-100,Fail 0-49' then 'PASS' else 'FAIL' end || ' 06 a new list replaces the whole set [' || coalesce(v_txt, 'null') || ']';

  -- 07 admin, principal and VP can each set it; the school-level set (section null) can be set too
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.set_grade_scale(v_org, v_nursery, v_four);
  v_ok := (select count(*) from public.grade_boundaries where section_id = v_nursery) = 4;
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_principal","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.set_grade_scale(v_org, v_nursery, '[{"grade": "All", "min_percent": 0, "max_percent": 100, "remark": null, "is_pass": true}]'::jsonb);
  v_ok := v_ok and (select count(*) from public.grade_boundaries where section_id = v_nursery) = 1;
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_vp","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.set_grade_scale(v_org, v_nursery, v_four);
  v_ok := v_ok and (select count(*) from public.grade_boundaries where section_id = v_nursery) = 4;
  perform public.set_grade_scale(v_org, null, '[
      {"grade": "A", "min_percent": 70, "max_percent": 100, "remark": "Excellent", "is_pass": true},
      {"grade": "B", "min_percent": 60, "max_percent": 69,  "remark": "Very Good", "is_pass": true},
      {"grade": "C", "min_percent": 50, "max_percent": 59,  "remark": "Good",      "is_pass": true},
      {"grade": "D", "min_percent": 45, "max_percent": 49,  "remark": "Fair",      "is_pass": true},
      {"grade": "E", "min_percent": 40, "max_percent": 44,  "remark": "Pass",      "is_pass": true},
      {"grade": "F", "min_percent": 0,  "max_percent": 39,  "remark": "Weak",      "is_pass": false}
    ]'::jsonb);
  v_ok := v_ok and (select remark from public.grade_boundaries where organization_id = v_org and section_id is null and grade = 'F') = 'Weak'
               and (select count(*) from public.grade_boundaries where section_id = v_secondary) = 9;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 07 admin, principal and VP each set a scale; the school-level set too, other sets untouched';

  -- snapshot of every grade row in both schools for the "nothing changed" checks below
  execute 'reset role';
  select string_agg(id::text || ':' || grade || ':' || min_percent || '-' || max_percent || ':' || coalesce(remark, '') || ':' || is_pass, ',' order by id)
    into v_before from public.grade_boundaries where organization_id in (v_org, v_org2);

  -- 08 bursar, teacher and another school's owner are refused (42501), for every RPC
  for v_case in
    select * from (values ('test_bursar', 'bursar'), ('test_teacher', 'teacher'), ('test_owner_b', 'other school''s owner')) as t (sub, label)
  loop
    execute 'reset role';
    perform set_config('request.jwt.claims', json_build_object('sub', v_case.sub, 'role', 'authenticated')::text, true);
    execute 'set local role authenticated';
    v_ok := true;
    begin perform public.set_grade_scale(v_org, v_nursery, v_four); v_ok := false;
    exception when others then v_ok := v_ok and sqlstate = '42501'; end;
    begin perform public.apply_grade_system(v_org, v_nursery, 'waec'); v_ok := false;
    exception when others then v_ok := v_ok and sqlstate = '42501'; end;
    begin perform public.copy_section_grading(v_org, null, v_nursery, true, true); v_ok := false;
    exception when others then v_ok := v_ok and sqlstate = '42501'; end;
    begin perform public.remove_section_grade_scale(v_org, v_nursery); v_ok := false;
    exception when others then v_ok := v_ok and sqlstate = '42501'; end;
    v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 08 ' || v_case.label || ' refused by all four RPCs (42501)';
  end loop;

  -- 09 anon can't call any of them
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  execute 'set local role anon';
  v_ok := true;
  begin perform public.set_grade_scale(v_org, v_nursery, v_four); v_ok := false;
  exception when others then v_ok := v_ok and sqlstate = '42501'; end;
  begin perform public.apply_grade_system(v_org, v_nursery, 'waec'); v_ok := false;
  exception when others then v_ok := v_ok and sqlstate = '42501'; end;
  begin perform public.copy_section_grading(v_org, null, v_nursery, true, true); v_ok := false;
  exception when others then v_ok := v_ok and sqlstate = '42501'; end;
  begin perform public.remove_section_grade_scale(v_org, v_nursery); v_ok := false;
  exception when others then v_ok := v_ok and sqlstate = '42501'; end;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 09 anon refused by all four RPCs';

  -- 10 every bad list is refused with its own message (P0001)
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  for v_case in
    select * from (values
      ('gap',                '[{"grade":"A","min_percent":70,"max_percent":100,"remark":null,"is_pass":true},{"grade":"B","min_percent":0,"max_percent":60,"remark":null,"is_pass":true}]',
                             'Nothing covers 61 to 69. A should start at 61'),
      ('overlap',            '[{"grade":"A","min_percent":60,"max_percent":100,"remark":null,"is_pass":true},{"grade":"B","min_percent":0,"max_percent":65,"remark":null,"is_pass":true}]',
                             'A overlaps the grade below it. A should start at 66'),
      ('doesn''t start at 0', '[{"grade":"A","min_percent":40,"max_percent":100,"remark":null,"is_pass":true}]',
                             'The lowest grade must start at 0. Nothing covers 0 to 39'),
      ('doesn''t end at 100', '[{"grade":"A","min_percent":50,"max_percent":99,"remark":null,"is_pass":true},{"grade":"F","min_percent":0,"max_percent":49,"remark":null,"is_pass":false}]',
                             'The highest grade must end at 100. Nothing covers 100'),
      ('min above max',      '[{"grade":"A","min_percent":50,"max_percent":40,"remark":null,"is_pass":true}]',
                             'Grade A: from (50) is higher than to (40)'),
      ('decimal',            '[{"grade":"A","min_percent":69.5,"max_percent":100,"remark":null,"is_pass":true},{"grade":"F","min_percent":0,"max_percent":69,"remark":null,"is_pass":false}]',
                             'Grade A: from and to must be whole numbers from 0 to 100'),
      ('below 0',            '[{"grade":"A","min_percent":-1,"max_percent":100,"remark":null,"is_pass":true}]',
                             'Grade A: from and to must be whole numbers from 0 to 100'),
      ('duplicate name',     '[{"grade":"A","min_percent":50,"max_percent":100,"remark":null,"is_pass":true},{"grade":" a ","min_percent":0,"max_percent":49,"remark":null,"is_pass":false}]',
                             'Two grades are called a. Give each grade its own name'),
      ('blank name',         '[{"grade":"  ","min_percent":0,"max_percent":100,"remark":null,"is_pass":true}]',
                             'Every grade needs a name'),
      ('name not text',      '[{"grade":7,"min_percent":0,"max_percent":100,"remark":null,"is_pass":true}]',
                             'Every grade needs a name'),
      ('number as text',     '[{"grade":"A","min_percent":"0","max_percent":100,"remark":null,"is_pass":true}]',
                             'Grade A: from and to must be whole numbers from 0 to 100'),
      ('missing max',        '[{"grade":"A","min_percent":0,"remark":null,"is_pass":true}]',
                             'Grade A: from and to must be whole numbers from 0 to 100'),
      ('remark not text',    '[{"grade":"A","min_percent":0,"max_percent":100,"remark":5,"is_pass":true}]',
                             'Grade A: the remark must be text'),
      ('is_pass missing',    '[{"grade":"A","min_percent":0,"max_percent":100,"remark":null}]',
                             'Grade A: say whether it is a pass grade'),
      ('is_pass as text',    '[{"grade":"A","min_percent":0,"max_percent":100,"remark":null,"is_pass":"true"}]',
                             'Grade A: say whether it is a pass grade'),
      ('element not object', '["A"]',
                             'Each grade needs a name, a from and to percentage, a remark and whether it is a pass'),
      ('not a list',         '{"grade":"A","min_percent":0,"max_percent":100,"remark":null,"is_pass":true}',
                             'Send the grade scale as a list of grades'),
      ('empty list',         '[]',
                             'Add at least one grade'),
      ('21 grades',          (select jsonb_agg(jsonb_build_object('grade', 'G' || i, 'min_percent', i * 4, 'max_percent', case when i = 20 then 100 else i * 4 + 3 end,
                                                                  'remark', null, 'is_pass', true))::text
                              from generate_series(0, 20) as i),
                             'A grade scale can have at most 20 grades')
    ) as t (label, grades, expected)
  loop
    begin
      perform public.set_grade_scale(v_org, v_nursery, v_case.grades::jsonb);
      v_log := v_log || E'\nFAIL 10 ' || v_case.label || ' accepted';
    exception when others then
      v_log := v_log || E'\n' || case when sqlstate = 'P0001' and sqlerrm = v_case.expected then 'PASS' else 'FAIL' end
            || ' 10 ' || v_case.label || ' refused [' || sqlerrm || ']';
    end;
  end loop;

  -- 11 a null list is refused like any other bad shape
  begin
    perform public.set_grade_scale(v_org, v_nursery, null);
    v_log := v_log || E'\nFAIL 11 null list accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = 'P0001' and sqlerrm = 'Send the grade scale as a list of grades' then 'PASS' else 'FAIL' end || ' 11 null list refused [' || sqlerrm || ']';
  end;

  -- 12 another school's section gets the same message as a section that doesn't exist; no leak
  v_msg1 := null; v_msg2 := null;
  begin
    perform public.set_grade_scale(v_org, v_other_primary, v_four);
  exception when others then v_msg1 := sqlstate || ' ' || sqlerrm;
  end;
  begin
    perform public.set_grade_scale(v_org, gen_random_uuid(), v_four);
  exception when others then v_msg2 := sqlstate || ' ' || sqlerrm;
  end;
  v_log := v_log || E'\n' || case when v_msg1 = v_msg2 and v_msg1 = 'P0001 That section no longer exists; refresh and try again' then 'PASS' else 'FAIL' end
        || ' 12 another school''s section refused like a missing one [' || coalesce(v_msg1, 'accepted') || ']';

  -- 13 using another school's id (with its own section) is refused as not a leader
  begin
    perform public.set_grade_scale(v_org2, v_other_primary, v_four);
    v_log := v_log || E'\nFAIL 13 owner changed another school''s grades';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 13 another school''s id refused [' || sqlerrm || ']';
  end;

  -- 14 none of the refusals above changed any grade row, in either school
  execute 'reset role';
  select string_agg(id::text || ':' || grade || ':' || min_percent || '-' || max_percent || ':' || coalesce(remark, '') || ':' || is_pass, ',' order by id)
    into v_after from public.grade_boundaries where organization_id in (v_org, v_org2);
  v_log := v_log || E'\n' || case when v_after = v_before then 'PASS' else 'FAIL' end || ' 14 refused calls left every grade row untouched';

  -- ── apply_grade_system ──
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';

  -- 15 WAEC on Primary and standard on Nursery, exact values
  perform public.apply_grade_system(v_org, v_primary, ' WAEC ');
  select string_agg(grade || ' ' || min_percent::int || '-' || max_percent::int || ' ' || remark || ' ' || case when is_pass then 'pass' else 'fail' end,
                    ',' order by min_percent desc) into v_txt
    from public.grade_boundaries where section_id = v_primary;
  v_ok := v_txt = 'A1 75-100 Excellent pass,B2 70-74 Very Good pass,B3 65-69 Good pass,C4 60-64 Credit pass,C5 55-59 Credit pass,'
               || 'C6 50-54 Credit pass,D7 45-49 Pass pass,E8 40-44 Pass pass,F9 0-39 Fail fail';
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 15a WAEC preset on Primary [' || coalesce(v_txt, 'null') || ']';
  perform public.apply_grade_system(v_org, v_nursery, 'standard');
  select string_agg(grade || ' ' || min_percent::int || '-' || max_percent::int || ' ' || remark || ' ' || case when is_pass then 'pass' else 'fail' end,
                    ',' order by min_percent desc) into v_txt
    from public.grade_boundaries where section_id = v_nursery;
  v_ok := v_txt = 'A 70-100 Excellent pass,B 60-69 Very Good pass,C 50-59 Good pass,D 45-49 Fair pass,E 40-44 Pass pass,F 0-39 Fail fail';
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 15b standard preset replaces Nursery''s scale [' || coalesce(v_txt, 'null') || ']';

  -- 16 apply_grade_system refusals
  for v_case in
    select * from (values
      ('unknown system',          v_nursery,       'igcse', 'Choose a grade system: waec or standard'),
      ('no system',               v_nursery,       null,    'Choose a grade system: waec or standard'),
      ('school-level set',        null::uuid,      'waec',  'Choose a section to apply the grade system to'),
      ('another school''s section', v_other_primary, 'waec', 'That section no longer exists; refresh and try again'),
      ('missing section',         gen_random_uuid(), 'waec', 'That section no longer exists; refresh and try again')
    ) as t (label, section_id, sys, expected)
  loop
    begin
      perform public.apply_grade_system(v_org, v_case.section_id, v_case.sys);
      v_log := v_log || E'\nFAIL 16 ' || v_case.label || ' accepted';
    exception when others then
      v_log := v_log || E'\n' || case when sqlstate = 'P0001' and sqlerrm = v_case.expected then 'PASS' else 'FAIL' end
            || ' 16 apply_grade_system: ' || v_case.label || ' refused [' || sqlerrm || ']';
    end;
  end loop;

  -- ── copy_section_grading ──
  -- Nursery gets its own columns first, so copying columns has something to replace.
  insert into public.score_columns (organization_id, section_id, name, max_score, sort_order) values (v_org, v_nursery, 'Observation', 100, 1);

  -- 17a columns only, from the school-level set into Nursery: replaces Nursery's columns, grades untouched
  perform public.copy_section_grading(v_org, null, v_nursery, true, false);
  select string_agg(name || ' ' || max_score::int || ' #' || sort_order, ',' order by sort_order) into v_txt
    from public.score_columns where section_id = v_nursery;
  v_ok := v_txt = 'CA 1 20 #1,CA 2 20 #2,Exam 60 #3'
      and (select count(*) from public.grade_boundaries where section_id = v_nursery and remark = 'Fair') = 1;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 17a columns only: Nursery''s columns replaced by the school''s, its grades kept [' || coalesce(v_txt, 'null') || ']';

  -- 17b grades only, from Senior Secondary into Nursery: Nursery's grades become WAEC, columns untouched
  perform public.copy_section_grading(v_org, v_secondary, v_nursery, false, true);
  select string_agg(grade || ' ' || min_percent::int || '-' || max_percent::int, ',' order by min_percent desc) into v_txt
    from public.grade_boundaries where section_id = v_nursery;
  v_ok := v_txt = 'A1 75-100,B2 70-74,B3 65-69,C4 60-64,C5 55-59,C6 50-54,D7 45-49,E8 40-44,F9 0-39'
      and (select count(*) from public.score_columns where section_id = v_nursery) = 3
      and (select count(*) from public.grade_boundaries where section_id = v_secondary) = 9;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 17b grades only: Nursery''s grades replaced by Senior Secondary''s, source kept [' || coalesce(v_txt, 'null') || ']';

  -- 17c both, from the school-level set into Primary ("Give Primary its own setup"): replaces Primary's WAEC
  perform public.copy_section_grading(v_org, null, v_primary, true, true);
  select string_agg(grade || ' ' || min_percent::int || '-' || max_percent::int || ' ' || remark, ',' order by min_percent desc) into v_txt
    from public.grade_boundaries where section_id = v_primary;
  v_ok := v_txt = 'A 70-100 Excellent,B 60-69 Very Good,C 50-59 Good,D 45-49 Fair,E 40-44 Pass,F 0-39 Weak'
      and (select string_agg(name, ',' order by sort_order) from public.score_columns where section_id = v_primary) = 'CA 1,CA 2,Exam'
      and (select string_agg(name, ',' order by sort_order) from public.score_columns_for_arm(v_pry1a)) = 'CA 1,CA 2,Exam'
      and (public.grade_for(v_pry1a, 30)).remark = 'Weak';
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 17c both from the school''s setup: Primary gets its own columns and grades [' || coalesce(v_txt, 'null') || ']';

  -- 17d copying again from another section replaces both kinds again (columns from Nursery, grades from Nursery)
  update public.score_columns set name = 'Test' where section_id = v_nursery and name = 'Exam';
  perform public.copy_section_grading(v_org, v_nursery, v_primary, true, true);
  v_ok := (select string_agg(name, ',' order by sort_order) from public.score_columns where section_id = v_primary) = 'CA 1,CA 2,Test'
      and (select count(*) from public.grade_boundaries where section_id = v_primary) = 9;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 17d a second copy replaces the target''s columns and grades';

  -- snapshot of both kinds before the copy refusals
  execute 'reset role';
  select string_agg(id::text || ':' || grade || ':' || min_percent || '-' || max_percent, ',' order by id)
         || '|' || (select string_agg(id::text || ':' || name || ':' || max_score || ':' || sort_order, ',' order by id)
                      from public.score_columns where organization_id in (v_org, v_org2))
    into v_before from public.grade_boundaries where organization_id in (v_org, v_org2);
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';

  -- 18 copy refusals (P0001), each changing nothing
  for v_case in
    select * from (values
      ('same section',                 v_nursery,         v_nursery,         true,  true,  'Choose a different set to copy from; a section can''t copy from itself'),
      ('no target',                    v_nursery,         null::uuid,        true,  true,  'Choose the section to copy to'),
      ('nothing chosen',               null::uuid,        v_nursery,         false, false, 'Choose what to copy: score columns, grades or both'),
      ('nothing chosen (nulls)',       null::uuid,        v_nursery,         null,  null,  'Choose what to copy: score columns, grades or both'),
      ('no columns in the source',     v_secondary,       v_nursery,         true,  false, 'There are no score columns to copy from Senior Secondary'),
      ('another school''s target',     null::uuid,        v_other_primary,   true,  true,  'That section no longer exists; refresh and try again'),
      ('another school''s source',     v_other_primary,   v_nursery,         true,  true,  'That section no longer exists; refresh and try again'),
      -- all or nothing: Nursery has columns but, after the next statement, no grades
      ('columns fine, grades missing', v_nursery,         v_secondary,       true,  true,  'There are no grades to copy from Nursery')
    ) as t (label, from_id, to_id, cols, grades, expected)
  loop
    if v_case.label = 'columns fine, grades missing' then
      perform public.remove_section_grade_scale(v_org, v_nursery);
      execute 'reset role';
      select string_agg(id::text || ':' || grade || ':' || min_percent || '-' || max_percent, ',' order by id)
             || '|' || (select string_agg(id::text || ':' || name || ':' || max_score || ':' || sort_order, ',' order by id)
                          from public.score_columns where organization_id in (v_org, v_org2))
        into v_before from public.grade_boundaries where organization_id in (v_org, v_org2);
      perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
      execute 'set local role authenticated';
    end if;
    begin
      perform public.copy_section_grading(v_org, v_case.from_id, v_case.to_id, v_case.cols, v_case.grades);
      v_log := v_log || E'\nFAIL 18 ' || v_case.label || ' accepted';
    exception when others then
      v_log := v_log || E'\n' || case when sqlstate = 'P0001' and sqlerrm = v_case.expected then 'PASS' else 'FAIL' end
            || ' 18 copy: ' || v_case.label || ' refused [' || sqlerrm || ']';
    end;
  end loop;
  execute 'reset role';
  select string_agg(id::text || ':' || grade || ':' || min_percent || '-' || max_percent, ',' order by id)
         || '|' || (select string_agg(id::text || ':' || name || ':' || max_score || ':' || sort_order, ',' order by id)
                      from public.score_columns where organization_id in (v_org, v_org2))
    into v_after from public.grade_boundaries where organization_id in (v_org, v_org2);
  v_ok := v_after = v_before
      and (select count(*) from public.score_columns where section_id = v_secondary) = 0;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 18z refused copies changed nothing (Senior Secondary got no columns when its grades part failed)';

  -- ── remove_section_grade_scale ──
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';

  -- 19 Primary goes back to the school's scale; removing again is fine; columns stay
  perform public.remove_section_grade_scale(v_org, v_primary);
  perform public.remove_section_grade_scale(v_org, v_primary);
  v_ok := (select count(*) from public.grade_boundaries where section_id = v_primary) = 0
      and (select count(*) from public.grade_boundaries_for_arm(v_pry1a)) = 6
      and (select count(*) from public.score_columns where section_id = v_primary) = 3;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 19 remove_section_grade_scale: Primary uses the school''s scale again (twice is fine)';

  -- 20 remove refusals
  for v_case in
    select * from (values
      ('school-level set',          null::uuid,        'Choose a section. The school''s own grade scale can''t be removed'),
      ('another school''s section', v_other_primary,   'That section no longer exists; refresh and try again')
    ) as t (label, section_id, expected)
  loop
    begin
      perform public.remove_section_grade_scale(v_org, v_case.section_id);
      v_log := v_log || E'\nFAIL 20 ' || v_case.label || ' accepted';
    exception when others then
      v_log := v_log || E'\n' || case when sqlstate = 'P0001' and sqlerrm = v_case.expected then 'PASS' else 'FAIL' end
            || ' 20 remove: ' || v_case.label || ' refused [' || sqlerrm || ']';
    end;
  end loop;
  execute 'reset role';  -- count as the table owner: RLS would hide the other school's rows
  v_ok := (select count(*) from public.grade_boundaries where organization_id = v_org2 and section_id is not null) = 9;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 20z the other school''s Senior Secondary scale is untouched';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';

  -- ── grade_for rounds first ──
  -- 21 Nursery back on the standard scale: 69.5 → 70 (A), 69.4 → 69 (B), 99.5 → 100 (A), 39.5 → 40 (E), 39.4 → F
  perform public.apply_grade_system(v_org, v_nursery, 'standard');
  v_txt := (public.grade_for(v_nur1a, 69.5)).grade || ',' || (public.grade_for(v_nur1a, 69.4)).grade || ','
        || (public.grade_for(v_nur1a, 99.5)).grade || ',' || (public.grade_for(v_nur1a, 39.5)).grade || ','
        || (public.grade_for(v_nur1a, 39.4)).grade || ',' || (public.grade_for(v_nur1a, 0)).grade || ','
        || (public.grade_for(v_nur1a, 100)).grade;
  v_ok := v_txt = 'A,B,A,E,F,F,A' and round(99.5::numeric) = 100;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 21 grade_for rounds half-up before grading [' || coalesce(v_txt, 'null') || ']';

  -- 22 grading_problems: nothing missing for a complete set
  v_ok := cardinality(public.grading_problems(v_org, v_nursery)) = 0
      and cardinality(public.grading_problems(v_org)) = 0;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 22 grading_problems is empty for complete sets';

  -- ── the deferred scale trigger ──
  -- 23 every set written so far passes the trigger when it is fired now
  begin
    execute 'set constraints all immediate';
    execute 'set constraints all deferred';
    v_log := v_log || E'\nPASS 23 every set the RPCs wrote passes the deferred check';
  exception when others then
    v_log := v_log || E'\nFAIL 23 the deferred check refused a set the RPCs wrote [' || sqlerrm || ']';
  end;

  -- 24 deleting a section cascades to its grades and columns, and the check accepts the now-empty set
  insert into public.sections (organization_id, name) values (v_org, 'Sixth Form') returning id into v_extra;
  perform public.apply_grade_system(v_org, v_extra, 'waec');
  perform public.copy_section_grading(v_org, null, v_extra, true, false);
  begin
    delete from public.sections where id = v_extra;
    execute 'set constraints all immediate';
    execute 'set constraints all deferred';
    v_ok := (select count(*) from public.grade_boundaries where section_id = v_extra) = 0
        and (select count(*) from public.score_columns where section_id = v_extra) = 0;
    v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 24 deleting a section still cascades its grades and columns';
  exception when others then
    v_log := v_log || E'\nFAIL 24 deleting a section with its own scale was refused [' || sqlerrm || ']';
  end;

  -- 25 a direct write that leaves a gap (as the table owner, e.g. the SQL editor) is refused at the check
  execute 'reset role';
  begin
    update public.grade_boundaries set max_percent = 64 where organization_id = v_org and section_id is null and grade = 'B';
    execute 'set constraints all immediate';
    v_log := v_log || E'\nFAIL 25 a gap left by a direct write passed the deferred check';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23514' and sqlerrm like 'A grade scale must cover 0 to 100 exactly%' then 'PASS' else 'FAIL' end
          || ' 25 the deferred check refuses a direct write that leaves a gap [' || sqlerrm || ']';
  end;
  execute 'set constraints all deferred';

  -- 26 a direct whole-set replace (delete, then insert, one transaction) passes, because the check waits for the end
  begin
    delete from public.grade_boundaries where section_id = v_nursery;
    insert into public.grade_boundaries (organization_id, section_id, grade, min_percent, max_percent, is_pass)
    values (v_org, v_nursery, 'P', 50, 100, true), (v_org, v_nursery, 'F', 0, 49, false);
    execute 'set constraints all immediate';
    execute 'set constraints all deferred';
    v_log := v_log || E'\nPASS 26 a delete-then-insert of a whole set passes the deferred check';
  exception when others then
    v_log := v_log || E'\nFAIL 26 a delete-then-insert of a whole set was refused [' || sqlerrm || ']';
  end;

  -- 27 the table checks: whole numbers, max <= 100, min <= max
  v_ok := true;
  begin
    insert into public.grade_boundaries (organization_id, section_id, grade, min_percent, max_percent) values (v_org, v_secondary, 'X', 0.5, 1);
    v_ok := false;
  exception when others then v_ok := v_ok and sqlstate = '23514'; end;
  begin
    insert into public.grade_boundaries (organization_id, section_id, grade, min_percent, max_percent) values (v_org, v_secondary, 'X', 0, 1.5);
    v_ok := false;
  exception when others then v_ok := v_ok and sqlstate = '23514'; end;
  begin
    insert into public.grade_boundaries (organization_id, section_id, grade, min_percent, max_percent) values (v_org, v_secondary, 'X', 0, 101);
    v_ok := false;
  exception when others then v_ok := v_ok and sqlstate = '23514'; end;
  begin
    insert into public.grade_boundaries (organization_id, section_id, grade, min_percent, max_percent) values (v_org, v_secondary, 'X', 5, 4);
    v_ok := false;
  exception when others then v_ok := v_ok and sqlstate = '23514'; end;
  begin
    insert into public.grade_boundaries (organization_id, section_id, grade, min_percent) values (v_org, v_secondary, 'X', 0);
    v_ok := false;
  exception when others then v_ok := v_ok and sqlstate = '23502'; end;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 27 the table refuses decimals, max above 100, min above max and a missing max';

  -- ── legacy (pre-34) sets ──
  -- 28 a legacy incomplete set (built as the table owner, then undone): grading_problems
  --    reports it, grade_for has nothing below its lowest grade, and it can't be copied
  begin
    delete from public.grade_boundaries where section_id = v_primary;
    insert into public.grade_boundaries (organization_id, section_id, grade, min_percent, max_percent, is_pass)
    values (v_org, v_primary, 'A', 70, 100, true), (v_org, v_primary, 'B', 40, 69, true);

    perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
    execute 'set local role authenticated';
    v_txt := array_to_string(public.grading_problems(v_org, v_primary), ' | ');
    v_ok := v_txt = 'No grade boundary at 0% | Grades don''t cover 0% to 100% yet'
        and (public.grade_for(v_pry1a, 30)) is null
        and (public.grade_for(v_pry1a, 39.5)).grade = 'B';
    v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 28a grading_problems reports a legacy incomplete set [' || coalesce(v_txt, 'null') || ']';
    begin
      perform public.copy_section_grading(v_org, v_primary, v_nursery, false, true);
      v_log := v_log || E'\nFAIL 28b a legacy incomplete set was copied';
    exception when others then
      v_log := v_log || E'\n' || case when sqlstate = 'P0001' and sqlerrm = 'The grades in Primary don''t cover 0 to 100 yet, so they can''t be copied. Fix them first' then 'PASS' else 'FAIL' end
            || ' 28b a legacy incomplete set can''t be copied [' || sqlerrm || ']';
    end;
    -- replacing it with set_grade_scale is the way out
    perform public.set_grade_scale(v_org, v_primary, v_four);
    v_ok := cardinality(public.grading_problems(v_org, v_primary)) = 0;
    execute 'reset role';
    execute 'set constraints all immediate';
    execute 'set constraints all deferred';
    v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 28c set_grade_scale replaces a legacy set with a complete one';
    raise exception 'undo legacy fixture';
  exception when others then
    if sqlerrm <> 'undo legacy fixture' then
      v_log := v_log || E'\nFAIL 28 legacy case stopped early [' || sqlerrm || ']';
    end if;
  end;
  execute 'reset role';

  -- 29 the backfill (migration 34, step 2) on a pre-34 shaped table: the decimal check finds
  --    decimal starts; whole starts get max = next start - 1, top = 100, per set; a set that
  --    doesn't start at 0 is filled the same way
  create temp table legacy_grades (
    id uuid primary key default gen_random_uuid(),
    organization_id uuid not null,
    section_id uuid,
    grade text not null,
    min_percent numeric(5, 2) not null,
    max_percent numeric(5, 2)
  ) on commit drop;
  insert into legacy_grades (organization_id, section_id, grade, min_percent) values
    (v_org,  null,      'A', 70), (v_org,  null,      'B', 60), (v_org,  null,      'F', 0),
    (v_org,  v_primary, 'A', 75), (v_org,  v_primary, 'C', 40),
    (v_org2, null,      'A', 70), (v_org2, null,      'B', 55.5);
  select count(*) into v_n from legacy_grades gb where gb.min_percent <> trunc(gb.min_percent);
  v_ok := v_n = 1;
  delete from legacy_grades where min_percent <> trunc(min_percent);
  update legacy_grades gb
  set max_percent = n.next_max
  from (
    select x.id,
           coalesce(lead(x.min_percent) over (partition by x.organization_id, x.section_id
                                              order by x.min_percent) - 1,
                    100) as next_max
    from legacy_grades x
  ) n
  where n.id = gb.id;
  select string_agg(case when organization_id = v_org2 then 'other ' when section_id is null then 'school ' else 'primary ' end
                    || grade || ' ' || min_percent::int || '-' || max_percent::int, ','
                    order by organization_id = v_org2, section_id nulls first, min_percent desc) into v_txt
    from legacy_grades;
  v_ok := v_ok and v_txt = 'school A 70-100,school B 60-69,school F 0-59,primary A 75-100,primary C 40-74,other A 70-100';
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 29 backfill (on a temp table): decimals found; max = next start - 1, top 100, per set [' || coalesce(v_txt, 'null') || ']';

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
