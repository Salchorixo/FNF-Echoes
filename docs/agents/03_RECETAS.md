# 03 — Recetas paso a paso

Cada receta es una lista cerrada. Síguela en orden. Si un paso no se cumple
(un archivo no existe, un nombre no coincide), **para y anótalo en el relevo**.

---

## Receta A — Pantalla nueva (estado)

1. Abre `data/states/MainMenuState.hx` (animación dibujada, UI en sprites, partículas, ratón y foco) y `data/states/EchoSelectState.hx` (sprites de pixel art animados, selección con elevación, ventana bloqueada que tiembla) y léelos completos: son los modelos.
2. Crea `mods/fnf-echoes/data/states/NombreState.hx` con el esqueleto de `02_HSCRIPT_CODENAME.md` §2.
3. Primera línea de `create()`: `FlxG.camera.scroll.set(0, 0);`
4. Si debe verse con el efecto VHS, adjúntalo con el bloque `vhsFx` de `02_HSCRIPT_CODENAME.md` §2. (El menú principal y la selección de Echo **no** lo llevan, por decisión de Zyra: sin curvatura ni filtros por ahora.)
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

1. Número siguiente al último en `docs/adr/` (hoy el último es 0003).
2. Nombre: `NNNN-titulo-en-kebab-case.md`, en español.
3. Secciones: Estado · Fecha · Contexto · Decisión · Opciones consideradas · Consecuencias · Action Items (copia el formato de un ADR existente).
4. Estado inicial: **Proposed**. Solo Zyra lo pasa a **Accepted**.

## Receta I — Que el juego mueva su propia ventana (Zyra la lanza desde dentro)

Historia: Zyra está dentro de la ventana como en una celda; al golpear la pared interior izquierda, la ventana sale lanzada a la izquierda, se estrella contra el borde de la pantalla y vuelve al centro; luego el golpe del otro lado (y al revés con la derecha). Ejemplo vivo: `mods/fnf-echoes/data/states/WindowChoreographyTestState.hx` (Zyra es un cuadrado de relleno hasta que haya arte) + `scripts/effects/windowFx.hx`. Solo HScript, no toca `engine/`.

División de trabajo: **el estado decide cuándo golpea Zyra** (su animación, dentro del juego); `windowFx` hace lo que la ventana hace con ese golpe.

1. En tu estado: `fx = Script.create(Paths.script('scripts/effects/windowFx')); fx.load();`.
2. **Llama `fx.call("update", [elapsed])` en cada `update()`** (los scripts compartidos no se actualizan solos) y `fx.call("restore")` en `destroy()` y al salir con ESC.
3. Con transparencia: `fx.call("setTransparent", [true])` (la reaplica tras cada cambio de modo; en Windows no se reaplica sola).
4. `fx.call("begin")`: sale de pantalla completa, dimensiona y centra → fase `ready`.
5. En el fotograma del golpe de Zyra: `fx.call("launch", [lado, segundos, ease, overshoot, hitstop])` (`lado` = `"left"`/`"right"`). Fases: `hitstop` (un instante congelado con un temblor mínimo) → `flying` (explosivo) → `impact` (temblor hacia dentro, decae) → `settling` → `recentering` (la ventana vuelve al centro de la pantalla) → `ready`. Vuelve a lanzar cuando la fase sea `ready` otra vez.
6. `fx.call("finish")`: vuelve a pantalla completa → fase `done`.
7. `popHits()` entrega un registro por choque: `[lado, hueco, número, velocidadDeImpacto]`.

**Curva y fuerza.**
- `ease`: `expoOut`, `quintOut`, `quartOut`, `cubeOut`, `quadOut`, `sineOut`, `circOut`, `linear`, `quadIn`, `cubeIn`, `expoIn`, `sineInOut`, `quadInOut` (lista en `easeFn()` de `windowFx.hx`). Las `...Out` salen a toda velocidad = explosivo.
- `overshoot` (p. ej. 0.4): un ease `...Out` acaba a velocidad 0, pero un golpe debe chocar **rápido**. La curva apunta a un destino virtual pasado el borde (`distancia × (1 + overshoot)`) y el borde de la pantalla la corta aún en movimiento. `0` = llega despacio.
- `fx.call("setRecenter", [segundos, ease])` cambia el regreso al centro (por defecto 0,8 s y `cubeInOut`). Todos los golpes salen del centro, así que recorren la misma distancia.
- El temblor del impacto y del hitstop escalan con el ancho de la pantalla y con la velocidad de impacto.

**Resolución.** No hay nada fijo: lee `window.display.bounds`, da a la ventana la proporción del juego (≤50 % del ancho y ≤70 % del alto del monitor) y la velocidad sale de la curva sobre la distancia real. `setVirtualScreen(w, h)` simula otra pantalla (solo prueba la matemática; no el SO).

**Trampas.** Cada cambio de modo es asíncrono: el script espera (0,9 s al salir, 0,5 s tras redimensionar, 1,0 s al entrar) en vez de leer `window.*` enseguida. La ventana nunca sale de la pantalla (el temblor está recortado a los bordes). Para no fiarse solo de `window.x`, mide desde fuera: en macOS, `CGWindowListCopyWindowInfo` por PID da la posición real.

## Receta J — Meter una animación dibujada (secuencia con alfa) en un estado

Ejemplo vivo: `createSketch()` en `data/states/MainMenuState.hx` (Zyra en su sofá). El vídeo del motor (hxvlc) **no lee alfa**, así que una animación sobre fondo transparente va como atlas de imágenes, no como mp4.

1. Los frames salen de Blender como PNG RGBA (1920×1080, numerados). El empaquetador **vive fuera del repo** (arte privado): `FNF_Echoes_Production/02_Scenes/menú/main menu/AI_pack_atlas.py <carpeta_renders> <salida> [ancho]` (solo Pillow). El menú principal se empaqueta con `1280` (720p); sin ancho conserva 1920×1080. Recorta cada frame a su caja opaca (Sparrow guarda `frameX/frameY` y el lienzo completo) y los reparte en páginas de máx. 4096×4096.
2. La salida va a `mods/fnf-echoes/images/<ruta>/1.png`, `1.xml`, `2.png`, `2.xml`… (convención multi-spritesheet del motor: `Paths.getFrames('<ruta>')` junta todas las páginas). Los frames se llaman `m_0000`… con el **número de frame del render**.
3. En el estado: `spr.frames = Paths.getFrames('<ruta>')`, luego `spr.animation.addByIndices('intro', 'm_', [indices], '', fps, false)` y otra `loop` con `true`. Encadena: `spr.animation.onFinish.add((n) -> if (n == 'intro') spr.animation.play('loop'))`.
4. Escala el sprite a la pantalla (`setGraphicSize(FlxG.width)`, `updateHitbox()`, posición 0,0): así cada frame conserva su sitio.
5. Para sincronizar algo con un fotograma (música, partículas) usa `spr.animation.onFrameChange.add((nombre, nFrame, _) -> ...)` con `>=`, no `==`, por si se salta un frame.
6. **Coste:** el atlas del menú principal (276 frames, v5) a 720p son ~36 MB en disco y ~240 MB de memoria de vídeo (5 páginas). A 1080p (con la v2) eran ~86 MB y ~800 MB (12 páginas). WebP no sirve: el motor solo lee PNG y JPG, y no baja la memoria de vídeo. Si hiciera falta aún menos: quitar el segundo frame de cada par (la pose va "a pasos de 2"; solo cambia el temblor del rayado).
