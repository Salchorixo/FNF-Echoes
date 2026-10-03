# AGENTS.md — Manual de trabajo para agentes de IA (FNF Echoes)

Este archivo es el contrato de trabajo de **cualquier** agente que toque este
repositorio: Claude Code, OpenCode, Cursor, Codex o un modelo local pequeño.
Está escrito para que un agente pueda **retomar una sesión a medias sin
adivinar nada**. Si tu herramienta no puede hacer algo de lo que aquí se pide
(compilar, abrir Linear, ver la pantalla), **dilo**. Nunca te saltes un paso en
silencio.

`CLAUDE.md` solo importa este archivo. No dupliques contenido allá.

---

## 0. Lo esencial (léelo SIEMPRE, aunque la tarea sea pequeña)

1. **Antes de tocar nada, lee `docs/agents/00_ESTADO_ACTUAL.md`.** Dice qué está hecho, qué está a medias y cuál es el siguiente paso.
2. **No inventes funciones, clases ni rutas del motor.** Si no la has visto escrita en `engine/source/` o en un archivo de `mods/fnf-echoes/`, no existe para ti. Búscala (§4). Si no aparece, pregunta.
3. **`engine/` no se edita.** Solo con un ADR aprobado por Zyra (ver ADR-0003 como ejemplo).
4. **Código en inglés** (nombres y comentarios). **Documentación y commits en español.** No se mezclan.
5. **El contenido del mod es HScript** en `mods/fnf-echoes/`. Ahí **no hay clases propias ni `import` entre archivos del mod**. Se comparte con `Script.create(...)` + `.load()` + `.call(...)` (ver `docs/agents/02_HSCRIPT_CODENAME.md`).
6. **Nunca trabajes ni commitees sobre `main`.** Rama `tipo/descripcion-corta`, PR, revisión (ver `docs/GIT_WORKFLOW.md`).
7. **Una tarea a la vez.** Si la tarea crece o toca algo que no se pidió, para y pregunta.
8. **Antes de decir "funciona", pruébalo.** Si no pudiste compilar o ejecutar, escribe literalmente "NO PROBADO" y por qué.
9. **Al terminar o al dejar algo a medias, deja el relevo escrito** (`docs/agents/01_PROTOCOLO_DE_SESION.md` §3) y actualiza `00_ESTADO_ACTUAL.md`.
10. **Historia, diseño de juego, arte y música los decide Zyra.** Tú propones; no decides.

---

## 1. Qué es este proyecto

**FNF Echoes** es un mod narrativo de *Friday Night Funkin'* y el TFM del Máster
de Desarrollo con IA de Salchorizo (Zyra). Motor: **Codename Engine** (Haxe +
HaxeFlixel + OpenFL), como submódulo en `engine/`. Plataformas: **macOS y
Windows**.

El mod tiene **3 canciones**: Soul, Taro y Kiyu (final). La música y las voces
se generan con Suno y forman parte del canon del juego. La historia ocurre
dentro de un computador; el final rompe la cuarta pared (crasheos, ventanas,
escritorio). Resumen en `docs/agents/05_GLOSARIO_Y_LORE.md`.

> **Ojo con el nombre "Zyra":** es el **personaje** (gatito negro, **macho**,
> siempre "él") y también el apodo del **autor**. Si hablas del autor, di
> "Zyra" o "Salchorizo", sin asumir pronombres.

---

## 2. Router: según tu tarea, lee esto

| Si tu tarea es... | Lee primero |
|---|---|
| Cualquier tarea | `docs/agents/00_ESTADO_ACTUAL.md` y `docs/agents/01_PROTOCOLO_DE_SESION.md` |
| Escribir o cambiar HScript (estados, scripts, UI) | `docs/agents/02_HSCRIPT_CODENAME.md` |
| Una tarea con receta (pantalla nueva, script compartido, canción, shader) | `docs/agents/03_RECETAS.md` |
| Algo "raro" que no funciona | `docs/agents/04_TRAMPAS_CONOCIDAS.md` |
| Entender personajes, lore o vocabulario | `docs/agents/05_GLOSARIO_Y_LORE.md` |
| Compilar el motor o tocar código nativo | `docs/adr/0001-motor-y-stack-tecnologico.md` (receta macOS) y `docs/adr/0003-transparencia-de-ventana.md` |
| Proponer un cambio de arquitectura | `docs/adr/` + `docs/CODING_STANDARDS.md` |
| Crear una carpeta o mover archivos | `docs/PROJECT_STRUCTURE.md` |
| Ramas, commits, PR | `docs/GIT_WORKFLOW.md` |

Lee **solo** lo que tu tarea necesita. Si tu contexto es pequeño, no cargues
todos los documentos a la vez.

---

## 3. Mapa rápido del repositorio

```
FNF_Echoes/
├── AGENTS.md                 ← este archivo
├── CLAUDE.md                 ← solo "@AGENTS.md"
├── context.md                ← explica la documentación (para evaluadores)
├── docs/
│   ├── agents/               ← manual operativo para agentes (empieza aquí)
│   ├── adr/                  ← decisiones técnicas (0001 a 0004)
│   ├── CODING_STANDARDS.md
│   ├── PROJECT_STRUCTURE.md
│   ├── GIT_WORKFLOW.md
│   └── WORKFLOW.md
├── engine/                   ← Codename Engine (submódulo). NO SE EDITA.
└── mods/
    ├── autoload.txt          ← contiene "fnf-echoes"
    └── fnf-echoes/           ← TODO el mod vive aquí
        ├── data/config/modpack.ini   ← nombre del mod + [StateRedirects]
        ├── data/states/              ← pantallas (HScript)
        ├── scripts/ui/               ← cardMenu, nodeArtPanel, translate
        ├── scripts/effects/          ← vhsShader
        └── shaders/                  ← VHSShader.frag
```

Ignorados por git (no los busques en el repo): `TFM-Requisitos.md`,
`audio_src/`, `export/`, `.haxelib/`.

---

## 4. Comandos útiles

Buscar antes de escribir (desde la raíz del repo):

```bash
# ¿Existe esta función o clase en el motor?
grep -rn "function nombreFuncion" engine/source
grep -rn "class NombreClase" engine/source

# ¿Cómo lo usa ya el mod?
grep -rn "Script.create" mods/fnf-echoes

# Ejemplo real de una estructura del motor (canciones, personajes, etc.)
ls engine/assets/songs/bopeebo
```

Git (siempre antes de empezar):

```bash
git status            # ¿hay cambios sin commitear de otra sesión?
git branch --show-current
git log --oneline -10
```

Compilar y probar: ver `docs/agents/01_PROTOCOLO_DE_SESION.md` §4. Resumen:
**los cambios en `mods/` no requieren recompilar el motor**; basta con volver a
abrir el juego ya compilado.

---

## 5. Qué decides tú y qué preguntas

**Decides tú** (y lo explicas en el relevo):
- Nombres de variables y funciones (en inglés).
- Cómo organizar el código dentro de un archivo, siguiendo los patrones que ya existen.
- Arreglos pequeños y evidentes en la tarea que te asignaron.

**Preguntas siempre a Zyra:**
- Cualquier cosa de historia, personajes, arte, música o mecánicas.
- Editar `engine/`, añadir una dependencia o código nativo.
- Crear una carpeta de primer nivel o un documento nuevo en `docs/`.
- Borrar archivos o reescribir un archivo entero.
- Cuando dos documentos se contradicen (ver §8).

Si no puedes preguntar (sesión sin humano), **no hagas el cambio**: déjalo
anotado en el relevo como pregunta pendiente.

---

## 6. Disciplina de trabajo (obligatoria, sobre todo para modelos pequeños)

1. **Lee el archivo completo antes de editarlo.** Nunca edites de memoria.
2. **Copia el patrón que ya existe.** Si `MainMenuState.hx` hace algo de una forma, haz lo mismo de la misma forma.
3. **Cambios mínimos.** Edita solo las líneas necesarias. No reformatees ni reordenes lo demás.
4. **No reescribas un archivo entero** salvo que la tarea lo pida explícitamente.
5. **Cita los errores literalmente** (copia y pega el mensaje). No los resumas.
6. **Regla de los 3 intentos:** si el mismo arreglo falla 3 veces, para, escribe el relevo con lo que probaste y pregunta.
7. **Una cosa por commit.** Mensaje: `tipo: descripción corta` en español.
8. **Si algo no lo sabes, escribe "no lo sé"** y cómo verificarlo. Nunca rellenes con suposiciones.

---

## 7. Linear y Notion

**Linear** (workspace **FNF Echoes**) es donde viven las tareas:

- Equipo **DESIGN (DS)**, con los proyectos: ANIMATIONS, DECISIONS, ART & BACKGROUNDS, MUSIC & AUDIO, CHARTS, MECHANICS, CUTSCENES & STORY.
- Equipo **BACK (BE)**, con los proyectos: ENGINE & PLATFORM, GAMEPLAY MECHANICS, MENUS & UI, FINAL SEQUENCE, ARCHITECTURE, RELEASE & TFM.
- **Ojo:** a tu herramienta puede estar conectado también otro workspace de Zyra (**SICDA**) con el mismo prefijo `BE-`. Comprueba que estás en **FNF Echoes** (`linear.app/fnf-echoes`) antes de tocar una issue.

Si tienes acceso a Linear: trabaja desde una issue, nombra la rama con su ID
(por ejemplo `feature/BE-12-transparencia-windows`) y deja el relevo como
comentario en esa issue. Si no tienes acceso, deja el relevo en
`00_ESTADO_ACTUAL.md` y dilo.

El ciclo completo (estados de Linear, ramas, PR con `Closes BE-12`, merge con
rebase) está en `docs/GIT_WORKFLOW.md`. Ahí también se dice qué **no** haces tú:
no cierras issues a mano, no mergeas PR, no cambias ajustes de GitHub/Linear.

**Notion** guarda la historia, el lore y las decisiones creativas (página
"FNF Echoes || (WIP)" → Historia, Decisiones, Canciones). Las decisiones
**técnicas** van como ADR en `docs/adr/`, no en Notion.

---

## 8. Qué documento manda (si se contradicen)

1. Lo que Zyra dijo explícitamente en la sesión actual.
2. Los ADR con estado **Accepted** en `docs/adr/`.
3. Este `AGENTS.md`.
4. `docs/agents/*`, `docs/CODING_STANDARDS.md`, `docs/PROJECT_STRUCTURE.md`.
5. El código existente.

Si encuentras una contradicción, **no la resuelvas tú**: anótala en el relevo
y pregunta.

---

## 9. Cómo hablarle a Zyra

- En **español**, directo y cálido. Sin relleno.
- Explica el **porqué** de lo que hiciste, no solo el qué.
- Si algo no salió, dilo primero y claro.
- Para decisiones, ofrece opciones concretas con su consecuencia, y recomienda una.
