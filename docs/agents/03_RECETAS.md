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
4. Los charts se hacen con el editor de charts del motor (abriéndolo dentro del juego), no a mano en JSON. **Cómo se abre (BE-40):** en el menú principal, ya listo (sin intro ni cambio de tema en curso), pulsa **7**: sale el selector de editores del motor; "Chart Editor" lista las canciones y "New song" abre un asistente (nombre, BPM, compás, `Inst`/voces). Al salir (ESC) vuelve al menú sin repetir la intro. Para probar desde un worktree hay que apuntar **dos** enlaces (ver `GIT_WORKFLOW.md` §12).
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

---

## Receta K — Fondos y ventanas en bucle por ambientación ("mood"), sin saltos

Ejemplo vivo: `StoryMapState.hx` (BE-11): cada nodo del selector tiene su fondo abstracto animado y su ventana de mecánicas. Arte generado por `FNF_Echoes_Production/02_Scenes/menú/AI_export_song_mood.py` (privado; solo Pillow).

1. **Un bucle por ambientación, de 64 frames a 10 fps (6,4 s), y todos sincronizados.** Cada ambientación (`soul`, `taro`, `kiyu`, `kiyu_inf`) es una hoja de 4 columnas (`bg_<mood>.png`, frames de 427×240, se muestra ×3) y otra de 8 columnas (`mood_<mood>.png`, la ventana, frames de 132×228). En el estado: `loadGraphic(Paths.image(...), true, ancho, alto)`, `pixelSprite()` y **un solo contador** (`Std.int(time * 10) % 64`) que se asigna a `animation.frameIndex` de todo lo visible. No uses `animation.add`: así el fondo, la ventana y el pulso del ritmo no se desfasan.
2. **Para que el bucle no salte, todo término temporal del arte debe ser periódico** en 128 frames de diseño (frame `i` = diseño `2i`): velocidades angulares múltiplos de 2π/128, rejillas que avanzan un número entero de pasos, y nada que "dé la vuelta" a la pantalla (las brasas y las burbujas recorren una distancia fija y desaparecen; los bokeh se balancean). Se comprueba con la diferencia entre el último y el primer frame frente a la de un paso normal (deben ser parecidas).
3. **Mantén cargadas todas las hojas** (un sprite por ambientación, solo visible la activa y la que se desvanece). Si se recarga una hoja con `loadGraphic` en cada cambio, el decodificado de ~1700×3840 px corta la animación, y Flixel libera el gráfico cuando nadie lo usa. Memoria: 4 fondos (~26 MB cada uno en GPU) + 4 ventanas (~8 MB): ~140 MB. En disco pesan poco (≈4 MB en total: son píxeles tramados).
4. **Cambio de ambientación:** fundido de ~0,28 s del nuevo sobre el antiguo y una sacudida horizontal aleatoria de los fondos durante 0,3 s (el "glitch de cambio de canal"). Los nombres, el color del camino y el puntero, y el trazo a lápiz cambian de golpe. Un nodo bloqueado se muestra con la ambientación apagada con un tinte (`sprite.color`), no con otra hoja.
5. **Icono animado en tiempo de ejecución a partir de poses**, no de una secuencia larga: `zyra_alert.png` (5 poses: mira al frente, al camino, arriba, abajo y el parpadeo `> <`) y `zyra_down.png` (19 poses: mirada × párpado, pupila contraída, reapertura y dos fotogramas de glitch). La lógica corre a 12 pasos por segundo con temporizadores aleatorios, y la respiración se lee del reloj (el sprite baja 1 píxel de pantalla ×3). El mapa de poses está en el comentario de `zyraTick()` y en la cabecera de `AI_export_song_mood.py`.

---

## Receta L — Un tema de escritorio (Vista, XP, Windows 98, Mac) y el cambio de canal

Ejemplo vivo: `MainMenuState.hx` + `scripts/ui/themeManager.hx` + `shaders/ChannelShader.frag` (BE-16). Un **tema** es un paquete de arte: fondo con su barra, botones, carpeta, vinilo y cursor, más sus sonidos. **Lo que nunca cambia** es Zyra y el trazo a lápiz.

1. **Arte** (privado): `AI_export_themes.py` escribe `images/menus/themes/<tema>_wall_es|en.png` (427×240 nativos, se muestran ×3 sin suavizado; hay un fondo por idioma porque la barra lleva palabras), `<tema>_buttons.png` (25 celdas de 322×166: 1 normal + 24 del brillo), `<tema>_folder.png`, `<tema>_vinyl.png` (24 frames de 300×300), `<tema>_cursor.png` y los lápices compartidos `pencil_button_0/1/2.png`, `pencil_folder.png`. `AI_export_theme_sounds.py` escribe `sounds/themes/` (`channel_change` y, por tema, `hover`, `confirm` y `arrive`; el `ffmpeg` de este Mac no trae `libvorbis`, se usa su Vorbis nativo).
2. **Dos cámaras:** la cámara por defecto dibuja lo temático (fondo, botones, etiquetas, carpeta, vinilo) y recibe el shader solo mientras dura un cambio; `topCam` (`new FlxCamera()` con `bgColor = 0x00000000`, añadida con `FlxG.cameras.add(topCam, false)`) dibuja encima los lápices, Zyra y las notas, así que el glitch nunca los toca. Cada sprite de `topCam` lleva `sprite.cameras = [topCam]`. Los lápices siguen a su elemento copiando posición y escala cada frame (`syncPencils()`).
3. **El cambio** (`changeTheme()`, unos 1,7 s: tiempos en la propia función): los botones se cierran como un CRT → el fondo pierde la señal (desgarros, división RGB, nieve) y se funde al blanco real de Zyra → con la pantalla blanca se cambian todas las pieles (`applyThemeArt()`) → llega el fondo nuevo con la firma de su sistema (Vista: floración con un destello; XP: repintado desde arriba con pocos colores primero; 98: mosaico de baldosas de 16 colores; Mac: onda desde el centro), con el glitch apagándose y un golpe de llegada (destello blanco, sacudida y zoom de la cámara temática; la de Zyra y el lápiz no se mueve) → entran los elementos de la interfaz uno tras otro, cada uno con una ráfaga de glitch, cada uno a su manera (Vista se hincha, XP entra deslizándose, 98 a saltos como una ventana arrastrada, Mac sale de una esquina como un genio). Todos los parámetros del shader son uniforms que se animan con `FlxTween.tween(themeParams, ...)`.
4. **Reglas** (`themeManager.hx`): el tema de cada canción es `themeBySong` (**provisional**); una pantalla pide un cambio con `requestForSong(i)` y el menú lo reproduce al abrirse. Se respetan los ajustes: "Cambios de fondo" apagado = nunca cambia; "Reducir destellos" = fundido suave sin desgarros, nieve ni destellos. **F4** pasa al siguiente tema (atajo de prueba).
5. **Cursor:** `FlxG.mouse.load(imagen, 1, 0, 0)` al aplicar el tema.
6. **Cuándo cambia** (BE-27/BE-28): al completar una canción (`requestForSong`), en cada transición de menú (`diffusionTransition.hx`, receta M) y **solo, cada 18-40 s, mientras estás en el menú** (`updateAutoChange()`). Una ventana encima del menú (Ajustes) también sufre el cambio: su cámara es transparente y el shader del fondo pinta alfa 1, así que usa `shaders/ChannelFx.frag` (conserva el alfa) con los valores vivos que el menú expone en `channelParams()` (`FlxG.state.call(...)` desde el subestado).
7. **Elección de la persona** (BE-29): Ajustes > Pantalla > Fondo del escritorio (AUTO o un tema fijo, `echoesThemeChoice`). Un tema elegido hace que `current()` devuelva siempre ese y `changesEnabled()` sea falso; el menú lo aplica al momento con `chooseTheme()`.
8. **Ventanas por tema** (BE-30): el marco de las ventanas de Echo y del selector de canciones sigue el tema. Un archivo por tema con prefijo (`<tema>_echo_*`, `<tema>_mood_*`, `refl_<tema>_*`); el estado lee `themer.call("current")` al crearse. Para añadir un tema: su función de marco en `AI_build_window_themes.py` y volver a ejecutar `AI_export_window_themes.py` y `AI_export_echo_bg.py`.
9. **La ventana de Ajustes** (BE-31) también sigue el tema: `images/menus/options/<tema>_window.png` (mismo tamaño y rectángulos que la de Vista) y cambia en vivo si el menú cambia de tema con ella abierta (`FlxG.save.data.echoesShownTheme`, trampa nº 27).

## Receta M — Una transición entre pantallas propia (script del motor)

Ejemplo real: `scripts/effects/diffusionTransition.hx` (BE-24, "Difusión").

1. El motor abre una `MusicBeatTransition` en la pantalla que se deja (`event.newState != null`) y otra en la que llega (`newState == null`). Su script recibe `create(event)`, `update(elapsed)`, `onFinish(event)`... y se pone con `MusicBeatTransition.script = '...'` (trampa nº 25).
2. En `create(event)`: decide si te toca (p. ej. solo si el destino es un menú; si no, `return` sin cancelar y corre la transición normal del motor), `event.cancel()` para que no corra el barrido negro, y dibuja con `add(...)` (la cámara de la transición ya está puesta). Para acabar llama a `finish()`: en la mitad que sale cambia de estado, en la que llega cierra.
3. Haz **una sola línea de tiempo determinista** (`showFrame(f)` que pinta el mismo cuadro sea cual sea la mitad que la llama) y que la mitad que llega continúe en el cuadro donde se quedó la que salió. Así el estado nuevo se carga escondido bajo la pantalla cubierta.
4. El destino: `ModState.lastName` es el nombre del último `ModState` creado (si `Type.getClassName(Type.getClass(state))` es `funkin.backend.scripting.ModState`); una canción (`PlayState`) no es `ModState`.
5. El arte se hornea en Python (`AI_export_diffusion.py`, carpeta de arte privada) a `images/menus/diffusion/`. El texto de consola usa `vcr.ttf` (monoespaciada: la columna decide la x) y un `FlxText` por trozo de color.

## Receta N — Nota mortal (`Deadly Note`) y cómo probar un chart

Boceto de BE-42: `mods/fnf-echoes/data/notes/Deadly Note.hx` (tipo de nota con script; ejemplos del motor en `engine/assets/data/notes/`).

1. En el editor de charts elige el tipo en *Note > Note Types List* y coloca la nota; el chart lo guarda en `noteTypes`.
2. Se ve en rojo; Botplay no la toca (`avoid`). **Si la tocas mueres** (`PlayState.instance.health = 0`); **si la dejas pasar no cuesta nada** (el fallo se cancela con `event.cancel()` y la nota se borra con `strumLine.deleteNote`; sin ese borrado se quedaría atascada).
3. **Probar un chart:** en el editor, **Enter** lanza el *playtest* desde la posición actual y **ESC** vuelve al editor.
4. Probado en macOS con una canción de prueba (3 notas mortales y una normal): dejarlas pasar no suma fallos; pulsar las cuatro teclas sin parar lleva al game over. Falta: arte final, sonido, animación de muerte y variantes.


## Receta V — Las flechas de Zyra dentro de la escena: plano 3D, Zyra por delante y el brazo alzado (BE-57, BE-56)

`songs/limboScene.hx` (solo Limbo) + `shaders/PlaneWarp.frag` + `images/characters/zyra_arm/` (el brazo suelto de la pose 3). Depende del personaje `zyra` de DS-2 (Receta U).

1. **Primera toma (juego de cuadros 0, la `Camera` de Blender).** La fila de Zyra (línea 1) la dibuja el motor como siempre, pero en **su propia cámara** (una `HudCamera`, así el downscroll sigue funcionando) y un shader de cámara pega esa imagen plana sobre un **plano 3D** de la escena: para cada píxel rehace el rayo de la cámara real de Blender (posición, ejes y focal; los mismos datos que `mist.hx`), busca dónde toca el plano y lee la fila en ese punto. Es una deformación de perspectiva verdadera (escorzo, convergencia a un punto de fuga, notas largas que se inclinan), no sprites movidos uno a uno (esa primera versión no daba profundidad y además costaba 200 ms por cuadro: el chart tiene ~700 notas vivas desde el principio). Valores que dejó Zyra con las teclas: x 0,44, profundidad 0,13, altura 0,3, giro 24,77°, inclinación 0, separación 0,59 (`PLANE_*`, `LANE_SPACING`).
2. **Las otras tomas:** la fila va plana por la misma cámara y el shader solo la achica (`FLAT_SCALE`) y la baja (`FLAT_DOWN`).
3. **La cámara de las flechas es `EXTRA_PX` (900) píxeles más alta que la pantalla** y empieza por encima de ella en downscroll: así las notas ya existen cuando cruzan el borde de arriba y no "nacen" a mitad de pantalla al achicar o bajar la fila. El shader convierte entre píxeles de pantalla y de esa cámara (`camSize`, `camOffset`).
4. **Zyra por encima de las flechas en la primera toma:** su personaje pasa a una cámara extra sobre la de las flechas que copia el scroll y el zoom de la del juego cada cuadro. En la pose 3 el cuerpo queda debajo y el **brazo suelto** (mismo cuadro y animación) por encima.
5. **El principio:** la canción empieza negra (Zyra y la barra de vida ocultas, las flechas no) y se revelan en 2,5 s; la fila de Soul no se ve hasta 2 s antes de su primera nota.
6. **Los efectos que se dibujan sobre la fila** (`splashHandler`, el efecto de las notas largas de `noteskin.hx`) tienen que ir en la **misma cámara** que la fila: la cámara de un strum suelto no vale (devuelve la de por defecto); se usa la del grupo (`strumLines.members[1].cameras[0]`).
7. **Trampas:** un shader o archivo nuevo **no se ve con el juego abierto** (hay que cerrarlo y abrirlo) y tiene que existir también en la carpeta del mod que se esté usando; `FlxG.cameras.add` con una `HudCamera` tallada con `setSize` y `y` negativo es la forma de dar margen; el espejo del downscroll es `y' = altura - y - alto - offset.y + origin.y`.
8. **Ajuste en vivo** (`TUNE = true`): en la primera toma Z X, C V, `,` `.`, G H, U I y B N mueven el plano; en las otras B N y `,` `.` cambian la fila plana; los números salen arriba a la izquierda. Ponlo en `false` para quitarlo.
9. **Entrada de la primera toma (2026-10-18):** la fila entra deslizándose **de izquierda a derecha** (empieza con su centro a un cuarto de la pantalla, `SLIDE_IN` = 1,6 m a lo largo de la fila) y aterriza donde estaba cuando Zyra termina de aparecer (2,5 s, `REVEAL_MS`); la luz de las flechas que publica para el agua se mueve con ella. Las **receptoras** tienen opacidad completa (se anula el fundido del motor) y se descubren con **glitch** de opacidad, una a una (`introGlitch`); mientras son transparentes **brillan con las notas de su propia fila** (`GLOW_PEAK`, `GLOW_LEAD_MS`); y un 25 % de las primeras notas (`TREMBLE_SHARE`, hasta `TREMBLE_END_MS`) tiembla solo en opacidad.
10. **Sin latigazo de cámara en los cortes** (`WHIP_ON = false`: Zyra pidió quitarlo porque no daba continuidad; `true` lo devuelve). El reflejo de las flechas en el suelo va en gris (`MIRROR_TINT`), como el agua de BE-54. El velo ASCII queda apagado (`ASCII_ON = false`; `AsciiVeil.frag` y `images/game/ascii` se conservan).
11. **NO PROBADO:** Windows, el rendimiento en equipos lentos (la cámara de 1280×1620 y el shader por píxel), el brazo sobre las notas con el chart real hasta el final, y las tomas 1 y 2 con la fila plana más allá de lo que Zyra vio.

## Receta T — La neblina de Limbo y el reflejo de agua (BE-54)

Script compartido `mods/fnf-echoes/scripts/effects/mist.hx` + dos shaders (`shaders/MistFog.frag`, `shaders/WaterReflect.frag`). Sala de pruebas: `data/states/MistTestState.hx` (tecla **9** del menú principal; las teclas están en el comentario de arriba del archivo).

1. **Orden de las llamadas** (es el orden de dibujado): `setView(cámara, anchorX, anchorY, escala)`, `createReflection(personaje, null)`, `createBack(null)`, el estado añade al personaje, `createFront(null)`. Cada frame: `update(elapsed)`. Después: `setLight(color, nivel, x, y, radio)`, `flash(n)` (un recuerdo que se enciende), `pulse(n)` (la niebla respira con un golpe), `push(fuerza, segundos)` (el claro alrededor de Zyra se ensancha: su cambio de pose), `setDensity`, `setQuality` (3 a 8 pasos por rayo: es la perilla entre aspecto y rendimiento), `setGlitch`, `setReflection(opacidad, hueco)`.
2. **La niebla vive en el espacio 3D de la cámara de Blender.** `CAMERAS` guarda posición, ejes y focal en píxeles de cada cámara (leídos de `test.blend`; se calculan con `matrix_world` y `lens / sensor_width * 1920`); el shader reconstruye el rayo de cada píxel y lo recorre por una capa de niebla sobre el suelo. Por eso hay que pasar la misma **escala del sprite** de Zyra y el punto del juego donde pisa (`anchorX/anchorY`); `setReflection(..., hueco)` mueve la línea del suelo de la niebla y del reflejo juntas (el contacto real de los pies queda unos píxeles por encima del borde inferior del sprite). Cada cámara lleva su altura de niebla (`top`): tiene que quedar **por debajo** de la cámara o la niebla se vuelve una pared gris.
3. **Aspecto acordado con Zyra:** gris oscuro, escasa y desolada (grandes bancos que se mueven despacio y mucho negro entre ellos), aire limpio cerca de la cámara, **sin niebla pegada a Zyra** (claro de `CLEAR_R` metros que se abre con `push`), viento con ráfagas, cizalla (arriba va más rápido) y oleadas hacia la cámara; la luz es un punto 3D que se dispersa hacia delante y Zyra proyecta una sombra volumétrica en la niebla iluminada.
4. **Reflejo:** copia volteada de Zyra con ondas, brillo y degradado, y glitch en ráfagas. El degradado lo hace el shader; **solo se ve bien sobre suelo negro**.
5. **Trampas del shader:** los uniformes `float` solo aceptan `Float` (un `1` en vez de `1.0` lanza `ShaderTypeException`); `smoothstep` con el borde de abajo mayor que el de arriba no es portable (se escribe `1.0 - smoothstep(a, b, x)`); no llames a una variable `patch` (reservada); los uniformes vectoriales se pasan como `[x, y, z]` de `Float`; el rectángulo de cada fotograma del atlas se manda al shader del reflejo cada frame (`frame.uv`).
6. **Probado (macOS):** Zyra lo vio en el juego con `Camera` y `Camera.002`; el registro no mostró errores de shader. **NO PROBADO:** rendimiento en equipos lentos (calcula 3D por píxel: bajar `setQuality`), Windows, el reflejo con los sprites de la pose 3 (DS-2) y la niebla en una canción real.

## Receta X — El agua de Limbo: suelo transparente con anillos de lápiz (BE-54)

En Limbo **el agua sustituye a la neblina** (el código de la neblina sigue en `mist.hx` y `MistFog.frag` por si vuelve). `songs/limboMist.hx` crea el agua con `scripts/effects/mist.hx` y `shaders/WaterSurface.frag`.

1. **Qué es:** un suelo **transparente** (sin cuerpo: donde el agua está lisa se ve el negro) en el mismo espacio 3D de la cámara de Blender que Zyra y las flechas. Solo se dibuja: (a) **anillos de lápiz** (líneas finas, pálidas, algo cortadas) que nacen solos por el suelo, salen de los pies de Zyra cada pocos segundos (uno grande al empezar el cambio de pose) y de la flecha que se acierta (en su color, tirando a gris); (b) un poco de **brillo fino** de la luz sobre algunos parches de ondas. Todo en **gris oscuro**. Zyra lleva las botas un poco hundidas (`WATER_SINK`, en metros) con una línea de agua sobre ellas. El reflejo de Zyra (`WaterReflect.frag`) solo se ve a través de las ondas (`REFL_PATCH`, 0 = espejo entero).
2. **Dos capas, como la neblina:** `createWaterBack` (detrás de Zyra, antes de ella en el orden de dibujo) y `createWaterFront` (delante, con la franja de las botas). `setWaterAmount(a)` la revela del negro en los primeros 2,5 s, igual que Zyra.
3. **Cámara por tiro:** `setStageView(nombre)` con la cámara del plano. **En el cambio de pose** el agua conserva la `Camera.002` hasta el cuadro 10 de la animación (donde el render corta a `Camera.003`) y luego se desvanece en `WATER_FADE_S` (1 s); no desaparece de golpe.
4. **Flechas:** `limboScene.hx` (BE-57) publica en `FlxG.save.data.echoesArrowLights` dónde están las receptoras; `hitLane(lane)` deja un anillo ahí. Sin BE-57 el agua funciona igual, solo sin los anillos de las flechas.
5. **Perillas:** `mist.hx` (`WATER_*`, `REFL_*`), `limboMist.hx` (`REFLECTION_ALPHA`, `LIGHT_COLOR`, `WATER_FADE_S`) y las constantes de `WaterSurface.frag` (parches, grosor de las líneas, destellos).
6. **NO PROBADO:** rendimiento en equipos lentos, Windows, y el aspecto con el fondo real (todo lo visto de la imagen fue un cálculo fuera del juego, aprobado por Zyra a ojo en el juego en macOS). Trampa: archivos nuevos (shaders) solo los ve el juego tras reiniciarlo.

---

## Receta S — La noteskin de Zyra (BE-52): flechas, receptoras, splash y notas largas

La fila de Zyra (strum line 1) usa su propio aspecto; la de Soul conserva el del motor hasta que tenga el suyo. Todo vive en el mod, sin tocar `engine/`.

1. **Atlas de notas y receptoras:** `images/game/notes/zyra.png` + `zyra.xml`, con los nombres que espera el motor (`purple0000`, `arrowLEFT0000`, `left press0000`, `left confirm0000`..`0003`, `purple hold piece0000`, `purple hold end0000`...). Cuatro direcciones: left=purple, down=blue, up=green, right=red. Los marcos miden ~156 px, como el atlas del motor, así que no hay que tocar escalas.
2. **Splash del acierto:** `images/game/splashes/zyra.png` + `data/splashes/zyra.xml` (formato del motor: `<splashes sprite=... alpha=...>` con un `<strum id>` por dirección y su `<anim anim="prefijo del atlas">`).
3. **Script de canción `songs/noteskin.hx`** (vale para todas): `onStrumCreation` cambia el sprite de las receptoras de la fila 1; `onNoteCreation` cambia el sprite de las notas y pone `note.splash = "zyra"`; `KEEP_ENGINE_SKIN` es la lista de tipos de nota que conservan el aspecto del motor (vacía: para las notas de Soul que se cuelan en la fila de Zyra, lo decide ella).
4. **Efecto de nota larga** (dibujado por el script con `images/game/holdfx/ring.png` y `sliver.png`, blancas y teñidas por dirección): mientras llegan piezas de una nota larga (`onPlayerHit` con `isSustainNote`), un anillo fino late cada 0,25 s y unas astillas suben hacia la receptora; al soltar sale un anillo y unas astillas. **Trampa:** en downscroll la `HudCamera` refleja las **posiciones** pero no voltea los sprites, así que en coordenadas el cuerpo de la nota está siempre en +y; no inviertas la dirección a mano.
5. **Cómo se regenera:** el arte se hornea con `AI_export_noteskin.py` (carpeta de producción, privada) a partir de las flechas simples que dibujó Zyra. **Ojo:** esas flechas están rehechas limpias desde una captura con el cuadriculado incluido; hay que sustituirlas por sus PNG con transparencia real.
6. **Probar:** abre Limbo desde el selector (ENTER en el nodo, y ENTER en el editor para el playtest). NO PROBADO: otras canciones, juego con las dos filas llenas de notas y Windows.

