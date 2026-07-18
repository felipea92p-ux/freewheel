-- ============================================================
--  FreeWheel · Fase 1 — identidad silenciosa + dueño de cada reporte
--  Pégalo en Supabase (proyecto Freewheel) → SQL Editor → New query → Run.
--
--  ⚠️ ORDEN IMPORTANTE (para no cortar el reporte en el sitio en vivo):
--    1) Activa "Anonymous sign-ins" en Authentication → Providers.
--    2) Avisa a Claude para que confirme que la sesión anónima ya funciona.
--    3) RECIÉN AHÍ corre este SQL.
--  Si lo corres con el toggle apagado, nadie podrá guardar reportes hasta activarlo.
-- ============================================================

-- 1) Columna dueño: la cuenta (anónima o real) que creó el reporte.
--    Se llena sola con la sesión actual en cada insert nuevo (default auth.uid()).
alter table public.reportes add column if not exists user_id uuid default auth.uid();

-- 2) Admins (Cayla + Carlos): podrán borrar/editar cualquier reporte.
--    Vacía por ahora; sus user_id se agregan en la Fase 2 (cuando tengan cuenta real).
create table if not exists public.admins (
  user_id uuid primary key
);
alter table public.admins enable row level security;  -- sin políticas: solo desde el SQL Editor

-- ¿La sesión actual es admin? (security definer para poder leer public.admins sin exponerla)
create or replace function public.es_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.admins a where a.user_id = auth.uid())
$$;

-- 3) Reglas de acceso (RLS) sobre reportes
-- Leer: sigue abierto a todos (la política "leer todos" ya existe del esquema inicial).

-- Insertar: solo con sesión (anónima o real), y el dueño debe ser uno mismo.
drop policy if exists "insertar todos"  on public.reportes;
drop policy if exists "insertar propios" on public.reportes;
create policy "insertar propios" on public.reportes for insert
  to authenticated with check (auth.uid() = user_id);

-- Editar: solo el dueño (o un admin).
drop policy if exists "editar propios" on public.reportes;
create policy "editar propios" on public.reportes for update
  to authenticated
  using      (auth.uid() = user_id or public.es_admin())
  with check (auth.uid() = user_id or public.es_admin());

-- Borrar: solo el dueño (o un admin).
drop policy if exists "borrar propios" on public.reportes;
create policy "borrar propios" on public.reportes for delete
  to authenticated
  using (auth.uid() = user_id or public.es_admin());

-- Listo. Desde aquí: cada quien borra/edita solo lo suyo, verificado por el servidor.
