-- 36 · Student list: search, filters, subject, teacher and pages in one call
--
-- The People tab's Students side (9.1) used to read up to 1000 students, with
-- their placements embedded, and group them in the app. There was no search,
-- no filter and no page. list_students does it on the server: it returns one
-- page of the school's students, in class order, with the filtered total and
-- how many students each class arm has, so the headers stay right while only
-- part of the list is loaded.
--
-- What the schema already knows (nothing new is needed):
--   * a student's class this session is student_placements (student, session
--     → arm); an arm belongs to a class, a class to a section;
--   * a subject is OFFERED to an arm by arm_subjects. Compulsory subjects are
--     taken by everyone in the arm and are NOT in student_subjects; optional
--     ones are taken only by the students with a student_subjects row for the
--     session (migration 06);
--   * the teacher is the teaching_assignments row for (session, arm, subject),
--     one per triple (its primary key), so a subject can have a different
--     teacher in every arm and none in some.
-- So "students taking Mathematics" is: placed in an arm that offers
-- Mathematics, and either it is compulsory there or they have the optional
-- row. The teacher is read from the student's OWN arm, never from "a teacher
-- who teaches Mathematics".
--
-- Security: security invoker, so the existing RLS decides everything
-- (students, student_placements, student_subjects, arm_subjects,
-- teaching_assignments, staff, sections, classes, class_arms). The school is
-- also scoped explicitly (every table joined on organization_id =
-- p_organization_id), so a platform admin or someone in two schools only sees
-- this one, and a caller outside the school gets no rows, a total of 0 and no
-- groups, the same as an empty school. The Students list is meant for the
-- admin app roles (owner, admin, principal, VP, bursar); a teacher who calls
-- it only gets what RLS lets a teacher read, so a subject filter would not
-- list optional-subject students for them.
--
-- No new indexes. The paths are all there already:
--   * students_org_name_idx (organization_id, last_name, first_name, id)
--   * student_placements_arm_session_idx / _session_idx
--   * arm_subjects_pkey (arm_id, subject_id) and arm_subjects_subject_idx
--   * student_subjects_pkey (student_id, session_id, subject_id) and
--     student_subjects_session_subject_idx
--   * teaching_assignments_pkey (session_id, arm_id, subject_id)
-- Every call counts the school's students that match (the total and the
-- group counts), so it reads the school's rows once anyway; a school has
-- hundreds to a few thousand students. Search is LIKE on lower(...) over those
-- rows. pg_trgm isn't enabled on the project and this migration doesn't enable
-- extensions; if a school ever has tens of thousands of students, enable
-- pg_trgm and add a GIN index on the same lower(concat_ws(...)) expression.
--
-- No DROP: a new function.
-- Test: supabase/tests/23_list_students_rpc_test.sql
-- Design notes: docs/people-schema.md (Listing students)

-- ─────────────────────────────────────────────────────────────
-- list_students
-- ─────────────────────────────────────────────────────────────
-- Returns ONE jsonb object (one round trip, one snapshot, so the rows, the
-- total and the group counts can't disagree). supabase-flutter returns it as
-- a Map from rpc().
--   {
--     "rows": [ {
--         "id", "first_name", "middle_name", "last_name", "admission_number",
--         "photo_url", "status",
--         "arm":     null | { "id", "name", "class_id", "class_name",
--                             "section_id", "class_sort_order" },
--         "subject": null | { "id", "name", "is_compulsory",
--                             "teacher": null | { "id", "first_name", "last_name" } }
--       }, … ],
--     "next_cursor": "…" | null,    -- null on the last page
--     "total":       n,             -- students matching every filter
--     "groups":      [ { "arm_id": uuid | null, "count": n }, … ]
--   }
-- "arm" is null for a student with no placement in the session. "subject" is
-- only set when p_subject_id is given; its "teacher" is null when nobody is
-- assigned to that subject in the student's arm. "groups" counts the whole
-- filtered set (not just this page), one entry per arm, and arm_id null for
-- students with no arm.
--
-- Parameters
--   p_search      Case-insensitive, partial. Each word must match the name
--                 (first, middle or last) or the admission number. Blank = no
--                 search.
--   p_session_id  The session whose placements, optional subjects and teachers
--                 count. null = the school's current session. With no current
--                 session nobody has an arm, so the class, section, arm and
--                 subject filters match nobody.
--   p_section_id, p_class_id, p_arm_id
--                 Narrow to the students placed there this session. They
--                 combine (all must hold). Students with no arm never match.
--   p_subject_id  Students taking that subject this session (see above).
--   p_statuses    The student's status. null or {} = all. The app sends
--                 {active} by default.
--   p_sort        'class' (default): sections, classes and arms in their set
--                 order, students with no arm last, then last name, first
--                 name, id. 'name': last name, first name, id.
--   p_limit       Page size, default 30, clamped to 1..100.
--   p_cursor      null for the first page, then the previous next_cursor.
--
-- Filters are applied before the page is cut, so the total, the group counts
-- and the rows all describe the same filtered set. Every student appears
-- once: placements are one per student per session, the subject is matched
-- with EXISTS, and the teacher join is on the assignment's primary key.
--
-- Keyset pagination, like list_staff (migration 30): the cursor holds the last
-- row's sort key with the id as the tie-break, so a student added or removed
-- while someone scrolls never repeats or skips anyone. The cursor is opaque
-- base64 of {"s": sort, "k": [sort key…]}. Start again with null when any
-- filter, the search or the sort changes. A cursor from the other sort is
-- refused (22023).
create function public.list_students(
  p_organization_id uuid,
  p_search          text                   default null,
  p_session_id      uuid                   default null,
  p_section_id      uuid                   default null,
  p_class_id        uuid                   default null,
  p_arm_id          uuid                   default null,
  p_subject_id      uuid                   default null,
  p_statuses        public.student_status[] default null,
  p_sort            text                   default 'class',
  p_limit           int                    default 30,
  p_cursor          text                   default null
)
returns jsonb
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  v_sort     text := coalesce(nullif(trim(p_sort), ''), 'class');
  v_limit    int  := least(greatest(coalesce(p_limit, 30), 1), 100);
  v_search   text := nullif(lower(trim(p_search)), '');
  v_patterns text[];
  v_session  uuid;
  v_cursor   jsonb;
  v_k        jsonb;    -- the cursor's sort key
  v_total    int;
  v_groups   jsonb;
  v_rows     jsonb;
  v_next_key jsonb;
begin
  if p_organization_id is null then
    raise exception 'Choose a school to list its students' using errcode = '22023';
  end if;

  if v_sort not in ('class', 'name') then
    raise exception 'Unknown sort "%". Use class or name', p_sort using errcode = '22023';
  end if;

  v_session := coalesce(
    p_session_id,
    (select s.id
     from public.academic_sessions s
     where s.organization_id = p_organization_id and s.is_current
     limit 1)
  );

  if v_search is not null then
    select array_agg('%' || regexp_replace(w, '([\\%_])', '\\\1', 'g') || '%' order by i)
    into v_patterns
    from unnest(regexp_split_to_array(v_search, '\s+')) with ordinality as t(w, i)
    where w <> '';
  end if;

  if p_cursor is not null then
    begin
      v_cursor := convert_from(decode(p_cursor, 'base64'), 'UTF8')::jsonb;
      if v_cursor ->> 's' is distinct from v_sort then
        raise exception using errcode = '22023', message = 'wrong sort';
      end if;
      v_k := v_cursor -> 'k';
      -- every part must be there and cast, or the cursor is refused
      if v_sort = 'class' then
        if jsonb_array_length(v_k) <> 9
           or (v_k ->> 0)::int is null or (v_k ->> 1)::int is null
           or (v_k ->> 2)::int is null or (v_k ->> 3)::uuid is null
           or (v_k ->> 4) is null      or (v_k ->> 5)::uuid is null
           or (v_k ->> 6) is null      or (v_k ->> 7) is null
           or (v_k ->> 8)::uuid is null then
          raise exception using errcode = '22023', message = 'incomplete';
        end if;
      else
        if jsonb_array_length(v_k) <> 3
           or (v_k ->> 0) is null or (v_k ->> 1) is null
           or (v_k ->> 2)::uuid is null then
          raise exception using errcode = '22023', message = 'incomplete';
        end if;
      end if;
    exception when others then
      raise exception 'This page cursor is not valid for this list. Load the list again from the start'
        using errcode = '22023';
    end;
  end if;

  with base as materialized (
    select
      st.id, st.first_name, st.middle_name, st.last_name, st.admission_number,
      st.photo_url, st.status,
      pl.arm_id,
      a.name       as arm_name,
      c.id         as class_id,
      c.name       as class_name,
      c.sort_order as class_sort,
      sec.id       as section_id,
      sec.sort_order as section_sort,
      sub.id       as sub_id,
      sub.name     as sub_name,
      asub.is_compulsory as sub_compulsory,
      t.id         as t_id,
      t.first_name as t_first,
      t.last_name  as t_last,
      -- sort keys. Students with no arm sort after every arm.
      case when pl.arm_id is null then 1 else 0 end                  as grp_rank,
      coalesce(sec.sort_order, 0)                                    as sec_key,
      coalesce(c.sort_order, 0)                                      as cls_key,
      coalesce(c.id,        '00000000-0000-0000-0000-000000000000')  as class_key,
      coalesce(lower(a.name), '')                                    as arm_key,
      coalesce(pl.arm_id,   '00000000-0000-0000-0000-000000000000')  as arm_key_id,
      lower(st.last_name)                                            as last_key,
      lower(st.first_name)                                           as first_key
    from public.students st
    left join public.student_placements pl
           on pl.organization_id = st.organization_id
          and pl.student_id      = st.id
          and pl.session_id      = v_session
    left join public.class_arms a
           on a.organization_id = pl.organization_id and a.id = pl.arm_id
    left join public.classes c
           on c.organization_id = a.organization_id and c.id = a.class_id
    left join public.sections sec
           on sec.organization_id = c.organization_id and sec.id = c.section_id
    -- the subject, the arm's offer of it and the arm's teacher for it: each
    -- is one row at most (primary keys), so they never repeat a student
    left join public.subjects sub
           on sub.organization_id = st.organization_id and sub.id = p_subject_id
    left join public.arm_subjects asub
           on asub.organization_id = st.organization_id
          and asub.arm_id          = pl.arm_id
          and asub.subject_id      = sub.id
    left join public.teaching_assignments ta
           on ta.organization_id = st.organization_id
          and ta.session_id      = v_session
          and ta.arm_id          = pl.arm_id
          and ta.subject_id      = sub.id
    left join public.staff t
           on t.organization_id = ta.organization_id and t.id = ta.staff_id
    where st.organization_id = p_organization_id
      and (coalesce(cardinality(p_statuses), 0) = 0 or st.status = any (p_statuses))
      and (p_section_id is null or sec.id = p_section_id)
      and (p_class_id   is null or c.id   = p_class_id)
      and (p_arm_id     is null or pl.arm_id = p_arm_id)
      and (
        p_subject_id is null
        or (
          asub.arm_id is not null
          and (
            asub.is_compulsory
            or exists (
              select 1
              from public.student_subjects ss
              where ss.organization_id = st.organization_id
                and ss.student_id      = st.id
                and ss.session_id      = v_session
                and ss.subject_id      = p_subject_id
            )
          )
        )
      )
      and (
        v_search is null
        or not exists (
          select 1
          from unnest(v_patterns) as w(pattern)
          where lower(concat_ws(' ', st.first_name, st.middle_name, st.last_name,
                                     st.admission_number)) not like w.pattern
        )
      )
  ),
  totals as (
    select count(*)::int as total from base
  ),
  group_counts as (
    select coalesce(jsonb_agg(jsonb_build_object('arm_id', g.arm_id, 'count', g.n)
                              order by g.arm_id nulls last), '[]'::jsonb) as groups
    from (select b.arm_id, count(*)::int as n from base b group by b.arm_id) g
  ),
  page as (
    select b.*,
           row_number() over (
             order by
               case when v_sort = 'class' then b.grp_rank   end,
               case when v_sort = 'class' then b.sec_key    end,
               case when v_sort = 'class' then b.cls_key    end,
               case when v_sort = 'class' then b.class_key  end,
               case when v_sort = 'class' then b.arm_key    end,
               case when v_sort = 'class' then b.arm_key_id end,
               b.last_key, b.first_key, b.id
           ) as rn
    from base b
    where v_cursor is null
       or (v_sort = 'class'
           and (b.grp_rank, b.sec_key, b.cls_key, b.class_key, b.arm_key, b.arm_key_id,
                b.last_key, b.first_key, b.id)
             > ((v_k ->> 0)::int, (v_k ->> 1)::int, (v_k ->> 2)::int, (v_k ->> 3)::uuid,
                (v_k ->> 4), (v_k ->> 5)::uuid, (v_k ->> 6), (v_k ->> 7), (v_k ->> 8)::uuid))
       or (v_sort = 'name'
           and (b.last_key, b.first_key, b.id)
             > ((v_k ->> 0), (v_k ->> 1), (v_k ->> 2)::uuid))
    order by rn
    limit v_limit + 1
  )
  select
    tt.total,
    g.groups,
    coalesce((
      select jsonb_agg(
               jsonb_build_object(
                 'id',               p.id,
                 'first_name',       p.first_name,
                 'middle_name',      p.middle_name,
                 'last_name',        p.last_name,
                 'admission_number', p.admission_number,
                 'photo_url',        p.photo_url,
                 'status',           p.status,
                 'arm', case when p.arm_id is null then null else jsonb_build_object(
                   'id',               p.arm_id,
                   'name',             p.arm_name,
                   'class_id',         p.class_id,
                   'class_name',       p.class_name,
                   'section_id',       p.section_id,
                   'class_sort_order', p.class_sort
                 ) end,
                 'subject', case when p.sub_id is null then null else jsonb_build_object(
                   'id',            p.sub_id,
                   'name',          p.sub_name,
                   'is_compulsory', p.sub_compulsory,
                   'teacher', case when p.t_id is null then null else jsonb_build_object(
                     'id',         p.t_id,
                     'first_name', p.t_first,
                     'last_name',  p.t_last
                   ) end
                 ) end
               ) order by p.rn)
      from page p
      where p.rn <= v_limit
    ), '[]'::jsonb),
    -- a row past the page means there is more: the cursor is the last row shown
    (select case when v_sort = 'class'
                 then jsonb_build_array(p.grp_rank, p.sec_key, p.cls_key, p.class_key, p.arm_key,
                                        p.arm_key_id, p.last_key, p.first_key, p.id)
                 else jsonb_build_array(p.last_key, p.first_key, p.id) end
     from page p
     where p.rn = v_limit
       and exists (select 1 from page q where q.rn = v_limit + 1))
  into v_total, v_groups, v_rows, v_next_key
  from totals tt, group_counts g;

  return jsonb_build_object(
    'rows',        v_rows,
    'next_cursor', case when v_next_key is null then null
                        else translate(encode(convert_to(
                               jsonb_build_object('s', v_sort, 'k', v_next_key)::text, 'UTF8'), 'base64'),
                             E'\n', '') end,
    'total',       v_total,
    'groups',      v_groups
  );
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- Privileges
-- ─────────────────────────────────────────────────────────────
revoke execute on function public.list_students(uuid, text, uuid, uuid, uuid, uuid, uuid,
                                                public.student_status[], text, int, text) from public, anon;
grant  execute on function public.list_students(uuid, text, uuid, uuid, uuid, uuid, uuid,
                                                public.student_status[], text, int, text) to authenticated;

-- ─────────────────────────────────────────────────────────────
-- Using it from the app (StudentService.listStudentsPage)
-- ─────────────────────────────────────────────────────────────
--   final result = await _supabase.rpc('list_students', params: {
--     'p_organization_id': organizationId,
--     'p_search': search,                 // null or text
--     'p_session_id': null,               // null = the current session
--     'p_section_id': sectionId,          // null = every section
--     'p_class_id': classId,
--     'p_arm_id': armId,
--     'p_subject_id': subjectId,          // null = no subject filter
--     'p_statuses': ['active'],
--     'p_sort': 'class',                  // 'class' | 'name'
--     'p_limit': 30,
--     'p_cursor': cursor,                 // null for page 1
--   }) as Map<String, dynamic>;
--   rows → students; next_cursor null = last page; total = matching students;
--   groups = [{arm_id, count}] for the whole filtered set (header counts).
--
-- Infinite scroll: page 1 with p_cursor null replaces the list; near the end,
-- call again with every filter unchanged and p_cursor = next_cursor and
-- append; stop when next_cursor is null. Any filter, search or sort change
-- (and pull to refresh) starts again from null.

-- Down (manual):
--   drop function public.list_students(uuid, text, uuid, uuid, uuid, uuid, uuid,
--                                      public.student_status[], text, int, text);
