-- 32 · register_student also refuses a class in a switched-off section
--
-- Migration 31 refuses a class or an arm that is switched off, but not a whole
-- section: the app hides a switched-off section, yet a stale screen or another
-- client could still send one of its arms. This replaces register_student with
-- the same function plus that one check, made with the other class and arm
-- checks, before the first write:
--   * the section the class belongs to must be switched on (P0001, "The …
--     section is switched off …").
--
-- Nothing else changes: same signature, same security (security invoker,
-- search_path = ''), same return value, same refusals in the same order. The
-- existing grants stay (create or replace keeps them); they are repeated below
-- only so this file reads on its own. No DROP.
--
-- Requires migration 31. Test: supabase/tests/19_register_student_access_test.sql
-- (case 17b). Design notes: docs/people-schema.md (Registering a student)

create or replace function public.register_student(
  p_organization_id      uuid,
  p_first_name           text,
  p_last_name            text,
  p_parents              jsonb,
  p_arm_id               uuid,
  p_session_id           uuid          default null,
  p_optional_subject_ids uuid[]        default '{}',
  p_middle_name          text          default null,
  p_admission_number     text          default null,
  p_gender               public.gender default null,
  p_admission_date       date          default null,
  p_photo_id             text          default null,
  p_photo_url            text          default null,
  p_date_of_birth        date          default null,
  p_address              text          default null,
  p_state_of_origin      text          default null,
  p_lga                  text          default null,
  p_blood_group          text          default null,
  p_genotype             text          default null,
  p_medical_notes        text          default null
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_leaders     constant public.member_role[] := array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[];
  v_item        jsonb;
  v_n           int;
  v_primaries   int := 0;
  v_rel         text;
  v_pid         uuid;
  v_phone       text;
  v_digits      text;
  v_existing    record;
  v_seen_ids    uuid[] := '{}';
  v_seen_phones text[] := '{}';
  v_arm         record;
  v_session     record;
  v_session_id  uuid;
  v_subject_ids uuid[];
  v_subject     record;
  v_student     public.students;
  v_parent      public.parents;
  v_parent_ids  uuid[] := '{}';
begin
  -- ── who ─────────────────────────────────────────────────────
  if p_organization_id is null
     or p_organization_id not in (select private.my_org_ids(v_leaders)) then
    raise exception 'Only the school''s leaders can register students' using errcode = '42501';
  end if;

  -- ── the student ─────────────────────────────────────────────
  if nullif(trim(p_first_name), '') is null or nullif(trim(p_last_name), '') is null then
    raise exception 'Enter the student''s first and last name' using errcode = '22023';
  end if;

  if nullif(trim(p_admission_number), '') is not null and exists (
    select 1 from public.students s
    where s.organization_id = p_organization_id
      and s.admission_number = trim(p_admission_number)
  ) then
    raise exception 'Admission number % is already used in this school. Leave it blank to generate one', trim(p_admission_number)
      using errcode = '23505';
  end if;

  -- ── parents ─────────────────────────────────────────────────
  if p_parents is null or jsonb_typeof(p_parents) <> 'array' or jsonb_array_length(p_parents) = 0 then
    raise exception 'Add at least one parent or guardian' using errcode = '22023';
  end if;

  for v_item in select e from jsonb_array_elements(p_parents) as t(e) loop
    if jsonb_typeof(v_item) <> 'object' then
      raise exception 'Each parent must be an object with a relationship' using errcode = '22023';
    end if;

    v_rel := nullif(trim(v_item ->> 'relationship'), '');
    if v_rel is null or v_rel not in ('father', 'mother', 'guardian', 'other') then
      raise exception 'Choose how each parent is related to the student: father, mother, guardian or other'
        using errcode = '22023';
    end if;

    if coalesce(v_item -> 'is_primary_contact' = 'true'::jsonb, false) then
      v_primaries := v_primaries + 1;
    end if;

    if nullif(trim(v_item ->> 'parent_id'), '') is not null then
      -- existing parent
      begin
        v_pid := (v_item ->> 'parent_id')::uuid;
      exception when invalid_text_representation then
        raise exception 'One of the parents has an id that isn''t valid' using errcode = '22023';
      end;

      if v_pid = any (v_seen_ids) then
        raise exception 'The same parent is listed twice. Add each parent once' using errcode = '22023';
      end if;
      v_seen_ids := v_seen_ids || v_pid;

      if not exists (
        select 1 from public.parents p
        where p.id = v_pid and p.organization_id = p_organization_id
      ) then
        raise exception 'That parent isn''t in this school. Search for them again, or add them as a new parent'
          using errcode = 'P0002';
      end if;
    else
      -- new parent
      v_phone := nullif(trim(v_item ->> 'phone'), '');
      if nullif(trim(v_item ->> 'first_name'), '') is null
         or nullif(trim(v_item ->> 'last_name'), '') is null
         or v_phone is null then
        raise exception 'Enter each new parent''s first name, last name and phone number' using errcode = '22023';
      end if;

      if nullif(trim(v_item ->> 'gender'), '') is not null
         and trim(v_item ->> 'gender') not in ('male', 'female') then
        raise exception 'A parent''s gender must be male or female' using errcode = '22023';
      end if;

      v_digits := coalesce(private.phone_digits(v_phone), v_phone);
      if v_digits = any (v_seen_phones) then
        raise exception 'Two new parents have the same phone number %. Add each parent once', v_phone
          using errcode = '22023';
      end if;
      v_seen_phones := v_seen_phones || v_digits;

      select p.id, p.first_name, p.last_name into v_existing
      from public.parents p
      where p.organization_id = p_organization_id
        and (p.phone = v_phone or private.phone_digits(p.phone) = v_digits)
      limit 1;
      if found then
        raise exception '% % is already a parent in this school with phone %. Choose them as an existing parent instead of adding them again',
          v_existing.first_name, v_existing.last_name, v_phone
          using errcode = '23505';
      end if;
    end if;
  end loop;

  if v_primaries = 0 then
    raise exception 'Choose one parent as the primary contact' using errcode = '22023';
  elsif v_primaries > 1 then
    raise exception 'Only one parent can be the primary contact' using errcode = '22023';
  end if;

  -- ── class and arm ───────────────────────────────────────────
  select a.id, a.name, a.is_active, c.name as class_name, c.is_active as class_active,
         sec.name as section_name, sec.is_active as section_active
  into v_arm
  from public.class_arms a
  join public.classes c on c.id = a.class_id
  join public.sections sec on sec.id = c.section_id
  where a.id = p_arm_id
    and a.organization_id = p_organization_id;
  if not found then
    raise exception 'Choose a class and arm in this school' using errcode = 'P0002';
  end if;
  if not v_arm.section_active then
    raise exception 'The % section is switched off. Choose a class in another section, or switch it back on first', v_arm.section_name
      using errcode = 'P0001';
  end if;
  if not v_arm.class_active then
    raise exception '% is switched off. Choose another class, or switch it back on first', v_arm.class_name
      using errcode = 'P0001';
  end if;
  if not v_arm.is_active then
    raise exception '% % is switched off. Choose another arm, or switch it back on first', v_arm.class_name, v_arm.name
      using errcode = 'P0001';
  end if;

  -- ── session ─────────────────────────────────────────────────
  if p_session_id is null then
    select s.id, s.closed_at into v_session
    from public.academic_sessions s
    where s.organization_id = p_organization_id
      and s.is_current;
    if not found then
      raise exception 'This school has no current session. Set one up in the calendar first' using errcode = 'P0001';
    end if;
  else
    select s.id, s.closed_at into v_session
    from public.academic_sessions s
    where s.id = p_session_id
      and s.organization_id = p_organization_id;
    if not found then
      raise exception 'Session not found in this school' using errcode = 'P0002';
    end if;
  end if;
  if v_session.closed_at is not null then
    raise exception 'That session is closed. Nothing new can be added to it; use the current session.'
      using errcode = 'P0001';
  end if;
  v_session_id := v_session.id;

  -- ── optional subjects ───────────────────────────────────────
  -- Same rule as private.check_student_subject: offered by the arm, and
  -- optional there. Duplicates and nulls in the array are dropped.
  select coalesce(array_agg(distinct x), '{}') into v_subject_ids
  from unnest(coalesce(p_optional_subject_ids, '{}'::uuid[])) as t(x)
  where x is not null;

  for v_subject in
    select x as id, sj.name, asub.is_compulsory, asub.subject_id is not null as offered
    from unnest(v_subject_ids) as t(x)
    left join public.subjects sj on sj.id = x and sj.organization_id = p_organization_id
    left join public.arm_subjects asub on asub.arm_id = p_arm_id and asub.subject_id = x
  loop
    if not v_subject.offered then
      raise exception '% isn''t offered to %. Choose from the arm''s optional subjects',
        coalesce(v_subject.name, 'That subject'), v_arm.class_name || ' ' || v_arm.name
        using errcode = '23514';
    end if;
    if v_subject.is_compulsory then
      raise exception '% is compulsory for %, so every student already takes it',
        v_subject.name, v_arm.class_name || ' ' || v_arm.name
        using errcode = '23514';
    end if;
  end loop;

  -- ── writes ──────────────────────────────────────────────────
  -- 1. student + private details (create_student runs as the caller too)
  v_student := public.create_student(
    p_organization_id  => p_organization_id,
    p_first_name       => trim(p_first_name),
    p_last_name        => trim(p_last_name),
    p_middle_name      => nullif(trim(p_middle_name), ''),
    p_admission_number => nullif(trim(p_admission_number), ''),
    p_gender           => p_gender,
    p_admission_date   => p_admission_date,
    p_photo_id         => p_photo_id,
    p_photo_url        => p_photo_url,
    p_status           => 'active',
    p_date_of_birth    => p_date_of_birth,
    p_address          => p_address,
    p_state_of_origin  => p_state_of_origin,
    p_lga              => p_lga,
    p_blood_group      => p_blood_group,
    p_genotype         => p_genotype,
    p_medical_notes    => p_medical_notes
  );

  -- 2 + 3. new parents, then every link (in the order given)
  for v_item, v_n in select e, i from jsonb_array_elements(p_parents) with ordinality as t(e, i) order by i loop
    if nullif(trim(v_item ->> 'parent_id'), '') is not null then
      v_pid := (v_item ->> 'parent_id')::uuid;
    else
      v_parent := public.create_parent(
        p_organization_id => p_organization_id,
        p_first_name      => trim(v_item ->> 'first_name'),
        p_last_name       => trim(v_item ->> 'last_name'),
        p_phone           => trim(v_item ->> 'phone'),
        p_title           => nullif(trim(v_item ->> 'title'), ''),
        p_gender          => nullif(trim(v_item ->> 'gender'), '')::public.gender,
        p_alt_phone       => nullif(trim(v_item ->> 'alt_phone'), ''),
        p_photo_id        => nullif(trim(v_item ->> 'photo_id'), ''),
        p_photo_url       => nullif(trim(v_item ->> 'photo_url'), ''),
        p_is_active       => true,
        p_email           => nullif(trim(v_item ->> 'email'), ''),
        p_occupation      => nullif(trim(v_item ->> 'occupation'), ''),
        p_address         => nullif(trim(v_item ->> 'address'), '')
      );
      v_pid := v_parent.id;
    end if;

    insert into public.student_parents (organization_id, student_id, parent_id, relationship, is_primary_contact)
    values (p_organization_id, v_student.id, v_pid,
            trim(v_item ->> 'relationship')::public.parent_relationship,
            coalesce(v_item -> 'is_primary_contact' = 'true'::jsonb, false));

    v_parent_ids := v_parent_ids || v_pid;
  end loop;

  -- 4. placement for the session
  insert into public.student_placements (organization_id, student_id, session_id, arm_id)
  values (p_organization_id, v_student.id, v_session_id, p_arm_id);

  -- 5. optional subjects (private.check_student_subject still checks each)
  insert into public.student_subjects (organization_id, student_id, session_id, subject_id)
  select p_organization_id, v_student.id, v_session_id, x
  from unnest(v_subject_ids) as t(x);

  return jsonb_build_object(
    'student',     to_jsonb(v_student),
    'parent_ids',  to_jsonb(v_parent_ids),
    'placement',   jsonb_build_object('session_id', v_session_id, 'arm_id', p_arm_id),
    'subject_ids', to_jsonb(v_subject_ids)
  );
end;
$$;

-- Privileges are unchanged (create or replace keeps them); stated again for clarity.
revoke execute on function public.register_student(uuid, text, text, jsonb, uuid, uuid, uuid[], text, text,
                                                   public.gender, date, text, text, date, text, text, text,
                                                   text, text, text) from public, anon;
grant  execute on function public.register_student(uuid, text, text, jsonb, uuid, uuid, uuid[], text, text,
                                                   public.gender, date, text, text, date, text, text, text,
                                                   text, text, text) to authenticated;

-- Down (manual): re-run the create function from migration 31.
