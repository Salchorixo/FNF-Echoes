# ADR-0003: Habilitar transparencia real de ventana en `engine/project.xml`

**Status:** Accepted
**Date:** 2026-08-08
**Deciders:** Salchorizo

## Contexto

El criterio 2 del ADR-0001 fija como no-negociable: "soporte de transparencia de ventana... sin romperse en ninguno de los dos sistemas operativos". Fue parte de por qué se descartó Psych Engine.

Al construir la Fase 1 del mod (`TitleState` — el ojo que se parte y la ventana se glitchea a transparente), se investigó cómo Codename Engine expone esa transparencia en tiempo de ejecución, revisando el `lime` real que usa el proyecto (versión 8.1.2, pineada por `engine/building/libs.xml`):

- `engine/project.xml` no declara `<window transparent="true" />` — la ventana se compila opaca.
- `engine/.haxelib/lime/8,1,2/src/lime/ui/Window.hx` no expone ninguna propiedad de transparencia utilizable en macOS/Windows/Linux (los únicos resultados de "transparent" en todo el paquete de lime son para targets de Flash/AIR y manifests de apps móviles — nada aplicable a un build de escritorio nativo).

Es decir: la transparencia real de ventana, aunque fue criterio de decisión del motor, **nunca se activó ni se probó** — quedó como supuesto teórico, no como capacidad validada. `AGENTS.md` prohíbe editar el código fuente del motor salvo necesidad justificada y documentada acá.

## Decisión

Se añade `transparent="true"` al `<window>` de `engine/project.xml`, y se recompila el motor para validar que realmente funciona en macOS antes de construir el resto de la Fase 1 sobre ese supuesto.

## Opciones consideradas

### Opción A: Habilitar transparencia real (ELEGIDA)
Editar `project.xml`, recompilar, probar. Fiel al criterio original del ADR-0001 y a lo diseñado en el mockup visual. Riesgo: puede toparse con el mismo tipo de fricción de plataforma que el `.ndll` de arm64 (ADR-0001, sección de actualización); exige otro ciclo de compilación de ~15-20 min.

### Opción B: Simular el efecto sin transparencia real
Cortar a negro sólido / estática en vez de mostrar el escritorio real. Cero riesgo, cero recompilación — pero abandona un criterio que fue decisivo para elegir este motor sobre Psych Engine, sin siquiera haberlo intentado.

### Opción C: Diferir la decisión
Construir el resto de la Fase 1 sin el toggle de transparencia, retomarlo como investigación aparte. Pospone el riesgo en vez de resolverlo.

## Análisis de trade-offs

Dado que "transparencia de ventana funcionando en ambos sistemas" fue *el* criterio que inclinó la balanza hacia Codename Engine en el ADR-0001, dejarlo sin probar — y descubrir recién en un lanzamiento real que no funciona — sería peor que gastar un ciclo de compilación ahora, con el motor ya validado y el flujo de "editar → recompilar → probar" ya rodado en esta sesión.

## Cómo se aplica el cambio sin romper la convención de submódulo

`engine/` sigue pineado a un commit específico de `CodenameCrew/CodenameEngine` (ver ADR-0001). Este parche se commitea **dentro del propio repositorio del submódulo** (un commit local, no destinado a subirse a CodenameCrew), y el puntero del submódulo en este repo se actualiza a ese nuevo commit. Así el cambio queda versionado y documentado, en vez de vivir como un working tree modificado sin registrar.

## Consecuencias

- Se gana: el criterio 2 del ADR-0001 queda validado empíricamente, no solo asumido.
- Se pierde: el submódulo ya no apunta a un commit "limpio" de upstream — apunta a un commit propio, un parche encima de `fb54e50b...`. Si CodenameCrew mergea soporte de transparencia más adelante, revisar si conviene rebasear y descartar este parche.
- A revisar más adelante: validar el mismo comportamiento en Windows (pendiente general del ADR-0001, action item 1).

## Action Items

1. [ ] Añadir `transparent="true"` al `<window>` de `engine/project.xml`, commitear dentro del submódulo.
2. [ ] Recompilar el motor y confirmar visualmente que la transparencia real funciona en macOS.
3. [ ] Actualizar el puntero del submódulo en este repo al nuevo commit.
