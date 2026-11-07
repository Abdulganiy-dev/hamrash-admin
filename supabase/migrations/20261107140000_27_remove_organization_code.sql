-- 27 · Remove the school code (organizations.code, `HMR-XXXXXX`)
--
-- The code was only a label: nothing granted access with it. Joining a school
-- uses the owner's claim code, and every rule goes through organizations.id.
--
-- * create_organization no longer makes or returns a school code. It now
--   returns (organization_id, owner_claim_code). The return type changes, so
--   it is dropped and recreated.
-- * check_claim_code no longer returns school_code. Same: dropped and recreated.
-- * private.guard_organization_update (migration 14) compared new.code with
--   old.code. Dropping the column would make every update by a non-platform
--   admin fail, so it is replaced first.
-- * Then the column, its unique index and its format check go.
--
-- Contains DROP, which the Supabase connector refuses to run: apply it in the
-- SQL editor, then record it in supabase_migrations.schema_migrations.

-- ─────────────────────────────────────────────────────────────
-- The update guard, without the code comparison (replaced in place, so the
-- trigger from migration 14 keeps using it)
-- ─────────────────────────────────────────────────────────────
create or replace function private.guard_organization_update()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if (select private.is_platform_admin()) then
    return new;
  end if;
  if new.status is distinct from old.status
     or new.created_by is distinct from old.created_by
     or new.created_at is distinct from old.created_at then
    raise exception 'Only Hamrash can change this' using errcode = '42501';
  end if;
  return new;
end $$;

-- ─────────────────────────────────────────────────────────────
-- create_organization: same, without the school code
-- ─────────────────────────────────────────────────────────────
drop function public.create_organization(text, text, text, text, text, text);

create function public.create_organization(
  p_name          text,
  p_number_prefix text,
  p_email         text default null,
  p_phone         text default null,
  p_address       text default null,
  p_state         text default null
)
returns table (organization_id uuid, owner_claim_code text)
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_sub    text := (select auth.jwt() ->> 'sub');
  v_prefix text := upper(trim(coalesce(p_number_prefix, '')));
  v_org    public.organizations;
  v_claim  text;
begin
  if not private.is_platform_admin() then
    raise exception 'Only Hamrash platform admins can create schools' using errcode = '42501';
  end if;

  if v_prefix !~ '^[A-Z0-9]{2,8}$' then
    raise exception 'Number prefix must be 2 to 8 letters or digits, e.g. KCL' using errcode = '22023';
  end if;

  insert into public.organizations (name, number_prefix, email, phone, address, state, created_by)
  values (trim(p_name), v_prefix, p_email, p_phone, p_address, p_state, v_sub)
  returning * into v_org;

  insert into public.organization_members (organization_id, role, invited_by)
  values (v_org.id, 'owner', v_sub)
  returning claim_code into v_claim;

  return query select v_org.id, v_claim;
end;
$$;

revoke execute on function public.create_organization(text, text, text, text, text, text) from public, anon;
grant  execute on function public.create_organization(text, text, text, text, text, text) to authenticated;

-- ─────────────────────────────────────────────────────────────
-- check_claim_code: same, without school_code
-- ─────────────────────────────────────────────────────────────
drop function public.check_claim_code(text);

create function public.check_claim_code(p_code text)
returns table (
  status          text,
  organization_id uuid,
  school_name     text,
  school_address  text,
  school_state    text,
  school_logo_url text,
  role            public.member_role,
  app             text,
  needs_name      boolean
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_sub    text := (select auth.jwt() ->> 'sub');
  v_code   text := private.normalise_claim_code(p_code);
  v_member public.organization_members;
  v_org    public.organizations;
begin
  if v_sub is null or v_sub = '' then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  select m.* into v_member
  from public.organization_members m
  where m.claim_code = v_code
    and m.status = 'invited';

  if not found then
    return query select 'not_found', null::uuid, null::text, null::text, null::text, null::text,
                        null::public.member_role, null::text, null::boolean;
    return;
  end if;

  select o.* into v_org from public.organizations o where o.id = v_member.organization_id;

  return query select
    case
      when v_org.status not in ('trial', 'active') then 'school_inactive'
      when exists (
        select 1 from public.organization_members m
        where m.organization_id = v_member.organization_id
          and m.clerk_user_id = v_sub
          and m.role = v_member.role
      ) then 'already_member'
      else 'ok'
    end,
    v_org.id, v_org.name, v_org.address, v_org.state, v_org.logo_url,
    v_member.role,
    private.member_role_app(v_member.role),
    private.owner_needs_staff_record(v_member, v_sub);
end;
$$;

revoke execute on function public.check_claim_code(text) from public, anon;
grant  execute on function public.check_claim_code(text) to authenticated;

-- ─────────────────────────────────────────────────────────────
-- The column itself (its unique index goes with it)
-- ─────────────────────────────────────────────────────────────
alter table public.organizations drop constraint organizations_code_format;
alter table public.organizations drop column code;
