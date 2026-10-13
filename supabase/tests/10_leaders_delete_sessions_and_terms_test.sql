-- Access test for migration 18 (principals and VPs delete sessions and terms).
--
-- How to run: paste the whole file into the Supabase SQL editor and run it.
-- It acts as several fake users (via request.jwt.claims + set role), checks every
-- rule, then raises an exception on purpose so EVERYTHING is rolled back.
-- The "error" you see at the end is the report: each line is PASS or FAIL.

do $test$
declare
  v_log    text := '';
  v_org    uuid;
  v_claim  text;
  v_principal_claim text;
  v_vp_claim        text;
  v_bursar_claim    text;
  v_session  uuid;
  v_session2 uuid;
  v_term     uuid;
  v_term2    uuid;
  v_n      int;
begin
  execute 'reset role';
  insert into public.platform_admins (clerk_user_id, full_name)
  values ('user_dummy_platform_admin', 'Dummy Platform Admin')
  on conflict (clerk_user_id) do nothing;

  -- Setup: a school with an owner, a principal, a VP and a bursar
  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select c.organization_id, c.owner_claim_code into v_org, v_claim
    from public.create_organization('Test School', 'TST') c;

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_claim, 'Olu', 'Owner');
  insert into public.organization_members (organization_id, role) values (v_org, 'principal')
    returning claim_code into v_principal_claim;
  insert into public.organization_members (organization_id, role) values (v_org, 'vice_principal')
    returning claim_code into v_vp_claim;
  insert into public.organization_members (organization_id, role) values (v_org, 'bursar')
    returning claim_code into v_bursar_claim;

  -- Principal adds two sessions, each with a term
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_principal","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_principal_claim);
  insert into public.academic_sessions (organization_id, name, starts_on, ends_on)
    values (v_org, '2026/27', '2026-09-07', '2027-07-16') returning id into v_session;
  insert into public.academic_terms (organization_id, session_id, name, sequence, starts_on, ends_on)
    values (v_org, v_session, 'First term', 1, '2026-09-07', '2026-12-11') returning id into v_term;
  insert into public.academic_sessions (organization_id, name, starts_on, ends_on)
    values (v_org, '2027/28', '2027-09-06', '2028-07-14') returning id into v_session2;
  insert into public.academic_terms (organization_id, session_id, name, sequence, starts_on, ends_on)
    values (v_org, v_session2, 'First term', 1, '2027-09-06', '2027-12-10') returning id into v_term2;

  -- 01 bursar cannot delete a term
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_bursar","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_bursar_claim);
  delete from public.academic_terms where id = v_term;
  get diagnostics v_n = row_count;
  v_log := v_log || E'\n' || case when v_n = 0 then 'PASS' else 'FAIL' end || ' 01 bursar cannot delete a term [' || v_n || ' rows]';

  -- 02 principal deletes a term
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_principal","role":"authenticated"}', true);
  execute 'set local role authenticated';
  delete from public.academic_terms where id = v_term;
  get diagnostics v_n = row_count;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 02 principal deletes a term';

  -- 03 principal deletes the now-empty session
  delete from public.academic_sessions where id = v_session;
  get diagnostics v_n = row_count;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 03 principal deletes an empty session';

  -- 04 a session with terms still can't be deleted
  begin
    delete from public.academic_sessions where id = v_session2;
    v_log := v_log || E'\nFAIL 04 deleted a session that still has terms';
  exception when foreign_key_violation then
    v_log := v_log || E'\nPASS 04 a session with terms is kept [' || sqlerrm || ']';
  end;

  -- 05 VP deletes a term, then its session
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_vp","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_vp_claim);
  delete from public.academic_terms where id = v_term2;
  delete from public.academic_sessions where id = v_session2;
  get diagnostics v_n = row_count;
  v_log := v_log || E'\n' || case when v_n = 1 then 'PASS' else 'FAIL' end || ' 05 VP deletes a term and its session';

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
