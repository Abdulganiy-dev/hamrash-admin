-- 20 · A current term must be replaced before it can be removed.
-- This is a database rule so a direct DELETE cannot bypass the app's disabled action.

create function private.guard_current_term_delete()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if old.is_current then
    raise exception 'Make another term current before removing this one' using errcode = 'P0001';
  end if;

  return old;
end;
$$;

create trigger academic_terms_guard_current_delete
  before delete on public.academic_terms
  for each row execute function private.guard_current_term_delete();

revoke execute on function private.guard_current_term_delete() from public, anon, authenticated;
