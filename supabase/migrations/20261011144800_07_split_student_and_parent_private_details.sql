  -- 07 · Split students AND parents into a profile and private details
  --
  -- Students
  --   students keeps the profile: names, admission number, admission date,
  --   photo, gender, status (and member_id). student_private_details takes date
  --   of birth, address, state of origin, LGA, blood group, genotype and
  --   medical notes.
  --     profile          leaders, bursar, current teachers, PAST teachers (any
  --                      session they taught the student, so old scores can
  --                      show a name), parents, the student, platform admins
  --     private details  leaders, CURRENT teachers, parents, the student,
  --                      platform admins (not the bursar, not past teachers)
  --
  -- Parents
  --   parents keeps title, names, gender, phone, alt phone, photo, is_active —
  --   what co-parents and teachers may see. parent_private_details takes email,
  --   occupation and address, so separated parents can't see each other's.
  --     private details  leaders, bursar, the parent themselves, platform
  --                      admins (not co-parents, not teachers)
  --
  -- No students or parents existed when this was written; the copy steps are
  -- for safety.
  -- Contains DROP COLUMN, so the Supabase connector won't run it: apply it in
  -- the SQL editor and record it in supabase_migrations.schema_migrations.
  -- Design notes: docs/people-schema.md, docs/results-design.md
  
  -- ─────────────────────────────────────────────────────────────
  -- student_private_details: exactly one row per student
  -- ─────────────────────────────────────────────────────────────
  create table public.student_private_details (
    student_id       uuid primary key,
    organization_id  uuid not null references public.organizations (id) on delete restrict,
    date_of_birth    date,
    address          text,
    state_of_origin  text,
    lga              text,
    blood_group      text,
    genotype         text,
    medical_notes    text,
    created_at       timestamptz not null default now(),
    updated_at       timestamptz not null default now(),
    constraint student_private_details_student_fkey foreign key (organization_id, student_id)
      references public.students (organization_id, id) on delete cascade,
    constraint student_private_details_blood_group_valid
      check (blood_group in ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    constraint student_private_details_genotype_valid
      check (genotype in ('AA', 'AS', 'AC', 'SS', 'SC', 'CC'))
  );
  
  alter table public.student_private_details enable row level security;
  
  create index student_private_details_org_student_idx on public.student_private_details (organization_id, student_id);
  
  create trigger student_private_details_set_updated_at
    before update on public.student_private_details
    for each row execute function private.set_updated_at();
  
  -- Copy anything that exists, then drop the private columns from students.
  insert into public.student_private_details
    (student_id, organization_id, date_of_birth, address, state_of_origin, lga, blood_group, genotype, medical_notes)
  select id, organization_id, date_of_birth, address, state_of_origin, lga, blood_group, genotype, medical_notes
  from public.students;
  
  alter table public.students
    drop column date_of_birth,
    drop column address,
    drop column state_of_origin,
    drop column lga,
    drop column blood_group,
    drop column genotype,
    drop column medical_notes;
  
  -- Every new student gets their (empty) details row automatically, so the app
  -- only ever updates it. security definer so clients need no insert grant.
  create function private.create_student_private_details()
  returns trigger
  language plpgsql
  security definer
  set search_path = ''
  as $$
  begin
    insert into public.student_private_details (student_id, organization_id)
    values (new.id, new.organization_id);
    return new;
  end;
  $$;
  
  create trigger students_create_private_details
    after insert on public.students
    for each row execute function private.create_student_private_details();
  
  -- ─────────────────────────────────────────────────────────────
  -- Students the caller has EVER taught: in any session, placed in an arm
  -- where, that session, the caller was a class teacher, taught a compulsory
  -- subject, or taught an optional subject the student took. Used only for
  -- the profile (name, photo…) so past scores and work can show who they
  -- belong to. Current-session access is private.my_taught_student_ids().
  -- ─────────────────────────────────────────────────────────────
  create function private.my_ever_taught_student_ids()
  returns setof uuid
  language sql
  stable
  security definer
  set search_path = ''
  as $$
    select sp.student_id
    from public.student_placements sp
    join public.class_teachers ct on ct.session_id = sp.session_id and ct.arm_id = sp.arm_id
    where ct.staff_id in (select private.my_staff_ids())
  
    union
  
    select sp.student_id
    from public.student_placements sp
    join public.teaching_assignments ta on ta.session_id = sp.session_id and ta.arm_id = sp.arm_id
    join public.arm_subjects asub on asub.arm_id = sp.arm_id and asub.subject_id = ta.subject_id
    where ta.staff_id in (select private.my_staff_ids())
      and asub.is_compulsory
  
    union
  
    select sp.student_id
    from public.student_placements sp
    join public.teaching_assignments ta on ta.session_id = sp.session_id and ta.arm_id = sp.arm_id
    join public.arm_subjects asub on asub.arm_id = sp.arm_id and asub.subject_id = ta.subject_id
    join public.student_subjects ss on ss.student_id = sp.student_id
                                   and ss.session_id = sp.session_id
                                   and ss.subject_id = ta.subject_id
    where ta.staff_id in (select private.my_staff_ids())
      and not asub.is_compulsory;
  $$;
  
  -- ─────────────────────────────────────────────────────────────
  -- Policies
  -- ─────────────────────────────────────────────────────────────
  
  -- profile: past teachers too (ever-taught includes current)
  alter policy "students: read by leaders, bursars, teachers, family, self" on public.students
    using (
      organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal', 'bursar']::public.member_role[]))
      or id in (select private.my_ever_taught_student_ids())
      or id in (select private.my_child_ids())
      or member_id in (select private.my_member_ids())
      or (select private.is_platform_admin())
    );
  
  -- private details: current teachers only, no bursar
  create policy "student_private_details: leaders, current teachers, family"
    on public.student_private_details for select to authenticated
    using (
      organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[]))
      or student_id in (select private.my_taught_student_ids())
      or student_id in (select private.my_child_ids())
      or student_id in (select private.my_student_ids())
      or (select private.is_platform_admin())
    );
  
  create policy "student_private_details: leaders can edit"
    on public.student_private_details for update to authenticated
    using      (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])))
    with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
  
  -- No insert or delete policy: rows are created with the student (trigger)
  -- and removed with them (cascade).
  
  -- ─────────────────────────────────────────────────────────────
  -- Saving the student form in one call (like create_staff / update_staff):
  -- profile + private details in ONE transaction. Run as the caller, so the
  -- normal RLS decides who may do it: leaders only.
  -- ─────────────────────────────────────────────────────────────
  
  -- Add student. Leave p_admission_number blank to have it generated.
  create function public.create_student(
    p_organization_id  uuid,
    p_first_name       text,
    p_last_name        text,
    p_middle_name      text                  default null,
    p_admission_number text                  default null,
    p_gender           public.gender         default null,
    p_admission_date   date                  default null,
    p_photo_id         text                  default null,
    p_photo_url        text                  default null,
    p_status           public.student_status default 'active',
    p_date_of_birth    date                  default null,
    p_address          text                  default null,
    p_state_of_origin  text                  default null,
    p_lga              text                  default null,
    p_blood_group      text                  default null,
    p_genotype         text                  default null,
    p_medical_notes    text                  default null
  )
  returns public.students
  language plpgsql
  security invoker
  set search_path = ''
  as $$
  declare
    v_student public.students;
  begin
    insert into public.students (organization_id, admission_number, first_name, middle_name, last_name,
                                 gender, admission_date, photo_id, photo_url, status)
    values (p_organization_id, p_admission_number, p_first_name, p_middle_name, p_last_name,
            p_gender, p_admission_date, p_photo_id, p_photo_url, p_status)
    returning * into v_student;
  
    -- the details row was just created by the students_create_private_details trigger
    update public.student_private_details d
    set date_of_birth   = p_date_of_birth,
        address         = p_address,
        state_of_origin = p_state_of_origin,
        lga             = p_lga,
        blood_group     = p_blood_group,
        genotype        = p_genotype,
        medical_notes   = p_medical_notes
    where d.student_id = v_student.id;
  
    return v_student;
  end;
  $$;
  
  -- Edit student. Every argument is required: the form sends the whole record,
  -- and null clears a field. A blank admission number keeps the current one.
  create function public.update_student(
    p_student_id       uuid,
    p_first_name       text,
    p_last_name        text,
    p_middle_name      text,
    p_admission_number text,
    p_gender           public.gender,
    p_admission_date   date,
    p_photo_id         text,
    p_photo_url        text,
    p_status           public.student_status,
    p_date_of_birth    date,
    p_address          text,
    p_state_of_origin  text,
    p_lga              text,
    p_blood_group      text,
    p_genotype         text,
    p_medical_notes    text
  )
  returns public.students
  language plpgsql
  security invoker
  set search_path = ''
  as $$
  declare
    v_student public.students;
  begin
    update public.students s
    set admission_number = coalesce(nullif(trim(p_admission_number), ''), s.admission_number),
        first_name       = p_first_name,
        middle_name      = p_middle_name,
        last_name        = p_last_name,
        gender           = p_gender,
        admission_date   = p_admission_date,
        photo_id         = p_photo_id,
        photo_url        = p_photo_url,
        status           = p_status
    where s.id = p_student_id
    returning s.* into v_student;
  
    if not found then
      raise exception 'Student record not found, or you can''t edit it' using errcode = '42501';
    end if;
  
    update public.student_private_details d
    set date_of_birth   = p_date_of_birth,
        address         = p_address,
        state_of_origin = p_state_of_origin,
        lga             = p_lga,
        blood_group     = p_blood_group,
        genotype        = p_genotype,
        medical_notes   = p_medical_notes
    where d.student_id = p_student_id;
  
    return v_student;
  end;
  $$;
  
  -- ═════════════════════════════════════════════════════════════
  -- Parents
  -- ═════════════════════════════════════════════════════════════
  
  -- parent_private_details: exactly one row per parent
  create table public.parent_private_details (
    parent_id        uuid primary key,
    organization_id  uuid not null references public.organizations (id) on delete restrict,
    email            text,
    occupation       text,
    address          text,
    created_at       timestamptz not null default now(),
    updated_at       timestamptz not null default now(),
    constraint parent_private_details_parent_fkey foreign key (organization_id, parent_id)
      references public.parents (organization_id, id) on delete cascade
  );
  
  alter table public.parent_private_details enable row level security;
  
  create index parent_private_details_org_parent_idx on public.parent_private_details (organization_id, parent_id);
  
  create trigger parent_private_details_set_updated_at
    before update on public.parent_private_details
    for each row execute function private.set_updated_at();
  
  -- Copy anything that exists, then drop the private columns from parents.
  insert into public.parent_private_details (parent_id, organization_id, email, occupation, address)
  select id, organization_id, email, occupation, address
  from public.parents;
  
  alter table public.parents
    drop column email,
    drop column occupation,
    drop column address;
  
  -- Every new parent gets their (empty) details row automatically.
  create function private.create_parent_private_details()
  returns trigger
  language plpgsql
  security definer
  set search_path = ''
  as $$
  begin
    insert into public.parent_private_details (parent_id, organization_id)
    values (new.id, new.organization_id);
    return new;
  end;
  $$;
  
  create trigger parents_create_private_details
    after insert on public.parents
    for each row execute function private.create_parent_private_details();
  
  -- private details: leaders, bursar (fees, invoices), the parent themselves.
  -- Not co-parents, not teachers — they keep name and phone on parents.
  create policy "parent_private_details: leaders, bursars, self"
    on public.parent_private_details for select to authenticated
    using (
      organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal', 'bursar']::public.member_role[]))
      or parent_id in (select private.my_parent_ids())
      or (select private.is_platform_admin())
    );
  
  create policy "parent_private_details: leaders can edit"
    on public.parent_private_details for update to authenticated
    using      (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])))
    with check (organization_id in (select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])));
  
  -- Add parent: profile + private details in one call (leaders only).
  create function public.create_parent(
    p_organization_id uuid,
    p_first_name      text,
    p_last_name       text,
    p_phone           text,
    p_title           text          default null,
    p_gender          public.gender default null,
    p_alt_phone       text          default null,
    p_photo_id        text          default null,
    p_photo_url       text          default null,
    p_is_active       boolean       default true,
    p_email           text          default null,
    p_occupation      text          default null,
    p_address         text          default null
  )
  returns public.parents
  language plpgsql
  security invoker
  set search_path = ''
  as $$
  declare
    v_parent public.parents;
  begin
    insert into public.parents (organization_id, title, first_name, last_name, gender, phone, alt_phone,
                                photo_id, photo_url, is_active)
    values (p_organization_id, p_title, p_first_name, p_last_name, p_gender, p_phone, p_alt_phone,
            p_photo_id, p_photo_url, p_is_active)
    returning * into v_parent;
  
    update public.parent_private_details d
    set email      = p_email,
        occupation = p_occupation,
        address    = p_address
    where d.parent_id = v_parent.id;
  
    return v_parent;
  end;
  $$;
  
  -- Edit parent: every argument required; null clears a field (leaders only).
  create function public.update_parent(
    p_parent_id  uuid,
    p_first_name text,
    p_last_name  text,
    p_phone      text,
    p_title      text,
    p_gender     public.gender,
    p_alt_phone  text,
    p_photo_id   text,
    p_photo_url  text,
    p_is_active  boolean,
    p_email      text,
    p_occupation text,
    p_address    text
  )
  returns public.parents
  language plpgsql
  security invoker
  set search_path = ''
  as $$
  declare
    v_parent public.parents;
  begin
    update public.parents p
    set title      = p_title,
        first_name = p_first_name,
        last_name  = p_last_name,
        gender     = p_gender,
        phone      = p_phone,
        alt_phone  = p_alt_phone,
        photo_id   = p_photo_id,
        photo_url  = p_photo_url,
        is_active  = p_is_active
    where p.id = p_parent_id
    returning p.* into v_parent;
  
    if not found then
      raise exception 'Parent record not found, or you can''t edit it' using errcode = '42501';
    end if;
  
    update public.parent_private_details d
    set email      = p_email,
        occupation = p_occupation,
        address    = p_address
    where d.parent_id = p_parent_id;
  
    return v_parent;
  end;
  $$;
  
  -- ─────────────────────────────────────────────────────────────
  -- Privileges
  -- ─────────────────────────────────────────────────────────────
  revoke all on public.parent_private_details from anon, authenticated;
  grant select on public.parent_private_details to authenticated;
  grant update (email, occupation, address) on public.parent_private_details to authenticated;
  
  revoke execute on function private.create_parent_private_details() from public, anon, authenticated;
  
  revoke execute on function public.create_parent(uuid, text, text, text, text, public.gender, text, text, text, boolean, text, text, text) from public, anon;
  revoke execute on function public.update_parent(uuid, text, text, text, text, public.gender, text, text, text, boolean, text, text, text) from public, anon;
  grant  execute on function public.create_parent(uuid, text, text, text, text, public.gender, text, text, text, boolean, text, text, text) to authenticated;
  grant  execute on function public.update_parent(uuid, text, text, text, text, public.gender, text, text, text, boolean, text, text, text) to authenticated;
  
  revoke all on public.student_private_details from anon, authenticated;
  grant select on public.student_private_details to authenticated;
  grant update (date_of_birth, address, state_of_origin, lga, blood_group, genotype, medical_notes)
    on public.student_private_details to authenticated;
  
  revoke execute on function private.create_student_private_details() from public, anon, authenticated;
  revoke execute on function private.my_ever_taught_student_ids()     from public, anon;
  grant  execute on function private.my_ever_taught_student_ids()     to authenticated;
  
  revoke execute on function public.create_student(uuid, text, text, text, text, public.gender, date, text, text,
                                                   public.student_status, date, text, text, text, text, text, text) from public, anon;
  revoke execute on function public.update_student(uuid, text, text, text, text, public.gender, date, text, text,
                                                   public.student_status, date, text, text, text, text, text, text) from public, anon;
  grant  execute on function public.create_student(uuid, text, text, text, text, public.gender, date, text, text,
                                                   public.student_status, date, text, text, text, text, text, text) to authenticated;
  grant  execute on function public.update_student(uuid, text, text, text, text, public.gender, date, text, text,
                                                   public.student_status, date, text, text, text, text, text, text) to authenticated;
