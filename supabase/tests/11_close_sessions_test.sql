-- Access test for migration 19 (close a session, protect the calendar).
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
  v_old    uuid;   -- 2025/26, ended
  v_old_term uuid;
  v_now    uuid;   -- this year, current
  v_now_term uuid;
  v_session public.academic_sessions;
  v_usage  record;
  v_n      int;
begin
  execute 'reset role';
  insert into public.platform_admins (clerk_user_id, full_name)
  values ('user_dummy_platform_admin', 'Dummy Platform Admin')
  on conflict (clerk_user_id) do nothing;

  -- Setup: a school with an owner and a principal
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

  -- Principal builds last year (ended) and this year (current)
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_principal","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_principal_claim);
  insert into public.academic_sessions (organization_id, name, starts_on, ends_on)
    values (v_org, '2024/25', '2024-09-09', '2025-07-18') returning id into v_old;
  insert into public.academic_terms (organization_id, session_id, name, sequence, starts_on, ends_on)
    values (v_org, v_old, 'First term', 1, '2024-09-09', '2024-12-13') returning id into v_old_term;
  insert into public.academic_sessions (organization_id, name, starts_on, ends_on)
    values (v_org, 'Next year', current_date - 30, current_date + 300) returning id into v_now;
  perform public.set_current_session(v_old);

  -- 01 session dates can't shrink past one of its terms
  begin
    update public.academic_sessions set starts_on = '2024-10-01' where id = v_old;
    v_log := v_log || E'\nFAIL 01 session dates left a term outside';
  exception when check_violation then
    v_log := v_log || E'\nPASS 01 session dates must still hold every term [' || sqlerrm || ']';
  end;

  -- 02 the current session can't be closed
  begin
    perform public.close_session(v_old);
    v_log := v_log || E'\nFAIL 02 closed the current session';
  exception when others then
    v_log := v_log || E'\n' || case when sqlerrm like '%current%' then 'PASS' else 'FAIL' end || ' 02 current session can''t be closed [' || sqlerrm || ']';
  end;

  -- 03 a new current session without a current term isn't enough
  perform public.set_current_session(v_now);
  begin
    perform public.close_session(v_old);
    v_log := v_log || E'\nFAIL 03 closed with no current term to take new work';
  exception when others then
    v_log := v_log || E'\n' || case when sqlerrm like '%current term%' then 'PASS' else 'FAIL' end || ' 03 needs a current term in the new session [' || sqlerrm || ']';
  end;

  -- the new session gets its current term
  insert into public.academic_terms (organization_id, session_id, name, sequence, starts_on, ends_on)
    values (v_org, v_now, 'First term', 1, current_date - 30, current_date + 60) returning id into v_now_term;
  perform public.set_current_term(v_now_term);

  -- 03b the current session itself can't be closed
  begin
    perform public.close_session(v_now);
    v_log := v_log || E'\nFAIL 03b closed the current session';
  exception when others then
    v_log := v_log || E'\n' || case when sqlerrm like '%current%' or sqlerrm like '%ended%' then 'PASS' else 'FAIL' end || ' 03b the current session can''t be closed [' || sqlerrm || ']';
  end;

  -- 04 principal closes last year once the new session and term are current
  v_session := public.close_session(v_old);
  v_log := v_log || E'\n' || case when v_session.closed_at is not null and v_session.closed_by = 'test_principal' then 'PASS' else 'FAIL' end || ' 04 principal closes an ended session';

  -- 05 a closed session can't be renamed
  begin
    update public.academic_sessions set name = 'Renamed' where id = v_old;
    v_log := v_log || E'\nFAIL 05 renamed a closed session';
  exception when others then
    v_log := v_log || E'\nPASS 05 closed session can''t be renamed [' || sqlerrm || ']';
  end;

  -- 06 a closed session's terms can't be added, edited or removed
  begin
    insert into public.academic_terms (organization_id, session_id, name, sequence, starts_on, ends_on)
      values (v_org, v_old, 'Second term', 2, '2025-01-06', '2025-04-04');
    v_log := v_log || E'\nFAIL 06a added a term to a closed session';
  exception when others then
    v_log := v_log || E'\nPASS 06a no new terms in a closed session [' || sqlerrm || ']';
  end;
  begin
    update public.academic_terms set name = 'Renamed' where id = v_old_term;
    v_log := v_log || E'\nFAIL 06b edited a closed session''s term';
  exception when others then
    v_log := v_log || E'\nPASS 06b closed session''s terms are read-only [' || sqlerrm || ']';
  end;
  begin
    delete from public.academic_terms where id = v_old_term;
    v_log := v_log || E'\nFAIL 06c removed a closed session''s term';
  exception when others then
    v_log := v_log || E'\nPASS 06c closed session''s terms can''t be removed [' || sqlerrm || ']';
  end;

  -- 07 a closed session can't be deleted
  begin
    delete from public.academic_sessions where id = v_old;
    v_log := v_log || E'\nFAIL 07 deleted a closed session';
  exception when others then
    v_log := v_log || E'\nPASS 07 closed session is kept [' || sqlerrm || ']';
  end;

  -- 08 session_usage counts what a session holds
  select * into v_usage from public.session_usage(v_old);
  v_log := v_log || E'\n' || case when v_usage.terms = 1 and v_usage.placements = 0 then 'PASS' else 'FAIL' end
        || ' 08 session_usage [terms ' || v_usage.terms || ', placements ' || v_usage.placements || ']';

  -- 09 principal can't reopen
  begin
    perform public.reopen_session(v_old);
    v_log := v_log || E'\nFAIL 09 principal reopened a session';
  exception when others then
    v_log := v_log || E'\n' || case when sqlstate = '42501' then 'PASS' else 'FAIL' end || ' 09 only the owner reopens [' || sqlerrm || ']';
  end;

  -- 10 owner reopens; the session can be edited again
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  v_session := public.reopen_session(v_old);
  update public.academic_sessions set name = '2024/25 (fixed)' where id = v_old;
  get diagnostics v_n = row_count;
  v_log := v_log || E'\n' || case when v_session.closed_at is null and v_n = 1 then 'PASS' else 'FAIL' end || ' 10 owner reopens and can edit again';

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
