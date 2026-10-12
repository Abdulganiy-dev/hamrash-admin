-- Access test for migration 04 (sections, classes, arms, sessions, terms,
-- class teachers, student placements). Expects migration 06's narrowing:
-- teachers see only the students they teach in the current session.
--
-- How to run: paste the whole file into the Supabase SQL editor and run it.
-- It acts as several fake users, checks every rule, then raises an exception on
-- purpose so EVERYTHING is rolled back. The "error" at the end is the report.
--
-- Requires the dummy platform admin 'user_dummy_platform_admin'.

do $test$
declare
  v_log  text := '';
  v_n    int;
  v_rows int;
  v_ok   boolean;
  -- schools
  v_org  uuid;  v_claim  text;
  v_org2 uuid;  v_claim2 text;
  v_org3 uuid;  v_claim3 text;
  v_names text;
  -- people in School A
  v_teacher uuid;  v_t_code text;
  v_teacher2 uuid;
  v_teacher3 uuid;
  v_teacher4 uuid;
  v_bursar uuid;  v_b_code text;
  v_arm uuid;
  v_s1 uuid;  v_s2 uuid;
  v_p1 uuid;  v_p_code text;  v_s_code text;
  -- structure in School A
  v_nursery uuid;  v_primary uuid;  v_secondary uuid;
  v_pry1 uuid;  v_pry2 uuid;  v_jss1 uuid;
  v_pry1a uuid;  v_pry1b uuid;
  v_sess1 uuid;  v_sess2 uuid;
  v_t1 uuid;  v_t2 uuid;  v_t3 uuid;
  -- structure in School B
  v_b_class uuid;
begin
  -- ── setup ──────────────────────────────────────────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select c.organization_id, c.owner_claim_code into v_org,  v_claim  from public.create_organization('School A', 'SCA') c;
  select c.organization_id, c.owner_claim_code into v_org2, v_claim2 from public.create_organization('School B', 'SCB') c;
  select c.organization_id, c.owner_claim_code into v_org3, v_claim3 from public.create_organization('School C', 'SCC') c;

  -- School B gets one section + class (for cross-school checks)
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner_b","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_claim2, 'Bimbo', 'Owner');
  with s as (insert into public.sections (organization_id, name) values (v_org2, 'Primary') returning id)
  insert into public.classes (organization_id, section_id, name) select v_org2, s.id, 'Primary 1' from s returning id into v_b_class;

  -- 00a the standard structure is refused once a school has sections
  begin
    perform public.create_standard_structure(v_org2);
    v_log := v_log || E'\nFAIL 00a standard structure added on top of existing sections';
  exception when others then
    v_log := v_log || E'\n' || case when sqlerrm like '%already has sections%' then 'PASS' else 'FAIL' end || ' 00a standard structure only for a new school [' || sqlerrm || ']';
  end;

  -- 00b a new school gets Nursery 1–3, Primary 1–6, JSS 1–3, SS 1–3 in promotion order
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner_c","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_claim3, 'Chika', 'Owner');
  v_n := public.create_standard_structure(v_org3);
  select string_agg(c.name, ',' order by s.sort_order, c.sort_order) into v_names
    from public.classes c join public.sections s on s.id = c.section_id
    where c.organization_id = v_org3;
  v_log := v_log || E'\n' || case when v_n = 15
        and v_names = 'Nursery 1,Nursery 2,Nursery 3,Primary 1,Primary 2,Primary 3,Primary 4,Primary 5,Primary 6,JSS 1,JSS 2,JSS 3,SS 1,SS 2,SS 3'
        then 'PASS' else 'FAIL' end || ' 00b standard structure created in promotion order [' || v_n || ' classes]';
  select string_agg(c.name, ',') into v_names from public.classes c where c.organization_id = v_org3 and c.is_graduating_class;
  v_log := v_log || E'\n' || case when v_names = 'SS 3' then 'PASS' else 'FAIL' end || ' 00c SS 3 marked as the graduating class [' || coalesce(v_names, '') || ']';

  -- School A owner sets up people
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_claim, 'Olu', 'Owner');
  insert into public.staff (organization_id, first_name, last_name) values (v_org, 'Ada', 'Teacher') returning id into v_teacher;
  insert into public.staff (organization_id, first_name, last_name) values (v_org, 'Bisi', 'Teacher') returning id into v_teacher2;
  insert into public.staff (organization_id, first_name, last_name) values (v_org, 'Kemi', 'Teacher') returning id into v_teacher3;
  insert into public.staff (organization_id, first_name, last_name) values (v_org, 'Lola', 'Teacher') returning id into v_teacher4;
  insert into public.students (organization_id, first_name, last_name) values (v_org, 'Chidi', 'Pupil') returning id into v_s1;
  insert into public.students (organization_id, first_name, last_name) values (v_org, 'Dayo', 'Pupil') returning id into v_s2;
  insert into public.parents (organization_id, first_name, last_name, phone) values (v_org, 'Ngozi', 'Pupil', '0801111111') returning id into v_p1;
  insert into public.student_parents (organization_id, student_id, parent_id, relationship, is_primary_contact)
    values (v_org, v_s1, v_p1, 'mother', true);
  v_t_code := public.invite_staff(v_teacher);
  insert into public.staff (organization_id, first_name, last_name, staff_type) values (v_org, 'Bayo', 'Bursar', 'non_teaching') returning id into v_bursar;
  v_b_code := public.invite_staff(v_bursar, 'bursar');
  v_p_code := public.invite_parent(v_p1);
  v_s_code := public.invite_student(v_s1);

  -- 01 owner builds sections → classes → arms
  insert into public.sections (organization_id, name, sort_order, head_staff_id) values (v_org, 'Nursery', 1, null) returning id into v_nursery;
  insert into public.sections (organization_id, name, sort_order, head_staff_id) values (v_org, 'Primary', 2, v_teacher2) returning id into v_primary;
  insert into public.sections (organization_id, name, sort_order) values (v_org, 'Secondary', 3) returning id into v_secondary;
  insert into public.classes (organization_id, section_id, name, sort_order) values (v_org, v_primary, 'Primary 1', 1) returning id into v_pry1;
  insert into public.classes (organization_id, section_id, name, sort_order) values (v_org, v_primary, 'Primary 2', 2) returning id into v_pry2;
  insert into public.classes (organization_id, section_id, name, sort_order) values (v_org, v_secondary, 'JSS 1', 1) returning id into v_jss1;
  insert into public.class_arms (organization_id, class_id, name, capacity) values (v_org, v_pry1, 'A', 30) returning id into v_pry1a;
  insert into public.class_arms (organization_id, class_id, name) values (v_org, v_pry1, 'B') returning id into v_pry1b;
  v_log := v_log || E'\nPASS 01 owner builds sections, classes and arms';

  -- 02 class names are unique in a school (case-insensitive)
  begin
    insert into public.classes (organization_id, section_id, name) values (v_org, v_primary, 'primary 1');
    v_log := v_log || E'\nFAIL 02 duplicate class name accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23505' then 'PASS' else 'FAIL' end || ' 02 class name unique per school [' || sqlerrm || ']';
  end;

  -- 03 arm names are unique within a class (case-insensitive)
  begin
    insert into public.class_arms (organization_id, class_id, name) values (v_org, v_pry1, 'a');
    v_log := v_log || E'\nFAIL 03 duplicate arm name accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23505' then 'PASS' else 'FAIL' end || ' 03 arm name unique per class [' || sqlerrm || ']';
  end;

  -- 04 an arm cannot hang off another school's class
  begin
    insert into public.class_arms (organization_id, class_id, name) values (v_org, v_b_class, 'X');
    v_log := v_log || E'\nFAIL 04 cross-school arm accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23503' then 'PASS' else 'FAIL' end || ' 04 cross-school arm rejected [' || sqlerrm || ']';
  end;

  -- 05 capacity must be positive
  begin
    insert into public.class_arms (organization_id, class_id, name, capacity) values (v_org, v_pry2, 'A', 0);
    v_log := v_log || E'\nFAIL 05 zero capacity accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23514' then 'PASS' else 'FAIL' end || ' 05 capacity must be positive [' || sqlerrm || ']';
  end;

  -- 06 session + three terms; a term outside the session is rejected
  insert into public.academic_sessions (organization_id, name, starts_on, ends_on)
    values (v_org, '2026/2027', '2026-09-01', '2027-07-31') returning id into v_sess1;
  insert into public.academic_terms (organization_id, session_id, name, sequence, starts_on, ends_on)
    values (v_org, v_sess1, 'First Term', 1, '2026-09-07', '2026-12-18') returning id into v_t1;
  insert into public.academic_terms (organization_id, session_id, name, sequence, starts_on, ends_on)
    values (v_org, v_sess1, 'Second Term', 2, '2027-01-06', '2027-04-02') returning id into v_t2;
  insert into public.academic_terms (organization_id, session_id, name, sequence, starts_on, ends_on)
    values (v_org, v_sess1, 'Third Term', 3, '2027-04-26', '2027-07-23') returning id into v_t3;
  begin
    insert into public.academic_terms (organization_id, session_id, name, sequence, starts_on, ends_on)
      values (v_org, v_sess1, 'Summer', 4, '2027-08-01', '2027-08-30');
    v_log := v_log || E'\nFAIL 06 term outside session accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23514' then 'PASS' else 'FAIL' end || ' 06 term must fall within session [' || sqlerrm || ']';
  end;

  -- 07 term sequence is unique within a session
  begin
    insert into public.academic_terms (organization_id, session_id, name, sequence, starts_on, ends_on)
      values (v_org, v_sess1, 'Another First', 1, '2026-09-07', '2026-10-01');
    v_log := v_log || E'\nFAIL 07 duplicate term sequence accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23505' then 'PASS' else 'FAIL' end || ' 07 term sequence unique per session [' || sqlerrm || ']';
  end;

  -- 08 is_current is not client-writable
  begin
    update public.academic_terms set is_current = true where id = v_t1;
    v_log := v_log || E'\nFAIL 08 client wrote is_current';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 08 is_current only via functions [' || sqlerrm || ']';
  end;

  -- 09 set_current_term makes the term and its session current
  perform public.set_current_term(v_t2);
  select (select count(*) from public.academic_terms where organization_id = v_org and is_current)
       + (select count(*) from public.academic_sessions where organization_id = v_org and is_current)
    into v_n;
  v_ok := exists (select 1 from public.academic_terms where id = v_t2 and is_current)
      and exists (select 1 from public.academic_sessions where id = v_sess1 and is_current);
  v_log := v_log || E'\n' || case when v_ok and v_n = 2 then 'PASS' else 'FAIL' end || ' 09 set_current_term sets term + session';

  -- 10 switching session clears the old session and its current term
  insert into public.academic_sessions (organization_id, name, starts_on, ends_on)
    values (v_org, '2027/2028', '2027-09-01', '2028-07-31') returning id into v_sess2;
  perform public.set_current_session(v_sess2);
  v_ok := exists (select 1 from public.academic_sessions where id = v_sess2 and is_current)
      and not exists (select 1 from public.academic_sessions where id = v_sess1 and is_current)
      and not exists (select 1 from public.academic_terms where organization_id = v_org and is_current);
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 10 set_current_session clears old session and term';

  -- 11 going back to a term of the old session flips the session back too
  perform public.set_current_term(v_t1);
  v_ok := exists (select 1 from public.academic_sessions where id = v_sess1 and is_current)
      and not exists (select 1 from public.academic_sessions where id = v_sess2 and is_current)
      and exists (select 1 from public.academic_terms where id = v_t1 and is_current);
  v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 11 current term always belongs to current session';

  -- 12 placements: one arm per student per session; moving updates the row
  insert into public.student_placements (organization_id, student_id, session_id, arm_id) values (v_org, v_s1, v_sess1, v_pry1a);
  insert into public.student_placements (organization_id, student_id, session_id, arm_id) values (v_org, v_s2, v_sess1, v_pry1b);
  begin
    insert into public.student_placements (organization_id, student_id, session_id, arm_id) values (v_org, v_s1, v_sess1, v_pry1b);
    v_log := v_log || E'\nFAIL 12a student placed twice in one session';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23505' then 'PASS' else 'FAIL' end || ' 12a one placement per student per session [' || sqlerrm || ']';
  end;
  update public.student_placements set arm_id = v_pry1b where student_id = v_s1 and session_id = v_sess1;
  update public.student_placements set arm_id = v_pry1a where student_id = v_s1 and session_id = v_sess1;
  insert into public.student_placements (organization_id, student_id, session_id, arm_id) values (v_org, v_s1, v_sess2, v_pry1b);
  select count(*) into v_n from public.student_placements where student_id = v_s1;
  v_log := v_log || E'\n' || case when v_n = 2 then 'PASS' else 'FAIL' end || ' 12b placement history kept across sessions [' || v_n || ']';

  -- 13 one lead class teacher per arm per session
  insert into public.class_teachers (organization_id, session_id, arm_id, staff_id, is_lead) values (v_org, v_sess1, v_pry1a, v_teacher, true);
  insert into public.class_teachers (organization_id, session_id, arm_id, staff_id, is_lead) values (v_org, v_sess1, v_pry1a, v_teacher2, true);
  select count(*) filter (where is_lead), bool_or(staff_id = v_teacher2 and is_lead) into v_n, v_ok
    from public.class_teachers where session_id = v_sess1 and arm_id = v_pry1a;
  v_log := v_log || E'\n' || case when v_n = 1 and v_ok then 'PASS' else 'FAIL' end || ' 13 new lead demotes previous lead to assistant';

  -- 13b an arm can have a lead with no assistants (Primary 1B: lead only)
  insert into public.class_teachers (organization_id, session_id, arm_id, staff_id, is_lead) values (v_org, v_sess1, v_pry1b, v_teacher3, true);
  v_log := v_log || E'\nPASS 13b lead with no assistants allowed';

  -- 13c at most two assistants: 1A has Ada (demoted) + Kemi; Lola would be a third
  insert into public.class_teachers (organization_id, session_id, arm_id, staff_id, is_lead) values (v_org, v_sess1, v_pry1a, v_teacher3, false);
  begin
    insert into public.class_teachers (organization_id, session_id, arm_id, staff_id, is_lead) values (v_org, v_sess1, v_pry1a, v_teacher4, false);
    v_log := v_log || E'\nFAIL 13c third assistant accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23514' then 'PASS' else 'FAIL' end || ' 13c at most two assistants [' || sqlerrm || ']';
  end;

  -- 13d with two assistants, a new lead would push the old lead into a third slot: refused
  begin
    insert into public.class_teachers (organization_id, session_id, arm_id, staff_id, is_lead) values (v_org, v_sess1, v_pry1a, v_teacher4, true);
    v_log := v_log || E'\nFAIL 13d lead change created a third assistant';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23514' then 'PASS' else 'FAIL' end || ' 13d lead change can''t overflow assistants [' || sqlerrm || ']';
  end;

  -- 14 structure in use can't be deleted
  begin
    delete from public.classes where id = v_pry1;
    v_log := v_log || E'\nFAIL 14a class with arms deleted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23503' then 'PASS' else 'FAIL' end || ' 14a class with arms cannot be deleted [' || sqlerrm || ']';
  end;
  begin
    delete from public.class_arms where id = v_pry1a;
    v_log := v_log || E'\nFAIL 14b arm with placements deleted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23503' then 'PASS' else 'FAIL' end || ' 14b arm with placements cannot be deleted [' || sqlerrm || ']';
  end;
  delete from public.classes where id = v_jss1;
  get diagnostics v_n = row_count;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 14c unused class can be deleted';

  -- 15 an arm can't be moved to another class
  begin
    update public.class_arms set class_id = v_pry2 where id = v_pry1b;
    v_log := v_log || E'\nFAIL 15 arm moved to another class';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 15 arm cannot change class [' || sqlerrm || ']';
  end;

  -- ── teacher ────────────────────────────────────────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_teacher","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_t_code);

  select count(*) into v_n from public.classes;
  v_log := v_log || E'\n' || case when v_n = 2 then 'PASS' else 'FAIL' end || ' 16a teacher reads school''s classes [' || v_n || ']';
  select count(*) into v_n from public.student_placements;
  v_log := v_log || E'\n' || case when v_n = 2 then 'PASS' else 'FAIL' end || ' 16b class teacher reads only own pupils'' placements [' || v_n || ']';
  begin
    insert into public.classes (organization_id, section_id, name) values (v_org, v_primary, 'Primary 9');
    v_log := v_log || E'\nFAIL 16c teacher added a class';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 16c teacher cannot add classes [' || sqlerrm || ']';
  end;
  begin
    perform public.set_current_term(v_t3);
    v_log := v_log || E'\nFAIL 16d teacher changed the current term';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 16d teacher cannot change current term [' || sqlerrm || ']';
  end;
  begin
    perform public.create_standard_structure(v_org);
    v_log := v_log || E'\nFAIL 16e teacher ran the standard structure';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 16e teacher cannot set up the structure [' || sqlerrm || ']';
  end;

  -- ── bursar: reads placements, can't change them ───────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_bursar","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_b_code);

  select count(*) into v_n from public.student_placements;
  v_log := v_log || E'\n' || case when v_n = 3 then 'PASS' else 'FAIL' end || ' 16f bursar reads placements [' || v_n || ']';
  begin
    insert into public.student_placements (organization_id, student_id, session_id, arm_id) values (v_org, v_s2, v_sess2, v_pry1a);
    v_log := v_log || E'\nFAIL 16g bursar placed a student';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 16g bursar cannot place students [' || sqlerrm || ']';
  end;
  update public.student_placements set arm_id = v_pry1b where student_id = v_s1 and session_id = v_sess1;
  get diagnostics v_n = row_count;
  delete from public.student_placements where student_id = v_s2;
  get diagnostics v_rows = row_count;
  v_log := v_log || E'\n' || case when v_n = 0 and v_rows = 0 then 'PASS' else 'FAIL' end || ' 16h bursar cannot move or remove placements';

  -- ── parent ─────────────────────────────────────────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_parent","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_p_code);

  select count(*) into v_n from public.sections;
  v_log := v_log || E'\n' || case when v_n = 3 then 'PASS' else 'FAIL' end || ' 17a parent reads school structure [' || v_n || ' sections]';
  select count(*) into v_n from public.academic_terms where is_current;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 17b parent sees the current term';
  select count(*) into v_n from public.student_placements;
  v_log := v_log || E'\n' || case when v_n = 2 then 'PASS' else 'FAIL' end || ' 17c parent sees only own child''s placements [' || v_n || ']';
  begin
    insert into public.student_placements (organization_id, student_id, session_id, arm_id) values (v_org, v_s2, v_sess2, v_pry1a);
    v_log := v_log || E'\nFAIL 17d parent placed a student';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 17d parent cannot place students [' || sqlerrm || ']';
  end;
  update public.student_placements set arm_id = v_pry1b where student_id = v_s1 and session_id = v_sess1;
  get diagnostics v_n = row_count;
  delete from public.student_placements where student_id = v_s1;
  get diagnostics v_rows = row_count;
  v_log := v_log || E'\n' || case when v_n = 0 and v_rows = 0 then 'PASS' else 'FAIL' end || ' 17e parent cannot move or remove own child''s placement';

  -- ── student ────────────────────────────────────────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_student","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_s_code);
  select count(*) into v_n from public.student_placements;
  v_log := v_log || E'\n' || case when v_n = 2 then 'PASS' else 'FAIL' end || ' 18 student sees only own placements [' || v_n || ']';
  begin
    insert into public.student_placements (organization_id, student_id, session_id, arm_id) values (v_org, v_s2, v_sess2, v_pry1a);
    v_log := v_log || E'\nFAIL 18b student placed a student';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 18b student cannot place students [' || sqlerrm || ']';
  end;
  update public.student_placements set arm_id = v_pry1b where student_id = v_s1 and session_id = v_sess1;
  get diagnostics v_n = row_count;
  delete from public.student_placements where student_id = v_s1;
  get diagnostics v_rows = row_count;
  v_log := v_log || E'\n' || case when v_n = 0 and v_rows = 0 then 'PASS' else 'FAIL' end || ' 18c student cannot move or remove own placement';

  -- 18d nothing above changed the placements: Chidi is still in 1A for 2026/2027
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select arm_id into v_arm from public.student_placements where student_id = v_s1 and session_id = v_sess1;
  select count(*) into v_n from public.student_placements where organization_id = v_org;
  v_log := v_log || E'\n' || case when v_arm = v_pry1a and v_n = 3 then 'PASS' else 'FAIL' end || ' 18d placements unchanged after bursar, parent and student attempts';

  -- ── other school's owner ───────────────────────────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner_b","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select count(*) into v_n from public.classes;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 19a other school sees only its own classes [' || v_n || ']';
  select count(*) into v_n from public.student_placements;
  v_log := v_log || E'\n' || case when v_n = 0 then 'PASS' else 'FAIL' end || ' 19b other school sees no School A placements [' || v_n || ']';
  begin
    perform public.set_current_session(v_sess2);
    v_log := v_log || E'\nFAIL 19c other school changed School A''s session';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 19c other school cannot change School A''s session [' || sqlerrm || ']';
  end;

  -- ── platform admin, then suspension ────────────────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select count(*) into v_n from public.classes;
  v_log := v_log || E'\n' || case when v_n = 18 then 'PASS' else 'FAIL' end || ' 20 platform admin reads classes in every school [' || v_n || ']';
  perform public.set_organization_status(v_org, 'suspended');

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_parent","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select count(*) into v_n from public.sections;
  v_log := v_log || E'\n' || case when v_n = 0 then 'PASS' else 'FAIL' end || ' 21 suspended school: parent sees no structure [' || v_n || ']';

  -- 22 anon has no access
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  execute 'set local role anon';
  begin
    perform count(*) from public.classes;
    v_log := v_log || E'\nFAIL 22 anon read classes';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 22 anon cannot read classes [' || sqlerrm || ']';
  end;

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
