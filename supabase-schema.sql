-- ============================================================
--  FreeWheel · esquema inicial de base de datos
--  Pégalo COMPLETO en Supabase → SQL Editor → New query → Run
--  (Postgres + PostGIS, ya incluidos en cualquier proyecto Supabase)
-- ============================================================

-- 1) PostGIS: superpoderes geográficos (distancias, "cerca de mí", etc.)
create extension if not exists postgis;

-- 2) La tabla donde vive cada reporte del mapa
create table if not exists public.reportes (
  id         bigint generated always as identity primary key,
  categoria  text not null check (categoria in
             ('rampa','superficie','peralte','obstaculo','sinvereda','accesible')),
  severidad  text not null check (severidad in ('green','amber','red')),
  nota       text,
  lng        double precision not null,   -- longitud (la que ya guarda la app)
  lat        double precision not null,   -- latitud
  geom       geography(Point,4326),       -- punto geográfico calculado (para PostGIS)
  reportero  text,                        -- apodo: "Carlos", un amigo, etc.
  creado_en  timestamptz not null default now()
);

-- 3) Rellena 'geom' solo, a partir de lng/lat, en cada insert/update
create or replace function public.set_geom()
returns trigger language plpgsql as $$
begin
  new.geom := st_setsrid(st_makepoint(new.lng, new.lat), 4326)::geography;
  return new;
end $$;

drop trigger if exists trg_set_geom on public.reportes;
create trigger trg_set_geom
  before insert or update on public.reportes
  for each row execute function public.set_geom();

-- 4) Índice espacial: consultas "¿qué barreras hay cerca?" rápidas
create index if not exists reportes_geom_idx on public.reportes using gist (geom);

-- 5) Tiempo real: que los reportes aparezcan al instante en todos los celulares
alter publication supabase_realtime add table public.reportes;

-- 6) Seguridad (RLS). Modelo "confianza abierta" del MVP, pensado para el
--    grupo de confianza de Carlos. Cualquiera con la app puede leer y aportar.
--    (La moderación / borrado con cuentas la añadimos cuando crezca.)
alter table public.reportes enable row level security;

drop policy if exists "leer todos"     on public.reportes;
drop policy if exists "insertar todos" on public.reportes;

create policy "leer todos"     on public.reportes for select using (true);
create policy "insertar todos" on public.reportes for insert with check (true);

-- Listo. La app se conecta con tu Project URL + la clave "anon public".
