# 00 — Estado actual del proyecto

> **Este archivo es el "dónde vamos".** Cada agente lo lee al empezar y lo
> **actualiza al terminar** (sección "Última sesión" y lo que haya cambiado).
> Si algo de aquí no coincide con el repo, **manda el repo**: corrige este
> archivo y dilo en el relevo.

**Última actualización:** 2026-10-03 (transparencia real en macOS conseguida, BE-7).

---

## 1. Resumen en una línea

Las 3 canciones ya tienen audio generado; el motor compila en macOS (Apple
Silicon) con parches; los menús del mod existen en HScript; ahora toca
producción: arte, animaciones, charts, mecánicas y la secuencia final.

## 2. Hecho (no lo rehagas)

| Área | Estado | Dónde |
|---|---|---|
| Motor en macOS arm64 | Compila y corre con 3 parches a `lime` 8.2.0 | ADR-0001, "Receta completa" |
| Motor en Windows | **Nunca probado** | ADR-0001, action item 1 |
| Menús del mod | Existen: Title, MainMenu, EchoSelect, StoryMap, Options, Loading | `mods/fnf-echoes/data/states/` |
| Scripts compartidos | `cardMenu`, `nodeArtPanel`, `translate`, `vhsShader` | `mods/fnf-echoes/scripts/` |
| Shader VHS | Existe, se adjunta por estado | `shaders/VHSShader.frag` + `scripts/effects/vhsShader.hx` |
| Transparencia de ventana en macOS | **Funciona** (probada a ojo, 2026-10-03): escritorio real visible a través del juego, en ventana y en pantalla completa sin Space | ADR-0003 "Actualización 2026-10-03"; ejemplo en `TransparencyTestState.hx` |
| Transparencia de ventana en Windows | **Sin hacer** | ADR-0003, action item 5 |
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

1. **Transparencia real de ventana en Windows** (Linear: BACK → ENGINE & PLATFORM): ventana *layered* con **color clave** (no necesita alfa en el framebuffer). macOS ya está (BE-7). El motor tiene puentes nativos en `engine/source/funkin/backend/utils/NativeAPI.hx` y `native/Windows.hx`. Plan B obligatorio: escritorio falso dibujado por el juego ("EchoOS").
   - **Antes de usar la transparencia en el juego:** el shader VHS fuerza alfa 1 (trampa nº 16) y la intro todavía pide `FlxG.fullscreen = true` (trampa nº 14).
2. **Secuencia final** (BACK → FINAL SEQUENCE): crasheo 1 real y controlado, menú roto, crasheo 2 falso, cutscene, bloque 2.
3. **Canciones dentro del mod**: crear `songs/<cancion>/` con la estructura del motor (ver `03_RECETAS.md`).

## 5. Inconsistencias conocidas (no las arregles sin preguntar)

- `docs/adr/0004-pipeline-local-de-voces-cromaticas.md` (estado *Proposed*) y `docs/AI_VOICE_CHROMATIC_PIPELINE.md` describen un pipeline de voces que **ya no se usa**: ahora la música y las voces salen de Suno. Falta decidir si se marca como *Superseded* y si se escribe un ADR nuevo.
- `docs/PROJECT_STRUCTURE.md` menciona `docs/DEPLOY.md`, que no existe todavía.
- Existe un worktree viejo de un agente en `.claude/worktrees/` (ya sin registrar en git; su rama local es `worktree-agent-a148a96f1853ae6ce`). No lo borres sin preguntar. Los worktrees nuevos van en `FNF_Echoes-worktrees/` (ver `GIT_WORKFLOW.md` §12).
- `mods/autoload.txt` y `mods/readme.txt` **no están versionados** (los ignora `mods/*` en `.gitignore`), aunque `AGENTS.md` §3 dibuja `autoload.txt` dentro del repo. Un clon o worktree nuevo no lo trae y el motor no cargaría el mod. Falta decidir si se versiona (`!mods/autoload.txt`) o se documenta como paso manual.
- `PROJECT_STRUCTURE.md` (regla 6) dice que se enlaza `mods/fnf-echoes/`, pero el enlace real del `.app` apunta a toda la carpeta `mods/`.
- **El commit del submódulo `engine/` no está en ningún remoto** (`74c80698` y `3c36a57d`, rama local `echoes/patches`): `.gitmodules` apunta a `CodenameCrew/CodenameEngine`, que no los tiene, así que un clon nuevo no puede bajar `engine/`. Decisión de Zyra: fork propio del motor (pendiente de crear y de apuntar `.gitmodules`).

## 6. Preguntas abiertas para Zyra

- ¿El crasheo 1 es real (el jugador reabre el juego) o falso? Propuesta actual: real pero controlado.
- ¿Qué final abierto se usa? (opciones en Notion → Canción 3 final).

## 7. Última sesión (sobrescribe esta sección al terminar)

- **Fecha:** 2026-10-03
- **Rama / issue:** `feature/BE-7-transparencia-macos` / BE-7
- **Qué se hizo:** transparencia real de ventana en macOS y pantalla completa sin Space. Parche en el submódulo (`engine/source/external/**`, `NativeAPI.hx`, `NativeWindow.hx`, `NativeApplication.hx`), estado de prueba `TransparencyTestState.hx` (sin atajo; se quitó la tecla T de la intro) y documentación (ADR-0003 con la causa real, trampas nº 10, 14, 15 y 16, `AGENTS.md` §0.11).
- **Probado:** a ojo por Zyra en macOS 27.2 (Apple Silicon) con Stage Manager: transparencia ON/OFF y pantalla completa ON/OFF repetidas veces, sin parpadeo y con el indicador de `FlxG.fullscreen` correcto. Medido con sonda de píxeles y con un programa de referencia (ADR-0003). **NO PROBADO:** Windows; con el shader VHS activo; juego distribuido (no `cne test`).
- **Qué quedó a medias:** crear el fork del motor y apuntar `.gitmodules` (sin eso la PR de BE-7 no se puede mergear sin romper clones).
- **Decisiones tomadas:** detrás del juego debe verse el escritorio real (no un Space nuevo ni un escritorio falso); pantalla completa = ventana sin bordes del tamaño del escritorio; fork propio del motor para versionar los parches.
- **Preguntas para Zyra:** ¿la intro arranca en ventana o en pantalla completa sin Space? ¿Ocultar Dock y barra de menús en pantalla completa?
- **Siguiente paso:** crear el fork `Salchorixo/CodenameEngine`, subir `echoes/patches`, apuntar `.gitmodules` y abrir la PR de BE-7.
