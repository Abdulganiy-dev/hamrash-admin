-- 16 · Let owners and admins mark a school's details as checked
--
-- organizations uses column-level UPDATE grants (name, address, phone, email,
-- state, number_prefix, logo_id, logo_url). Migration 14 added
-- details_confirmed_at but never granted it, so "Looks good" failed with
-- "permission denied for table organizations".
--
-- Only the column the app sends is granted. The stamp trigger (15) fills in
-- the real time and details_confirmed_by, which stays ungranted. The
-- owners/admins update policy still applies on top.

grant update (details_confirmed_at) on public.organizations to authenticated;
