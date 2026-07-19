# REVISIÓN FreeWheel — checklist para retomar

> Última actualización: 2026-07-18 (tras desplegar linkIdentity, avatares, fix EXIF y compartir por WhatsApp). Verificado contra el código real.
> Esfuerzo: **Rápido** (<1h) · **Medio** (~medio día) · **Grande** (1+ día). Orden por impacto dentro de cada sección.

## 📍 Estado actual (en vivo en freewheel-psi.vercel.app)
- **Reportes** con foto (comprimida + Supabase Storage, **orientación EXIF corregida**), tiempo real, apodo. **Compartir cada punto por WhatsApp** (link `?r=<id>` que abre la app en ese pin).
- **Ruta accesible** A→B (perfil silla de ruedas de OpenRouteService), elegir puntos por texto/autocompletado (todo Perú) o tocando el mapa, "usar mi ubicación".
- **Cuentas — Fase 1 y Fase 2 EN VIVO:**
  - Identidad anónima silenciosa por dispositivo → **borrar/editar solo lo tuyo** (verificado por RLS en el servidor).
  - **Login con Google** (opcional) → perfil, avatar, base de estrellas. Panel de cuenta vistoso.
- **Diseño:** índigo cálido, foco de teclado visible, identidad ♿.
- **Esquemas SQL** (ya corridos): `supabase-schema.sql` (base), `supabase-fase1-cuentas.sql`, `supabase-fase2-perfiles.sql`.

> **✅ Todo lo local ya está DESPLEGADO** (2026-07-18): indicador de carga, mensaje amable de ruta sin datos, cierre del panel de cuenta al tocar fuera, propagación de ediciones en tiempo real, **conservar reportes anónimos al entrar con Google** (linkIdentity) y **avatares/nombre de perfil en los pines**. Nada de esto tocó la base de datos.

---

## ⚠️ LO PRIMERO PARA MAÑANA (pendientes concretos de la sesión)

00. **Correr `supabase-tramos.sql`** — *Rápido (SQL)* · Agrega la columna `tramo` (jsonb) para que funcione el botón **"Marcar tramo"**. Seguro: no rompe nada (los reportes normales ya andan sin ella; solo *guardar un tramo* la necesita). Supabase → SQL Editor → pegar el archivo → Run.

0. **Activar "Allow manual linking" en Supabase** — *Rápido* · Authentication → **Sign In / Providers** → sección **User Signups** → activar **Allow manual linking**. Sin esto, entrar con Google **no** conserva los reportes hechos como anónimo (el código lo intenta con `linkIdentity` y, si el toggle está apagado, cae a login normal sin romperse — pero los reportes quedan huérfanos). Con el toggle activo, "tus reportes te siguen" se cumple de verdad.

1. **Hacer admins a Cayla y Carlos** — *Rápido (SQL)* · Para que puedan moderar (borrar/editar cualquier reporte). La tabla `admins` está vacía. Pasos: que cada uno entre con Google una vez → `select id, email from auth.users;` → `insert into public.admins (user_id) values ('<uid>');`. Ver notas en `supabase-fase2-perfiles.sql`.

2. **Aviso "Google no ha verificado esta app"** — *Rápido* · Al entrar con Google saldrá esa advertencia (app en modo testing). Solución: en Google Auth Platform → **Público** → agregar a Cayla/Carlos como **usuarios de prueba**, o **publicar la app** (los usuarios verían el aviso pero pueden continuar). Para el piloto, agregar test users es lo más limpio.

3. **Probar en celular real** — crear reporte logueado, ver tu avatar en el pin, confirmar que editar/borrar sigue al usuario; **subir una foto vertical y ver que NO sale girada**; tocar **"Compartir"** en un pin y confirmar que abre la hoja de WhatsApp, y que el link recibido abre la app en ese punto.

---

## 🐛 BUGS / cosas frágiles

1. **[MEDIO] La API key de OpenRouteService está expuesta en el código público** — *Medio* ·
   Cualquiera puede copiarla y gastar tu cuota (2000/día) o usarla. Mitigar: restringir la key por dominio en el panel de ORS, o proxy vía función serverless (Vercel) con la key en secreto.

2. **[MEDIO] Sin escala: se cargan TODOS los reportes, un marcador por cada uno** — *Grande* ·
   `loadReports()` hace `select("*")` sin límite y crea un pin por reporte. Con cientos, el mapa se pone lento en celular; con miles, se traba. (Ahora además trae los perfiles con `.in("user_id", …)`; con muchos autores la URL crece — otra razón para paginar/acotar al área visible.) Urgirá cuando la comunidad aporte de verdad.

3. **[MEDIO] Moderación de contenido ajeno (spam/ofensas)** — *Grande* ·
   Con login, ya hay identidad y admins (una vez configurados), pero falta el botón **"marcar como inapropiado"** y que cualquiera pueda insertar sin límite sigue abierto. Cuando el link circule, conviene rate-limit + reporte de contenido (parte de la Fase 3). **Ahora es más urgente**: con "Compartir" los puntos se difunden por WhatsApp, así que llegará gente nueva antes.

4. **[BAJO] El modal (hoja de reporte) no atrapa el foco del teclado** — *Medio* ·
   Tabulando se puede salir a los controles del mapa detrás. Falta focus-trap (accesibilidad).

5. **[BAJO] El panel de RUTA no se cierra al tocar fuera** — *Rápido* ·
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

5. **Compartir una RUTA por link/WhatsApp** — *Medio* · Compartir un *punto* ya está hecho (botón "Compartir" en cada pin → `?r=<id>`). Falta compartir una ruta A→B armada (codificar origen+destino en la URL y rearmarla al abrir).

6. **"Cerca de mí": lista de puntos accesibles/bloqueados alrededor** — *Medio* · A veces solo quieres saber "¿qué hay difícil cerca?" antes de salir.

7. ~~**Reporte rápido: un toque para "bloqueado aquí"**~~ ✅ Hecho (2026-07-18).

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
- **[bug MEDIO] Fotos de celular ya no salen giradas** — `createImageBitmap` con `imageOrientation:"from-image"` hornea la orientación EXIF antes de comprimir; fallback a `<img>` en navegadores viejos.
- **[difusión] Compartir un punto por WhatsApp** — botón "Compartir" en cada pin; `navigator.share` (hoja del sistema) o `wa.me`/copiar link; el link `?r=<id>` abre la app volando a ese punto. Verificado en la página en vivo (parse de `?r=` y armado del link/texto); falta confirmar visualmente en celular que el popup abre solo.
- **[identidad] "Trujillo sin barreras"** — público ampliado a sillas de ruedas + coches de bebé + adultos mayores (mismo modelo de barreras). Tagline, pregunta de gravedad y ETA reescritas; meta description + Open Graph para preview al compartir. **Ciegos = producto aparte a futuro** (barreras distintas + el mapa visual es en sí una barrera). Decisión guardada en la memoria del proyecto.
- **[Carlos] Marcar tramo** — 1ª petición del usuario real: marcar una **calle/cuadra entera** accesible, no solo un punto. Botón "📏 Marcar tramo" → toca inicio y final → línea (recta v1) guardada como reporte con geometría, pintada del color de su gravedad (**verde/ámbar/rojo aquí SÍ es honesto**: lo afirma una persona). Columna nueva `tramo` jsonb (punto O tramo, misma tabla/RLS); payload manda `tramo` solo cuando lo es (no rompe reportes normales si falta la columna). Verificado: syntax, flujo DOM (botón→modo→hint→cancelar), `rebuildTramos` con datos de prueba, sin errores de consola, layout. **Falta correr el SQL** (pendiente #00) y el round-trip visual en celular (trazar→guardar→línea de color). Curva calle-a-calle = v2.
- **[adopción] Reporte rápido** — botón rojo "🔴 Bloqueado aquí" sobre el FAB: un toque → "toca dónde está bloqueado" → guarda directo un reporte (obstáculo, rojo) **sin abrir el formulario**; el detalle se agrega luego tocando el pin → Editar. Baja la fricción en la calle (clave para Carlos). Verificado en vivo el ingreso al modo + hint + cancelar + layout; el save-on-tap reusa el insert probado del Guardar (confirmar el round-trip en celular).
- **[adopción] Pantalla de bienvenida (primera vez)** — overlay ligero (localStorage `fw_welcomed`) que dice qué es FreeWheel para el público ampliado y la única acción ("Reportar aquí"); baja la fricción de primer contacto para quien recibe el link. Verificado en vivo de punta a punta (aparece, cierra con "Empecemos", persiste el flag) + captura visual OK.
- **[comunidad] "Actividad reciente" (motor de aliento, pieza A)** — tocar el contador de reportes abre los últimos aportes (quién/qué/cuándo); cada fila vuela al punto. Sin ubicación en vivo ni cambio de BD. Verificado: toggle del panel + estado vacío en vivo, orden y render con datos de prueba. Siguiente: B (confirmaciones) y C (presencia en vivo) sobre los mismos datos, en secuencia.
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
