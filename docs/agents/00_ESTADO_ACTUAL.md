# 00 — Estado actual del proyecto

> **Este archivo es el "dónde vamos".** Cada agente lo lee al empezar y lo
> **actualiza al terminar** (sección "Última sesión" y lo que haya cambiado).
> Si algo de aquí no coincide con el repo, **manda el repo**: corrige este
> archivo y dilo en el relevo.

**Última actualización:** 2026-10-13 (menús con arte propio; selector de canciones por ambientación, BE-11).

---

## 1. Resumen en una línea

Las 3 canciones ya tienen audio generado; el motor compila en macOS (Apple
Silicon) y arranca en Windows con parches propios; los menús del mod existen en
HScript; la transparencia de ventana funciona en macOS y Windows y el juego ya
sabe mover su propia ventana. **La parte técnica de la ventana está lista:** ahora
toca producción: arte, animaciones, cutscenes, charts, mecánicas y la secuencia final.

## 2. Hecho (no lo rehagas)

| Área | Estado | Dónde |
|---|---|---|
| Motor en macOS arm64 | Compila y corre con 3 parches a `lime` 8.2.0 | ADR-0001, "Receta completa" |
| Motor en Windows | Arranca y corre el mod en una VM Windows 11 ARM64 (motor oficial v1.0.1 y el compilado del fork); **sin probar en hardware real** | ADR-0001 action item 1; ADR-0003 (BE-10) |
| Menús del mod | Existen: Title, MainMenu (rediseñado el 2026-10-11 según el boceto de Zyra: fondo blanco, botones amarillos PLAY/SETTINGS/CREDITS a la izquierda, Zyra con auriculares en su sofá, carpeta arriba a la derecha y vinilo abajo a la derecha; Zyra y el sofá son la **animación dibujada real** (atlas, Receta J; música: OST de Soul `music/menuOst.ogg` al abrir y, en el frame de aterrizaje, el inst `music/menuInst.ogg` desde su drop en el segundo 26); botones, carpeta y vinilo están en el **lenguaje Vista con trazo a lápiz** (pixel art ×3 con el lápiz encima; el vinilo tiene 24 frames; BE-13) y las notas son partículas variadas (azules de los auriculares de Zyra, rojas del vinilo), todo en `images/menus/main/ui/` (`vista_*.png` por `AI_export_main_menu_vista.py`, `notes.png` por `AI_build_menu_ui.py`; arte privado). Los sprites XP (`xp_*.png`) se conservan para el futuro tema XP; sin VHS), EchoSelect (rehecha el 2026-10-13: 3 ventanas de cristal Vista en pixel art con trazo a lápiz, BE-14; el arte XP anterior se conserva), StoryMap, Options, Loading. Además dos estados de prueba sin acceso desde la UI: `TransparencyTestState` y `WindowChoreographyTestState` | `mods/fnf-echoes/data/states/` |
| Scripts compartidos | `cardMenu`, `nodeArtPanel`, `translate`, `vhsShader`, `windowFx` | `mods/fnf-echoes/scripts/` |
| Shader VHS | Existe, se adjunta por estado | `shaders/VHSShader.frag` + `scripts/effects/vhsShader.hx` |
| Transparencia de ventana en macOS | **Funciona** (probada a ojo, 2026-10-03): escritorio real visible a través del juego, en ventana y en pantalla completa sin Space | ADR-0003 "Actualización 2026-10-03"; ejemplo en `TransparencyTestState.hx` |
| Transparencia de ventana en Windows | **Funciona en VM** (2026-10-03), en ventana y en pantalla completa; **sin probar en hardware real** | ADR-0003 "Actualización 2026-10-03 (BE-10)"; `NativeAPI.setWindowTransparent` |
| Zyra lanza la ventana (golpe → vuelo explosivo → choque con el borde → vuelve al centro) | **Hecho y mergeado (PR #17, 2026-10-10).** macOS: 4 choques con hueco 0 (2560×1440 y pantalla virtual 4:3), medido también desde el SO. Windows (VM, 96 dpi): 8 de 8 con hueco 0 (2560×1440 y virtual 1280×800); transparencia vista a ojo por Zyra. **NO PROBADO:** que la transparencia siga puesta tras volver a pantalla completa en Windows, escalado 125/150 %, monitores reales y Stage Manager. Curva y temblor son valores de partida: Zyra los afina a ojo. Falta el temblor de la ventana y los saltos a otras posiciones | `scripts/effects/windowFx.hx`, `WindowChoreographyTestState.hx`, Receta I, trampas nº 14 y 19 |
| Audio de las 3 canciones | Generado en Suno (fuera del repo) | Notion → Canciones |

## 3. Datos de las canciones (para charts y código)

| Canción | Bloques | BPM | Tonalidad |
|---|---|---|---|
| 1 — Soul | (ver Notion) | 150 | Fa menor |
| 2 — Taro | Antes / después de la pastilla | **150 → 175** | La♭ mayor → Fa menor |
| 3 — Kiyu (final) | Con Kiyu / Zyra solo | **140 → 150** | La♭ mayor → Fa menor |

Entre los dos bloques de Kiyu van los crasheos y una cutscene (ver
`05_GLOSARIO_Y_LORE.md`). Los archivos de audio todavía **no** están en el repo.

## 4. En curso / siguiente paso

1. **Antes de usar la transparencia con arte y canciones (bloquean, en este orden):**
   - **BE-8:** el shader VHS fuerza alfa 1 y anula la transparencia mientras esté activo (trampa nº 16). Todo estado que quiera ver el escritorio a través del juego necesita esto resuelto.
   - **BE-9:** la intro todavía pide `FlxG.fullscreen = true` (trampa nº 14). Decisión de Zyra: ¿arranca en ventana o en pantalla completa sin Space?
2. **Producción:** arte, animaciones y cutscenes empiezan ahora (la documentación de arte es privada, ver `AGENTS.md` §2). Los estados nuevos con arte siguen las recetas A y B; cualquier uso de la ventana va por `windowFx.hx` (Receta I).
3. **Coreografía de ventana, lo que falta:** temblor de la ventana, saltos a otras posiciones, afinar curva y temblor de impacto a ojo, y probar en Windows lo que sigue en NO PROBADO (fila de §2).
4. **Probar la transparencia y la pantalla completa en un PC con Windows real** (BE-10 y la coreografía están hechos y probados en VM). Se necesita un PC prestado: el `.exe` del flujo `windows.yml` del fork + el mod (receta en la trampa nº 18). Plan B si algo falla: color clave (ADR-0003) y, si nada funciona, escritorio falso dibujado por el juego ("EchoOS").
5. **Secuencia final** (BACK → FINAL SEQUENCE): crasheo 1 real y controlado, menú roto, crasheo 2 falso, cutscene, bloque 2. Se apoya en la coreografía de ventana.
6. **Canciones dentro del mod**: crear `songs/<cancion>/` con la estructura del motor (ver `03_RECETAS.md`).

## 5. Inconsistencias conocidas (no las arregles sin preguntar)

- Los documentos del antiguo pipeline local de voces (ADR-0004, nunca aprobado) se eliminaron el 2026-10-09: la música y las voces salen de Suno. Si ves una referencia a ellos, ignórala.
- `docs/PROJECT_STRUCTURE.md` menciona `docs/DEPLOY.md`, que no existe todavía.
- Existe un worktree viejo de un agente en `.claude/worktrees/` (ya sin registrar en git; su rama local es `worktree-agent-a148a96f1853ae6ce`). No lo borres sin preguntar. Los worktrees nuevos van en `FNF_Echoes-worktrees/` (ver `GIT_WORKFLOW.md` §12).
- `mods/autoload.txt` y `mods/readme.txt` **no están versionados** (los ignora `mods/*` en `.gitignore`), aunque `AGENTS.md` §3 dibuja `autoload.txt` dentro del repo. Un clon o worktree nuevo no lo trae y el motor no cargaría el mod. Falta decidir si se versiona (`!mods/autoload.txt`) o se documenta como paso manual.
- `PROJECT_STRUCTURE.md` (regla 6) dice que se enlaza `mods/fnf-echoes/`, pero el enlace real del `.app` apunta a toda la carpeta `mods/`.
- El motor vive en un fork propio, `Salchorixo/CodenameEngine` (rama `echoes/patches`, con los commits `74c80698`, `3c36a57d` y `d315654f`); `.gitmodules` apunta a él y `upstream` = CodenameCrew dentro del submódulo. Un clon nuevo puede bajar `engine/` (comprobado 2026-10-10: el fork tiene `d315654f`).
- **No hay issues de Linear (workspace FNF Echoes) para la coreografía de ventana ni para pasar a producción;** las sesiones de agente a veces tienen conectado el Linear de SICDA, no el de FNF Echoes. Hay que crearlas y enlazar la PR #17 a mano.
- `docs/` y el mapa de `AGENTS.md` mencionan solo los estados de menú; los dos estados de prueba (`TransparencyTestState`, `WindowChoreographyTestState`) existen a propósito y no son pantallas del juego.

## 6. Preguntas abiertas para Zyra

- ¿El crasheo 1 es real (el jugador reabre el juego) o falso? Propuesta actual: real pero controlado.
- ¿Qué final abierto se usa? (opciones en Notion → Canción 3 final).
- ¿La intro arranca en ventana o en pantalla completa sin Space (BE-9)? ¿Ocultar Dock y barra de menús en pantalla completa?
- Coreografía de ventana: ¿qué curva y qué fuerza de temblor al chocar? ¿El regreso al centro más lento y pesado? ¿Zyra empieza su carrera mientras la ventana vuelve al centro?
- ¿Tienes acceso a un PC con Windows real para la prueba final?

## 7. Última sesión (sobrescribe esta sección al terminar)

- **Fecha:** 2026-10-13
- **Rama:** `feature/BE-14-echo-vista` (worktree `FNF_Echoes-worktrees/menu-principal`), encima de `feature/BE-13-menu-principal-vista`, `feature/BE-11-selector-canciones-mood` y `feature/menu-principal`: todo **local**, sin push y sin PR por decisión de Zyra. Los relevos de BE-11 y BE-13 están en los comentarios de sus issues.
- **Issue:** [BE-14](https://linear.app/fnf-echoes/issue/BE-14/seleccion-de-echo-en-lenguaje-vista-tres-ventanas-de-cristal-con-trazo) (workspace FNF Echoes). Pendiente al abrir PR: rehacer los mensajes de los commits de `feature/menu-principal` con su ID.
- **Objetivo de la sesión:** pasar la selección de Echo al lenguaje Vista (segunda de las tres pantallas: menú ✔, Echo ✔, ajustes pendiente).
- **Qué se hizo:** `EchoSelectState.hx` usa ventanas de cristal Vista con el trazo a lápiz ya dibujado dentro de cada sprite (la ventana mide 288×384 y el sprite lleva 24 px de margen; el hitbox es solo la ventana). Echo 1 es una imagen; Echo 2 (cadenas, 32 frames) y Echo 3 (tinta y glitch, 64 frames) son hojas animadas a 10 fps. Comportamiento, entrada, elevación, temblor y navegación sin cambios. Arte: `vista_echo_1.png`, `vista_echo_chains.png`, `vista_echo_glitch.png` (~1,5 MB), de `AI_export_echo_vista.py` (privado, sobre `AI_build_vista_screens.py`). Receta K aplica a las hojas grandes.
- **Probado:** macOS 2560×1440: abre sin errores en el log; capturas del juego con las tres ventanas, las cadenas y la tinta animadas. **NO PROBADO:** la selección con teclado y ratón, el temblor de las bloqueadas, ACCEPT y BACK en la pantalla nueva, la entrada animada, Windows. La hoja del glitch mide 2784×3984 px: cabe en 4096, pero una GPU con tope menor no la cargaría.
- **Qué quedó a medias:** el menú de ajustes en Vista; el título de las ventanas ("ECHO 1/2/3") sigue con la fuente pixel del diseño.
- **Errores pendientes:** ninguno en el log.
- **Decisiones tomadas:** el diseño se exporta sobre fondo blanco (el del juego), de modo que el cristal es pálido; las hojas llevan el lápiz dentro para que se mueva con cada ventana; no se borran `card_1.png`, `chains.png` y `glitch.png` (tema XP).
- **Preguntas para Zyra:** ¿te gusta el cristal pálido sobre blanco o quieres un poco más de tinte azul en el marco?
- **Siguiente paso:** la pantalla de Ajustes en Vista (`AI_build_settings_menu.py: vista_window()` es el diseño de partida).
