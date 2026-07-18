-- ============================================================
--  FreeWheel · Fase 2 — perfiles (nombre + avatar) por cuenta
--  Correr en Supabase (proyecto Freewheel) → SQL Editor → New query → Run.
--  Requiere: Fase 1 ya aplicada. La config de Google no bloquea este SQL.
-- ============================================================

-- 1) Tabla de perfiles: un perfil por cuenta (anónima o con Google).
create table if not exists public.perfiles (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  nombre     text,
  avatar_url text,
  estrellas  int not null default 0,          -- se usa en la Fase 3
  creado_en  timestamptz not null default now()
);

alter table public.perfiles enable row level security;

-- Leer perfiles: público (para mostrar el nombre/avatar de quien reportó).
drop policy if exists "leer perfiles" on public.perfiles;
create policy "leer perfiles" on public.perfiles for select using (true);

-- Crear tu propio perfil.
drop policy if exists "crear mi perfil" on public.perfiles;
create policy "crear mi perfil" on public.perfiles for insert
  to authenticated with check (auth.uid() = user_id);

-- Editar tu propio perfil.
drop policy if exists "editar mi perfil" on public.perfiles;
create policy "editar mi perfil" on public.perfiles for update
  to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Nota: el perfil se llena/actualiza desde la app tras entrar con Google
-- (nombre y avatar vienen de la cuenta de Google). El campo estrellas queda
-- listo para la Fase 3.

-- ============================================================
--  Cómo hacer admins a Cayla y Carlos (después de que entren con Google):
--    1) Que cada uno entre con Google en la app al menos una vez.
--    2) Buscar su user_id:  select id, email from auth.users order by created_at desc;
--    3) insert into public.admins (user_id) values ('<uid-de-cayla>'), ('<uid-de-carlos>');
--  Desde ahí podrán borrar/editar cualquier reporte (moderación).
-- ============================================================
