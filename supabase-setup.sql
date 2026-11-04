-- =====================================================================
--  Verbali · configurazione Supabase
--  Esegui tutto questo in: Supabase → SQL Editor → New query → Run
-- =====================================================================

-- 1) TABELLE -----------------------------------------------------------
create table if not exists public.verbali (
  id         uuid primary key default gen_random_uuid(),
  title      text not null,
  path       text not null,                 -- percorso del file nello storage
  created_at timestamptz not null default now()
);

create table if not exists public.sessions (
  id            uuid primary key default gen_random_uuid(),
  reader_name   text not null,
  verbale_id    uuid,
  verbale_title text,
  duration_sec  integer not null,
  started_at    timestamptz,
  ended_at      timestamptz not null default now()
);

-- 2) SICUREZZA (RLS) ---------------------------------------------------
-- Impostazione semplice e permissiva: adatta a uso interno a basso rischio.
-- Chiunque abbia la pagina può leggere/aggiungere. (Vedi nota nel README.)
alter table public.verbali  enable row level security;
alter table public.sessions enable row level security;

drop policy if exists "verbali_read"   on public.verbali;
drop policy if exists "verbali_insert" on public.verbali;
drop policy if exists "verbali_delete" on public.verbali;
create policy "verbali_read"   on public.verbali for select using (true);
create policy "verbali_insert" on public.verbali for insert with check (true);
create policy "verbali_delete" on public.verbali for delete using (true);

drop policy if exists "sessions_read"   on public.sessions;
drop policy if exists "sessions_insert" on public.sessions;
create policy "sessions_read"   on public.sessions for select using (true);
create policy "sessions_insert" on public.sessions for insert with check (true);

-- 3) STORAGE -----------------------------------------------------------
-- Crea il bucket pubblico "verbali" (idempotente).
insert into storage.buckets (id, name, public)
values ('verbali', 'verbali', true)
on conflict (id) do update set public = true;

-- Permessi sui file del bucket "verbali".
drop policy if exists "verbali_files_read"   on storage.objects;
drop policy if exists "verbali_files_insert" on storage.objects;
drop policy if exists "verbali_files_delete" on storage.objects;
create policy "verbali_files_read"   on storage.objects for select using (bucket_id = 'verbali');
create policy "verbali_files_insert" on storage.objects for insert with check (bucket_id = 'verbali');
create policy "verbali_files_delete" on storage.objects for delete using (bucket_id = 'verbali');

-- Fatto. ---------------------------------------------------------------
