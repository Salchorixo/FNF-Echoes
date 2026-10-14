# 00 — Estado actual del proyecto

> **Este archivo es el "dónde vamos".** Cada agente lo lee al empezar y lo
> **actualiza al terminar** (sección "Última sesión" y lo que haya cambiado).
> Si algo de aquí no coincide con el repo, **manda el repo**: corrige este
> archivo y dilo en el relevo.

**Última actualización:** 2026-10-10 (la ventana ya se mueve sola; empieza la producción de arte).

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
- **Rama:** `feature/menu-principal` (worktree `FNF_Echoes-worktrees/menu-principal`), 4 commits **locales**: sin push y sin PR (decisión de Zyra).
- **Issue:** sin issue. **Acordado con Zyra: crear la issue de Linear del workspace FNF Echoes (`linear.app/fnf-echoes`, no el de SICDA) ANTES de abrir la PR**, y poner su ID en la rama y en los commits (rehacer los mensajes entonces).
- **Objetivo de la sesión:** dejar hechos los menús con las animaciones y el arte de Zyra: menú principal, selección de Echo y selector de canciones.
- **Qué se hizo:**
  - **Menú principal** (`MainMenuState.hx`, `translate.hx`, `images/menus/main/`, `music/`): la animación dibujada de Zyra (`renders/v5/`, atlas a 720p de 5 páginas, 36 MB; intro de 126 frames una vez y bucle de 150 a 60 fps); suena el OST (`menuOst.ogg`) y en el frame 42 (aterrizaje) entra el inst (`menuInst.ogg`) en el segundo 26; botones, carpeta y vinilo como sprites XP bocetados a lápiz; notas musicales como partículas; sin VHS (decisión de Zyra).
  - **Selección de Echo** (`EchoSelectState.hx`, `images/menus/echo/`): tres ventanas XP en pixel art sobre blanco; Echo 1 activa, Echo 2 apagada y encadenada, Echo 3 apagada y rota con tinta. Ya no usa `cardMenu.hx`.
  - **Selector de canciones** (`StoryMapState.hx`, `images/menus/songs/`): camino vertical sobre negro con tres nodos-esfera (SOUL, TARO, KIYU que se infecta al completar la canción 2), ventana de mecánica (relleno) a la izquierda, rectángulo de arte a la derecha, Zyra (icono provisional) a la derecha del nodo. Nodos con bucles de 64/48/80/56 frames desfasados, chispas en vivo y eventos aleatorios cada 3-9 s solo en los desbloqueados. **ACCEPT es un prototipo** (no hay canciones en el mod).
  - Los PNG se versionan **tal cual** (sin Git LFS): ~39 MB en total, el archivo más pesado 9,4 MB.
  - El arte lo generan scripts de la carpeta de producción privada (fuera del repo): `AI_pack_atlas.py`, `AI_build_menu_ui.py`, `AI_build_echo_select.py`, `AI_build_song_select.py --export`. Recetas: J en `03_RECETAS.md`.
- **Probado:** macOS 2560×1440: el menú principal con animación, UI, notas y música (el inst entró en ≈26,9 s); la pantalla de Echo abre con las tres ventanas animadas; todo sin errores en el log. **NO PROBADO:** la intro del menú principal en movimiento, ACCEPT/volver desde Settings, la navegación con teclado y el temblor de las ventanas bloqueadas de Echo, el selector de canciones visto en el juego (se abrió sin errores en el log pero el Mac se bloqueó durante la prueba; las hojas de frames coinciden con el código), el clic del ratón, la infección de Kiyu y Windows.
- **Qué quedó a medias:** nada de código. Pendiente de Zyra: el inst de cada canción al pasar por su nodo (no tiene todos), el fondo definitivo del selector (hoy negro, provisional), las imágenes de las mecánicas, el arte del nivel, su icono de Zyra (sustituir `images/menus/songs/zyra_icon.png`), decidir las burbujas de Echo 3 y la tercera cadena que tapa la tinta.
- **Errores pendientes:** ninguno en el log.
- **Decisiones tomadas:** animación como secuencia PNG con alfa recortada y a 720p (el vídeo del motor no lee alfa y la memoria de vídeo manda); WebP descartado (el motor solo lee PNG y JPG); PNG sin LFS; sin VHS en estos menús; `FlxG.sound.music.ID` marca si suena el OST o el inst.
- **Limpieza pendiente (no hecha, preguntar):** `scripts/ui/cardMenu.hx` quedó sin ninguna pantalla que lo use (¿borrarlo?); `MainMenuState.hx` tiene el mismo detalle del ratón que se corrigió en `EchoSelectState.hx` (`lastMouseX/Y` arrancan en -1 y el ratón en reposo selecciona algo en el primer frame). `TitleState.hx` del worktree conserva una línea `TEMP-TEST` de Zyra que salta el título: **no se commiteó**.
- **Preguntas para Zyra:** ver §6; además, ¿la intro del menú principal se repite al volver de Settings?
- **Siguiente paso:** que Zyra pruebe a mano los tres menús (flechas, ratón, ACCEPT, la infección de Kiyu); crear la issue de Linear; entonces empujar la rama y abrir la PR contra `main`.
