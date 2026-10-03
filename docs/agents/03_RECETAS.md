# 03 — Recetas paso a paso

Cada receta es una lista cerrada. Síguela en orden. Si un paso no se cumple
(un archivo no existe, un nombre no coincide), **para y anótalo en el relevo**.

---

## Receta A — Pantalla nueva (estado)

1. Abre `data/states/MainMenuState.hx` y léelo completo: es el modelo.
2. Crea `mods/fnf-echoes/data/states/NombreState.hx` con el esqueleto de `02_HSCRIPT_CODENAME.md` §2.
3. Primera línea de `create()`: `FlxG.camera.scroll.set(0, 0);`
4. Si debe verse con el efecto VHS, adjúntalo igual que en `MainMenuState.hx`.
5. Conecta la entrada: en la pantalla que lleva a esta, `FlxG.switchState(new ModState("NombreState"));`
6. Conecta la salida: `controls.BACK` vuelve a la pantalla anterior.
7. Solo si **reemplaza** una pantalla nativa: añade la línea en `data/config/modpack.ini` (`02` §4).
8. Prueba: abre el juego, entra, sal, vuelve a entrar. Anota qué viste.
9. Actualiza la tabla de responsabilidades de `docs/CODING_STANDARDS.md` (sección POO) con una fila nueva.

## Receta B — Script compartido

**Solo si dos pantallas lo necesitan de verdad.** Si no, deja el código inline.

1. Crea `mods/fnf-echoes/scripts/<area>/nombreScript.hx` (`<area>` = `ui`, `effects` o `gameplay`).
2. Escribe funciones sueltas (`function doSomething(arg) { ... }`), sin clases.
3. En cada pantalla que lo use: `Script.create(Paths.script('scripts/<area>/nombreScript'))`, luego `.load()`, luego `.call(...)`.
4. Mueve el código duplicado de las pantallas al script (no lo dejes repetido).
5. Añade el script a la tabla de `02_HSCRIPT_CODENAME.md` §3 y a `docs/CODING_STANDARDS.md`.

## Receta C — Añadir una canción al mod

La estructura real del motor (verificada en `engine/assets/songs/bopeebo/`) es:

```
mods/fnf-echoes/songs/<nombre-cancion>/
├── charts/
│   ├── easy.json
│   ├── normal.json
│   └── hard.json
├── song/
│   ├── Inst.ogg
│   └── Voices.ogg
├── meta.json
└── events.json
```

1. Copia la **estructura** (no el contenido) de `engine/assets/songs/bopeebo/`.
2. Abre `engine/assets/songs/bopeebo/meta.json` y úsalo como plantilla; cambia nombre y BPM (BPM en `00_ESTADO_ACTUAL.md` §3).
3. El audio (`Inst.ogg`, `Voices.ogg`) lo entrega Zyra. **No generes ni descargues audio.**
4. Los charts se hacen con el editor de charts del motor (abriéndolo dentro del juego), no a mano en JSON.
5. Si la canción cambia de BPM entre bloques, eso se marca en el chart (cambio de BPM), no partiendo la canción en dos.
6. Si las voces de cada personaje van en archivos separados, **pregunta primero**: busca cómo lo resuelve el motor (`grep -rn "Voices" engine/source/funkin/backend`) antes de inventar nombres de archivo.

## Receta D — Opción nueva en el menú de opciones

1. Abre `data/states/OptionsState.hx` completo y localiza cómo están definidas las filas existentes.
2. Copia una fila del mismo tipo (interruptor, número, etc.) y cambia solo clave, texto y valor por defecto.
3. Añade la clave y su texto en EN/ES a `scripts/ui/translate.hx`.
4. Verifica dónde se guarda el valor (busca en `OptionsState.hx` cómo guardan las demás filas) y guárdalo igual.
5. Opciones previstas por diseño: **"Reducir destellos"** (fotosensibilidad) y **"Efectos de escritorio"** (privacidad en stream). Pregunta a Zyra el texto exacto.

## Receta E — Guardar un dato entre sesiones (por ejemplo, "ya pasó el crasheo 1")

1. Busca primero cómo guarda datos el mod o el motor: `grep -rn "FlxG.save" engine/source mods/fnf-echoes`.
2. Usa el mismo mecanismo que encuentres, con una clave en inglés con prefijo `echoes` (por ejemplo `echoesCrash1Done`).
3. Asegúrate de forzar el guardado en disco antes de cerrar el juego (busca cómo lo hace el motor: `grep -rn "flush" engine/source`).
4. Prueba en macOS: activar → cerrar → reabrir → comprobar que se leyó. Anota si Windows queda **NO PROBADO**.

## Receta F — Cerrar el juego a propósito (crasheo 1 controlado)

1. **No uses errores reales** para cerrar el juego (nada de lanzar excepciones a propósito).
2. Guarda antes el aviso (Receta E).
3. Busca cómo cierra el juego el propio motor: `grep -rn "exit" engine/source/funkin --include=*.hx`. Usa esa misma vía.
4. Prueba en macOS que el proceso termina por completo (en macOS la app puede quedar en el Dock; comprueba con `pgrep -fl CodenameEngine`).

## Receta G — Cambio que necesita tocar `engine/`

1. **Para.** No edites `engine/` todavía.
2. Explica a Zyra qué necesitas y por qué no se puede con HScript.
3. Escribe o revisa el ADR correspondiente (copia la estructura de `docs/adr/0003-transparencia-de-ventana.md`) y espera aprobación.
4. Si se aprueba: el cambio va en su propia rama y su propia PR, con el ADR enlazado, y dejando claro qué plataforma afecta.

## Receta H — ADR nuevo

1. Número siguiente al último en `docs/adr/` (hoy el último es 0004).
2. Nombre: `NNNN-titulo-en-kebab-case.md`, en español.
3. Secciones: Estado · Fecha · Contexto · Decisión · Opciones consideradas · Consecuencias · Action Items (copia el formato de un ADR existente).
4. Estado inicial: **Proposed**. Solo Zyra lo pasa a **Accepted**.
