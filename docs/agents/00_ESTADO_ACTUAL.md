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
| Menús del mod | Existen: Title, MainMenu (**con sistema de temas desde 2026-10-13, BE-16:** el fondo y la interfaz cambian entre Vista, XP, Windows 98 y Mac con un glitch de cambio de canal; rediseñado el 2026-10-11 según el boceto de Zyra: fondo blanco, botones amarillos PLAY/SETTINGS/CREDITS a la izquierda, Zyra con auriculares en su sofá, carpeta arriba a la derecha y vinilo abajo a la derecha; Zyra y el sofá son la **animación dibujada real** (atlas, Receta J; música: solo el instrumental de Soul `music/menuInst.ogg`, que arranca al abrir el menú sincronizado para que su drop caiga en el aterrizaje de Zyra (BE-19); `menuOst.ogg` se borró; Zyra hará una música propia para el menú); botones, carpeta y vinilo están en el **lenguaje Vista con trazo a lápiz** (pixel art ×3 con el lápiz encima; el vinilo tiene 24 frames; BE-13) y las notas son partículas variadas (azules de los auriculares de Zyra, rojas del vinilo), todo en `images/menus/main/ui/` (`vista_*.png` por `AI_export_main_menu_vista.py`, `notes.png` por `AI_build_menu_ui.py`; arte privado). Los sprites XP (`xp_*.png`) se conservan para el futuro tema XP; sin VHS), EchoSelect (rehecha el 2026-10-13: 3 ventanas de cristal Vista en pixel art con trazo a lápiz, BE-14; el arte XP anterior se conserva), StoryMap, Options (rehecha el 2026-10-13: ventana de cristal Vista con cinco categorías, BE-15), Loading. Además dos estados de prueba sin acceso desde la UI: `TransparencyTestState` y `WindowChoreographyTestState` | `mods/fnf-echoes/data/states/` |
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
   - **BE-9:** resuelto por Zyra (2026-10-13, BE-18): el juego **arranca en ventana**; `TitleState.hx` ya no pide pantalla completa. Queda decidir si algún momento posterior la usa (el final la usa a través de `windowFx.hx`).
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
- ¿Ocultar Dock y barra de menús cuando el final pase a pantalla completa? (La intro ya arranca en ventana, BE-18.)
- Coreografía de ventana: ¿qué curva y qué fuerza de temblor al chocar? ¿El regreso al centro más lento y pesado? ¿Zyra empieza su carrera mientras la ventana vuelve al centro?
- ¿Tienes acceso a un PC con Windows real para la prueba final?

## 7. Última sesión (sobrescribe esta sección al terminar)

- **Fecha:** 2026-10-13
- **Rama:** `feature/BE-20-ajustes-ventanita` (worktree `FNF_Echoes-worktrees/menu-principal`), encima de `fix/BE-18-arranque-en-ventana`, `fix/BE-19-menu-solo-inst`, `feature/BE-16-sistema-de-temas`, `fix/BE-17-menu-sin-intro-al-volver`, `feature/BE-15-ajustes-vista`, `feature/BE-14-echo-vista`, `feature/BE-13-menu-principal-vista`, `feature/BE-11-selector-canciones-mood` y `feature/menu-principal`: todo **local**, sin push y sin PR por decisión de Zyra. Los relevos anteriores están en los comentarios de sus issues.
- **Issues:** BE-18 (ventana), BE-19 (solo el inst) y BE-20 (Ajustes encima del menú), del workspace FNF Echoes. Pendiente al abrir PR: rehacer los mensajes de los commits de `feature/menu-principal` con su ID.
- **Qué se hizo:**
  - **BE-18:** el juego arranca en **ventana** (`TitleState.hx` ya no pide pantalla completa; comprobado). Cierra la pregunta de BE-9.
  - **BE-19:** el menú suena **solo con el instrumental**. Antes arrancaba el OST con voces y lo cambiaba por el inst al aterrizar; si la música no estaba sonando al abrir el menú, el OST se quedaba (el motor reutiliza el objeto de sonido y su marca `ID` seguía en "inst"). Ahora arranca directamente `menuInst.ogg`, 0,7 s antes de su drop para que caiga en el aterrizaje de Zyra. `music/menuOst.ogg` se borró con el visto bueno de Zyra (hará una música propia para el menú). **Si siguen oyéndose voces, las lleva el propio `inst 1st song.wav`:** se comprobó que los wav de OST e inst tienen casi cero correlación entre sí, así que parecen dos generaciones distintas.
  - **BE-20:** **Ajustes es una ventanita encima del menú, no una pantalla**: `OptionsState.hx` pasa a **subestado** (`ModSubState`) abierto desde `MainMenuState.openSettings()`, sin transición, con su propia cámara por encima de las del menú; el menú sigue moviéndose detrás (Zyra, notas, música) pero ignora teclado y ratón mientras tanto; entra con un fundido y una subida suave y se cierra con el fundido contrario; al cerrar se refrescan los textos y el fondo si cambió el idioma. Trampa nº 23.
- **Probado:** macOS, juego en ventana: abre sin errores; la música arranca con `menuInst` desde 25,3 s (traza en el log); Ajustes aparece y se cierra sobre el menú sin transición, con el menú vivo detrás (capturas). **NO PROBADO:** el cambio de idioma estando abierta la ventana (y que el menú se actualice al cerrar), el audio (no se pudo oír), Windows. Un fallo durante la prueba (recursión infinita por un reemplazo con expresión regular) ya está corregido.
  - **BE-21 (rama `feature/BE-21-cambio-de-tema-dinamico`, encima de BE-20):** el cambio de tema dura ~1,7 s en vez de ~4,5 s y es más dinámico: botones que se cierran en ~0,3 s, pérdida de señal con saltos de rodillo y destellos de blanco, sacudida de la cámara temática, un golpe de llegada (destello, zoom y sacudida) al aparecer el fondo nuevo, y una ráfaga de glitch en cada entrada de la interfaz. Zyra y el lápiz no se mueven. "Reducir destellos" sigue siendo un fundido suave (~1,2 s). Probado en capturas (la velocidad real no se puede medir con capturas); **NO PROBADO** el modo suave.
- **Qué quedó a medias:** lo de BE-16 (temas solo en el menú principal; ajustar la dinámica de los cambios), el menú roto, las insignias (BE-12).
- **Errores pendientes:** ninguno en el log.
- **Preguntas para Zyra:** ninguna abierta de esta tanda (la música del menú se oye bien según Zyra).
- **Siguiente paso:** que Zyra pruebe los cambios de tema (F4) y diga si la velocidad y la fuerza están bien.
