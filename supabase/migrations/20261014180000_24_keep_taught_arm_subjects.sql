-- 24 · A subject stays on an arm while it's taught or chosen there
--
-- Taking a subject off an arm (deleting its arm_subjects row) used to leave
-- that arm's teaching assignments and students' optional choices for it
-- behind. The teacher would keep the class on their timetable and keep
-- seeing those students' records. Now it's refused while, in a session
-- that isn't closed:
--   - a teacher is assigned to that subject in that arm, or
--   - students placed in that arm chose it as an optional subject.
-- Unassign the teacher or remove the choices first. Closed sessions are
-- history and don't count.
--
-- Deleting the arm or the subject itself still takes its links with it;
-- those deletes have their own rules (migrations 21, 22 and 23).
--
-- arm_subject_usage() tells the app, ahead of time, which links are in use,
-- so it can grey out "Remove" and say why.

-- ─────────────────────────────────────────────────────────────
-- 1. Refuse removing a link that's in use
-- ─────────────────────────────────────────────────────────────
create function private.refuse_if_arm_subject_in_use()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_teacher text;
  v_choices int;
  v_subject text;
  v_arm     text;
begin
  -- The arm or subject is being deleted and this link is going with it.
  if not exists (select 1 from public.class_arms a where a.id = old.arm_id)
     or not exists (select 1 from public.subjects s where s.id = old.subject_id) then
    return old;
  end if;

  select trim(st.first_name || ' ' || st.last_name) into v_teacher
  from public.teaching_assignments ta
  join public.academic_sessions se on se.id = ta.session_id and se.closed_at is null
  join public.staff st on st.id = ta.staff_id
  where ta.arm_id = old.arm_id
    and ta.subject_id = old.subject_id
  limit 1;

  select count(*)::int into v_choices
  from public.student_subjects ss
  join public.academic_sessions se on se.id = ss.session_id and se.closed_at is null
  join public.student_placements sp on sp.student_id = ss.student_id and sp.session_id = ss.session_id
  where sp.arm_id = old.arm_id
    and ss.subject_id = old.subject_id;

  if v_teacher is null and v_choices = 0 then
    return old;
  end if;

  select s.name into v_subject from public.subjects s where s.id = old.subject_id;
  select c.name || case when length(a.name) = 1 then '' else ' ' end || a.name into v_arm
  from public.class_arms a
  join public.classes c on c.id = a.class_id
  where a.id = old.arm_id;

  if v_teacher is not null then
    raise exception '% teaches % in %. Unassign them first.', v_teacher, v_subject, v_arm
      using errcode = 'P0001';
  end if;

  raise exception '% in % chose %. Remove their choice first.',
    case when v_choices = 1 then '1 student' else v_choices || ' students' end, v_arm, v_subject
    using errcode = 'P0001';
end;
$$;

create trigger arm_subjects_in_use
  before delete on public.arm_subjects
  for each row execute function private.refuse_if_arm_subject_in_use();

-- ─────────────────────────────────────────────────────────────
-- 2. Which links are in use, for the app
-- ─────────────────────────────────────────────────────────────
create function public.arm_subject_usage(p_organization_id uuid)
returns table (
  arm_id       uuid,
  subject_id   uuid,
  teacher_name text,
  choices      int
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if p_organization_id not in (select private.my_org_ids()) then
    raise exception 'School not found' using errcode = '42501';
  end if;

  return query
  with taught as (
    select ta.arm_id, ta.subject_id, min(trim(st.first_name || ' ' || st.last_name)) as teacher_name
    from public.teaching_assignments ta
    join public.academic_sessions se on se.id = ta.session_id and se.closed_at is null
    join public.staff st on st.id = ta.staff_id
    where ta.organization_id = p_organization_id
    group by ta.arm_id, ta.subject_id
  ), chosen as (
    select sp.arm_id, ss.subject_id, count(*)::int as choices
    from public.student_subjects ss
    join public.academic_sessions se on se.id = ss.session_id and se.closed_at is null
    join public.student_placements sp on sp.student_id = ss.student_id and sp.session_id = ss.session_id
    where ss.organization_id = p_organization_id
    group by sp.arm_id, ss.subject_id
  )
  select coalesce(t.arm_id, c.arm_id), coalesce(t.subject_id, c.subject_id),
         t.teacher_name, coalesce(c.choices, 0)
  from taught t
  full join chosen c on c.arm_id = t.arm_id and c.subject_id = t.subject_id;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- Grants
-- ─────────────────────────────────────────────────────────────
revoke execute on function private.refuse_if_arm_subject_in_use()  from public, anon, authenticated;
revoke execute on function public.arm_subject_usage(uuid)          from public, anon;
grant  execute on function public.arm_subject_usage(uuid)          to authenticated;
