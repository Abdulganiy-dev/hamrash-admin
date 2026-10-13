-- Access test for migration 20 (a current term cannot be removed).
-- Run in the Supabase SQL editor. The final exception reports results and
-- rolls back every test row.

do $test$
declare
  v_log text := '';
  v_org uuid;
  v_claim text;
  v_session uuid;
  v_first uuid;
  v_second uuid;
  v_count int;
begin
  execute 'reset role';
  insert into public.platform_admins (clerk_user_id, full_name)
  values ('user_dummy_platform_admin', 'Dummy Platform Admin')
  on conflict (clerk_user_id) do nothing;

  perform set_config('request.jwt.claims', '{"sub":"user_dummy_platform_admin","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select c.organization_id, c.owner_claim_code into v_org, v_claim
    from public.create_organization('Current Term Test School', 'CTS') c;

  execute 'reset role';
  perform set_config('request.jwt.claims', '{"sub":"test_owner","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.redeem_claim_code(v_claim, 'Olu', 'Owner');

  insert into public.academic_sessions (organization_id, name, starts_on, ends_on)
    values (v_org, '2026/27', current_date - 90, current_date + 300)
    returning id into v_session;
  insert into public.academic_terms (organization_id, session_id, name, sequence, starts_on, ends_on)
    values (v_org, v_session, 'First term', 1, current_date - 90, current_date - 10)
    returning id into v_first;
  insert into public.academic_terms (organization_id, session_id, name, sequence, starts_on, ends_on)
    values (v_org, v_session, 'Second term', 2, current_date, current_date + 80)
    returning id into v_second;
  perform public.set_current_term(v_first);

  -- 01 direct DELETE of the current term fails with the intended message.
  begin
    delete from public.academic_terms where id = v_first;
    v_log := v_log || E'\nFAIL 01 deleted the current term';
  exception when others then
    v_log := v_log || E'\n' || case
      when sqlstate = 'P0001' and sqlerrm = 'Make another term current before removing this one'
        then 'PASS' else 'FAIL' end
      || ' 01 current term deletion is refused [' || sqlerrm || ']';
  end;
  select count(*) into v_count from public.academic_terms where id = v_first;
  v_log := v_log || E'\n' || case when v_count = 1 then 'PASS' else 'FAIL' end
    || ' 02 refused deletion keeps the current term';

  -- 03 ordinary non-current term remains deletable.
  delete from public.academic_terms where id = v_second;
  get diagnostics v_count = row_count;
  v_log := v_log || E'\n' || case when v_count = 1 then 'PASS' else 'FAIL' end
    || ' 03 non-current term can be removed';

  -- 04 after making another term current, the former current term can go.
  insert into public.academic_terms (organization_id, session_id, name, sequence, starts_on, ends_on)
    values (v_org, v_session, 'Second term', 2, current_date, current_date + 80)
    returning id into v_second;
  perform public.set_current_term(v_second);
  delete from public.academic_terms where id = v_first;
  get diagnostics v_count = row_count;
  v_log := v_log || E'\n' || case when v_count = 1 then 'PASS' else 'FAIL' end
    || ' 04 former current term can be removed after replacement';

  execute 'reset role';
  raise exception 'TEST REPORT (all changes rolled back):%', v_log;
end;
$test$;
