# REVISIÓN FreeWheel — checklist para retomar

> Generado en la revisión del 2026-07-17 (noche). Todo verificado contra el código real de `index.html` y `supabase-schema.sql`.
> Esfuerzo aproximado: **Rápido** (<1h) · **Medio** (~medio día) · **Grande** (1+ día).
> El orden dentro de cada sección es por impacto (lo de arriba pesa más).

## ✅ Ya resuelto (2026-07-17, mismo día)
- Bug #7 — se habilitó el zoom de la página (accesibilidad).
- Bug #5 — el apodo ahora es un campo editable en la hoja (adiós al pop-up que dejaba "Anónimo").
- Mejora #1 — botón "Usar mi ubicación" para el origen de la ruta (GPS).
- Mejora #4 — la foto del popup se amplía al tocarla (abre en pestaña nueva).
- Mejora #5 — el popup muestra "hace X días".
- Mejora #8 — copy de ruta: "en silla de ruedas" en vez de "caminando".
- Mejora #10 — se puede elegir foto de la galería (antes forzaba la cámara).

**Pendiente lo demás de abajo.** Lo más importante que sigue abierto: los bugs #1 y #2 (botón Eliminar + moderación, necesitan tu decisión) y las ideas #1 (PWA) y #2 (Fase 2).

---

## 1) 🐛 BUGS / cosas frágiles o incorrectas

1. **El botón "Eliminar reporte" nunca funciona para nadie** — *Rápido de decidir, Medio de resolver bien*
   La RLS no tiene política de `delete`, así que borrar desde la app siempre falla (muestra "No se pudo eliminar todavía"). O sea: le mostramos a la gente un botón que no hace nada. Hay que decidir: (a) ocultar el botón hasta tener moderación real, o (b) permitir borrado con alguna regla (ej. solo quien lo creó, usando el apodo o un id de dispositivo). Hoy borrar solo se puede desde el SQL Editor.

2. **Cualquiera puede llenar el mapa de reportes falsos o contenido ofensivo (sin moderación)** — *Grande*
   El modelo "confianza abierta" permite insertar sin límite ni cuenta. En cuanto el link se comparta fuera del grupo de confianza, alguien puede meter cientos de puntos falsos, notas o fotos ofensivas — y no hay forma de borrarlos desde la app (ver #1). Riesgo real de vandalismo. Mínimo: rate-limit por dispositivo, o un botón de "reportar contenido", o pasar a moderación cuando crezca.

3. **La API key de OpenRouteService está expuesta en el código público** — *Medio*
   Cualquiera puede copiarla del sitio y gastar tu cuota diaria (2000 búsquedas/día) o usarla para lo suyo. A diferencia de la clave de Supabase (que está protegida por RLS y es pública por diseño), la de ORS solo tiene el límite de cuota. Mitigación: restringir la key por dominio en el panel de ORS, o pasar las llamadas por una función serverless (Vercel) que guarde la key en secreto.

4. **Las fotos de celular pueden salir giradas** — *Medio*
   Al comprimir la foto en un `<canvas>` se pierde la orientación EXIF; muchas fotos tomadas en vertical con el celular se guardan de lado. Hay que leer la orientación EXIF y rotar el canvas antes de subir. Es un bug clásico y muy visible en una app donde la foto es el valor.

5. **El apodo se pide con `window.prompt()` y en navegadores in-app queda "Anónimo" para siempre** — *Medio*
   Está protegido contra el crash (ya lo arreglamos), pero si el navegador bloquea `prompt()` (Instagram, WhatsApp, Facebook — justo por donde se comparte el link), el apodo se guarda como "Anónimo" en `localStorage` y **nunca se vuelve a preguntar**. Solución: reemplazar el prompt por un campo de apodo dentro de la hoja de reporte (funciona en todos lados y se puede editar).

6. **Sin escala: se cargan TODOS los reportes y se dibuja un marcador por cada uno** — *Grande*
   `loadReports()` hace `select("*")` sin límite y crea un pin en el DOM por reporte. Con unos cientos de reportes el mapa se pone lento en celular; con miles, se traba. Falta agrupar marcadores (clustering) o cargar solo los del área visible. No urge hoy (hay pocos reportes), pero es lo primero que va a doler cuando la comunidad aporte de verdad.

7. **Se desactivó el zoom de la página (`user-scalable=no`)** — *Rápido*
   El `<meta viewport>` bloquea el pinch-zoom. En una app de accesibilidad eso es contradictorio: una persona con baja visión no puede acercar el formulario ni los textos. Quitar `maximum-scale=1, user-scalable=no`.

8. **El modal (hoja de reporte) no atrapa el foco del teclado** — *Medio*
   Al abrir la hoja, tabulando se puede salir a los controles del mapa que están "detrás". Falta un focus-trap para que el teclado se quede dentro del diálogo mientras está abierto (accesibilidad).

---

## 2) 🔧 MEJORAS a lo que ya existe

1. **"Ruta desde mi ubicación"** — *Rápido/Medio*
   Ya existe el control de geolocalización en el mapa, pero no está conectado a la ruta. Un botón "usar mi ubicación" en el campo "Desde" ahorraría escribir y es lo más natural para alguien parado en la calle. Alto impacto, bajo costo.

2. **Apodo como campo editable en la hoja** (resuelve el bug #5 y mejora UX) — *Medio*
   Además de arreglar el bug, permite cambiar el apodo y se ve más profesional que un pop-up del navegador.

3. **Leyenda interactiva / filtros** — *Medio*
   Hoy la leyenda solo informa. Poder tocar "Bloqueado" para ver solo esos puntos (o esconder los "Accesible") ayuda a planear un recorrido. También filtrar por tipo de barrera.

4. **Foto ampliable en el popup** — *Rápido*
   Hoy la foto se ve chica en el globo. Tocarla para verla en grande (o abrirla) hace que la evidencia sirva de verdad.

5. **Mostrar "hace cuánto" en cada reporte** — *Rápido*
   El popup no muestra fecha. Un "hace 3 días" ayuda a saber si el dato sigue vigente (una rampa pudo arreglarse). El dato `creado_en` ya se guarda.

6. **Cola offline para reportes** — *Grande*
   En la calle con datos móviles intermitentes, si falla el guardado se pierde el reporte (aunque hoy la hoja no se cierra y se puede reintentar). Guardar en cola local y subir cuando vuelva la señal haría la app confiable en campo.

7. **Indicador de carga al abrir** — *Rápido*
   Mientras cargan mapa y reportes no hay señal visual. Un pequeño "Cargando reportes…" evita la sensación de app rota los primeros segundos.

8. **Copy de la ruta: "en silla de ruedas", no "caminando"** — *Rápido*
   El resultado dice "min caminando (perfil silla de ruedas)". Suena raro para el usuario real. Ajustar el texto.

9. **Mensaje claro cuando no hay ruta accesible** — *Rápido*
   En zonas de Trujillo con pocos datos de veredas en OpenStreetMap, la ruta falla. Vale un mensaje más útil ("no hay datos suficientes de veredas en esa zona todavía") en vez del genérico.

10. **El botón de foto obliga a usar la cámara (no deja elegir de la galería)** — *Rápido*
   El input tiene `capture="environment"`, que en varios celulares abre la cámara directo y no deja escoger una foto ya tomada. A veces sacaste la foto antes y quieres subirla de la galería. Quitar `capture` (o dar las dos opciones) lo hace más flexible.

---

## 3) 💡 IDEAS ÚTILES — funciones nuevas para Cayla y Carlos

1. **Convertir en PWA (instalable + funciona offline)** — *Medio* · **Por qué:** Carlos la tendría como ícono en su pantalla de inicio, abre al toque y sigue mostrando el último mapa aunque no haya señal. Es el mayor salto de "sitio web" a "app de verdad" para uso en la calle.

2. **Fase 2: la ruta avisa si pasa cerca de una barrera bloqueada** — *Grande* · **Por qué:** es el corazón de la idea — usar los reportes de la comunidad (con PostGIS, ya habilitado) para desviar o advertir. Solo tiene sentido cuando haya reportes reales; por eso quedó para después.

3. **"Confirmar / Yo también lo vi" en un reporte** — *Medio* · **Por qué:** validación entre la comunidad. Un punto con 5 confirmaciones es más confiable que uno suelto, y da frescura (si nadie lo confirma en meses, quizás ya se arregló).

4. **"Ya está arreglado" para marcar un punto como resuelto** — *Medio* · **Por qué:** las barreras cambian (arreglan una rampa). Poder marcar "resuelto" mantiene el mapa vivo y no lleno de datos viejos.

5. **"Cerca de mí": lista de puntos accesibles/bloqueados alrededor** — *Medio* · **Por qué:** a veces no quieres una ruta, solo saber "¿qué hay difícil cerca?" antes de salir.

6. **Compartir un reporte o una ruta por link/WhatsApp** — *Rápido/Medio* · **Por qué:** "mira, esta esquina está bloqueada" enviado por WhatsApp difunde la app sola y es súper natural en Perú.

7. **Modo voz reforzado para Carlos** — *Medio* · **Por qué:** ya hay dictado en la nota; llevarlo más lejos (botón de voz grande, elegir categoría por voz) respeta su movilidad limitada de manos, que es parte del origen del proyecto.

8. **Reporte más rápido: un solo toque para "bloqueado aquí"** — *Rápido* · **Por qué:** para registrar rápido en la calle sin llenar el formulario completo; el detalle se agrega después.

9. **Panel/estadística para mostrar a una municipalidad u ONG** — *Medio* · **Por qué:** "en el centro de Trujillo hay 40 puntos bloqueados para sillas de ruedas" es una herramienta de incidencia. Convierte los datos de la comunidad en argumento para exigir mejoras.

10. **Categorías propias del contexto peruano** — *Rápido* · **Por qué:** ambulantes que bloquean la vereda, mototaxis, huecos de desagüe sin tapa — barreras muy locales que las categorías genéricas no capturan.

---

### Nota de coherencia (no es bug, es decisión pendiente)
La búsqueda ahora funciona en todo Perú, pero la marca, el mapa inicial y los reportes son de Trujillo. Hoy no molesta (Cayla y Carlos saben para qué es), pero si se decide que sea multi-ciudad de verdad, hay que repensar la portada y mostrar reportes por ciudad. Decisión de producto, no técnica.
