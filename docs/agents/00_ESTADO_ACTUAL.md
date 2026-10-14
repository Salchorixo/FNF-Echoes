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
| Menús del mod | Existen: Title, MainMenu (rediseñado el 2026-10-11 según el boceto de Zyra: fondo blanco, botones amarillos PLAY/SETTINGS/CREDITS a la izquierda, Zyra con auriculares en su sofá, carpeta arriba a la derecha y vinilo abajo a la derecha; Zyra y el sofá son la **animación dibujada real** (atlas, Receta J; música: OST de Soul `music/menuOst.ogg` al abrir y, en el frame de aterrizaje, el inst `music/menuInst.ogg` desde su drop en el segundo 26); botones, carpeta y vinilo son sprites **bocetados a lápiz con forma Windows XP** y las notas son partículas variadas (azules de los auriculares de Zyra, rojas del vinilo), todo en `images/menus/main/ui/` generado por `AI_build_menu_ui.py` (arte privado); sin VHS), EchoSelect (rehecha el 2026-10-13: 3 ventanas XP en pixel art), StoryMap, Options, Loading. Además dos estados de prueba sin acceso desde la UI: `TransparencyTestState` y `WindowChoreographyTestState` | `mods/fnf-echoes/data/states/` |
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
- **Rama:** `feature/BE-11-selector-canciones-mood` (worktree `FNF_Echoes-worktrees/menu-principal`), encima de `feature/menu-principal` (5 commits **locales**, sin push y sin PR por decisión de Zyra).
- **Issue:** [BE-11](https://linear.app/fnf-echoes/issue/BE-11/selector-de-canciones-fondo-y-ventana-por-nodo-zyra-animado) (workspace FNF Echoes, proyecto MENUS & UI). Los commits de `feature/menu-principal` siguen sin ID: rehacer sus mensajes al abrir la PR.
- **Objetivo de la sesión:** llevar al juego el diseño nuevo del selector de canciones (lenguaje Vista con trazo a lápiz): ambientación por nodo y Zyra animado.
- **Qué se hizo:**
  - `StoryMapState.hx`: cuatro ambientaciones (`soul`, `taro`, `kiyu`, `kiyu_inf`), cada una con fondo abstracto en bucle, ventana de mecánicas que toma su ambiente, nombres, camino, puntero, halos y trazo a lápiz; cambio con fundido y sacudida; nodo bloqueado con la ambientación apagada. Icono de Zyra animado (respiración, parpadeo `> <`, mirada hacia el nodo al que va) y carita depredadora cuando está en la última canción con la última desbloqueada. Receta K en `03_RECETAS.md`.
  - Arte nuevo en `images/menus/songs/`: `bg_*.png`, `mood_*.png`, `names_*.png`, `halo.png`, `pointer.png` (ahora blanco, se tiñe), `pencil_light/dark.png`, `zyra_alert.png`, `zyra_down.png` (~4 MB en total). Lo genera `AI_export_song_mood.py` (privado), con `AI_build_song_bg_loops.py` (versiones periódicas de los fondos) y `AI_build_zyra_icon.py` (el icono y su lógica de animación).
  - Trampa nº 20 (probar con teclado desde la terminal en macOS).
- **Probado:** macOS 2560×1440, ventana: abrí el selector con un atajo temporal en `modpack.ini` (ya restaurado) y recorrí a mano el desbloqueo Soul → Taro → Kiyu infectada con teclado. Vi, en capturas del juego, las cuatro ambientaciones, la ventana de cada una, el apagado de nodos bloqueados, la carita tierna y la depredadora. El log no tiene errores y el contador de memoria marcaba ~146 MB. **NO PROBADO:** el movimiento en vivo a ojo (solo capturas: parpadeo, mirada, sacudida del cambio, respiración), el ratón, volver con BACK, Windows, y que el bucle de 6,4 s no se note en una sesión larga.
- **Qué quedó a medias:** las **insignias** (`AI_build_badges.py` existe pero no se exportaron ni hay dónde mostrarlas: aún no hay resultados de canción); el inst de cada nodo; las imágenes reales de las mecánicas (la ventana lleva el relleno "MECANICA 1" dentro del arte); el arte de cada nivel (el rectángulo de la derecha sigue siendo el color provisional de `nodeArtPanel.hx`). ACCEPT sigue siendo prototipo.
- **Errores pendientes:** ninguno en el log.
- **Decisiones tomadas:** bucles de 64 frames a 10 fps con un contador compartido (el diseño original no era periódico y saltaba); las brasas y burbujas ya no dan la vuelta a la pantalla y los bokeh se balancean (cambio visual pequeño respecto al vídeo del diseño); un sprite por ambientación, todos cargados; la lógica del icono corre a 12 pasos por segundo.
- **Archivos que ya no se usan (preguntar antes de borrar):** `images/menus/songs/names.png`, `mech_window.png` y `zyra_icon.png`. Siguen pendientes de la sesión anterior: `scripts/ui/cardMenu.hx` sin consumidores y el detalle del ratón de `MainMenuState.hx`. `TitleState.hx` conserva la línea `TEMP-TEST` de Zyra: **no se commitea**.
- **Preguntas para Zyra:** ¿borrar los tres PNG obsoletos? ¿Quieres que las insignias vayan en este mismo bloque o en otro? ¿El rectángulo de la derecha debe tener el mismo color en los tres nodos?
- **Siguiente paso:** que Zyra pruebe el selector en movimiento (flechas, ratón, la infección de Kiyu) y diga qué retocar; después, el siguiente bloque que elija (temas del sistema operativo o el lenguaje Vista en las otras tres pantallas).
