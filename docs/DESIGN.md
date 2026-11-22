# Design System: Cora v2.0 — Salud Femenina Integral

> **Fuente de verdad visual y semántica** optimizada para **Google Stitch** (`stitch.withgoogle.com` / `labs.google/stitch`) y la implementación Flutter Material 3 (`mobile/lib/core/theme/cora_theme.dart`).

---

## 1. Visual Theme & Atmosphere

Una interfaz **editorial, serena, táctil y profundamente humana** diseñada específicamente para el cuidado longitudinal de la salud femenina a lo largo de sus 7 etapas biológicas. La atmósfera combina el rigor de una guía clínica contemporánea con la calidez orgánica de un diario botánico moderno (*Warm Botanical Health Editorial*):

- **Density:** `4 / 10` (*Daily App Balanced — Airy*) — respiro visual generoso en la pantalla principal; cada bloque tiene un propósito claro sin saturación cognitiva.
- **Variance:** `6 / 10` (*Refined Asymmetric Rhythm*) — tarjeta protagonista (Hero de ciclo/etapa) con presencia clara seguida de una tira semanal horizontal interactiva y bloques informativos estructurados sin grillas repetitivas de 8 botones iguales.
- **Motion:** `5 / 10` (*Fluid Organic Springs*) — micro-interacciones suaves con curvas amortiguadas (`Curves.easeOutCubic` / resortes físicos) al cambiar días en el calendario, abrir el menú lateral y transicionar entre etapas de vida.
- **Accessibility First:** Contraste `>= 4.5:1` (`WCAG AA`) en modo estándar y un tema dedicado `highLegibility()` (`WCAG AAA >= 7:1`, objetivos táctiles `>= 56dp`) para la etapa **Plenitud y Vitalidad Sénior**.

---

## 2. Color Palette & Roles

### Superficies y Neutros Cálidos (sin `#000000` puro en modo estándar)
- **Warm Ivory Canvas** (`#FBF8F6`) — Fondo principal del `Scaffold`, cálido y descansado para lectura prolongada.
- **Pure Petal Surface** (`#FFFFFF`) — Superficie de tarjetas principales, paneles de detalle diario y hojas modales.
- **Soft Sand Tint** (`#F4ECE8`) — Superficie secundaria para contenedores sutiles, chips inactivos y fondo de cabecera del menú lateral (`Drawer`).
- **Deep Espresso Ink** (`#241A1E`) — Texto principal, encabezados y cifras clave del día del ciclo (contraste `> 14:1` sobre `#FBF8F6`).
- **Muted Mauve Slate** (`#67585F`) — Texto secundario, subtítulos, etiquetas de días de la semana y metadatos clínicos (contraste `> 6.2:1` sobre `#FFFFFF`).
- **Whisper Rose Border** (`#E9DCD6`) — Bordes estructurales finos de `1px` para definir jerarquía sin sombras pesadas.

### Acento Principal Único (Saturación controlada < 80%)
- **Clinical Terracotta Rose** (`#B33A63`) — Acento principal para el CTA primario ("Registrar hoy"), estados activos, foco de inputs y navegación seleccionada en el `Drawer`.
- **Blush Mist** (`#FCEBF1`) — Fondo suave de realce para pills activos, ícono de acento y estados seleccionados.

### Tokens Semánticos Clínicos (Fases del Ciclo y Alertas — siempre acompañados de forma/icono + etiqueta)
- **Menstrual Crimson** (`#C83757`, superficie `#FDECEF`) — Días de periodo registrado (relleno sólido) y predicción de próximo periodo (contorno discontinuo).
- **Follicular Amber** (`#B86428`, superficie `#FDF3EA`) — Fase folicular y ascenso estrogénico.
- **Fertile Sage** (`#1E7A65`, superficie `#E8F6F2`) — Ventana fértil (halo suave) y día estimado de ovulación (anillo doble + punto central).
- **Luteal Plum** (`#644E87`, superficie `#F2EEF9`) — Fase lútea y preparación premenstrual.
- **Hormonal Slate** (`#3F627A`, superficie `#EDF4F8`) — Ciclo bajo gestión hormonal / anticoncepción.
- **Preventive Amber Alert** (`#B45309`, superficie `#FEF3C7`) — Alertas preventivas FIGO / ACOG / STRAW+10 (tono empático, nunca alarmista).
- **Urgent Clinical Crimson** (`#B91C1C`, superficie `#FEE2E2`) — Exclusivo para banderas rojas obstétricas, preeclampsia severa o crisis EPDS ítem 10.

### Modo Alta Legibilidad (`CoraTheme.highLegibility()` — WCAG AAA `>= 7:1`)
- **Pure White Canvas** (`#FFFFFF`)
- **Deep Obsidian Text** (`#121212`)
- **High-Contrast Burgundy Primary** (`#5C0A28`)
- **High-Contrast Forest Secondary** (`#004D40`)
- **Crisp Focus Border** (`#1F1F1F`, `2px`)

---

## 3. Typography Rules

- **Display & Headings:** `Outfit` (geométrica cálida, tracking `-0.02em`, pesos `600`–`700`). Jerarquía guiada por peso, contraste y espaciado, nunca por tamaños estridentes.
- **Body & Clinical Guidance:** `Plus Jakarta Sans` (lectura fluida en español, interlineado `1.45`–`1.55`, mínimo `14px`/`1rem` en cuerpo y `16px`–`18px` en `highLegibility`).
- **Biomedical Numerals & Dates:** `Tabular Figures` (`FontFeature.tabularFigures()`) para días del ciclo, cuentas regresivas ("En 5 días"), temperaturas BBT (`36.7 °C`), presión arterial (`118/76 mmHg`) y cuadrícula de calendario para alineación impecable.
- **Offline-First Rule:** Los estilos tipográficos funcionan completamente sin conexión a internet (fuentes empaquetadas localmente o fallback limpio de sistema sin dependencias obligatorias de red).
- **Banned:** `Inter`, `Times New Roman`, `Georgia`, serifs genéricas en paneles de datos, texto con gradientes neón.

---

## 4. Component Stylings

- **Navigation Drawer (`CoraNavigationDrawer`):** Superficie `#FFFFFF` con cabecera en `#F4ECE8` mostrando nombre, etapa de vida activa y botón rápido de cambio de etapa. Secciones claramente separadas por divisores sutiles (`#E9DCD6`): *Mi Salud Diaria*, *Expediente e Inteligencia Clínica*, *Personalización y Privacidad*. Ítem activo en cápsula `#FCEBF1` con texto/icono `#B33A63`.
- **Hero Cycle Card (`HomeCycleHeroCard`):** Esquinas redondeadas generosas (`24px`), borde sutil `1px` (`#E9DCD6`), sombra cálida difusa mínima (`rgba(36, 26, 30, 0.05)`). Muestra anillo de progreso limpio a la izquierda/centro con **Día del ciclo**, **Fase actual**, **cuenta regresiva de próximo periodo**, **fecha estimada de ovulación** y un único CTA primario táctil (**"Registrar hoy"**).
- **Interactive Week Strip (`HomeWeekCalendarStrip`):** 7 celdas limpias con inicial del día, número en tabular figures y marcador visual dual (color + borde/punto). Tocar cualquier día o el enlace *"Ver calendario →"* navega al Calendario Menstrual completo.
- **Menstrual Month Grid (`MenstrualMonthGrid`):** Cuadrícula de 7 columnas con área táctil mínima `44–48dp` por celda. Nunca depende solo del color:
  - Periodo registrado → círculo sólido `#C83757` con número blanco.
  - Próximo periodo predicho → círculo de borde discontinuo `#C83757` con fondo `#FDECEF`.
  - Ventana fértil → fondo `#E8F6F2` con texto `#1E7A65`.
  - Día estimado de ovulación → doble anillo `#1E7A65` + punto central.
  - Síntoma registrado → micro-indicador inferior de `4px`.
- **Buttons:** Planos sin resplandor neón, esquinas de `14px`, altura mínima `48dp` (`56dp` en `highLegibility`), respuesta táctil inmediata.
- **Inputs & Pickers:** Etiqueta visible arriba o clara en `OutlineInputBorder` de `14px`, foco en `#B33A63`, errores empáticos debajo en `#B91C1C`.
- **Empty & Educational States:** Tarjetas compuestas con ícono clínico lineal, explicación cálida y una acción concreta (nunca pantallas vacías genéricas).

---

## 5. Layout Principles

- **Mobile-First Single Column:** En pantallas móviles (`< 600dp`), flujo vertical en una sola columna con márgenes laterales de `20px` y separación vertical consistente (`16px` entre tarjetas relacionadas, `24px` entre secciones).
- **Zero Home Saturation:** Prohibido apilar grillas de 8 módulos/accesos directos en el Home principal. El Home contiene únicamente:
  1. Cabecera minimalista (`Menu Drawer` + Saludo + Chip de etapa).
  2. `HomeCycleHeroCard` (ciclo/etapa actual + próximo periodo + ovulación + CTA primario).
  3. `HomeWeekCalendarStrip` (resumen semanal interactivo → Calendario completo).
  4. `HomePhaseEducationCard` ("Acerca de tu periodo y fase actual" + alertas preventivas si existen).
- **Responsive Text Scaling:** Todo layout debe resistir `TextScaler.linear(2.0)` sin `RenderFlex overflow` usando `Wrap`, `Flexible`, `Expanded` y layouts verticales de respaldo.

---

## 6. Motion & Interaction

- **Transiciones orgánicas:** `Duration(milliseconds: 280)` con `Curves.easeOutCubic` al seleccionar otro día en el calendario mensual o expandir el detalle diario.
- **Anillo de ciclo animado:** Transición suave de arco en `CustomPainter` (`TweenAnimationBuilder`) al cargar o actualizar registros del día.
- **Micro-interacciones táctiles:** Retroalimentación inmediata (`InkWell` / `AnimatedScale` sutil `0.97` en pulsación) en celdas del calendario y botón principal.
- **Rendimiento:** Animar únicamente `transform` y `opacity` / `CustomPainter` ligero; respetar `MediaQuery.disableAnimationsOf(context)` para usuarias con reducción de movimiento.

---

## 7. Anti-Patterns (Strictly Banned)

- Cero emojis en UI, botones, encabezados o alertas clínicas.
- Cero estética "AI Purple/Blue Neon", sombras fluorescentes o fondos oscuros espaciales.
- Cero `#000000` puro en modo estándar.
- Cero fuente `Inter` o serifs genéricas (`Times New Roman`, `Georgia`).
- Cero grillas saturadas de 8–10 botones en la pantalla de inicio (usar `CoraNavigationDrawer`).
- Cero textos de relleno ("Desliza para explorar", flechas rebotando) o clichés de marketing ("Elevate", "Next-Gen", "Seamless").
- Cero predicciones menstruales/ovulatorias mostradas a usuarias en etapas `pregnancy` o `senior_vitality` (siempre adaptar al contexto biológico).

---

## 8. Google Stitch Visual Exploration Notes

Resultado verificado en sesión de diseño sobre **Google Stitch** (`https://stitch.google.com/projects/6856994269909508525`, modo Mobile, estilo *Warm Botanical Health Editorial*):

1. **Cabecera y Navegación:**
   - Top bar minimalista con ícono hamburguesa (`☰`) a la izquierda para desplegar el menú lateral (`CoraNavigationDrawer`), isotipo de gota terracota + wordmark editorial `Cora`, y avatar circular de perfil en rosa terracota a la derecha.
   - Siguiendo el requerimiento de producto de Cora v2.0, todas las herramientas secundarias se centralizan en el menú desplegable lateral (`CoraNavigationDrawer`), dejando el Home limpio y enfocado en el día actual.
2. **Pantalla `Cora - Inicio` (Home Limpio):**
   - Encabezado con fecha en *eyebrow*, pill de contexto (`Ciclo natural • N días`), saludo principal (`Hola, <Nombre>`) y subtítulo breve.
   - **Tarjeta Hero de Ciclo:** Anillo de progreso circular con arco sólido terracota-ciruela para los días transcurridos y pista punteada suave para los días restantes; al centro: pill de fase (`Fase Folicular`), cifra protagonista (`Día 12`) y subtítulo (`de 28 días`).
   - **Dos tarjetas compactas de predicción inmediata:**
     - Caja en salvia suave (`#E8F6F2`): *Ventana fértil / Ovulación calculada en X días* + badge de probabilidad (`Alta prob.`).
     - Caja blanca con borde cálido (`#E9DCD6`): *Próximo periodo menstrual / Esperado en aprox. X días* + fecha destacada a la derecha.
   - **Botón CTA primario full-width** en `#B33A63` (*Registrar biomarcadores de hoy*).
   - **Tira Semanal Interactiva (`Semana N del ciclo` + enlace `Calendario →`)**: 7 días con pill destacado en el día actual.
   - **Tarjetas Educativas:** Tarjeta editorial sobre la fase actual con tiempo de lectura y enlace a la Biblioteca Clínica + tarjeta de *Recomendación biológica* con badge salvia.
3. **Pantalla `Cora - Calendario` (Calendario Menstrual Interactivo):**
   - Selector de mes con flechas circulares `< >` y 2 pills de contexto debajo (*Ciclo de N días* y *Día N del ciclo actual*).
   - **Cuadrícula mensual en tarjeta blanca (`L M X J V S D`):**
     - Periodo registrado → círculo sólido `#C83757` con cifra blanca.
     - Próximo periodo predicho → círculo de borde discontinuo `#C83757`.
     - Ventana fértil → halo salvia `#E8F6F2` + doble anillo en día estimado de ovulación `#1E7A65`.
     - Día actual/seleccionado → borde circular nítido; micro-puntos inferiores para días con síntomas.
     - Leyenda 2x2 directamente debajo de la cuadrícula (`Periodo registrado`, `Predicción`, `Ventana fértil`, `Ovulación`).
   - **Panel `DETALLE DEL REGISTRO`:** Eyebrow + pill de fase, fecha completa en español, caja interna salvia con estado fértil/ovulación, bloque `SÍNTOMAS Y BIOMARCADORES` en chips arena suave (`#F4ECE8`), nota clínica y botón full-width `#B33A63` (*Registrar o modificar este día*).
   - **Métricas rápidas al pie:** 2 tarjetas compactas lado a lado (ej. *Temp. Basal* y *Descanso*).
