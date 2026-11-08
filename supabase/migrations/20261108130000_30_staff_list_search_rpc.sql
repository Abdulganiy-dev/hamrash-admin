-- 30 · Staff list: search, filters, counts and pages in one call
--
-- The Staffs screen (8.1) and its filter sheet (8.17) need search, a login
-- filter, roles, staff type, record status, two sorts, chip counts and
-- infinite scroll. TeamService.listStaff used to read every staff row and
-- every staff_private_details row for the school and join them in the app.
-- list_staff does it on the server and returns only what the list shows: the
-- staff profile and its login. No private details.
--
-- Security: security invoker, so the existing RLS decides everything:
--   * staff: every active member of the school (and Hamrash) reads the
--     profiles (migration 05). A caller who isn't an active member of
--     p_organization_id, or whose school is suspended, gets no rows, a total
--     of 0 and zero counts, the same as an empty school.
--   * organization_members: leaders (owner, admin, principal, VP) read the
--     school's logins; everyone reads their own (migrations 01 · 02). For a
--     teacher, bursar, parent or student, `member` is null on every row except
--     their own, so their login filter and counts treat other people as
--     not_on_app. Only leaders reach the Staffs screen.
-- The school is also scoped explicitly (s.organization_id = p_organization_id),
-- so a platform admin or someone in two schools only sees this one.
--
-- No new indexes. Every call counts all of the school's staff that match
-- the filters (the chip counts), so it reads the school's rows once anyway,
-- through staff_org_id_key (organization_id, id), and joins logins by
-- organization_members_pkey. A sort index can't skip that read, and a school
-- has hundreds of staff, not millions. pg_trgm isn't enabled on the project
-- and this migration doesn't enable extensions, so search is LIKE on
-- lower(...) over those rows. If a school ever has thousands of staff,
-- enable pg_trgm and add a GIN index on the same lower(concat_ws(...))
-- expression.
--
-- No DROP: a new function and a new private helper.
-- Test: supabase/tests/18_staff_list_rpc_test.sql
-- Design notes: docs/people-schema.md (Listing staff)

-- ─────────────────────────────────────────────────────────────
-- Phone numbers compared by their digits
-- ─────────────────────────────────────────────────────────────
-- A Nigerian phone number as bare national digits, so "0803 555 0142",
-- "8035550142" and "+234 803 555 0142" all become 8035550142. Drops every
-- non-digit, then a leading 234 country code, then leading zeros. Null when
-- nothing is left.
create function private.phone_digits(p_phone text)
returns text
language sql
immutable
set search_path = ''
as $$
  select nullif(
    regexp_replace(
      regexp_replace(
        regexp_replace(p_phone, '\D', '', 'g'),
        '^234', ''),
      '^0+', ''),
    '');
$$;

-- ─────────────────────────────────────────────────────────────
-- list_staff
-- ─────────────────────────────────────────────────────────────
-- One page of the school's staff list, with chip counts and the cursor for
-- the next page.
--
-- Returns ONE jsonb object, not setof + a second counts function: one round
-- trip for the rows, the counts and the cursor, worked out from the same
-- filtered set in the same snapshot, so they can't disagree. supabase-flutter
-- returns it as a Map from rpc().
--   {
--     "rows":        [ { staff columns…, "member": {…} | null }, … ],
--     "next_cursor": "…" | null,   -- null on the last page
--     "total":       n,            -- rows matching every filter
--     "counts":      { "all", "on_app", "code_ready", "not_on_app", "suspended" }
--   }
-- counts use the search, staff type, statuses and roles but IGNORE p_login,
-- so every login chip shows how many it would list. on_app includes the owner.
--
-- Parameters
--   p_search     Case-insensitive, partial. Each word must match the name
--                (first, middle or last), staff number, email or phone.
--                Phone matching uses private.phone_digits on both sides, so
--                "0803 555 0142", "8035550142" and "+2348035550142" find
--                the same number however it was saved. Digit searches need
--                at least 3 digits to match a phone. Blank = no search.
--   p_login      null or 'all' | 'on_app' (active login, owner included)
--                | 'code_ready' (unclaimed invite) | 'not_on_app' (no login)
--                | 'suspended'.
--   p_roles      The login's role. People with no login have no role, so a
--                role filter only ever matches people with a login (any
--                login status). null or {} = every role.
--   p_staff_type null = both.
--   p_statuses   The record's status. null or {} = all. The app sends
--                {active} by default.
--   p_sort       'name' (default): the active owner first, then first name,
--                last name (case-insensitive), then id. 'newest': created_at
--                descending, then id.
--   p_limit      Page size, default 30, clamped to 1..100.
--   p_cursor     null for the first page, then the previous next_cursor.
--
-- Keyset pagination, not offset: when someone is added or removed while the
-- user scrolls, an offset shifts and the list repeats or skips a person; a
-- cursor holding the last row's sort key (and id as the tie-break) always
-- continues after that row. The cursor is opaque base64 of
-- {"s": sort, "k": [sort key…]}. Start again with null when the filters
-- change. A cursor from the other sort is refused.
create function public.list_staff(
  p_organization_id uuid,
  p_search          text                  default null,
  p_login           text                  default null,
  p_roles           public.member_role[]  default null,
  p_staff_type      public.staff_type     default null,
  p_statuses        public.staff_status[] default null,
  p_sort            text                  default 'name',
  p_limit           int                   default 30,
  p_cursor          text                  default null
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
-- Privileges
-- list_staff runs as the caller, so the caller also needs phone_digits.
-- ─────────────────────────────────────────────────────────────
revoke execute on function private.phone_digits(text) from public, anon;
grant  execute on function private.phone_digits(text) to authenticated;

revoke execute on function public.list_staff(uuid, text, text, public.member_role[], public.staff_type,
                                             public.staff_status[], text, int, text) from public, anon;
grant  execute on function public.list_staff(uuid, text, text, public.member_role[], public.staff_type,
                                             public.staff_status[], text, int, text) to authenticated;

-- ─────────────────────────────────────────────────────────────
-- Using it from the app (TeamService.listStaff; not changed by this migration)
-- ─────────────────────────────────────────────────────────────
--   final result = await _supabase.rpc('list_staff', params: {
--     'p_organization_id': organizationId,
--     'p_search': search,                       // null or text
--     'p_login': login,                         // null | 'on_app' | 'code_ready' | 'not_on_app' | 'suspended'
--     'p_roles': [for (final r in roles) r.value],          // [] = every role
--     'p_staff_type': staffType,                // null | 'teaching' | 'non_teaching'
--     'p_statuses': [for (final s in statuses) s.value],    // default ['active']
--     'p_sort': sort,                           // 'name' | 'newest'
--     'p_limit': 30,
--     'p_cursor': cursor,                       // null for page 1
--   }) as Map<String, dynamic>;
--   final rows = [
--     for (final row in result['rows'] as List)
--       StaffMember.fromJson(Map<String, dynamic>.from(row as Map)),
--   ];                                          // same keys as StaffMember.columns, `member` included
--   final nextCursor = result['next_cursor'] as String?;  // null = last page
--   final total = result['total'] as int;
--   final counts = Map<String, int>.from(result['counts'] as Map);
--
-- Infinite scroll: page 1 with p_cursor null replaces the list; near the end,
-- call again with every filter unchanged and p_cursor = nextCursor and
-- append; stop when nextCursor is null. Any filter, search or sort change
-- (and pull to refresh) starts again from null. Chips read counts['all'],
-- counts['on_app'], …; they don't change when only the login chip changes.
-- The rows are already in order (owner first on the name sort), so the view
-- model no longer sorts them.

-- Down (manual):
--   drop function public.list_staff(uuid, text, text, public.member_role[], public.staff_type,
--                                   public.staff_status[], text, int, text);
--   drop function private.phone_digits(text);
