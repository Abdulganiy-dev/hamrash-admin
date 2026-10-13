-- 02 · Tidy-ups flagged by the Supabase advisors after migration 01
--
-- 1. Rewrite two policies to ((select auth.jwt()) ->> 'sub') so the linter
--    recognises the once-per-query form. Access rules are unchanged.
-- 2. Revoke EXECUTE on public.rls_auto_enable() (Supabase's auto-enable-RLS
--    event-trigger function) from API roles. It can't be called directly anyway;
--    this clears the "anon can execute SECURITY DEFINER function" warning.

alter policy "platform_admins: read own row, platform admins read all"
  on public.platform_admins
  using (
    clerk_user_id = ((select auth.jwt()) ->> 'sub')
    or (select private.is_platform_admin())
  );

alter policy "organization_members: own rows, school leaders and platform admins can read"
  on public.organization_members
  using (
    clerk_user_id = ((select auth.jwt()) ->> 'sub')
    or organization_id in (
      select private.my_org_ids(array['owner', 'admin', 'principal', 'vice_principal']::public.member_role[])
    )
    or (select private.is_platform_admin())
  );

-- rls_auto_enable() exists only on hosted Supabase, so skip it on a local
-- database (supabase start / db reset). Same effect on the hosted project.
do $$
begin
  if to_regprocedure('public.rls_auto_enable()') is not null then
    revoke execute on function public.rls_auto_enable() from public, anon, authenticated;
  end if;
end;
$$;
