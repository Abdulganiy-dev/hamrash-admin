-- 38 · Move a student to another arm without stranding their subjects
--
-- A student is placed in one arm per session (student_placements). Leaders may
-- already UPDATE the placement's arm directly (migration 04), but that leaves
-- the student's optional subjects behind: student_subjects rows are checked
-- only on insert (migration 06), so after a plain move a student can be
-- "taking" French in an arm that doesn't offer French, or in one where it is
-- now compulsory. The student page's "Move to another arm" (9.15) needs the
-- move and the clean-up to happen together or not at all.
--
-- move_student_to_arm(p_student_id, p_arm_id) moves the student's placement in
-- the school's CURRENT session to p_arm_id, and removes the student's optional
-- subject choices for that session that the new arm doesn't offer as optional.
-- Choices the new arm still offers as optional are kept. It returns how many
-- choices were removed, so the app can say so.
--
-- Security: security invoker, so the existing RLS decides: only leaders
-- (owner, admin, principal, VP) can update placements and delete
-- student_subjects. A student or arm in another school is "not found" (the
-- placement lookup and the arm lookup are both scoped to the student's school).
-- Everything below runs as the caller; nothing is elevated.
--
-- Readable refusals, all before any write:
--   * no current session                          → P0001
--   * the student isn't placed this session       → P0001 (nothing to move)
--   * student not found / not yours               → 42501
--   * the arm isn't in the student's school       → 42501
--   * the arm is switched off                     → P0001
--   * already in that arm                         → P0001
--   * the arm's section is switched off           → P0001
-- A closed session is refused by the existing student_placements_session_open
-- trigger (migration 19) with its own message.
--
-- No new indexes: student_placements_pkey (student_id, session_id),
-- student_subjects_pkey and arm_subjects_pkey cover every lookup.
--
-- No DROP: a new function.
-- Test: supabase/tests/25_move_student_to_arm_test.sql
-- Design notes: docs/people-schema.md (Moving a student)

create function public.move_student_to_arm(
  p_student_id uuid,
  p_arm_id     uuid
)
returns integer
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_org        uuid;
  v_session    uuid;
  v_placement  public.student_placements;
  v_arm        public.class_arms;
  v_section_on boolean;
  v_removed    integer := 0;
begin
  select s.organization_id into v_org
  from public.students s
  where s.id = p_student_id;
  if not found then
    raise exception 'Student not found, or you can''t move them' using errcode = '42501';
  end if;

  select se.id into v_session
  from public.academic_sessions se
  where se.organization_id = v_org and se.is_current
  limit 1;
  if v_session is null then
    raise exception 'The school has no current session, so there is no class to move them in'
      using errcode = 'P0001';
  end if;

  select pl.* into v_placement
  from public.student_placements pl
  where pl.student_id = p_student_id and pl.session_id = v_session
  for update;
  if not found then
    raise exception 'This student isn''t in a class this session yet' using errcode = 'P0001';
  end if;

  select a.* into v_arm
  from public.class_arms a
  where a.id = p_arm_id and a.organization_id = v_org;
  if not found then
    raise exception 'That class arm wasn''t found at this school' using errcode = '42501';
  end if;
  if not v_arm.is_active then
    raise exception 'That arm is switched off, so it takes no new students' using errcode = 'P0001';
  end if;
  if v_placement.arm_id = p_arm_id then
    raise exception 'They are already in that arm' using errcode = 'P0001';
  end if;

  select sec.is_active into v_section_on
  from public.classes c
  join public.sections sec on sec.organization_id = c.organization_id and sec.id = c.section_id
  where c.id = v_arm.class_id and c.organization_id = v_org;
  if not coalesce(v_section_on, false) then
    raise exception 'That arm''s section is switched off, so it takes no new students' using errcode = 'P0001';
  end if;

  update public.student_placements pl
  set arm_id = p_arm_id
  where pl.student_id = p_student_id and pl.session_id = v_session;
  if not found then
    -- RLS refused the update: only leaders move students
    raise exception 'Only the owner, admins, the principal and vice principals can move students'
      using errcode = '42501';
  end if;

  -- optional choices the new arm doesn't offer as optional no longer apply
  with gone as (
    delete from public.student_subjects ss
    where ss.student_id = p_student_id
      and ss.session_id = v_session
      and not exists (
        select 1
        from public.arm_subjects asub
        where asub.arm_id = p_arm_id
          and asub.subject_id = ss.subject_id
          and not asub.is_compulsory
      )
    returning 1
  )
  select count(*) into v_removed from gone;

  return v_removed;
end;
$$;

revoke execute on function public.move_student_to_arm(uuid, uuid) from public, anon;
grant  execute on function public.move_student_to_arm(uuid, uuid) to authenticated;

-- ─────────────────────────────────────────────────────────────
-- Using it from the app (StudentService.moveToArm)
-- ─────────────────────────────────────────────────────────────
--   final removed = await _supabase.rpc('move_student_to_arm', params: {
--     'p_student_id': studentId,
--     'p_arm_id': armId,
--   }) as int;   // optional choices dropped because the new arm doesn't offer them

-- Down (manual):
--   drop function public.move_student_to_arm(uuid, uuid);
