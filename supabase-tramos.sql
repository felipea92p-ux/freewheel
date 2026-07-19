-- ============================================================
--  FreeWheel · Tramos — marcar un tramo entero (una cuadra/calle) accesible
--  Correr en Supabase (proyecto Freewheel) → SQL Editor → New query → Run.
--  Seguro y no rompe nada: agrega UNA columna opcional. Los reportes viejos
--  (puntos) quedan con tramo = null y siguen funcionando igual.
-- ============================================================

-- Un reporte puede ser un PUNTO (tramo null, usa lng/lat) o un TRAMO (línea).
-- Guardamos el tramo como lista de coordenadas [[lng,lat],[lng,lat],...].
alter table public.reportes add column if not exists tramo jsonb;

-- No hace falta tocar RLS: las políticas por dueño (insertar/editar/borrar
-- propios) ya cubren esta columna. lng/lat se mantienen como ancla del tramo
-- (primer punto), para centrar el mapa y anclar el popup.
