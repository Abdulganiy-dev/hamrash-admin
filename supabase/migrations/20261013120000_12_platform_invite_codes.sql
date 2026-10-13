-- 12 · Platform invite codes: join the Hamrash team with a one-time code
--
-- Until now a platform admin could only be added by hand in the SQL editor.
-- Now any active platform admin can create a one-time code in Hamrash
-- Platform Admin (Team tab) and give it to a new team member. That person
-- signs in, enters the code, and becomes a platform admin.
--
-- Decisions:
-- * Any active platform admin can create, list and cancel codes.
-- * A code works once and expires 7 days after it's created.
-- * A code isn't tied to an email (Apple "Hide my email" would break that).
-- * Codes are 12 characters (about 60 bits) and only their SHA-256 hash is
--   stored, so a code is shown once, when it's created.
-- * 5 wrong codes per account per hour, then redeeming is blocked for the
--   rest of the hour.
-- * A platform admin who was turned off (is_active = false) can't use a code
--   to get back in. Turn them back on in the SQL editor if that's intended.
--
-- Everything lives in the private schema (not exposed by the Data API); the
-- app only reaches it through the four RPCs below.
-- Design notes: docs/organization-schema.md → Platform invite codes

-- ─────────────────────────────────────────────────────────────
-- Tables
-- ─────────────────────────────────────────────────────────────
create table private.platform_invite_codes (
  id           uuid primary key default gen_random_uuid(),
  code_hash    text not null unique,         -- sha256 hex of the 12-char code
  code_hint    text not null,                -- last 4 chars, so admins can tell codes apart
  note         text,                         -- who it's for, e.g. "Amina, support"
  created_by   text not null references public.platform_admins (clerk_user_id),
  created_at   timestamptz not null default now(),
  expires_at   timestamptz not null,
  redeemed_by  text references public.platform_admins (clerk_user_id),
  redeemed_at  timestamptz,
  revoked_by   text references public.platform_admins (clerk_user_id),
  revoked_at   timestamptz,
  constraint platform_invite_codes_hint_format check (code_hint ~ '^[A-Z0-9]{4}$'),
  constraint platform_invite_codes_redeemed_pair check ((redeemed_by is null) = (redeemed_at is null)),
  constraint platform_invite_codes_revoked_pair  check ((revoked_by is null) = (revoked_at is null)),
  constraint platform_invite_codes_used_once     check (redeemed_at is null or revoked_at is null)
);

create index platform_invite_codes_created_by_idx  on private.platform_invite_codes (created_by);
create index platform_invite_codes_redeemed_by_idx on private.platform_invite_codes (redeemed_by);
create index platform_invite_codes_revoked_by_idx  on private.platform_invite_codes (revoked_by);
create index platform_invite_codes_created_at_idx  on private.platform_invite_codes (created_at desc);

-- Wrong-code attempts, for the 5-per-hour limit. Old rows are pruned on use.
create table private.platform_invite_attempts (
  id             bigint generated always as identity primary key,
  clerk_user_id  text not null,
  attempted_at   timestamptz not null default now()
);

create index platform_invite_attempts_user_time_idx
  on private.platform_invite_attempts (clerk_user_id, attempted_at desc);

-- Not exposed and no grants, but RLS (with no policies) as a second layer:
-- only the security-definer functions below can touch these tables.
alter table private.platform_invite_codes    enable row level security;
alter table private.platform_invite_attempts enable row level security;

-- ─────────────────────────────────────────────────────────────
-- Helper: normalise and hash a code the way it's stored
-- "abcd-efgh-2345" → sha256("ABCDEFGH2345")
-- ─────────────────────────────────────────────────────────────
create function private.platform_code_hash(p_code text)
returns text
language sql
immutable
set search_path = ''
as $$
  select encode(
    extensions.digest(upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g')), 'sha256'),
    'hex'
  );
$$;

-- ─────────────────────────────────────────────────────────────
-- RPC: create a code (platform admins only). The plain code is returned
-- once and never stored.
-- ─────────────────────────────────────────────────────────────
create function public.create_platform_invite(p_note text default null)
returns table (invite_id uuid, code text, expires_at timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_sub  text := (select auth.jwt() ->> 'sub');
  v_code text;
  v_row  private.platform_invite_codes;
begin
  if not private.is_platform_admin() then
    raise exception 'Only Hamrash platform admins can invite team members' using errcode = '42501';
  end if;

  loop
    v_code := private.random_code(12);
    exit when not exists (
      select 1 from private.platform_invite_codes c
      where c.code_hash = private.platform_code_hash(v_code)
    );
  end loop;

  insert into private.platform_invite_codes (code_hash, code_hint, note, created_by, expires_at)
  values (private.platform_code_hash(v_code), right(v_code, 4), nullif(trim(p_note), ''), v_sub,
          now() + interval '7 days')
  returning * into v_row;

  return query select v_row.id, v_code, v_row.expires_at;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- RPC: list codes (platform admins only), newest first.
-- status: 'pending' | 'used' | 'expired' | 'cancelled'
-- ─────────────────────────────────────────────────────────────
create function public.list_platform_invites()
returns table (
  invite_id        uuid,
  code_hint        text,
  note             text,
  status           text,
  created_by_name  text,
  created_at       timestamptz,
  expires_at       timestamptz,
  redeemed_by_name text,
  redeemed_at      timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not private.is_platform_admin() then
    raise exception 'Only Hamrash platform admins can see team invites' using errcode = '42501';
  end if;

  return query
  select c.id,
         c.code_hint,
         c.note,
         case
           when c.redeemed_at is not null then 'used'
           when c.revoked_at  is not null then 'cancelled'
           when c.expires_at <= now()     then 'expired'
           else 'pending'
         end,
         creator.full_name,
         c.created_at,
         c.expires_at,
         redeemer.full_name,
         c.redeemed_at
  from private.platform_invite_codes c
  join public.platform_admins creator on creator.clerk_user_id = c.created_by
  left join public.platform_admins redeemer on redeemer.clerk_user_id = c.redeemed_by
  order by c.created_at desc
  limit 100;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- RPC: cancel an unused code (platform admins only)
-- ─────────────────────────────────────────────────────────────
create function public.revoke_platform_invite(p_invite_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_sub text := (select auth.jwt() ->> 'sub');
begin
  if not private.is_platform_admin() then
    raise exception 'Only Hamrash platform admins can cancel team invites' using errcode = '42501';
  end if;

  update private.platform_invite_codes c
  set revoked_by = v_sub,
      revoked_at = now()
  where c.id = p_invite_id
    and c.redeemed_at is null
    and c.revoked_at is null;

  if not found then
    raise exception 'This invite has already been used or cancelled' using errcode = 'P0001';
  end if;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- RPC: redeem a code and join the Hamrash team (any signed-in user)
--
-- Returns the caller's platform_admins row, or NULL when the code is wrong,
-- used, cancelled or expired. A wrong code doesn't raise, so the attempt row
-- is kept and counts towards the limit.
-- ─────────────────────────────────────────────────────────────
create function public.redeem_platform_invite(
  p_code      text,
  p_full_name text,
  p_email     text default null
)
returns public.platform_admins
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_sub      text := (select auth.jwt() ->> 'sub');
  v_existing public.platform_admins;
  v_invite   private.platform_invite_codes;
  v_admin    public.platform_admins;
  v_tries    int;
begin
  if v_sub is null or v_sub = '' then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  -- Already on the team: nothing to redeem, and the code stays unused.
  select pa.* into v_existing from public.platform_admins pa where pa.clerk_user_id = v_sub;
  if found then
    if v_existing.is_active then
      return v_existing;
    end if;
    raise exception 'Your platform access was turned off. Ask a Hamrash admin to turn it back on.'
      using errcode = '42501';
  end if;

  if nullif(trim(p_full_name), '') is null then
    raise exception 'Enter your full name to join the Hamrash team' using errcode = '22023';
  end if;

  delete from private.platform_invite_attempts a
  where a.clerk_user_id = v_sub and a.attempted_at < now() - interval '1 day';

  select count(*) into v_tries
  from private.platform_invite_attempts a
  where a.clerk_user_id = v_sub and a.attempted_at > now() - interval '1 hour';

  if v_tries >= 5 then
    raise exception 'Too many wrong codes. Wait an hour, then try again.' using errcode = 'P0001';
  end if;

  select c.* into v_invite
  from private.platform_invite_codes c
  where c.code_hash = private.platform_code_hash(p_code)
    and c.redeemed_at is null
    and c.revoked_at is null
    and c.expires_at > now()
  for update;

  if not found then
    insert into private.platform_invite_attempts (clerk_user_id) values (v_sub);
    return null;
  end if;

  insert into public.platform_admins (clerk_user_id, full_name, email)
  values (v_sub, trim(p_full_name), nullif(trim(p_email), ''))
  returning * into v_admin;

  update private.platform_invite_codes c
  set redeemed_by = v_sub,
      redeemed_at = now()
  where c.id = v_invite.id;

  delete from private.platform_invite_attempts a where a.clerk_user_id = v_sub;

  return v_admin;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- Privileges
-- ─────────────────────────────────────────────────────────────
revoke execute on function private.platform_code_hash(text)                   from public, anon, authenticated;
revoke execute on function public.create_platform_invite(text)                from public, anon;
revoke execute on function public.list_platform_invites()                     from public, anon;
revoke execute on function public.revoke_platform_invite(uuid)                from public, anon;
revoke execute on function public.redeem_platform_invite(text, text, text)    from public, anon;
grant  execute on function public.create_platform_invite(text)                to authenticated;
grant  execute on function public.list_platform_invites()                     to authenticated;
grant  execute on function public.revoke_platform_invite(uuid)                to authenticated;
grant  execute on function public.redeem_platform_invite(text, text, text)    to authenticated;
