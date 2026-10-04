# ADR-0003: Transparencia de ventana — intento real, simulación adoptada

**Status:** Accepted (revisado; actualizado 2026-10-03, ver "Actualización 2026-10-03")
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
4. [x] macOS: transparencia real conseguida **sin** parchear el C++ de lime (BE-7, 2026-10-03). Ver "Actualización 2026-10-03".
5. [x] Windows: transparencia real con DWM (alfa por píxel) + ventana *layered* (BE-10, 2026-10-03). **Probada en VM, sin probar en hardware real.** Ver "Actualización 2026-10-03 (BE-10)".
6. [ ] Que `VHSShader.frag` conserve el alfa de origen (hoy fuerza `1.0` y anularía la transparencia).


## Actualización 2026-10-03 (BE-7): la transparencia real SÍ funciona en macOS

**Resultado.** Probada a ojo por Zyra en macOS 27.2 (Apple Silicon), con Stage Manager activado: el escritorio real, sus ventanas y su Dock se ven a través del contenido del juego, sin parpadeo, tanto en ventana como en pantalla completa y al alternar entre ambos varias veces. **Windows: sin probar.**

**La causa que daba este ADR (el C++ de lime) era incorrecta.** No hizo falta tocar `lime.ndll`. Hacían falta cuatro cosas a la vez; el intento anterior solo hizo la segunda de forma incompleta:

1. **Limpiar OpenFL a alfa 0:** `FlxG.stage.color = null`. `OpenGLRenderer.__clear()` limpia a `(0,0,0,0)` solo con ese valor. El intento original solo tocó `camera.bgColor`, que no afecta ese limpiado.
2. **Cámara sin fondo:** `FlxG.camera.bgColor = 0x00000000` (Flixel omite el `fill` si el alfa es 0).
3. **Ventana de macOS no opaca y superficie GL translúcida:** `NSWindow` con `opaque = NO`, fondo `clearColor`, sin sombra, y `NSOpenGLContextParameterSurfaceOpacity = 0`.
4. **Capas de AppKit sin fondo opaco:** AppKit da un `backgroundColor` opaco al marco de la ventana y al `_NSOpenGLViewBackingLayer`; ese fondo se ve negro justo donde OpenGL dibujó alfa 0. Y **AppKit rehace esas capas** al cambiar el estilo, el tamaño o el modo de la ventana, así que el parche las limpia y las **vuelve a limpiar sola** (notificaciones de ventana + comprobación a 120 Hz) para que no haya parpadeo.

**Cómo se averiguó (para no repetirlo).** Una sonda con `glReadPixels` leyó el fondo como `0x00000000` y el recuadro como opaco: OpenGL dibujaba bien, así que el problema era la composición. Un programa de referencia independiente (Objective-C, sin el motor) mostró que esta macOS sí compone transparencia con `NSOpenGLContext`, también si se activa en caliente y con ventana con título, y que **una capa con fondo negro opaco la anula** (alfa 255). Ahí estaba la diferencia con el juego.

**Pantalla completa.** La pantalla completa nativa de macOS crea un **Space propio, siempre opaco y sin escritorio detrás**: ahí la transparencia no puede funcionar. Se resuelve así:
- `disableNativeFullscreen()` marca las ventanas con `NSWindowCollectionBehaviorFullScreenNone` al crearlas (el botón verde pasa a hacer zoom).
- `SDL_VIDEO_MAC_FULLSCREEN_SPACES=0`, fijada antes de que SDL arranque, hace que `FlxG.fullscreen`, Alt+Enter y Ctrl+Cmd+F usen el modo de escritorio de SDL: una ventana sin bordes del tamaño de la pantalla, sin Space.
- Bug de lime corregido en `NativeApplication.hx`: en macOS ese modo hace que SDL envíe `WINDOW_MAXIMIZE` y `WINDOW_RESTORE`, y lime respondía `__fullscreen = false`, dejando `FlxG.fullscreen` desincronizado de la ventana real (F no podía salir).

**El parche.** Commit `3c36a57d` en la rama `echoes/patches` del submódulo `engine/` (sobre `74c80698`). Archivos: `source/external/src/mac/Mac.mm`, `include/mac/Mac.h`, `ExternalMac.hx`, `external_code.xml` (enlaza `OpenGL` y `QuartzCore`), `funkin/backend/utils/native/Mac.hx`, `NativeAPI.hx` (`setWindowTransparent`, `disableNativeFullscreen`; no-op fuera de macOS) y los reemplazos de motor `lime/_internal/backend/native/NativeWindow.hx` y `NativeApplication.hx`. Uso desde el mod, ver `mods/fnf-echoes/data/states/TransparencyTestState.hx`.

**Compilar.** `cne build` equivale a `haxelib run lime build macos -DTEST_BUILD` desde `engine/` con `HAXE_STD_PATH=/opt/homebrew/lib/haxe/std`; incremental, ~1 min. El `.app` queda en modo `cne test` (busca los mods en `engine/mods/`, ver `docs/agents/04_TRAMPAS_CONOCIDAS.md` nº 15).

**Límites y pendientes.**
- Windows: hecho en BE-10, solo probado en VM (ver la actualización de abajo). Falta probarlo en un PC con Windows real.
- El shader VHS termina en `gl_FragColor = vec4(col, 1.0)`: fuerza alfa 1 en toda la pantalla y anula la transparencia mientras esté activo.
- Usa `NSOpenGLContext`, API en desuso desde macOS 10.14 (sigue funcionando en 27.2). Si Apple la retirara, habría que pasar a una capa Metal.
- Dock y barra de menús siguen visibles en pantalla completa (no se ocultan). Con la transparencia activa se ven por encima del juego.
- **El commit del submódulo no está en ningún remoto** (ni el `74c80698` anterior): un clon nuevo no puede bajar `engine/`. Se resuelve con un fork propio del motor (decisión de Zyra, 2026-10-03).


## Actualización 2026-10-03 (BE-10): la transparencia real también funciona en Windows

**Resultado.** Probada a ojo por Zyra en una máquina virtual: Windows 11 Pro ARM64 (build 26200) en VMware Fusion Pro 26H1 sobre un Mac M4, con aceleración 3D (VMware SVGA 3D 9.17.11.4), ejecutando el motor compilado para x64 (emulado). El escritorio de Windows se ve a través del juego, tanto en ventana como en pantalla completa, alternando ambas varias veces. **No probado en hardware real** (Intel/AMD con una GPU de verdad).

**La receta.** Del lado del juego es igual que en macOS: `FlxG.stage.color = null` y `camera.bgColor` con alfa 0. Del lado de Windows, sobre el HWND de SDL (clase `SDL_app`), **en este orden**:
1. `DwmEnableBlurBehindWindow` con `DWM_BB_ENABLE | DWM_BB_BLURREGION` y una región **vacía** (`CreateRectRgn(0, 0, -1, -1)`): DWM compone el alfa sin desenfocar nada.
2. `WS_EX_LAYERED` y `SetLayeredWindowAttributes(hwnd, 0, 255, LWA_ALPHA)`.

Es la misma secuencia que usa GLFW. **Solo el paso 1 no basta**: la ventana seguía opaca. El color clave (`LWA_COLORKEY` con magenta `0xFF00FF`) también funciona como plan B, con halos magenta en los bordes del texto.

**Cómo se averiguó (para no repetirlo).** Antes de escribir C++ se probó desde fuera con un script de PowerShell sobre el juego en marcha, que confirmó que se tocaba la ventana correcta (`SDL_app`) y que el estado cambiaba (`layered=False` antes, `True` después). La primera hipótesis (que la VM traducía OpenGL a Direct3D y por eso las técnicas fallaban) era **errónea**: ese paquete de traducción de Microsoft ni siquiera estaba instalado. Lo que faltaba era el segundo paso.

**Implementación.** `Windows.setWindowTransparent(title, enable)` en `engine/source/funkin/backend/utils/native/Windows.hx`, expuesta por `NativeAPI.setWindowTransparent` con la misma API que en macOS. Commit `d315654f` en la rama `echoes/patches` del fork.

**Compilar y probar sin un Windows físico.** El fork `Salchorixo/CodenameEngine` trae el flujo `windows.yml`, que se dispara con cada `push` (en un fork está desactivado hasta que el dueño acepta el aviso en la web de GitHub). El artefacto `Codename Engine` (240 MB) es la carpeta completa del juego para x64. En el Mac se probó dentro de una VM de VMware Fusion Pro (gratis para uso personal); UTM no sirve porque no acelera 3D en invitados Windows.

**Límites y pendientes.**
- Hardware real sin probar.
- En Windows la transparencia **no se reaplica sola** tras cambios de estilo de la ventana (en macOS sí). En las pruebas de la VM la pantalla completa no la rompió, pero habría que repetirlo en un PC real.
- El shader VHS (BE-8) fuerza alfa 1 y la anularía.
