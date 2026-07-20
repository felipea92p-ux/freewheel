-- ============================================================
--  FreeWheel · Confirmaciones — "¿Sigue así?" (frescura del dato)
--  Correr en Supabase (proyecto Freewheel) → SQL Editor → New query → Run.
--  Seguro: crea UNA tabla nueva. No toca reportes ni nada existente.
--
--  Por qué tabla aparte y no columnas en 'reportes':
--   confirmar el punto de OTRA persona debe poder hacerlo cualquiera, pero la
--   RLS de 'reportes' solo deja al dueño editar. Una tabla propia con sus reglas
--   lo resuelve, evita confirmaciones repetidas (una por persona) y da el conteo.
-- ============================================================

create table if not exists public.confirmaciones (
  id          bigint generated always as identity primary key,
  reporte_id  bigint not null references public.reportes(id) on delete cascade,
  user_id     uuid    not null default auth.uid(),
  sigue       boolean not null,                 -- true = "sí, sigue así"; false = "ya cambió"
  creado_en   timestamptz not null default now(),
  unique (reporte_id, user_id)                  -- una respuesta por persona por reporte
);

alter table public.confirmaciones enable row level security;

-- Leer: público (para mostrar "confirmado por N" y la frescura).
drop policy if exists "leer confirmaciones" on public.confirmaciones;
create policy "leer confirmaciones" on public.confirmaciones for select using (true);

-- Crear tu confirmación (cualquiera con sesión, anónima o real; el dueño eres tú).
drop policy if exists "crear mi confirmacion" on public.confirmaciones;
create policy "crear mi confirmacion" on public.confirmaciones for insert
  to authenticated with check (auth.uid() = user_id);

-- Cambiar de opinión (upsert): editar tu propia confirmación.
drop policy if exists "editar mi confirmacion" on public.confirmaciones;
create policy "editar mi confirmacion" on public.confirmaciones for update
  to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Índice para agrupar rápido por reporte.
create index if not exists idx_confirmaciones_reporte on public.confirmaciones (reporte_id);
