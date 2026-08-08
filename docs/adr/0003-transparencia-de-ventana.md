# ADR-0003: Transparencia de ventana — intento real, simulación adoptada

**Status:** Accepted (revisado)
**Date:** 2026-08-08
**Deciders:** Salchorizo

## Contexto

El criterio 2 del ADR-0001 fija como no-negociable: "soporte de transparencia de ventana... sin romperse en ninguno de los dos sistemas operativos". Fue parte de por qué se descartó Psych Engine.

Al construir la Fase 1 del mod (`TitleState` — el ojo que se parte y la ventana se glitchea a transparente), se investigó cómo Codename Engine expone esa transparencia en tiempo de ejecución, revisando el `lime` real que usa el proyecto (versión 8.1.2, pineada por `engine/building/libs.xml`):

- `engine/project.xml` no declara `<window transparent="true" />` — la ventana se compila opaca.
- `engine/.haxelib/lime/8,1,2/src/lime/ui/Window.hx` no expone ninguna propiedad de transparencia utilizable en macOS/Windows/Linux (los únicos resultados de "transparent" en todo el paquete de lime son para targets de Flash/AIR y manifests de apps móviles — nada aplicable a un build de escritorio nativo).

Es decir: la transparencia real de ventana, aunque fue criterio de decisión del motor, **nunca se activó ni se probó** — quedó como supuesto teórico, no como capacidad validada. `AGENTS.md` prohíbe editar el código fuente del motor salvo necesidad justificada y documentada acá.

## Decisión

Se añadió `transparent="true"` al `<window>` de `engine/project.xml` y se recompiló el motor para validar empíricamente si eso alcanza. **No alcanzó.** Ver "Resultado del intento" abajo. Dado ese resultado, se adopta la Opción B (simular el efecto) para no bloquear la Fase 1, dejando la Opción A como investigación futura documentada, no descartada.

## Opciones consideradas

### Opción A: Habilitar transparencia real (intentada, insuficiente por ahora)
Editar `project.xml`, recompilar, probar. Fiel al criterio original del ADR-0001 y a lo diseñado en el mockup visual.

**Resultado del intento:** con `transparent="true"` recompilado, se probó en runtime forzando `FlxG.camera.bgColor` a alpha 0 (`0x00000000`) junto con `useBgAlphaBlending = true`. El toggle en sí se ejecuta correctamente (se confirmó ocultando un texto de prueba en el mismo cambio), pero la ventana se mantiene con fondo negro sólido — el escritorio real nunca se ve a través. Rastreando la causa: `engine/.haxelib/lime/8,1,2/src/lime/_internal/backend/native/NativeWindow.hx:69` fija `contextAttributes.background` a partir del `background` declarado en `project.xml` (actualmente `#000000`), y ese valor alimenta el clear del framebuffer en el backend **nativo compilado (C++)** de lime, no en la capa Haxe/Flixel. Es decir: el flag `transparent="true"` prepara la ventana del SO para poder componer con transparencia, pero el propio lime sigue limpiando cada frame a negro opaco a nivel nativo — hace falta un segundo parche, esta vez en el backend C++ de lime, del mismo calibre que la reconstrucción de `lime.ndll` para arm64 documentada en el ADR-0001. No se intentó en esta sesión por alcance/tiempo.

### Opción B: Simular el efecto sin transparencia real (ELEGIDA, por ahora)
Cortar a negro sólido / estática en vez de mostrar el escritorio real. Cero riesgo, cero recompilación adicional — permite seguir con el resto de la Fase 1 sin bloquear en un problema de backend nativo sin resolver todavía.

### Opción C: Diferir la decisión
Construir el resto de la Fase 1 sin el toggle de transparencia, retomarlo como investigación aparte. Se descarta por ahora porque Opción B da un resultado visual utilizable de inmediato con el mismo costo de "no tener transparencia real todavía".

## Análisis de trade-offs

"Transparencia de ventana funcionando en ambos sistemas" fue *el* criterio que inclinó la balanza hacia Codename Engine en el ADR-0001. Ese criterio sigue sin resolverse — pero ahora está **empíricamente entendido** (dónde exactamente falla, y qué se necesitaría para resolverlo) en vez de ser un supuesto sin probar. Simular el efecto ahora no cierra la puerta a la Opción A: cuando se retome, es un parche nativo aislado, no un rediseño de la Fase 1 (el punto donde se activa/desactiva el efecto queda igual, solo cambia qué hace internamente).

## Cómo se aplica el cambio sin romper la convención de submódulo

`engine/` sigue pineado a un commit específico de `CodenameCrew/CodenameEngine` (ver ADR-0001). Este parche se commitea **dentro del propio repositorio del submódulo** (un commit local, no destinado a subirse a CodenameCrew), y el puntero del submódulo en este repo se actualiza a ese nuevo commit. Así el cambio queda versionado y documentado, en vez de vivir como un working tree modificado sin registrar.

## Consecuencias

- Se gana: el criterio 2 del ADR-0001 queda investigado empíricamente — sabemos exactamente por qué no funciona todavía, no es un supuesto sin probar.
- Se pierde: el submódulo ya no apunta a un commit "limpio" de upstream — apunta a un commit propio (`transparent="true"`), un parche encima de `fb54e50b...` que por ahora no tiene efecto visual por sí solo (queda como base para cuando se aborde el parche nativo).
- La Fase 1 usa el efecto simulado (corte a negro/estática, sin transparencia real de SO) hasta que se resuelva la Opción A.
- A revisar más adelante: (1) el parche nativo de lime para transparencia real, (2) validar el mismo comportamiento en Windows (pendiente general del ADR-0001, action item 1).

## Action Items

1. [x] Añadir `transparent="true"` al `<window>` de `engine/project.xml`, commitear dentro del submódulo.
2. [x] Recompilar el motor y probar en runtime — **transparencia real no funciona aún** (ver "Resultado del intento").
3. [x] Actualizar el puntero del submódulo en este repo al nuevo commit.
4. [ ] (Futuro, fuera de alcance de la Fase 1) Investigar el parche nativo de lime (`NativeWindow.hx` / backend C++) para que `transparent="true"` realmente deje pasar el escritorio.
