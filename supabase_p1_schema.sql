-- =====================================================================
-- P1 Financial Model — Supabase schema
-- =====================================================================
-- Run this once in the Supabase SQL Editor for project ewdloawwudqkdrstqfet
-- It creates a shared `p1_versions` table that the whole team can read/write.
-- One row carries the "default" flag (is_default=true) — that's the version
-- the model loads when you open it. Users can save additional named versions
-- (scenarios). All versions are visible to every authenticated user.
-- =====================================================================

create table if not exists public.p1_versions (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  is_default  boolean not null default false,
  data        jsonb not null default '{}'::jsonb,
  created_by  uuid references auth.users(id) on delete set null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  updated_by  uuid references auth.users(id) on delete set null
);

-- Only one row can ever carry is_default = true.
create unique index if not exists p1_versions_only_one_default
  on public.p1_versions (is_default)
  where is_default = true;

-- Auto-bump updated_at on every UPDATE.
create or replace function public.p1_versions_touch_updated_at()
  returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_p1_versions_touch on public.p1_versions;
create trigger trg_p1_versions_touch
  before update on public.p1_versions
  for each row execute function public.p1_versions_touch_updated_at();

-- ---------------------------------------------------------------------
-- Row-level security: shared across all authenticated users.
-- ---------------------------------------------------------------------
alter table public.p1_versions enable row level security;

drop policy if exists "p1_versions read"   on public.p1_versions;
drop policy if exists "p1_versions insert" on public.p1_versions;
drop policy if exists "p1_versions update" on public.p1_versions;
drop policy if exists "p1_versions delete" on public.p1_versions;

create policy "p1_versions read"
  on public.p1_versions for select
  to authenticated using (true);

create policy "p1_versions insert"
  on public.p1_versions for insert
  to authenticated with check (auth.uid() = created_by);

create policy "p1_versions update"
  on public.p1_versions for update
  to authenticated using (true) with check (true);

create policy "p1_versions delete"
  on public.p1_versions for delete
  to authenticated using (true);

-- ---------------------------------------------------------------------
-- Done. The app will auto-create the first "Current" version on first
-- load if no rows exist.
-- ---------------------------------------------------------------------
