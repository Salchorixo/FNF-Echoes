# 04 — Trampas conocidas

Problemas que **ya costaron tiempo**. Si algo "raro" pasa, búscalo aquí antes
de investigar desde cero. Si descubres una trampa nueva, **añádela aquí** con el
mismo formato: síntoma → causa → qué hacer.

---

### 1. El script global del mod nunca se ejecuta
- **Síntoma:** código en `data/global/LIB_<mod>.hx` (hook `postStateSwitch`) no hace nada, sin error.
- **Causa:** sin diagnosticar (ver `docs/PROJECT_STRUCTURE.md`, regla 7).
- **Qué hacer:** no lo uses. El shader VHS se adjunta en el `create()` de cada pantalla.

### 2. La pantalla aparece desplazada hacia un lado
- **Síntoma:** al entrar a una pantalla, todo está corrido a la izquierda o a la derecha.
- **Causa:** `cardMenu.hx` mueve la cámara según la tarjeta elegida y no la resetea al salir.
- **Qué hacer:** primera línea del `create()` de cada pantalla: `FlxG.camera.scroll.set(0, 0);`

### 3. `import` de otro archivo del mod no funciona
- **Síntoma:** error de clase no encontrada al importar un script propio.
- **Causa:** el contenido del mod es HScript interpretado; no pasa por el compilador de Haxe.
- **Qué hacer:** usa `Script.create(...)` + `.load()` + `.call(...)` (ver `02_HSCRIPT_CODENAME.md` §3).

### 4. Llamar a un script compartido no hace nada
- **Síntoma:** `.call(...)` no devuelve nada o no tiene efecto.
- **Causa probable:** faltó `.load()` después de `Script.create(...)`, o el nombre de la función o los argumentos no coinciden.
- **Qué hacer:** copia exactamente el patrón de `MainMenuState.hx` y abre el script para confirmar el nombre de la función.

### 5. Los cambios del mod no aparecen en el juego
- **Causa:** el juego compilado busca `mods/` **junto a su ejecutable** (`CodenameEngine.app/Contents/Resources/mods/` en macOS), no en la raíz del repo.
- **Qué hacer:** comprueba que existe el enlace simbólico de `mods/fnf-echoes/` hacia esa ruta (ver `docs/PROJECT_STRUCTURE.md`, regla 6). Cierra y vuelve a abrir el juego.

### 6. No existe `meta.json` del mod
- **Causa:** Codename Engine no lee metadata de mods. El nombre se declara en `data/config/modpack.ini` → `[Common] NAME=`.
- **Ojo:** `songs/<cancion>/meta.json` **sí** existe, pero es otra cosa (metadata de canción).

### 7. Los charts van dentro de la carpeta de cada canción
- **La estructura real del motor** es `songs/<cancion>/charts/*.json` y `songs/<cancion>/song/Inst.ogg` (verificada en `engine/assets/songs/bopeebo/`). Versiones antiguas de `PROJECT_STRUCTURE.md` mostraban una carpeta `charts/` aparte: ya está corregido. Ver `03_RECETAS.md`, Receta C.

### 8. Compilar en macOS Apple Silicon falla al cargar `lime.ndll`
- **Causa:** el `lime.ndll` que trae el motor es solo x86_64.
- **Qué hacer:** **no improvises.** La solución (lime 8.2.0 + 3 parches + copiar el `.ndll` a dos rutas) está en el ADR-0001, "Receta completa". Si no tienes esa preparación hecha, para y avisa.

### 9. Crash de HarfBuzz/FreeType al arrancar (`Assertion failed ... hb-buffer.hh`)
- **Causa y solución:** ADR-0001, sección "Diagnóstico del crash de HarfBuzz". No desactives `LIME_HARFBUZZ` entero: el juego se cuelga.

### 10. `transparent="true"` en `project.xml` no hace la ventana transparente
- **Causa:** por sí solo no basta. En macOS hacen falta cuatro cosas a la vez (limpiar OpenFL a alfa 0 con `FlxG.stage.color = null`, `camera.bgColor` alfa 0, ventana y superficie GL no opacas y capas de AppKit sin fondo opaco). La explicación antigua del ADR-0003 (el C++ de lime) era incorrecta.
- **Qué hacer:** usa el patrón de `mods/fnf-echoes/data/states/TransparencyTestState.hx`: `FlxG.stage.color = null`, `FlxG.camera.bgColor = 0x00000000` y `NativeAPI.setWindowTransparent(true)`. Detalles y por qué en el ADR-0003, "Actualización 2026-10-03". Windows: ver nº 17. Cuidado con el shader VHS (nº 16).

### 11. Traducir "ECHOES"
- **Regla fija:** "ECHOES" y "ECHO" no pasan nunca por `translate.hx`. Se quedan en inglés.

### 12. Confundir al autor con el personaje
- **Zyra (personaje):** gatito negro, **macho** → siempre "él", "he/his" en inglés. En los prompts de Suno, nunca "she/her" (eso cambia la voz generada).
- **Zyra / Salchorizo (autor):** la persona que hace el mod.

### 13. Documentos viejos sobre voces
- Los documentos del antiguo pipeline de voces ya no existen (se eliminaron el 2026-10-09; ahora las voces son de Suno). Si encuentras una referencia a ellos, ignórala.

### 14. La pantalla completa nativa en macOS impide la transparencia
- **Síntoma:** al pasar a pantalla completa el escritorio "se va a la derecha" y, aunque la transparencia esté activa, la ventana se ve negra.
- **Causa:** la pantalla completa nativa de macOS crea un **Space propio**, siempre opaco y sin escritorio detrás.
- **Qué hace ya el motor (parche de BE-7):** la bloquea en todas las ventanas y fija `SDL_VIDEO_MAC_FULLSCREEN_SPACES=0`, así que `FlxG.fullscreen`, Alt+Enter y Ctrl+Cmd+F dan una ventana sin bordes del tamaño del escritorio, **sin Space**, donde la transparencia funciona. No hace falta código especial en el mod.
- **Qué NO hacer:** no recoloques la ventana a mano (`window.x/y/width/height`, `borderless`) como parche para arreglar el fullscreen: Stage Manager y AppKit la reubican y queda a medias. **Excepción deliberada:** la coreografía de ventana (`scripts/effects/windowFx.hx`, Receta I) sí mueve y redimensiona la ventana a propósito, siempre desde modo ventana y terminando en pantalla completa; en macOS 27.2 (Apple Silicon, sin escalado) las posiciones pedidas coincidieron con las que ve el SO, y en Windows (VM, escala 100 %) los 8 choques dieron hueco 0. Stage Manager y escalado 125/150 % en Windows: NO PROBADO. No dependas de `window.fullscreen` leído justo después de cambiarlo.
- **Regla obligatoria (`AGENTS.md` §0.11):** el juego se abre en ventana. `TitleState.hx` ya no pide pantalla completa (decisión de Zyra, 2026-10-13, BE-18): el juego arranca en ventana.

### 15. En modo `cne test` el motor busca los mods en `engine/mods/`, no en el `.app`
- **Síntoma:** el juego arranca con el menú de Story Mode de siempre; en el log sale `Mod "fnf-echoes" not found in mods list, switching to base game!` y el botón `DISABLE MODS` aparece solo.
- **Causa:** el `.app` está compilado con `-DTEST_BUILD` (`cne build`/`lime test`). En ese modo `ModsFolder.modsPath` es `./<pathBack>mods/`, que resuelve a `engine/mods/`, y la carpeta solo trae un `readme.txt`. El enlace de `Contents/Resources/mods` no se usa para la lista de mods.
- **Qué hacer (ajuste local, no se versiona):** `ln -s ../../mods/fnf-echoes engine/mods/fnf-echoes`. El submódulo no se ensucia porque su `.gitignore` ignora `mods/*`. Para ver el log al abrir: `open -n --stdout LOG --stderr LOG <app>`.

### 16. El shader VHS anula la transparencia
- **Causa:** `VHSShader.frag` termina en `gl_FragColor = vec4(col, 1.0)`: fuerza alfa 1 en toda la pantalla.
- **Qué hacer:** antes de usar transparencia en un estado con VHS, que el shader conserve el alfa de origen. Está pendiente como issue aparte.

### 17. En Windows, DWM por sí solo no hace la ventana transparente
- **Síntoma:** `DwmEnableBlurBehindWindow` devuelve `S_OK` (HRESULT 0) pero el fondo sigue negro.
- **Causa:** falta marcar la ventana como *layered*: `WS_EX_LAYERED` y `SetLayeredWindowAttributes(hwnd, 0, 255, LWA_ALPHA)`, después del paso de DWM. Es la secuencia de GLFW y la implementa `Windows.setWindowTransparent`.
- **Qué hacer:** usa `NativeAPI.setWindowTransparent(true)` (la misma llamada que en macOS); no reinventes la secuencia. Probado solo en VM, no en hardware real (ADR-0003, BE-10).

### 18. Probar en Windows desde un Mac
- **UTM no sirve para esto:** no acelera gráficos 3D en invitados Windows y el motor usa OpenGL.
- **Qué hacer:** VMware Fusion Pro (gratis para uso personal, cuenta de Broadcom) con Windows 11 ARM64, "Accelerate 3D Graphics" activado e instaladas las VMware Tools (sin ellas la pantalla sale en 4:3 y sin aceleración). Guarda la VM en un disco con espacio (ocupa 30-60 GB) y haz un snapshot del estado limpio.
- **Compilar sin Windows:** `Salchorixo/CodenameEngine` → Actions → *Windows Builds* (se dispara con cada `push`; cancela los de Linux y macOS). Descarga el artefacto `Codename Engine` y úsalo en la VM.
- **Pasar archivos al invitado:** arrastrar un único `.zip` a la ventana de la VM funciona; arrastrar carpetas con enlaces simbólicos falla ("Cannot create symlink").
- **Limitación:** la VM es ARM64 con GPU emulada. No sirve para medir rendimiento ni para dar por válido algo en hardware real.

### 19. En Windows, `modpack.ini` puede abrir un estado de prueba al arrancar
- **Síntoma:** al abrir el juego aparece un estado de prueba (p. ej. `TransparencyTestState`) en vez de la intro, aunque `TitleState.hx` sea correcto. En el log no hay errores: la primera línea de tu estado nunca sale.
- **Causa:** `[StateRedirects]` de `mods/fnf-echoes/data/config/modpack.ini` tenía `TitleState="TransparencyTestState"` (atajo de una prueba anterior), que gana sobre `TitleState.hx`.
- **Qué hacer:** `Get-Content mods\fnf-echoes\data\config\modpack.ini`. Para probar un estado, ponerlo ahí (`TitleState="MiEstadoDePrueba"`) y **devolver `TitleState="TitleState"` al terminar**. No lo versiones con el atajo puesto. Si hay varias copias del juego (p. ej. en Descargas y en el Escritorio), comprueba cuál abres.

### 20. Probar el juego con el teclado desde la terminal (macOS)
- **Síntoma:** al mandar teclas con `osascript -e 'tell application "System Events" to key code 126'` el juego las procesa a veces sí y a veces no, o con un fotograma de retraso; la selección parece "no hacer caso".
- **Causa:** (1) `key code` pulsa y suelta en el mismo instante y el juego pierde la pulsación si cae entre dos fotogramas; (2) si la ventana del agente recupera el foco entre comandos, la tecla va a otra app.
- **Qué hacer:** poner el juego en primer plano justo antes (`set frontmost of first process whose name is "CodenameEngine" to true`) y mandar la tecla con una pulsación **sostenida** (~0,12 s) con CoreGraphics desde Python (`ctypes` + `CGEventCreateKeyboardEvent` / `CGEventPost`), esperando ~1 s entre teclas. Con el Mac bloqueado las capturas salen negras: no lo desbloquees.

### 21. Un shader de cámara afecta a todo lo que dibuja esa cámara
- **Síntoma:** al poner un shader (glitch, VHS...) con `FlxG.camera.addShader(...)`, Zyra, el lápiz y todo lo demás sale deformado, aunque solo se quisiera afectar al fondo y a los botones.
- **Causa:** un shader de cámara procesa la imagen final de esa cámara entera.
- **Qué hacer:** separar en dos cámaras. Lo que debe quedar intacto va en una cámara propia, transparente y por encima (`new FlxCamera()`, `bgColor = 0x00000000`, `FlxG.cameras.add(cam, false)`; cada sprite con `sprite.cameras = [cam]`). Y el shader solo se añade mientras dura el efecto y se quita con `removeShader` al terminar.

### 22. Probar un juego que Zyra también puede estar usando
- Al abrir el juego desde la terminal aparece en la pantalla de Zyra y puede estar tocándolo a la vez: el estado cambia solo (se abre Ajustes, se mueve un deslizador). **Una prueba con teclas puede cambiar sus ajustes guardados** (idioma, calidad, volumen...). Antes de pulsar teclas en pantallas de Ajustes, apunta los valores de partida y devuélvelos; mejor probar esas pantallas con capturas y lo mínimo de teclas.

### 23. Un subestado (ModSubState) necesita su propia cámara si debe verse por encima de otras cámaras
- **Síntoma:** una ventana abierta con `openSubState` queda tapada por Zyra o por el lápiz del estado de debajo, o el estado de debajo se queda congelado.
- **Causa:** los objetos del subestado se dibujan en la cámara por defecto, y una cámara añadida después (`topCam` del menú) se dibuja por encima; además, el estado de debajo solo se actualiza si `persistentUpdate = true`.
- **Qué hacer:** dar al subestado su propia cámara transparente (`new FlxCamera()`, `bgColor = 0x00000000`, `FlxG.cameras.add(cam, false)`), asignar `obj.cameras = [cam]` a cada objeto antes de `add(obj)` (un `put(obj)` auxiliar) y quitarla en `destroy()`. En el estado de debajo: `persistentUpdate = true` al abrirlo y, mientras `subState != null`, hacer solo lo que debe seguir moviéndose y salir de `update()` antes de leer el teclado y el ratón. Ojo al sustituir `add(` por `put(` con una expresión regular: no cambies el `add(` de dentro de `put` (se llamaría a sí misma sin fin y el juego se cierra con un fallo de pila).

### 24. Traer un objeto al frente en un estado: `remove(obj, true)`
- **Síntoma:** `remove(obj); add(obj);` no cambia el orden de dibujo: el objeto sigue por debajo de otros.
- **Causa:** `remove` sin segundo argumento deja un hueco (`null`) en la lista de miembros y `add` reutiliza ese primer hueco, que es el mismo sitio.
- **Qué hacer:** `remove(obj, true)` (con `splice`) y luego `add(obj)`: al quitarlo de verdad, `add` lo pone al final, y lo último se dibuja encima.

### 25. Una transición propia no se activa con `[Flags]` del `modpack.ini`: hay que fijarla desde un estado del mod
- **Síntoma:** pones `DEFAULT_TRANSITION_SCRIPT` en `[Flags]` de `data/config/modpack.ini` y el motor sigue con su barrido negro.
- **Causa:** el motor solo aplica los flags de un mod si es el mod "actual"; los mods cargados como addon (`mods/autoload.txt`, como este) guardan los suyos aparte y no los aplican. Además, `MainState` reinicia `MusicBeatTransition.script` justo después de cargar el global script del mod, así que tampoco sirve `data/global/LIB_<mod>.hx`.
- **Qué hacer:** `import funkin.backend.MusicBeatTransition;` y `MusicBeatTransition.script = 'scripts/effects/diffusionTransition';` en el `create()` de un estado del mod que toda sesión visite (`MainMenuState`). La transición se abre dos veces (en la pantalla que se deja y en la que llega) y no comparten nada: se pasan un aviso con `FlxG.save.data` (sin guardarlo en disco).

### 26. Una lambda de HScript no ve los parámetros de su función
- **Síntoma:** en el registro, `Unknown variable: nombre` justo cuando se ejecuta una lambda (`(_) -> algo(nombre)`) pasada a un temporizador, aunque `nombre` sea un parámetro de la función que la crea.
- **Causa:** al ejecutarse más tarde, la lambda ya no tiene el ámbito de los argumentos de la función; solo recuerda variables locales (`var`).
- **Qué hacer:** copiar el parámetro a una variable local antes de crear la lambda (`var target = newTheme; later(0.4, (_) -> chooseTheme(target));`), igual que se hace con `var index = i` en los bucles.

### 27. Para pasar un dato de un script a otro, `FlxG.save.data`, no `FlxG.state.call(...)`
- **Síntoma:** una ventana (subestado) pregunta al estado de debajo con `FlxG.state.call("funcion")` y recibe `null` o valores que no cuadran (en BE-31, el tema que muestra el menú).
- **Causa:** `call()` entre scripts depende de qué scripts tenga el estado y de cómo combine sus resultados; con una función con tipo de retorno (`:String`) devolvió `null`, y sin tipo dio resultados inconsistentes. Con objetos (`channelParams()`) sí funcionó, pero no es fiable.
- **Qué hacer:** que quien sabe el dato lo **publique** en `FlxG.save.data.algo` (en memoria; no hace falta guardarlo en disco) cada vez que cambie, y que el otro script lo lea de ahí (`MainMenuState.publishTheme()` / `OptionsState.currentTheme()`).

