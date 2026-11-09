-- Access test for migrations 31 and 32 (register_student: the Add Student wizard in one call).
--
-- How to run: paste the whole file into the Supabase SQL editor and run it.
-- It acts as several fake users (via request.jwt.claims + set role), checks every
-- rule, then raises an exception on purpose so EVERYTHING is rolled back.
-- The "error" you see at the end is the report: each line is PASS or FAIL.
--
-- Requires migrations 01–32.
--
-- School "Test School" (TST): owner Olu, a teacher and a bursar on the app,
-- the standard structure with JSS 1A (standard curriculum) and JSS 1B
-- (switched off), last year's session (closed) and this year's (current),
-- and one parent already on file: Pam Parent, 0803 000 0000.
-- "Other School" (OTH) has its own parent, Oscar.

do $test$
declare
  v_log     text := '';
  v_ok      boolean;
  v_n       int;
  v_org     uuid;  v_claim  text;
  v_org2    uuid;  v_claim2 text;
  v_teacher_claim text;
  v_bursar_claim  text;
  v_jss1    uuid;
  v_jss1a   uuid;
  v_jss1b   uuid;
  v_old     uuid;  -- closed
  v_now     uuid;  -- current
  v_now_term uuid;
  v_optional   uuid;  -- optional on JSS 1A
  v_compulsory uuid;  -- compulsory on JSS 1A
  v_not_offered uuid; -- in the school, not on JSS 1A
  v_pam     uuid;
  v_oscar   uuid;
  v_res     jsonb;
  v_student uuid;
  v_new_parent uuid;
  v_students_before int;
  v_parents_before  int;
  v_links_before    int;
  v_one_parent jsonb;
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
  insert into public.parents (organization_id, first_name, last_name, phone)
    values (v_org2, 'Oscar', 'Elsewhere', '08039999999') returning id into v_oscar;

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_claim, 'Olu', 'Owner');
  insert into public.organization_members (organization_id, role) values (v_org, 'teacher')
    returning claim_code into v_teacher_claim;
  insert into public.organization_members (organization_id, role) values (v_org, 'bursar')
    returning claim_code into v_bursar_claim;

  -- structure and curriculum
  perform public.create_standard_structure(v_org);
  select id into v_jss1 from public.classes where organization_id = v_org and name = 'JSS 1';
  insert into public.class_arms (organization_id, class_id, name) values (v_org, v_jss1, 'A') returning id into v_jss1a;
  insert into public.class_arms (organization_id, class_id, name, is_active) values (v_org, v_jss1, 'B', false) returning id into v_jss1b;
  perform public.create_standard_subjects(v_org);
  select subject_id into v_optional   from public.arm_subjects where arm_id = v_jss1a and not is_compulsory limit 1;
  select subject_id into v_compulsory from public.arm_subjects where arm_id = v_jss1a and is_compulsory limit 1;
  select s.id into v_not_offered from public.subjects s
    where s.organization_id = v_org
      and not exists (select 1 from public.arm_subjects a where a.arm_id = v_jss1a and a.subject_id = s.id)
    limit 1;

  -- calendar: last year (ended, closed) and this year (current, with a current term)
  insert into public.academic_sessions (organization_id, name, starts_on, ends_on)
    values (v_org, '2024/25', '2024-09-09', '2025-07-18') returning id into v_old;
  insert into public.academic_sessions (organization_id, name, starts_on, ends_on)
    values (v_org, 'This year', current_date - 30, current_date + 300) returning id into v_now;
  insert into public.academic_terms (organization_id, session_id, name, sequence, starts_on, ends_on)
    values (v_org, v_now, 'First term', 1, current_date - 30, current_date + 60) returning id into v_now_term;
  perform public.set_current_term(v_now_term);
  perform public.close_session(v_old);

  insert into public.parents (organization_id, first_name, last_name, phone)
    values (v_org, 'Pam', 'Parent', '0803 000 0000') returning id into v_pam;

  -- teacher and bursar join
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_teacher","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_teacher_claim);
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_bursar","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_bursar_claim);

  -- the usual parents list: Pam (existing) as primary
  v_one_parent := jsonb_build_array(jsonb_build_object('parent_id', v_pam, 'relationship', 'mother', 'is_primary_contact', true));

  -- everything below runs as the owner unless it says otherwise
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';

  -- 01 a leader registers a student: existing parent + new parent, current session, one optional subject
  v_res := public.register_student(
    p_organization_id      => v_org,
    p_first_name           => 'Chidi',
    p_last_name            => 'Okafor',
    p_parents              => jsonb_build_array(
                                jsonb_build_object('parent_id', v_pam, 'relationship', 'mother', 'is_primary_contact', true),
                                jsonb_build_object('first_name', 'Emeka', 'last_name', 'Okafor', 'phone', '08035550143',
                                                   'title', 'Mr', 'gender', 'male', 'email', 'emeka@example.ng',
                                                   'occupation', 'Engineer', 'relationship', 'father',
                                                   'is_primary_contact', false)),
    p_arm_id               => v_jss1a,
    p_optional_subject_ids => array[v_optional, v_optional],
    p_gender               => 'male',
    p_date_of_birth        => '2014-03-02',
    p_genotype             => 'AA'
  );
  v_student    := (v_res -> 'student' ->> 'id')::uuid;
  v_new_parent := (v_res -> 'parent_ids' ->> 1)::uuid;
  v_ok := v_student is not null
      and v_res -> 'student' ->> 'admission_number' like 'TST/%'
      and v_res -> 'student' ->> 'status' = 'active'
      and jsonb_array_length(v_res -> 'parent_ids') = 2
      and (v_res -> 'parent_ids' ->> 0)::uuid = v_pam
      and (v_res -> 'placement' ->> 'session_id')::uuid = v_now
      and (v_res -> 'placement' ->> 'arm_id')::uuid = v_jss1a
      and v_res -> 'subject_ids' = jsonb_build_array(v_optional);
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 01 leader registers a student [' || coalesce(v_res -> 'student' ->> 'admission_number', 'no student') || ']';

  -- 02 every row was written
  v_ok := exists (select 1 from public.students where id = v_student and first_name = 'Chidi')
      and exists (select 1 from public.student_private_details where student_id = v_student
                    and date_of_birth = '2014-03-02' and genotype = 'AA')
      and exists (select 1 from public.parents where id = v_new_parent and organization_id = v_org
                    and first_name = 'Emeka' and phone = '08035550143' and title = 'Mr' and gender = 'male')
      and exists (select 1 from public.parent_private_details where parent_id = v_new_parent
                    and email = 'emeka@example.ng' and occupation = 'Engineer')
      and (select count(*) from public.student_parents where student_id = v_student) = 2
      and exists (select 1 from public.student_parents where student_id = v_student and parent_id = v_pam
                    and relationship = 'mother' and is_primary_contact)
      and exists (select 1 from public.student_parents where student_id = v_student and parent_id = v_new_parent
                    and relationship = 'father' and not is_primary_contact)
      and exists (select 1 from public.student_placements where student_id = v_student
                    and session_id = v_now and arm_id = v_jss1a)
      and (select count(*) from public.student_subjects where student_id = v_student) = 1
      and exists (select 1 from public.student_subjects where student_id = v_student
                    and session_id = v_now and subject_id = v_optional);
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 02 student, details, new parent, links, placement and subject all saved';

  -- 03 explicit session and no optional subjects (a sibling reusing Pam)
  v_res := public.register_student(v_org, 'Ada', 'Okafor', v_one_parent, v_jss1a, v_now);
  v_ok := (v_res -> 'placement' ->> 'session_id')::uuid = v_now
      and v_res -> 'subject_ids' = '[]'::jsonb
      and (select count(*) from public.student_parents where parent_id = v_pam) = 2;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 03 sibling reuses an existing parent, explicit session, no subjects';

  -- snapshot for the "nothing kept" checks below
  select count(*) into v_students_before from public.students where organization_id = v_org;
  select count(*) into v_parents_before  from public.parents  where organization_id = v_org;
  select count(*) into v_links_before    from public.student_parents where organization_id = v_org;

  -- 04 teacher refused
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_teacher","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    perform public.register_student(v_org, 'Tee', 'Kid', v_one_parent, v_jss1a);
    v_log := v_log || E'\nFAIL 04 teacher registered a student';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 04 teacher refused [' || sqlerrm || ']';
  end;

  -- 05 bursar refused
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_bursar","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    perform public.register_student(v_org, 'Bee', 'Kid', v_one_parent, v_jss1a);
    v_log := v_log || E'\nFAIL 05 bursar registered a student';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 05 bursar refused [' || sqlerrm || ']';
  end;

  -- 06 another school's owner refused
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner_b","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    perform public.register_student(v_org, 'Xen', 'Kid', v_one_parent, v_jss1a);
    v_log := v_log || E'\nFAIL 06 other school''s owner registered a student';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 06 other school''s owner refused [' || sqlerrm || ']';
  end;

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';

  -- 07 closed session refused
  begin
    perform public.register_student(v_org, 'Old', 'Kid', v_one_parent, v_jss1a, v_old);
    v_log := v_log || E'\nFAIL 07 registered into a closed session';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = 'P0001' and sqlerrm like '%closed%' then 'PASS' else 'FAIL' end || ' 07 closed session refused [' || sqlerrm || ']';
  end;

  -- 08 compulsory subject refused
  begin
    perform public.register_student(v_org, 'Com', 'Kid', v_one_parent, v_jss1a, null, array[v_compulsory]);
    v_log := v_log || E'\nFAIL 08 compulsory subject accepted as optional';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23514' and sqlerrm like '%compulsory%' then 'PASS' else 'FAIL' end || ' 08 compulsory subject refused [' || sqlerrm || ']';
  end;

  -- 09 subject the arm doesn't offer refused
  begin
    perform public.register_student(v_org, 'Off', 'Kid', v_one_parent, v_jss1a, null, array[v_not_offered]);
    v_log := v_log || E'\nFAIL 09 subject not offered to the arm accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23514' and sqlerrm like '%isn''t offered%' then 'PASS' else 'FAIL' end || ' 09 subject not offered refused [' || sqlerrm || ']';
  end;

  -- 10 no primary contact refused
  begin
    perform public.register_student(v_org, 'No', 'Primary',
      jsonb_build_array(jsonb_build_object('parent_id', v_pam, 'relationship', 'mother', 'is_primary_contact', false)), v_jss1a);
    v_log := v_log || E'\nFAIL 10 registered with no primary contact';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '22023' and sqlerrm like '%primary contact%' then 'PASS' else 'FAIL' end || ' 10 no primary contact refused [' || sqlerrm || ']';
  end;

  -- 11 two primary contacts refused
  begin
    perform public.register_student(v_org, 'Two', 'Primaries',
      jsonb_build_array(
        jsonb_build_object('parent_id', v_pam, 'relationship', 'mother', 'is_primary_contact', true),
        jsonb_build_object('first_name', 'Second', 'last_name', 'Parent', 'phone', '08031111111',
                           'relationship', 'father', 'is_primary_contact', true)), v_jss1a);
    v_log := v_log || E'\nFAIL 11 registered with two primary contacts';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '22023' and sqlerrm like 'Only one parent%' then 'PASS' else 'FAIL' end || ' 11 two primary contacts refused [' || sqlerrm || ']';
  end;

  -- 12 no parents refused
  begin
    perform public.register_student(v_org, 'No', 'Parents', '[]'::jsonb, v_jss1a);
    v_log := v_log || E'\nFAIL 12 registered with no parents';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '22023' and sqlerrm like '%at least one parent%' then 'PASS' else 'FAIL' end || ' 12 no parents refused [' || sqlerrm || ']';
  end;

  -- 13 another school's parent refused
  begin
    perform public.register_student(v_org, 'Cross', 'School',
      jsonb_build_array(jsonb_build_object('parent_id', v_oscar, 'relationship', 'father', 'is_primary_contact', true)), v_jss1a);
    v_log := v_log || E'\nFAIL 13 linked another school''s parent';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = 'P0002' then 'PASS' else 'FAIL' end || ' 13 other school''s parent refused [' || sqlerrm || ']';
  end;

  -- 14 the same parent twice refused
  begin
    perform public.register_student(v_org, 'Dup', 'Parent',
      jsonb_build_array(
        jsonb_build_object('parent_id', v_pam, 'relationship', 'mother', 'is_primary_contact', true),
        jsonb_build_object('parent_id', v_pam, 'relationship', 'guardian', 'is_primary_contact', false)), v_jss1a);
    v_log := v_log || E'\nFAIL 14 same parent listed twice accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '22023' and sqlerrm like '%listed twice%' then 'PASS' else 'FAIL' end || ' 14 duplicate parent refused [' || sqlerrm || ']';
  end;

  -- 15 a NEW parent with an existing parent's phone (other format) is refused, not merged
  begin
    perform public.register_student(v_org, 'Same', 'Phone',
      jsonb_build_array(jsonb_build_object('first_name', 'Pamela', 'last_name', 'Parent', 'phone', '+234 803 000 0000',
                                           'relationship', 'mother', 'is_primary_contact', true)), v_jss1a);
    v_log := v_log || E'\nFAIL 15 new parent with an existing phone accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23505' and sqlerrm like 'Pam Parent%existing parent%' then 'PASS' else 'FAIL' end || ' 15 existing phone refused, reuse suggested [' || sqlerrm || ']';
  end;

  -- 16 unknown relationship refused
  begin
    perform public.register_student(v_org, 'Bad', 'Relation',
      jsonb_build_array(jsonb_build_object('parent_id', v_pam, 'relationship', 'aunt', 'is_primary_contact', true)), v_jss1a);
    v_log := v_log || E'\nFAIL 16 unknown relationship accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '22023' and sqlerrm like '%father, mother, guardian or other%' then 'PASS' else 'FAIL' end || ' 16 unknown relationship refused [' || sqlerrm || ']';
  end;

  -- 17 switched-off arm, and an arm from another school, refused
  v_ok := true;
  begin
    perform public.register_student(v_org, 'Off', 'Arm', v_one_parent, v_jss1b);
    v_ok := false;
  exception when others then
    v_ok := sqlstate = 'P0001' and sqlerrm like '%switched off%';
  end;
  begin
    perform public.register_student(v_org, 'No', 'Arm', v_one_parent, gen_random_uuid());
    v_ok := false;
  exception when others then
    v_ok := v_ok and sqlstate = 'P0002';
  end;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 17 switched-off or unknown arm refused';

  -- 17b a class in a switched-off section is refused (migration 32); switching it back on allows it
  update public.sections set is_active = false where id = (select section_id from public.classes where id = v_jss1);
  v_ok := false;
  begin
    perform public.register_student(v_org, 'Off', 'Section', v_one_parent, v_jss1a);
  exception when others then
    v_ok := sqlstate = 'P0001' and sqlerrm like '%section is switched off%';
  end;
  update public.sections set is_active = true where id = (select section_id from public.classes where id = v_jss1);
  v_ok := v_ok
    and (select count(*) from public.students where organization_id = v_org) = v_students_before;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 17b switched-off section refused, nothing kept';

  -- 18 a failure after the first write (bad blood group fails in create_student,
  --    after the student row is inserted) keeps nothing: no student, parent or link
  begin
    perform public.register_student(
      p_organization_id => v_org,
      p_first_name      => 'Roll',
      p_last_name       => 'Back',
      p_parents         => jsonb_build_array(jsonb_build_object('first_name', 'Rita', 'last_name', 'Back',
                             'phone', '08032222222', 'relationship', 'mother', 'is_primary_contact', true)),
      p_arm_id          => v_jss1a,
      p_blood_group     => 'Z+');
    v_log := v_log || E'\nFAIL 18 invalid blood group accepted';
  exception when others then
    v_ok := sqlstate = '23514'
        and (select count(*) from public.students where organization_id = v_org) = v_students_before
        and (select count(*) from public.parents  where organization_id = v_org) = v_parents_before
        and (select count(*) from public.student_parents where organization_id = v_org) = v_links_before
        and not exists (select 1 from public.students where organization_id = v_org and first_name = 'Roll')
        and not exists (select 1 from public.parents where organization_id = v_org and phone = '08032222222');
    v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 18 failure rolls everything back [' || sqlerrm || ']';
  end;

  -- 19 none of the refusals above kept anything
  v_ok := (select count(*) from public.students where organization_id = v_org) = v_students_before
      and (select count(*) from public.parents  where organization_id = v_org) = v_parents_before
      and (select count(*) from public.student_parents where organization_id = v_org) = v_links_before;
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 19 refused calls left no rows behind';

  -- 20 anon can't call it
  execute 'reset role';
  execute 'set local role anon';
  begin
    perform public.register_student(v_org, 'Anon', 'Kid', v_one_parent, v_jss1a);
    v_log := v_log || E'\nFAIL 20 anon called register_student';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 20 anon refused [' || sqlerrm || ']';
  end;

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
