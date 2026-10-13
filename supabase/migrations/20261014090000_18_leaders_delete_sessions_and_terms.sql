-- 18 · Principals and vice principals can delete sessions and terms
--
-- They already add and edit the academic calendar; removing a wrong term or
-- session is part of the same job. Deleting still fails while anything
-- depends on it: a session with terms, student placements or student subjects
-- can't go (on delete restrict). Deleting a session also removes its class
-- teacher and teaching assignments (on delete cascade), which these roles can
-- already change.

drop policy "academic_sessions: owners and admins can delete"
  on public.academic_sessions;

create policy "academic_sessions: leaders can delete"
  on public.academic_sessions for delete to authenticated
  using (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));

drop policy "academic_terms: owners and admins can delete"
  on public.academic_terms;

create policy "academic_terms: leaders can delete"
  on public.academic_terms for delete to authenticated
  using (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
