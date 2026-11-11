-- 37 · Staff list: filter by the subject a teacher teaches, and where
--
-- The Staffs filter sheet (9.4) could narrow by login, role, staff type and
-- status, but not by what someone teaches. An administrator asking "who
-- teaches Mathematics, and in which classes?" had to open every teacher.
--
-- What the schema already knows (nothing new is needed): a teaching
-- assignment is one row in teaching_assignments per (session, arm, subject)
-- with the staff member who teaches it (migration 06). That is the real
-- teacher → subject → class relationship: the same subject can have a
-- different teacher in every arm, and a teacher can teach several subjects
-- and arms. It is not inferred from job titles, class_teachers (homeroom) or
-- any "subject a teacher is associated with".
--
-- list_staff gets four more optional parameters, so the new filter combines
-- with the search, login, role, type and status filters, the counts and the
-- paging that already work:
--   p_subject_id  staff who teach this subject this session
--   p_class_id    staff who teach in any arm of this class
--   p_section_id  staff who teach in any class of this section
--   p_session_id  which session's assignments count; null = the current one
--                 (with no current session the teaching filters match nobody)
-- The three teaching filters apply to the SAME assignment (subject AND class
-- AND section must all hold on one row), so "Mathematics in JSS 2" means they
-- teach Mathematics in JSS 2, not Mathematics somewhere and JSS 2 for
-- something else. They also narrow `total` and every chip count, since they
-- are part of the filtered set.
--
-- When any teaching filter is given, each row also carries `teaching`: the
-- matching assignments only, as
--   [ { subject_id, subject_name, arm_id, arm_name, class_id, class_name }, … ]
-- ordered by section, class, arm, then subject. A teacher with many matching
-- classes is ONE row (the filter is an EXISTS) with several entries here.
-- Without a teaching filter `teaching` is null and nothing extra is read. A
-- teacher with no assignment this session simply doesn't match a teaching
-- filter; with no teaching filter they list as before.
--
-- This replaces list_staff (migration 30): a function can't gain parameters
-- in place, and keeping both signatures would make a call with the old
-- parameters ambiguous. The new parameters are last and default to null, so
-- every call the app already makes keeps working unchanged. Same security
-- (security invoker, so RLS decides: teaching_assignments, class_arms,
-- classes, sections and subjects are readable by every member of the school;
-- the school is also scoped explicitly), same paging, same cursor.
--
-- No new indexes: teaching_assignments_staff_idx (organization_id, staff_id)
-- and teaching_assignments_subject_idx (organization_id, subject_id) cover
-- both ways in, and the primary key (session_id, arm_id, subject_id) covers
-- the per-arm lookups.
--
-- DROP: the old signature of list_staff, replaced in the same migration.
-- Nothing in the database depends on it (the app calls it directly).
-- Test: supabase/tests/24_staff_teaching_filter_test.sql
-- Design notes: docs/people-schema.md (Listing staff)

drop function public.list_staff(uuid, text, text, public.member_role[], public.staff_type,
                                public.staff_status[], text, int, text);

create function public.list_staff(
  p_organization_id uuid,
  p_search          text                  default null,
  p_login           text                  default null,
  p_roles           public.member_role[]  default null,
  p_staff_type      public.staff_type     default null,
  p_statuses        public.staff_status[] default null,
  p_sort            text                  default 'name',
  p_limit           int                   default 30,
  p_cursor          text                  default null,
  p_subject_id      uuid                  default null,
  p_class_id        uuid                  default null,
  p_section_id      uuid                  default null,
  p_session_id      uuid                  default null
)
returns jsonb
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  v_sort        text := coalesce(nullif(trim(p_sort), ''), 'name');
  v_login       text := coalesce(nullif(trim(p_login), ''), 'all');
  v_limit       int  := least(greatest(coalesce(p_limit, 30), 1), 100);
  v_search      text := nullif(lower(trim(p_search)), '');
  v_teaching    boolean := p_subject_id is not null or p_class_id is not null or p_section_id is not null;
  v_session     uuid;
  v_phone       text;      -- the whole search as phone digits, when it looks like a phone
  v_patterns    text[];    -- one LIKE pattern per word
  v_word_phones text[];    -- each word as phone digits, or null
  v_cursor      jsonb;
  v_c_rank      int;
  v_c_first     text;
  v_c_last      text;
  v_c_created   timestamptz;
  v_c_id        uuid;
  v_counts      jsonb;
  v_rows        jsonb;
  v_next_key    jsonb;
begin
  if p_organization_id is null then
    raise exception 'Choose a school to list its staff' using errcode = '22023';
  end if;

  v_session := coalesce(
    p_session_id,
    (select se.id
     from public.academic_sessions se
     where se.organization_id = p_organization_id and se.is_current
     limit 1)
  );

  if v_login not in ('all', 'on_app', 'code_ready', 'not_on_app', 'suspended') then
    raise exception 'Unknown login filter "%". Use all, on_app, code_ready, not_on_app or suspended', p_login
      using errcode = '22023';
  end if;

  if v_sort not in ('name', 'newest') then
    raise exception 'Unknown sort "%". Use name or newest', p_sort using errcode = '22023';
  end if;

  if v_search is not null then
    if v_search ~ '^[0-9+().\s-]+$' then
      v_phone := private.phone_digits(v_search);
      if length(v_phone) < 3 then
        v_phone := null;
      end if;
    end if;

    select array_agg('%' || regexp_replace(w, '([\\%_])', '\\\1', 'g') || '%' order by i),
           array_agg(case when w ~ '^[0-9+().-]+$' and length(private.phone_digits(w)) >= 3
                          then private.phone_digits(w) end order by i)
    into v_patterns, v_word_phones
    from unnest(regexp_split_to_array(v_search, '\s+')) with ordinality as t(w, i)
    where w <> '';
  end if;

  if p_cursor is not null then
    begin
      v_cursor := convert_from(decode(p_cursor, 'base64'), 'UTF8')::jsonb;
      if v_cursor ->> 's' is distinct from v_sort then
        raise exception using errcode = '22023', message = 'wrong sort';
      end if;
      if v_sort = 'name' then
        v_c_rank  := (v_cursor -> 'k' ->> 0)::int;
        v_c_first := v_cursor -> 'k' ->> 1;
        v_c_last  := v_cursor -> 'k' ->> 2;
        v_c_id    := (v_cursor -> 'k' ->> 3)::uuid;
        if v_c_rank is null or v_c_first is null or v_c_last is null or v_c_id is null then
          raise exception using errcode = '22023', message = 'incomplete';
        end if;
      else
        v_c_created := (v_cursor -> 'k' ->> 0)::timestamptz;
        v_c_id      := (v_cursor -> 'k' ->> 1)::uuid;
        if v_c_created is null or v_c_id is null then
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
      s.id, s.first_name, s.middle_name, s.last_name, s.job_title, s.gender,
      s.phone, s.email, s.photo_url, s.staff_number, s.staff_type, s.status,
      s.created_at, s.member_id,
      m.id            as m_id,
      m.role          as m_role,
      m.status        as m_status,
      m.claim_code    as m_claim_code,
      m.joined_at     as m_joined_at,
      m.created_at    as m_created_at,
      m.clerk_user_id as m_clerk_user_id,
      case when m.id is null          then 'not_on_app'
           when m.status = 'active'   then 'on_app'
           when m.status = 'invited'  then 'code_ready'
           else 'suspended' end as facet,
      case when m.role = 'owner' and m.status = 'active' then 0 else 1 end as owner_rank,
      lower(s.first_name) as first_key,
      lower(s.last_name)  as last_key
    from public.staff s
    -- RLS on organization_members decides whether the login is visible;
    -- the composite staff_member_fkey keeps it in the same school.
    left join public.organization_members m on m.id = s.member_id
    where s.organization_id = p_organization_id
      and (p_staff_type is null or s.staff_type = p_staff_type)
      and (coalesce(cardinality(p_statuses), 0) = 0 or s.status = any (p_statuses))
      and (coalesce(cardinality(p_roles), 0) = 0 or m.role = any (p_roles))
      -- teaching filters: at least one assignment this session that matches
      -- the subject and where it is taught. EXISTS, so a teacher with many
      -- matching classes is still one row.
      and (
        not v_teaching
        or exists (
          select 1
          from public.teaching_assignments ta
          join public.class_arms a on a.organization_id = ta.organization_id and a.id = ta.arm_id
          join public.classes cl   on cl.organization_id = a.organization_id and cl.id = a.class_id
          where ta.organization_id = s.organization_id
            and ta.staff_id        = s.id
            and ta.session_id      = v_session
            and (p_subject_id is null or ta.subject_id = p_subject_id)
            and (p_class_id   is null or cl.id         = p_class_id)
            and (p_section_id is null or cl.section_id = p_section_id)
        )
      )
      and (
        v_search is null
        or coalesce(private.phone_digits(s.phone) like '%' || v_phone || '%', false)
        or not exists (
          select 1
          from unnest(v_patterns, v_word_phones) as w(pattern, phone)
          where not (
            lower(concat_ws(' ', s.first_name, s.middle_name, s.last_name,
                                 s.staff_number, s.email, s.phone)) like w.pattern
            or coalesce(private.phone_digits(s.phone) like '%' || w.phone || '%', false)
          )
        )
      )
  ),
  counts as (
    select jsonb_build_object(
      'all',        count(*),
      'on_app',     count(*) filter (where b.facet = 'on_app'),
      'code_ready', count(*) filter (where b.facet = 'code_ready'),
      'not_on_app', count(*) filter (where b.facet = 'not_on_app'),
      'suspended',  count(*) filter (where b.facet = 'suspended')
    ) as counts
    from base b
  ),
  page as (
    select b.*,
           row_number() over (
             order by
               case when v_sort = 'name'   then b.owner_rank end,
               case when v_sort = 'name'   then b.first_key  end,
               case when v_sort = 'name'   then b.last_key   end,
               case when v_sort = 'newest' then b.created_at end desc,
               case when v_sort = 'name'   then b.id         end,
               case when v_sort = 'newest' then b.id         end desc
           ) as rn
    from base b
    where (v_login = 'all' or b.facet = v_login)
      and (
        v_cursor is null
        or (v_sort = 'name'
            and (b.owner_rank, b.first_key, b.last_key, b.id) > (v_c_rank, v_c_first, v_c_last, v_c_id))
        or (v_sort = 'newest'
            and (b.created_at, b.id) < (v_c_created, v_c_id))
      )
    order by rn
    limit v_limit + 1
  )
  select
    c.counts,
    coalesce((
      select jsonb_agg(
               jsonb_build_object(
                 'id',           p.id,
                 'first_name',   p.first_name,
                 'middle_name',  p.middle_name,
                 'last_name',    p.last_name,
                 'job_title',    p.job_title,
                 'gender',       p.gender,
                 'phone',        p.phone,
                 'email',        p.email,
                 'photo_url',    p.photo_url,
                 'staff_number', p.staff_number,
                 'staff_type',   p.staff_type,
                 'status',       p.status,
                 'created_at',   p.created_at,
                 'member_id',    p.member_id,
                 'teaching', case when not v_teaching then null else (
                   select coalesce(jsonb_agg(
                            jsonb_build_object(
                              'subject_id',   ta.subject_id,
                              'subject_name', sj.name,
                              'arm_id',       a.id,
                              'arm_name',     a.name,
                              'class_id',     cl.id,
                              'class_name',   cl.name
                            ) order by sec.sort_order, cl.sort_order, cl.id, lower(a.name), a.id,
                                       lower(sj.name), sj.id), '[]'::jsonb)
                   from public.teaching_assignments ta
                   join public.class_arms a   on a.organization_id  = ta.organization_id and a.id  = ta.arm_id
                   join public.classes cl     on cl.organization_id = a.organization_id  and cl.id = a.class_id
                   join public.sections sec   on sec.organization_id = cl.organization_id and sec.id = cl.section_id
                   join public.subjects sj    on sj.organization_id = ta.organization_id and sj.id = ta.subject_id
                   where ta.organization_id = p_organization_id
                     and ta.staff_id        = p.id
                     and ta.session_id      = v_session
                     and (p_subject_id is null or ta.subject_id = p_subject_id)
                     and (p_class_id   is null or cl.id         = p_class_id)
                     and (p_section_id is null or cl.section_id = p_section_id)
                 ) end,
                 'member', case when p.m_id is null then null else jsonb_build_object(
                   'id',            p.m_id,
                   'role',          p.m_role,
                   'status',        p.m_status,
                   'claim_code',    p.m_claim_code,
                   'joined_at',     p.m_joined_at,
                   'created_at',    p.m_created_at,
                   'clerk_user_id', p.m_clerk_user_id
                 ) end
               ) order by p.rn)
      from page p
      where p.rn <= v_limit
    ), '[]'::jsonb),
    -- a row past the page means there is more: the cursor is the last row shown
    (select case when v_sort = 'name'
                 then jsonb_build_array(p.owner_rank, p.first_key, p.last_key, p.id)
                 else jsonb_build_array(p.created_at, p.id) end
     from page p
     where p.rn = v_limit
       and exists (select 1 from page q where q.rn = v_limit + 1))
  into v_counts, v_rows, v_next_key
  from counts c;

  return jsonb_build_object(
    'rows',        v_rows,
    'next_cursor', case when v_next_key is null then null
                        else translate(encode(convert_to(
                               jsonb_build_object('s', v_sort, 'k', v_next_key)::text, 'UTF8'), 'base64'),
                             E'\n', '') end,
    'total',       (v_counts ->> v_login)::int,
    'counts',      v_counts
  );
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- Privileges (the new signature is a new function, so grant again)
-- ─────────────────────────────────────────────────────────────
revoke execute on function public.list_staff(uuid, text, text, public.member_role[], public.staff_type,
                                             public.staff_status[], text, int, text, uuid, uuid, uuid, uuid) from public, anon;
grant  execute on function public.list_staff(uuid, text, text, public.member_role[], public.staff_type,
                                             public.staff_status[], text, int, text, uuid, uuid, uuid, uuid) to authenticated;

-- ─────────────────────────────────────────────────────────────
-- Using it from the app (TeamService.listStaffPage)
-- ─────────────────────────────────────────────────────────────
--   add to the params of migration 30's call:
--     'p_subject_id': subjectId,    // null = no subject filter
--     'p_class_id':   classId,
--     'p_section_id': sectionId,
--   rows[i]['teaching'] is a list when any of the three is set, else null.

-- Down (manual): put migration 30's version back.
--   drop function public.list_staff(uuid, text, text, public.member_role[], public.staff_type,
--                                   public.staff_status[], text, int, text, uuid, uuid, uuid, uuid);
--   then re-run the create function and the grants from migration 30.
