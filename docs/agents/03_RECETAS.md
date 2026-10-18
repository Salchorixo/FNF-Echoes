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


## Receta T — La neblina de Limbo y el reflejo de agua (BE-54)

Script compartido `mods/fnf-echoes/scripts/effects/mist.hx` + dos shaders (`shaders/MistFog.frag`, `shaders/WaterReflect.frag`). Sala de pruebas: `data/states/MistTestState.hx` (tecla **9** del menú principal; las teclas están en el comentario de arriba del archivo).

1. **Orden de las llamadas** (es el orden de dibujado): `setView(cámara, anchorX, anchorY, escala)`, `createReflection(personaje, null)`, `createBack(null)`, el estado añade al personaje, `createFront(null)`. Cada frame: `update(elapsed)`. Después: `setLight(color, nivel, x, y, radio)`, `flash(n)` (un recuerdo que se enciende), `pulse(n)` (la niebla respira con un golpe), `push(fuerza, segundos)` (el claro alrededor de Zyra se ensancha: su cambio de pose), `setDensity`, `setQuality` (3 a 8 pasos por rayo: es la perilla entre aspecto y rendimiento), `setGlitch`, `setReflection(opacidad, hueco)`.
2. **La niebla vive en el espacio 3D de la cámara de Blender.** `CAMERAS` guarda posición, ejes y focal en píxeles de cada cámara (leídos de `test.blend`; se calculan con `matrix_world` y `lens / sensor_width * 1920`); el shader reconstruye el rayo de cada píxel y lo recorre por una capa de niebla sobre el suelo. Por eso hay que pasar la misma **escala del sprite** de Zyra y el punto del juego donde pisa (`anchorX/anchorY`); `setReflection(..., hueco)` mueve la línea del suelo de la niebla y del reflejo juntas (el contacto real de los pies queda unos píxeles por encima del borde inferior del sprite). Cada cámara lleva su altura de niebla (`top`): tiene que quedar **por debajo** de la cámara o la niebla se vuelve una pared gris.
3. **Aspecto acordado con Zyra:** gris oscuro, escasa y desolada (grandes bancos que se mueven despacio y mucho negro entre ellos), aire limpio cerca de la cámara, **sin niebla pegada a Zyra** (claro de `CLEAR_R` metros que se abre con `push`), viento con ráfagas, cizalla (arriba va más rápido) y oleadas hacia la cámara; la luz es un punto 3D que se dispersa hacia delante y Zyra proyecta una sombra volumétrica en la niebla iluminada.
4. **Reflejo:** copia volteada de Zyra con ondas, brillo y degradado, y glitch en ráfagas. El degradado lo hace el shader; **solo se ve bien sobre suelo negro**.
5. **Trampas del shader:** los uniformes `float` solo aceptan `Float` (un `1` en vez de `1.0` lanza `ShaderTypeException`); `smoothstep` con el borde de abajo mayor que el de arriba no es portable (se escribe `1.0 - smoothstep(a, b, x)`); no llames a una variable `patch` (reservada); los uniformes vectoriales se pasan como `[x, y, z]` de `Float`; el rectángulo de cada fotograma del atlas se manda al shader del reflejo cada frame (`frame.uv`).
6. **Probado (macOS):** Zyra lo vio en el juego con `Camera` y `Camera.002`; el registro no mostró errores de shader. **NO PROBADO:** rendimiento en equipos lentos (calcula 3D por píxel: bajar `setQuality`), Windows, el reflejo con los sprites de la pose 3 (DS-2) y la niebla en una canción real.
