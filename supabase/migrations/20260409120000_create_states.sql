-- Reference / lookup table (Type 3 — see docs/RLS_Approach_Guide.md)
-- Nigerian states: 36 rows

-- 1. Create table
create table public.states (
  id uuid not null default gen_random_uuid(),
  name text not null,
  constraint states_pkey primary key (id, name),
  constraint states_name_key unique (name)
) tablespace pg_default;

-- 2. Enable RLS
alter table public.states enable row level security;

-- 3. Policies (select → insert → update → delete)
create policy select_states on public.states
  for select to authenticated
  using ((auth.jwt() ->> 'sub') is not null);

create policy service_role_insert_states on public.states
  for insert to service_role
  with check (true);

create policy service_role_update_states on public.states
  for update to service_role
  using (true)
  with check (true);

create policy service_role_delete_states on public.states
  for delete to service_role
  using (true);

-- 4. Indexes (name already unique-indexed; optional helper for id-only lookups)
create index if not exists idx_states_id on public.states (id);

-- 5. Seed: 36 Nigeria states (idempotent)
insert into public.states (name) values
  ('Abia'),
  ('Adamawa'),
  ('Akwa Ibom'),
  ('Anambra'),
  ('Bauchi'),
  ('Bayelsa'),
  ('Benue'),
  ('Borno'),
  ('Cross River'),
  ('Delta'),
  ('Ebonyi'),
  ('Edo'),
  ('Ekiti'),
  ('Enugu'),
  ('Gombe'),
  ('Imo'),
  ('Jigawa'),
  ('Kaduna'),
  ('Kano'),
  ('Katsina'),
  ('Kebbi'),
  ('Kogi'),
  ('Kwara'),
  ('Lagos'),
  ('Nasarawa'),
  ('Niger'),
  ('Ogun'),
  ('Ondo'),
  ('Osun'),
  ('Oyo'),
  ('Plateau'),
  ('Rivers'),
  ('Sokoto'),
  ('Taraba'),
  ('Yobe'),
  ('Zamfara')
on conflict (name) do nothing;
