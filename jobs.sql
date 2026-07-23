-- TipLog v1.1.19.5 — Arbeitgeber-Feature (Tabelle "jobs" + Spalte "job_id" an "shifts")
-- Einmalig im Supabase SQL-Editor ausführen (Projekt qqninfkcgtbxbvjanage).
-- Idempotent: kann gefahrlos mehrfach laufen.

create table if not exists public.jobs (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  start_date date not null default current_date,
  end_date date,
  created_at timestamptz not null default now()
);

alter table public.jobs enable row level security;

drop policy if exists "jobs_select_own" on public.jobs;
create policy "jobs_select_own" on public.jobs
  for select using (auth.uid() = user_id);

drop policy if exists "jobs_insert_own" on public.jobs;
create policy "jobs_insert_own" on public.jobs
  for insert with check (auth.uid() = user_id);

drop policy if exists "jobs_update_own" on public.jobs;
create policy "jobs_update_own" on public.jobs
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Bewusst KEINE Delete-Policy: die App löscht Jobs nie einzeln.
-- Bei Konto-Löschung räumt der Cascade über auth.users automatisch auf.

create index if not exists jobs_user_id_idx on public.jobs(user_id);

-- shifts erweitern: Zuordnung zur Firma (bleibt beim Job-Löschen einfach leer)
alter table public.shifts add column if not exists job_id uuid references public.jobs(id) on delete set null;
create index if not exists shifts_job_id_idx on public.shifts(job_id);
