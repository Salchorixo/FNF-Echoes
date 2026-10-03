# 00 — Estado actual del proyecto

> **Este archivo es el "dónde vamos".** Cada agente lo lee al empezar y lo
> **actualiza al terminar** (sección "Última sesión" y lo que haya cambiado).
> Si algo de aquí no coincide con el repo, **manda el repo**: corrige este
> archivo y dilo en el relevo.

**Última actualización:** 2026-10-03 (`git done` y worktrees documentados, BE-6).

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
| Transparencia de ventana | **Intentada, no funciona**; se usa efecto simulado | ADR-0003 |
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

1. **Transparencia real de ventana** (Linear: BACK → ENGINE & PLATFORM). Idea a probar:
   - Windows: ventana *layered* con **color clave** (no necesita alpha en el framebuffer, así que esquiva el problema del ADR-0003).
   - macOS: ventana no opaca + superficie que limpie con alpha 0 (choca con lo encontrado en el ADR-0003; resultado incierto).
   - El motor ya tiene puentes nativos: `engine/source/funkin/backend/utils/NativeAPI.hx`, `native/Windows.hx`, `native/Mac.hx` (este usa `external.ExternalMac`).
   - **Requiere revisar el ADR-0003 antes de tocar `engine/`.** Plan B obligatorio: escritorio falso dibujado por el juego ("EchoOS").
2. **Secuencia final** (BACK → FINAL SEQUENCE): crasheo 1 real y controlado, menú roto, crasheo 2 falso, cutscene, bloque 2.
3. **Canciones dentro del mod**: crear `songs/<cancion>/` con la estructura del motor (ver `03_RECETAS.md`).

## 5. Inconsistencias conocidas (no las arregles sin preguntar)

- `docs/adr/0004-pipeline-local-de-voces-cromaticas.md` (estado *Proposed*) y `docs/AI_VOICE_CHROMATIC_PIPELINE.md` describen un pipeline de voces que **ya no se usa**: ahora la música y las voces salen de Suno. Falta decidir si se marca como *Superseded* y si se escribe un ADR nuevo.
- `docs/PROJECT_STRUCTURE.md` menciona `docs/DEPLOY.md`, que no existe todavía.
- Existe un worktree viejo de un agente en `.claude/worktrees/` (ya sin registrar en git; su rama local es `worktree-agent-a148a96f1853ae6ce`). No lo borres sin preguntar. Los worktrees nuevos van en `FNF_Echoes-worktrees/` (ver `GIT_WORKFLOW.md` §12).
- `mods/autoload.txt` y `mods/readme.txt` **no están versionados** (los ignora `mods/*` en `.gitignore`), aunque `AGENTS.md` §3 dibuja `autoload.txt` dentro del repo. Un clon o worktree nuevo no lo trae y el motor no cargaría el mod. Falta decidir si se versiona (`!mods/autoload.txt`) o se documenta como paso manual.
- `PROJECT_STRUCTURE.md` (regla 6) dice que se enlaza `mods/fnf-echoes/`, pero el enlace real del `.app` apunta a toda la carpeta `mods/`.

## 6. Preguntas abiertas para Zyra

- ¿El crasheo 1 es real (el jugador reabre el juego) o falso? Propuesta actual: real pero controlado.
- ¿Qué final abierto se usa? (opciones en Notion → Canción 3 final).

## 7. Última sesión (sobrescribe esta sección al terminar)

- **Fecha:** 2026-10-03
- **Rama / issue:** `docs/BE-6-git-done-y-worktrees` / BE-6
- **Qué se hizo:** se documentó el alias local `git done` (limpieza tras el merge) y el flujo con worktrees en `docs/GIT_WORKFLOW.md` §8 y §12. Antes ya se había aplicado la configuración de Linear (estado *In Review*, etiquetas `needs-zyra`/`blocked`/`engine`/`windows`) y la protección de `main` en GitHub.
- **Probado:** `git done` en el checkout principal, dentro de un worktree (se niega), con un worktree de rama mergeada simulada (lo quita y borra la rama) y con cambios sin commitear (lo conserva). **NO PROBADO:** ejecutar el juego desde un worktree (reapuntar el enlace de `mods`).
- **Qué quedó a medias:** nada de código. Pendiente comprobar que la integración GitHub ↔ Linear mueve BE-6 sola (In Progress → In Review → Done).
- **Siguiente paso recomendado:** prueba aislada de transparencia en Windows con color clave, documentada antes en una revisión del ADR-0003.
