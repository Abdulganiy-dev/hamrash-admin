-- Test for migration 39 (the standard structure in four sections: Nursery,
-- Primary, Junior Secondary, Senior Secondary; WAEC grades for Senior
-- Secondary, and still for a pre-39 "Secondary").
--
-- How to run: paste the whole file into the Supabase SQL editor and run it.
-- It acts as several fake users, checks every rule, then raises an exception on
-- purpose so EVERYTHING is rolled back. The "error" at the end is the report.
--
-- Requires migrations 01–39.
--
-- School "School A" gets the standard structure, subjects and grading, with
-- arms JSS 1A and SS 1A. "School B" was set up by hand before 39, with one
-- section named "Secondary".

do $test$
declare
  v_log    text := '';
  v_n      int;
  v_ok     boolean;
  v_txt    text;
  v_org    uuid;  v_claim  text;
  v_org2   uuid;  v_claim2 text;
  v_junior uuid;  v_senior uuid;  v_legacy uuid;
  v_jss1a  uuid;  v_ss1a   uuid;
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

  -- 01 someone from another school can't set up School A
  begin
    perform public.create_standard_structure(v_org);
    v_log := v_log || E'\nFAIL 01 another school''s owner set up the structure';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end
          || ' 01 another school''s owner is refused [' || sqlerrm || ']';
  end;

  -- ── School A: the standard structure ───────────────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_claim, 'Olu', 'Owner');

  -- 02 four sections in order, 15 classes
  v_n := public.create_standard_structure(v_org);
  select string_agg(s.name, ',' order by s.sort_order) into v_txt
    from public.sections s where s.organization_id = v_org;
  v_log := v_log || E'\n' || case when v_n = 15 and v_txt = 'Nursery,Primary,Junior Secondary,Senior Secondary'
        then 'PASS' else 'FAIL' end || ' 02 four sections, 15 classes [' || v_n || ': ' || coalesce(v_txt, 'null') || ']';

  -- 03 each section holds its own classes, in promotion order
  select string_agg(s.name || ':' || c.name, ',' order by s.sort_order, c.sort_order) into v_txt
    from public.classes c join public.sections s on s.id = c.section_id
    where c.organization_id = v_org and s.sort_order >= 3;
  v_log := v_log || E'\n' || case when v_txt =
        'Junior Secondary:JSS 1,Junior Secondary:JSS 2,Junior Secondary:JSS 3,'
        'Senior Secondary:SS 1,Senior Secondary:SS 2,Senior Secondary:SS 3'
        then 'PASS' else 'FAIL' end || ' 03 JSS 1–3 in Junior Secondary, SS 1–3 in Senior Secondary [' || coalesce(v_txt, 'null') || ']';

  select string_agg(s.name || ':' || c.name, ',' order by s.sort_order, c.sort_order) into v_txt
    from public.classes c join public.sections s on s.id = c.section_id
    where c.organization_id = v_org and s.sort_order <= 2;
  v_log := v_log || E'\n' || case when v_txt =
        'Nursery:Nursery 1,Nursery:Nursery 2,Nursery:Nursery 3,'
        'Primary:Primary 1,Primary:Primary 2,Primary:Primary 3,Primary:Primary 4,Primary:Primary 5,Primary:Primary 6'
        then 'PASS' else 'FAIL' end || ' 03b Nursery and Primary unchanged [' || coalesce(v_txt, 'null') || ']';

  -- 04 SS 3 is still the only graduating class
  select string_agg(c.name, ',') into v_txt from public.classes c
    where c.organization_id = v_org and c.is_graduating_class;
  v_log := v_log || E'\n' || case when v_txt = 'SS 3' then 'PASS' else 'FAIL' end
        || ' 04 SS 3 is the graduating class [' || coalesce(v_txt, '') || ']';

  -- 05 still only for a school with no sections
  begin
    perform public.create_standard_structure(v_org);
    v_log := v_log || E'\nFAIL 05 standard structure added twice';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = 'P0001' and sqlerrm like '%already has sections%' then 'PASS' else 'FAIL' end
          || ' 05 standard structure only for a new school [' || sqlerrm || ']';
  end;

  select id into v_junior from public.sections where organization_id = v_org and name = 'Junior Secondary';
  select id into v_senior from public.sections where organization_id = v_org and name = 'Senior Secondary';
  insert into public.class_arms (organization_id, class_id, name)
    select v_org, id, 'A' from public.classes where organization_id = v_org and name = 'JSS 1' returning id into v_jss1a;
  insert into public.class_arms (organization_id, class_id, name)
    select v_org, id, 'A' from public.classes where organization_id = v_org and name = 'SS 1' returning id into v_ss1a;

  -- 06 the standard subjects still reach both secondary sections (matched by class name)
  v_n := public.create_standard_subjects(v_org);
  select (select count(*) filter (where is_compulsory) || '+' || count(*) filter (where not is_compulsory)
            from public.arm_subjects where arm_id = v_jss1a)
      || ' / '
      || (select count(*) filter (where is_compulsory) || '+' || count(*) filter (where not is_compulsory)
            from public.arm_subjects where arm_id = v_ss1a)
    into v_txt;
  v_log := v_log || E'\n' || case when v_n = 41 and v_txt = '14+3 / 3+21' then 'PASS' else 'FAIL' end
        || ' 06 JSS 1A and SS 1A get their curriculum [' || v_n || ' subjects; compulsory+optional ' || coalesce(v_txt, 'null') || ']';

  -- 07 standard grading: WAEC for Senior Secondary, nothing of its own for Junior Secondary
  perform public.create_standard_grading(v_org);
  v_ok := (select count(*) from public.grade_boundaries where section_id = v_senior) = 9
      and (select count(*) from public.grade_boundaries where section_id = v_junior) = 0
      and (select count(*) from public.grade_boundaries where organization_id = v_org and section_id is not null) = 9
      and (select count(*) from public.grade_boundaries where organization_id = v_org and section_id is null) = 6;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 07 WAEC grades only on Senior Secondary';

  -- 08 an SS arm grades with WAEC, a JSS arm with the school's A–F
  v_txt := (public.grade_for(v_ss1a, 74.5)).grade || ',' || (public.grade_for(v_ss1a, 39)).grade || ','
        || (public.grade_for(v_jss1a, 74.5)).grade || ',' || (public.grade_for(v_jss1a, 39)).grade;
  v_log := v_log || E'\n' || case when v_txt = 'A1,F9,A,F' then 'PASS' else 'FAIL' end
        || ' 08 SS 1A uses WAEC, JSS 1A the school''s [' || coalesce(v_txt, 'null') || ']';

  -- ── School B: set up before 39, with a "Secondary" section ──
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner_b","role":"authenticated"}', true);
  execute 'set local role authenticated';
  insert into public.sections (organization_id, name, sort_order) values (v_org2, 'Secondary', 1) returning id into v_legacy;

  -- 09 an old "Secondary" section still gets WAEC
  perform public.create_standard_grading(v_org2);
  v_ok := (select count(*) from public.grade_boundaries where section_id = v_legacy) = 9;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 09 a pre-39 Secondary section still gets WAEC';

  -- 10 School A's grades are untouched by School B's setup
  execute 'reset role';  -- count as the table owner: RLS would hide the other school's rows
  v_ok := (select count(*) from public.grade_boundaries where organization_id = v_org) = 15;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 10 the other school''s grades are untouched';

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
