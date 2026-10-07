-- Access test for migration 03 (staff, students, parents, student_parents).
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
  v_ok   boolean;
  -- schools and owner codes
  v_org  uuid;  v_claim  text;
  v_org2 uuid;  v_claim2 text;
  -- school A records
  v_teacher_staff uuid;
  v_bursar_staff  uuid;
  v_s1 uuid;
  v_s2 uuid;
  v_p1 uuid;
  v_p2 uuid;
  v_p3 uuid;
  v_names text;
  -- school B records
  v_pb uuid;
  -- claim codes
  v_t_code  text;
  v_t_code2 text;
  v_b_code  text;
  v_p_code  text;
  v_s_code  text;
  -- numbering
  v_num  text;
  v_year text := extract(year from (now() at time zone 'Africa/Lagos')::date)::text;
begin
  -- ── setup: two schools, two owners ─────────────────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select c.organization_id, c.owner_claim_code into v_org,  v_claim  from public.create_organization('School A', 'SCA') c;
  select c.organization_id, c.owner_claim_code into v_org2, v_claim2 from public.create_organization('School B', 'SCB') c;

  -- 00 a school's number prefix must be 2-8 letters or digits
  begin
    perform public.create_organization('Bad Prefix School', 'k!');
    v_log := v_log || E'\nFAIL 00 bad prefix accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '22023' then 'PASS' else 'FAIL' end || ' 00 bad number prefix rejected [' || sqlerrm || ']';
  end;

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner_b","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_claim2);
  insert into public.parents (organization_id, first_name, last_name, phone)
    values (v_org2, 'Bola', 'Other', '0800000000') returning id into v_pb;
  insert into public.students (organization_id, first_name, last_name, admission_number)
    values (v_org2, 'Tunde', 'Other', 'B001');

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_claim);

  -- 01 owner adds staff, students, parents and links
  insert into public.staff (organization_id, first_name, last_name, job_title)
    values (v_org, 'Ada', 'Teacher', 'Maths Teacher') returning id into v_teacher_staff;
  insert into public.staff (organization_id, first_name, last_name, job_title, staff_type)
    values (v_org, 'Bayo', 'Bursar', 'Bursar', 'non_teaching') returning id into v_bursar_staff;
  insert into public.students (organization_id, first_name, last_name, admission_number, blood_group, genotype, photo_id)
    values (v_org, 'Chidi', 'Pupil', 'A001', 'O+', 'AA', 'cf-image-id-123') returning id into v_s1;
  insert into public.students (organization_id, first_name, last_name, admission_number)
    values (v_org, 'Dayo', 'Pupil', 'A002') returning id into v_s2;
  insert into public.parents (organization_id, title, first_name, last_name, phone)
    values (v_org, 'Mrs', 'Ngozi', 'Pupil', '0801111111') returning id into v_p1;
  insert into public.student_parents (organization_id, student_id, parent_id, relationship, is_primary_contact)
    values (v_org, v_s1, v_p1, 'mother', true);
  -- an unrelated parent (Dayo's mother) that Chidi's parents must NOT see
  insert into public.parents (organization_id, title, first_name, last_name, phone)
    values (v_org, 'Mrs', 'Funke', 'Other', '0803333333') returning id into v_p3;
  insert into public.student_parents (organization_id, student_id, parent_id, relationship, is_primary_contact)
    values (v_org, v_s2, v_p3, 'mother', true);
  v_log := v_log || E'\nPASS 01 owner adds staff, students, parents and links';

  -- 02 invite_staff returns a code; asking again returns the same code
  v_t_code  := public.invite_staff(v_teacher_staff);
  v_t_code2 := public.invite_staff(v_teacher_staff);
  v_log := v_log || E'\n' || case when v_t_code ~ '^[A-Z0-9]{8}$' and v_t_code = v_t_code2 then 'PASS' else 'FAIL' end
        || ' 02 invite_staff is repeatable before redeem [' || v_t_code || ' / ' || v_t_code2 || ']';

  -- 03 staff cannot be invited as owner
  begin
    perform public.invite_staff(v_bursar_staff, 'owner');
    v_log := v_log || E'\nFAIL 03 staff invited as owner';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '22023' then 'PASS' else 'FAIL' end || ' 03 staff cannot be invited as owner [' || sqlerrm || ']';
  end;

  v_b_code := public.invite_staff(v_bursar_staff, 'bursar');
  v_p_code := public.invite_parent(v_p1);
  v_s_code := public.invite_student(v_s1);

  -- 04 member_id is not client-writable
  begin
    update public.staff set member_id = null where id = v_teacher_staff;
    v_log := v_log || E'\nFAIL 04 client wrote member_id';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 04 member_id is not client-writable [' || sqlerrm || ']';
  end;

  -- 05 admission numbers are unique within a school
  begin
    insert into public.students (organization_id, first_name, last_name, admission_number) values (v_org, 'Dup', 'Licate', 'A001');
    v_log := v_log || E'\nFAIL 05 duplicate admission number accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23505' then 'PASS' else 'FAIL' end || ' 05 admission number unique per school [' || sqlerrm || ']';
  end;

  -- 05b staff numbers are generated with the prefix given at school creation
  select s.staff_number into v_num from public.staff s where s.id = v_bursar_staff;
  v_log := v_log || E'\n' || case when v_num = 'SCA/STF/0002' then 'PASS' else 'FAIL' end || ' 05b staff number generated [' || v_num || ']';

  -- 05c admission numbers are generated when left blank
  insert into public.students (organization_id, first_name, last_name) values (v_org, 'Auto', 'One')
    returning admission_number into v_num;
  v_log := v_log || E'\n' || case when v_num = 'SCA/' || v_year || '/0001' then 'PASS' else 'FAIL' end || ' 05c admission number generated [' || v_num || ']';

  -- 05d owner can correct the prefix (and set the logo id); the counter carries on
  update public.organizations set number_prefix = 'SCX', logo_id = 'cf-logo-id-1' where id = v_org;
  insert into public.students (organization_id, first_name, last_name) values (v_org, 'Auto', 'Two')
    returning admission_number into v_num;
  v_log := v_log || E'\n' || case when v_num = 'SCX/' || v_year || '/0002' then 'PASS' else 'FAIL' end || ' 05d corrected prefix used [' || v_num || ']';

  -- 05e a number already typed in by the school is skipped
  insert into public.students (organization_id, first_name, last_name, admission_number)
    values (v_org, 'Manual', 'Three', 'SCX/' || v_year || '/0003');
  insert into public.students (organization_id, first_name, last_name) values (v_org, 'Auto', 'Four')
    returning admission_number into v_num;
  v_log := v_log || E'\n' || case when v_num = 'SCX/' || v_year || '/0004' then 'PASS' else 'FAIL' end || ' 05e taken number skipped [' || v_num || ']';

  -- 05f admission year comes from admission_date when given (own counter per year)
  insert into public.students (organization_id, first_name, last_name, admission_date) values (v_org, 'Auto', 'Old', '2024-09-10')
    returning admission_number into v_num;
  v_log := v_log || E'\n' || case when v_num = 'SCX/2024/0001' then 'PASS' else 'FAIL' end || ' 05f admission year from admission_date [' || v_num || ']';

  -- remove the numbering students so later counts stay at S1 + S2
  delete from public.students where organization_id = v_org and id not in (v_s1, v_s2);

  -- 06 a student cannot be linked to a parent from another school
  begin
    insert into public.student_parents (organization_id, student_id, parent_id, relationship) values (v_org, v_s1, v_pb, 'guardian');
    v_log := v_log || E'\nFAIL 06 cross-school link accepted';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '23503' then 'PASS' else 'FAIL' end || ' 06 cross-school link rejected [' || sqlerrm || ']';
  end;

  -- 07 making a second parent primary clears the first
  insert into public.parents (organization_id, title, first_name, last_name, phone)
    values (v_org, 'Mr', 'Emeka', 'Pupil', '0802222222') returning id into v_p2;
  insert into public.student_parents (organization_id, student_id, parent_id, relationship, is_primary_contact)
    values (v_org, v_s1, v_p2, 'father', true);
  select count(*) filter (where is_primary_contact), bool_or(parent_id = v_p2 and is_primary_contact)
    into v_n, v_ok
    from public.student_parents where student_id = v_s1;
  v_log := v_log || E'\n' || case when v_n = 1 and v_ok then 'PASS' else 'FAIL' end || ' 07 one primary contact per student';

  -- 08 owner A cannot see school B's people
  select count(*) into v_n from public.students;
  v_log := v_log || E'\n' || case when v_n = 2 then 'PASS' else 'FAIL' end || ' 08 owner sees only own school''s students [' || v_n || ' rows]';

  -- ── teacher ────────────────────────────────────────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_teacher","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_t_code);

  select count(*) into v_n from public.students;
  v_log := v_log || E'\n' || case when v_n = 2 then 'PASS' else 'FAIL' end || ' 09a teacher reads all students in school [' || v_n || ']';
  select count(*) into v_n from public.parents;
  v_log := v_log || E'\n' || case when v_n = 3 then 'PASS' else 'FAIL' end || ' 09b teacher reads all parents in school [' || v_n || ']';
  select count(*) into v_n from public.staff;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 09c teacher reads only own staff record [' || v_n || ']';

  begin
    insert into public.students (organization_id, first_name, last_name) values (v_org, 'Sneaky', 'Add');
    v_log := v_log || E'\nFAIL 10a teacher added a student';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 10a teacher cannot add students [' || sqlerrm || ']';
  end;
  update public.students set first_name = 'Changed' where id = v_s1;
  get diagnostics v_n = row_count;
  v_log := v_log || E'\n' || case when v_n = 0 then 'PASS' else 'FAIL' end || ' 10b teacher cannot edit students';
  begin
    perform public.invite_student(v_s2);
    v_log := v_log || E'\nFAIL 10c teacher issued a login';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 10c teacher cannot issue logins [' || sqlerrm || ']';
  end;

  -- ── bursar ─────────────────────────────────────────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_bursar","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_b_code);

  select count(*) into v_n from public.students;
  v_log := v_log || E'\n' || case when v_n = 2 then 'PASS' else 'FAIL' end || ' 11a bursar reads students [' || v_n || ']';
  select count(*) into v_n from public.staff;
  v_log := v_log || E'\n' || case when v_n = 2 then 'PASS' else 'FAIL' end || ' 11b bursar reads all staff [' || v_n || ']';
  begin
    insert into public.staff (organization_id, first_name, last_name) values (v_org, 'Sneaky', 'Hire');
    v_log := v_log || E'\nFAIL 11c bursar added staff';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 11c bursar cannot add staff [' || sqlerrm || ']';
  end;

  -- ── parent ─────────────────────────────────────────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_parent","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_p_code);

  select count(*) into v_n from public.students;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 12a parent sees only own child [' || v_n || ']';
  select count(*), string_agg(first_name, ', ' order by first_name) into v_n, v_names from public.parents;
  v_log := v_log || E'\n' || case when v_n = 2 and v_names = 'Emeka, Ngozi' then 'PASS' else 'FAIL' end
        || ' 12b parent sees self and child''s other parent, not unrelated parents [' || coalesce(v_names, '') || ']';
  select count(*) into v_n from public.student_parents;
  v_log := v_log || E'\n' || case when v_n = 2 then 'PASS' else 'FAIL' end || ' 12c parent sees all of own child''s links, not others [' || v_n || ']';
  select count(*) into v_n from public.staff;
  v_log := v_log || E'\n' || case when v_n = 0 then 'PASS' else 'FAIL' end || ' 12d parent sees no staff records [' || v_n || ']';

  -- ── student ────────────────────────────────────────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_student","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_s_code);

  select count(*) into v_n from public.students;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 13a student sees only own record [' || v_n || ']';
  select count(*) into v_n from public.student_parents;
  v_log := v_log || E'\n' || case when v_n = 2 then 'PASS' else 'FAIL' end || ' 13b student sees own parent links [' || v_n || ']';
  select count(*) into v_n from public.staff;
  v_log := v_log || E'\n' || case when v_n = 0 then 'PASS' else 'FAIL' end || ' 13c student sees no staff records [' || v_n || ']';

  -- ── owner again ────────────────────────────────────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';

  -- 14 a redeemed login cannot be re-issued
  begin
    perform public.invite_parent(v_p1);
    v_log := v_log || E'\nFAIL 14 login re-issued after redeem';
  exception when others then
    v_log := v_log || E'\n' || case when sqlerrm like '%already has a login%' then 'PASS' else 'FAIL' end || ' 14 redeemed login cannot be re-issued [' || sqlerrm || ']';
  end;

  -- 15 deleting a parent removes their links
  delete from public.parents where id = v_p2;
  select count(*) into v_n from public.student_parents where student_id = v_s1;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 15 deleting a parent removes their links [' || v_n || ' left]';

  -- 15b another school's owner gets the same generic error for a real record
  --     in School A as for an id that doesn't exist (nothing is revealed)
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner_b","role":"authenticated"}', true);
  execute 'set local role authenticated';
  begin
    perform public.invite_student(v_s2);
    v_log := v_log || E'\nFAIL 15b other school issued a login for School A';
  exception when others then
    v_ok := sqlstate = '42501' and sqlerrm like '%not found, or you can''t issue logins%';
    begin
      perform public.invite_student(gen_random_uuid());
      v_ok := false;
    exception when others then
      v_ok := v_ok and sqlstate = '42501' and sqlerrm like '%not found, or you can''t issue logins%';
    end;
    v_log := v_log || E'\n' || case when v_ok then 'PASS' else 'FAIL' end || ' 15b same error for other school''s record and unknown id [' || sqlerrm || ']';
  end;

  -- ── platform admin ─────────────────────────────────────────
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select count(*) into v_n from public.students;
  v_log := v_log || E'\n' || case when v_n = 3 then 'PASS' else 'FAIL' end || ' 16 platform admin reads students in every school [' || v_n || ']';
  perform public.set_organization_status(v_org, 'suspended');

  -- 17 suspended school: teacher and parent lose access
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_teacher","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select count(*) into v_n from public.students;
  v_log := v_log || E'\n' || case when v_n = 0 then 'PASS' else 'FAIL' end || ' 17a suspended school: teacher sees no students [' || v_n || ']';

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_parent","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select count(*) into v_n from public.students;
  v_log := v_log || E'\n' || case when v_n = 0 then 'PASS' else 'FAIL' end || ' 17b suspended school: parent sees no children [' || v_n || ']';

  -- 18 anon has no access
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  execute 'set local role anon';
  begin
    perform count(*) from public.students;
    v_log := v_log || E'\nFAIL 18 anon read students';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 18 anon cannot read students [' || sqlerrm || ']';
  end;

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
