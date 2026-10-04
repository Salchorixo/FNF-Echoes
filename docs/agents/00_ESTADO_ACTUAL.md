# 00 — Estado actual del proyecto

> **Este archivo es el "dónde vamos".** Cada agente lo lee al empezar y lo
> **actualiza al terminar** (sección "Última sesión" y lo que haya cambiado).
> Si algo de aquí no coincide con el repo, **manda el repo**: corrige este
> archivo y dilo en el relevo.

**Última actualización:** 2026-10-03 (transparencia real en Windows conseguida en VM, BE-10).

---

## 1. Resumen en una línea

Las 3 canciones ya tienen audio generado; el motor compila en macOS (Apple
Silicon) con parches; los menús del mod existen en HScript; ahora toca
producción: arte, animaciones, charts, mecánicas y la secuencia final.

## 2. Hecho (no lo rehagas)

| Área | Estado | Dónde |
|---|---|---|
| Motor en macOS arm64 | Compila y corre con 3 parches a `lime` 8.2.0 | ADR-0001, "Receta completa" |
| Motor en Windows | Arranca y corre el mod en una VM Windows 11 ARM64 (motor oficial v1.0.1 y el compilado del fork); **sin probar en hardware real** | ADR-0001 action item 1; ADR-0003 (BE-10) |
| Menús del mod | Existen: Title, MainMenu, EchoSelect, StoryMap, Options, Loading | `mods/fnf-echoes/data/states/` |
| Scripts compartidos | `cardMenu`, `nodeArtPanel`, `translate`, `vhsShader` | `mods/fnf-echoes/scripts/` |
| Shader VHS | Existe, se adjunta por estado | `shaders/VHSShader.frag` + `scripts/effects/vhsShader.hx` |
| Transparencia de ventana en macOS | **Funciona** (probada a ojo, 2026-10-03): escritorio real visible a través del juego, en ventana y en pantalla completa sin Space | ADR-0003 "Actualización 2026-10-03"; ejemplo en `TransparencyTestState.hx` |
| Transparencia de ventana en Windows | **Funciona en VM** (2026-10-03), en ventana y en pantalla completa; **sin probar en hardware real** | ADR-0003 "Actualización 2026-10-03 (BE-10)"; `NativeAPI.setWindowTransparent` |
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

1. **Probar la transparencia y la pantalla completa en un PC con Windows real** (BE-10 está hecho y probado en VM). Se necesita un PC prestado: el `.exe` del flujo `windows.yml` del fork + el mod (receta en la trampa nº 18). Plan B si algo falla: color clave (ADR-0003) y, si nada funciona, escritorio falso dibujado por el juego ("EchoOS").
   - **Antes de usar la transparencia en el juego:** el shader VHS fuerza alfa 1 (trampa nº 16, **BE-8**) y la intro todavía pide `FlxG.fullscreen = true` (trampa nº 14, **BE-9**, con decisiones de Zyra pendientes).
2. **Secuencia final** (BACK → FINAL SEQUENCE): crasheo 1 real y controlado, menú roto, crasheo 2 falso, cutscene, bloque 2.
3. **Canciones dentro del mod**: crear `songs/<cancion>/` con la estructura del motor (ver `03_RECETAS.md`).

## 5. Inconsistencias conocidas (no las arregles sin preguntar)

- `docs/adr/0004-pipeline-local-de-voces-cromaticas.md` (estado *Proposed*) y `docs/AI_VOICE_CHROMATIC_PIPELINE.md` describen un pipeline de voces que **ya no se usa**: ahora la música y las voces salen de Suno. Falta decidir si se marca como *Superseded* y si se escribe un ADR nuevo.
- `docs/PROJECT_STRUCTURE.md` menciona `docs/DEPLOY.md`, que no existe todavía.
- Existe un worktree viejo de un agente en `.claude/worktrees/` (ya sin registrar en git; su rama local es `worktree-agent-a148a96f1853ae6ce`). No lo borres sin preguntar. Los worktrees nuevos van en `FNF_Echoes-worktrees/` (ver `GIT_WORKFLOW.md` §12).
- `mods/autoload.txt` y `mods/readme.txt` **no están versionados** (los ignora `mods/*` en `.gitignore`), aunque `AGENTS.md` §3 dibuja `autoload.txt` dentro del repo. Un clon o worktree nuevo no lo trae y el motor no cargaría el mod. Falta decidir si se versiona (`!mods/autoload.txt`) o se documenta como paso manual.
- `PROJECT_STRUCTURE.md` (regla 6) dice que se enlaza `mods/fnf-echoes/`, pero el enlace real del `.app` apunta a toda la carpeta `mods/`.
- **El commit del submódulo `engine/` no está en ningún remoto** (`74c80698` y `3c36a57d`, rama local `echoes/patches`): `.gitmodules` apunta a `CodenameCrew/CodenameEngine`, que no los tiene, así que un clon nuevo no puede bajar `engine/`. Resuelto en BE-7: fork propio `Salchorixo/CodenameEngine` (rama `echoes/patches`), `.gitmodules` apuntando a él y `upstream` = CodenameCrew dentro del submódulo.

## 6. Preguntas abiertas para Zyra

- ¿El crasheo 1 es real (el jugador reabre el juego) o falso? Propuesta actual: real pero controlado.
- ¿Qué final abierto se usa? (opciones en Notion → Canción 3 final).

## 7. Última sesión (sobrescribe esta sección al terminar)

- **Fecha:** 2026-10-03
- **Rama / issue:** `feature/BE-10-transparencia-windows` / BE-10
- **Qué se hizo:** transparencia real de ventana en Windows. `Windows.setWindowTransparent` (DWM alfa por píxel + ventana *layered*) y su rama en `NativeAPI.setWindowTransparent`; commit `d315654f` en `echoes/patches` del fork. Se montó una VM de Windows 11 ARM64 en VMware Fusion Pro para probarlo, con el motor compilado en las Actions del fork. Documentado en el ADR-0003, trampas nº 17 y 18 y `01_PROTOCOLO_DE_SESION.md` §4.
- **Probado:** a ojo por Zyra en la VM: transparencia ON/OFF y pantalla completa ON/OFF en todas las combinaciones, con el `.exe` compilado en CI. **NO PROBADO:** hardware real; con el shader VHS activo; reaplicación automática tras cambios de estilo de ventana.
- **Qué quedó a medias:** nada de BE-10. Seguimiento: probar en un PC real, BE-8 (VHS conserva el alfa) y BE-9 (arranque de la intro).
- **Decisiones tomadas:** receta de Windows = DWM con región vacía + ventana *layered* (no el color clave, que queda de plan B); probar en VM con VMware Fusion Pro y no en UTM (sin 3D).
- **Preguntas para Zyra:** ¿tienes acceso a un PC con Windows real para la prueba final? ¿La intro arranca en ventana o en pantalla completa sin Space (BE-9)?
- **Siguiente paso:** mergear la PR de BE-10 y seguir con BE-8.
