# REVISIÓN FreeWheel — checklist para retomar

> Última actualización: 2026-07-18 (tras desplegar linkIdentity + avatares en el mapa). Verificado contra el código real.
> Esfuerzo: **Rápido** (<1h) · **Medio** (~medio día) · **Grande** (1+ día). Orden por impacto dentro de cada sección.

## 📍 Estado actual (en vivo en freewheel-psi.vercel.app)
- **Reportes** con foto (comprimida + Supabase Storage), tiempo real, apodo.
- **Ruta accesible** A→B (perfil silla de ruedas de OpenRouteService), elegir puntos por texto/autocompletado (todo Perú) o tocando el mapa, "usar mi ubicación".
- **Cuentas — Fase 1 y Fase 2 EN VIVO:**
  - Identidad anónima silenciosa por dispositivo → **borrar/editar solo lo tuyo** (verificado por RLS en el servidor).
  - **Login con Google** (opcional) → perfil, avatar, base de estrellas. Panel de cuenta vistoso.
- **Diseño:** índigo cálido, foco de teclado visible, identidad ♿.
- **Esquemas SQL** (ya corridos): `supabase-schema.sql` (base), `supabase-fase1-cuentas.sql`, `supabase-fase2-perfiles.sql`.

> **✅ Todo lo local ya está DESPLEGADO** (2026-07-18): indicador de carga, mensaje amable de ruta sin datos, cierre del panel de cuenta al tocar fuera, propagación de ediciones en tiempo real, **conservar reportes anónimos al entrar con Google** (linkIdentity) y **avatares/nombre de perfil en los pines**. Nada de esto tocó la base de datos.

---

## ⚠️ LO PRIMERO PARA MAÑANA (pendientes concretos de la sesión)

0. **Activar "Allow manual linking" en Supabase** — *Rápido* · Authentication → **Sign In / Providers** → sección **User Signups** → activar **Allow manual linking**. Sin esto, entrar con Google **no** conserva los reportes hechos como anónimo (el código lo intenta con `linkIdentity` y, si el toggle está apagado, cae a login normal sin romperse — pero los reportes quedan huérfanos). Con el toggle activo, "tus reportes te siguen" se cumple de verdad.

1. **Hacer admins a Cayla y Carlos** — *Rápido (SQL)* · Para que puedan moderar (borrar/editar cualquier reporte). La tabla `admins` está vacía. Pasos: que cada uno entre con Google una vez → `select id, email from auth.users;` → `insert into public.admins (user_id) values ('<uid>');`. Ver notas en `supabase-fase2-perfiles.sql`.

2. **Aviso "Google no ha verificado esta app"** — *Rápido* · Al entrar con Google saldrá esa advertencia (app en modo testing). Solución: en Google Auth Platform → **Público** → agregar a Cayla/Carlos como **usuarios de prueba**, o **publicar la app** (los usuarios verían el aviso pero pueden continuar). Para el piloto, agregar test users es lo más limpio.

3. **Probar el login real en celular** — crear reporte logueado, ver avatar, confirmar que editar/borrar sigue al usuario entre dispositivos.

---

## 🐛 BUGS / cosas frágiles

1. **[MEDIO] La API key de OpenRouteService está expuesta en el código público** — *Medio* ·
   Cualquiera puede copiarla y gastar tu cuota (2000/día) o usarla. Mitigar: restringir la key por dominio en el panel de ORS, o proxy vía función serverless (Vercel) con la key en secreto.

2. **[MEDIO] Las fotos de celular pueden salir giradas** — *Medio* ·
   Al comprimir en `<canvas>` se pierde la orientación EXIF; fotos verticales se guardan de lado. Leer EXIF y rotar antes de subir.

3. **[MEDIO] Sin escala: se cargan TODOS los reportes, un marcador por cada uno** — *Grande* ·
   `loadReports()` hace `select("*")` sin límite y crea un pin por reporte. Con cientos, el mapa se pone lento en celular; con miles, se traba. (Ahora además trae los perfiles con `.in("user_id", …)`; con muchos autores la URL crece — otra razón para paginar/acotar al área visible.) Urgirá cuando la comunidad aporte de verdad.

4. **[MEDIO] Moderación de contenido ajeno (spam/ofensas)** — *Grande* ·
   Con login, ya hay identidad y admins (una vez configurados), pero falta el botón **"marcar como inapropiado"** y que cualquiera pueda insertar sin límite sigue abierto. Cuando el link circule, conviene rate-limit + reporte de contenido (parte de la Fase 3).

5. **[BAJO] El modal (hoja de reporte) no atrapa el foco del teclado** — *Medio* ·
   Tabulando se puede salir a los controles del mapa detrás. Falta focus-trap (accesibilidad).

6. **[BAJO] El panel de RUTA no se cierra al tocar fuera** — *Rápido* ·
   El panel de cuenta ya cierra con clic afuera (hecho). Falta el de ruta, pero es más delicado por su modo "elegir punto en el mapa" (no debe cerrarse al tocar el mapa para picar); dejarlo para cuando se pueda probar bien.

---

## 🔧 MEJORAS a lo que ya existe

1. **Leyenda interactiva / filtros** — *Medio* · Tocar "Bloqueado" para ver solo esos, esconder "Accesible", filtrar por tipo de barrera. Ayuda a planear un recorrido.

2. **Cola offline para reportes** — *Grande* · En la calle con señal intermitente, guardar en cola local y subir cuando vuelva la conexión. Hoy si falla, la hoja no se cierra y se puede reintentar, pero no hay cola.

3. **Editar/cambiar el apodo desde el panel de cuenta** — *Rápido* · Hoy el apodo se edita en la hoja de reporte; tenerlo también en el perfil sería más claro para usuarios logueados.

---

## 💡 IDEAS ÚTILES — funciones nuevas

1. **Convertir en PWA (instalable + offline)** — *Medio* · Carlos la tendría como ícono en su pantalla de inicio, abre a pantalla completa y muestra el último mapa aunque no haya señal. El mayor salto de "web" a "app" sin reescribir. (También abre el camino a Google Play con TWA.)

2. **Fase 3 — Estrellas + la ruta avisa de barreras bloqueadas** — *Grande* · El corazón de la idea: ganar ⭐ por aportar (reportar, que confirmen tus puntos) y usar PostGIS (ya habilitado) para advertir/desviar cuando una ruta pasa cerca de un punto "bloqueado". Cobra sentido con reportes reales.

3. **"Confirmar / Yo también lo vi"** — *Medio* · Validación comunitaria; un punto con varias confirmaciones es más confiable y más fresco.

4. **"Ya está arreglado"** — *Medio* · Marcar un punto como resuelto (las barreras cambian) mantiene el mapa vivo.

5. **Compartir un reporte o una ruta por link/WhatsApp** — *Rápido/Medio* · Difunde la app sola; súper natural en Perú.

6. **"Cerca de mí": lista de puntos accesibles/bloqueados alrededor** — *Medio* · A veces solo quieres saber "¿qué hay difícil cerca?" antes de salir.

7. **Reporte rápido: un toque para "bloqueado aquí"** — *Rápido* · Registrar al vuelo en la calle, detalle después.

8. **Modo voz reforzado para Carlos** — *Medio* · Botón de voz grande, elegir categoría por voz; respeta su movilidad limitada de manos.

9. **Panel/estadística para municipalidad u ONG** — *Medio* · "40 puntos bloqueados en el centro" como herramienta de incidencia.

10. **Categorías propias del contexto peruano** — *Rápido* · Ambulantes en la vereda, mototaxis, huecos de desagüe sin tapa.

---

### Nota de coherencia (decisión de producto, no bug)
La búsqueda funciona en todo Perú, pero la marca, el mapa inicial y los reportes son de Trujillo. Hoy no molesta; si se decide multi-ciudad de verdad, repensar la portada y mostrar reportes por ciudad.

---

## ✅ Resuelto el 2026-07-18
- **[bug ALTO] Entrar con Google ahora conserva los reportes anónimos** — `linkIdentity` vincula Google a la cuenta anónima (mismo uid), con fallback seguro a `signInWithOAuth` en otro dispositivo. **Falta el toggle "Allow manual linking" en Supabase** (pendiente #0) para que surta efecto pleno.
- **[bug MEDIO] Avatares y nombre de perfil en los pines** — al cargar reportes se traen los perfiles por `user_id` y se pintan (foto + nombre de Google) en el popup; sin perfil, cae al apodo. El perfil propio se cachea al loguearse.
- **Todo lo local quedó desplegado** en freewheel-psi.vercel.app.

## ✅ Resuelto el 2026-07-17
- Cuentas Fase 1 (identidad anónima + borrar/editar lo propio, RLS) y Fase 2 (login Google + perfiles + avatares + panel vistoso) — **en vivo**.
- Indicador "Cargando mapa…" al abrir; mensaje amable cuando ORS no encuentra ruta accesible; log de fallos al guardar perfil; el panel de cuenta se cierra al tocar fuera; **las ediciones ahora se propagan en tiempo real** (handler UPDATE en la suscripción, además de INSERT/DELETE).
- Bug: botón "Eliminar" ahora funciona (para el dueño) — antes fallaba siempre por falta de política RLS.
- Zoom de página habilitado (accesibilidad); foto elegible desde galería (quitado `capture`).
- Apodo como campo editable en la hoja (adiós al `prompt()` que dejaba "Anónimo").
- "Usar mi ubicación" en la ruta; foto ampliable en el popup; "hace X días" en el popup; copy "en silla de ruedas".
- Búsqueda a todo Perú (con Trujillo como ancla); autocompletado de direcciones; panel de ruta que no tapa el botón; rediseño índigo; identidad ♿.
- Race condition de pines duplicados; contraste WCAG de las etiquetas de severidad; escape XSS del apodo en el popup.
