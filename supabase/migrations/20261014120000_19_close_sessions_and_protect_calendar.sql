-- 19 · Close a session, and protect the calendar from accidental loss
--
-- 1. Links to a session block its deletion instead of cascading. Deleting a
--    session no longer silently removes its class teachers and teaching
--    assignments; it fails while anything still uses it.
-- 2. A session's dates can't change so that one of its terms falls outside
--    them (terms were already checked; sessions weren't).
-- 3. close_session seals a finished year: the session, its terms and
--    everything recorded against it (class teachers, placements, teaching
--    assignments, student subjects) become read-only and can't be deleted,
--    and nothing new can be assigned to it. Leaders close a session once it
--    has ended and a new session is current with its current term set, so
--    new work always has somewhere to go. Only the owner can reopen it.
-- 4. session_usage returns what a session is used by, so the app can say why
--    "Remove session" is unavailable.

-- ─────────────────────────────────────────────────────────────
-- 1. Block instead of cascade
-- ─────────────────────────────────────────────────────────────
alter table public.class_teachers
  drop constraint class_teachers_session_fkey,
  add constraint class_teachers_session_fkey foreign key (organization_id, session_id)
    references public.academic_sessions (organization_id, id) on delete restrict;

alter table public.teaching_assignments
  drop constraint teaching_assignments_session_fkey,
  add constraint teaching_assignments_session_fkey foreign key (organization_id, session_id)
    references public.academic_sessions (organization_id, id) on delete restrict;

-- ─────────────────────────────────────────────────────────────
-- 3a. Closed state. Clients have no column grant on these; only
--     close_session / reopen_session write them.
-- ─────────────────────────────────────────────────────────────
alter table public.academic_sessions
  add column closed_at timestamptz,
  add column closed_by text;

-- ─────────────────────────────────────────────────────────────
-- 2 + 3b. Guard the session row itself
-- ─────────────────────────────────────────────────────────────
create function private.guard_session_change()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'DELETE' then
    if old.closed_at is not null then
      raise exception 'This session is closed. Its records are kept as history.' using errcode = 'P0001';
    end if;
    return old;
  end if;

  -- a closed session only changes when reopen_session reopens it
  if old.closed_at is not null
     and current_setting('hamrash.reopening_session', true) is distinct from 'on' then
    raise exception 'This session is closed and can''t be changed' using errcode = 'P0001';
  end if;

  if (new.starts_on, new.ends_on) is distinct from (old.starts_on, old.ends_on)
     and exists (
       select 1 from public.academic_terms t
       where t.session_id = new.id
         and (t.starts_on < new.starts_on or t.ends_on > new.ends_on)
     ) then
    raise exception 'A term falls outside these dates. Change that term first.' using errcode = '23514';
  end if;

  return new;
end;
$$;

create trigger academic_sessions_guard_change
  before update or delete on public.academic_sessions
  for each row execute function private.guard_session_change();

-- ─────────────────────────────────────────────────────────────
-- 3c. Everything recorded against a closed session is read-only
-- ─────────────────────────────────────────────────────────────
create function private.refuse_if_session_closed()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op in ('UPDATE', 'DELETE') and exists (
    select 1 from public.academic_sessions s
    where s.id = old.session_id and s.closed_at is not null
  ) then
    raise exception 'This belongs to a closed session and can''t be changed' using errcode = 'P0001';
  end if;

  if tg_op in ('INSERT', 'UPDATE') and exists (
    select 1 from public.academic_sessions s
    where s.id = new.session_id and s.closed_at is not null
  ) then
    raise exception 'That session is closed. Nothing new can be added to it; use the current session.' using errcode = 'P0001';
  end if;

  return coalesce(new, old);
end;
$$;

create trigger academic_terms_session_open
  before insert or update or delete on public.academic_terms
  for each row execute function private.refuse_if_session_closed();
create trigger class_teachers_session_open
  before insert or update or delete on public.class_teachers
  for each row execute function private.refuse_if_session_closed();
create trigger student_placements_session_open
  before insert or update or delete on public.student_placements
  for each row execute function private.refuse_if_session_closed();
create trigger teaching_assignments_session_open
  before insert or update or delete on public.teaching_assignments
  for each row execute function private.refuse_if_session_closed();
create trigger student_subjects_session_open
  before insert or update or delete on public.student_subjects
  for each row execute function private.refuse_if_session_closed();

-- ─────────────────────────────────────────────────────────────
-- 3d. Close and reopen
-- ─────────────────────────────────────────────────────────────
-- Leaders close a session once it has ended and another one is current.
create function public.close_session(p_session_id uuid)
returns public.academic_sessions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_session public.academic_sessions;
begin
  select s.* into v_session
  from public.academic_sessions s
  where s.id = p_session_id
    and private.can_manage_academics(s.organization_id)
  for update;
  if not found then
    raise exception 'Session not found, or you can''t manage this school''s calendar' using errcode = '42501';
  end if;
  if v_session.closed_at is not null then
    raise exception 'This session is already closed' using errcode = 'P0001';
  end if;
  if v_session.is_current then
    raise exception 'Make the new session current before closing this one' using errcode = 'P0001';
  end if;
  -- new work needs somewhere to go: a current session with a current term
  if not exists (
    select 1
    from public.academic_terms t
    join public.academic_sessions s on s.id = t.session_id
    where t.organization_id = v_session.organization_id
      and t.is_current
      and s.id <> v_session.id
      and s.closed_at is null
  ) then
    raise exception 'Set up the new session and its current term before closing this one' using errcode = 'P0001';
  end if;
  if v_session.ends_on >= current_date then
    raise exception 'This session hasn''t ended yet' using errcode = 'P0001';
  end if;

  update public.academic_sessions s
  set closed_at = now(),
      closed_by = (select auth.jwt() ->> 'sub')
  where s.id = p_session_id
  returning s.* into v_session;
  return v_session;
end;
$$;

-- Only the owner reopens a closed session, to fix a genuine mistake.
create function public.reopen_session(p_session_id uuid)
returns public.academic_sessions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_session public.academic_sessions;
begin
  select s.* into v_session
  from public.academic_sessions s
  where s.id = p_session_id
    and s.organization_id in (select private.my_org_ids(array['owner']::public.member_role[]))
  for update;
  if not found then
    raise exception 'Session not found, or only the owner can reopen it' using errcode = '42501';
  end if;
  if v_session.closed_at is null then
    return v_session;
  end if;

  perform set_config('hamrash.reopening_session', 'on', true);
  update public.academic_sessions s
  set closed_at = null,
      closed_by = null
  where s.id = p_session_id
  returning s.* into v_session;
  perform set_config('hamrash.reopening_session', 'off', true);
  return v_session;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- 4. What a session is used by
-- ─────────────────────────────────────────────────────────────
create function public.session_usage(p_session_id uuid)
returns table (
  terms                int,
  placements           int,
  student_subjects     int,
  class_teachers       int,
  teaching_assignments int
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.academic_sessions s
    where s.id = p_session_id
      and s.organization_id in (select private.my_org_ids())
  ) then
    raise exception 'Session not found' using errcode = '42501';
  end if;

  return query select
    (select count(*)::int from public.academic_terms       x where x.session_id = p_session_id),
    (select count(*)::int from public.student_placements   x where x.session_id = p_session_id),
    (select count(*)::int from public.student_subjects     x where x.session_id = p_session_id),
    (select count(*)::int from public.class_teachers       x where x.session_id = p_session_id),
    (select count(*)::int from public.teaching_assignments x where x.session_id = p_session_id);
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- Grants
-- ─────────────────────────────────────────────────────────────
revoke execute on function private.guard_session_change()      from public, anon, authenticated;
revoke execute on function private.refuse_if_session_closed()  from public, anon, authenticated;

revoke execute on function public.close_session(uuid)  from public, anon;
revoke execute on function public.reopen_session(uuid) from public, anon;
revoke execute on function public.session_usage(uuid)  from public, anon;
grant  execute on function public.close_session(uuid)  to authenticated;
grant  execute on function public.reopen_session(uuid) to authenticated;
grant  execute on function public.session_usage(uuid)  to authenticated;
