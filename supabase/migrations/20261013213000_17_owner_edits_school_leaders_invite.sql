-- 17 · Only the owner edits the school; principals and VPs invite the team
--
-- School details (name, address, phone, email, logo, number prefix, and
-- confirming them) move from owners and admins to the owner alone.
--
-- Inviting the team opens up to principals and vice principals, up to their
-- own level: principal, vice principal, bursar, teacher, staff. Owners and
-- admins can still invite any role except owner. Leaders can cancel an
-- unclaimed invite they could have sent. Changing a member's role or status
-- stays with owners and admins.

-- ─────────────────────────────────────────────────────────────
-- organizations: owner only
-- ─────────────────────────────────────────────────────────────
drop policy "organizations: owners, admins and platform admins can update"
  on public.organizations;

create policy "organizations: owners and platform admins can update"
  on public.organizations for update to authenticated
  using (
    id in (select private.my_org_ids(array['owner']::public.member_role[]))
    or (select private.is_platform_admin())
  )
  with check (
    id in (select private.my_org_ids(array['owner']::public.member_role[]))
    or (select private.is_platform_admin())
  );

-- ─────────────────────────────────────────────────────────────
-- organization_members: invites
-- ─────────────────────────────────────────────────────────────
drop policy "organization_members: owners and admins invite; platform admins invite owners"
  on public.organization_members;

create policy "organization_members: leaders invite; platform admins invite owners"
  on public.organization_members for insert to authenticated
  with check (
    status = 'invited'
    and (
      (role <> 'owner'
       and organization_id in (select private.my_org_ids(array['owner', 'admin']::public.member_role[])))
      or (role in ('principal', 'vice_principal', 'bursar', 'teacher', 'staff')
       and organization_id in (select private.my_org_ids(array['principal', 'vice_principal']::public.member_role[])))
      or (select private.is_platform_admin())
    )
  );

drop policy "organization_members: owners, admins and platform admins can delete unclaimed invites"
  on public.organization_members;

create policy "organization_members: leaders and platform admins can delete unclaimed invites"
  on public.organization_members for delete to authenticated
  using (
    status = 'invited'
    and (
      organization_id in (select private.my_org_ids(array['owner', 'admin']::public.member_role[]))
      or (role in ('principal', 'vice_principal', 'bursar', 'teacher', 'staff')
       and organization_id in (select private.my_org_ids(array['principal', 'vice_principal']::public.member_role[])))
      or (select private.is_platform_admin())
    )
  );
