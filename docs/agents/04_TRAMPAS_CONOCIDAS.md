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
- **Qué hacer:** usa el patrón de `mods/fnf-echoes/data/states/TransparencyTestState.hx`: `FlxG.stage.color = null`, `FlxG.camera.bgColor = 0x00000000` y `NativeAPI.setWindowTransparent(true)`. Detalles y por qué en el ADR-0003, "Actualización 2026-10-03". Windows: sin hacer. Cuidado con el shader VHS (nº 16).

### 11. Traducir "ECHOES"
- **Regla fija:** "ECHOES" y "ECHO" no pasan nunca por `translate.hx`. Se quedan en inglés.

### 12. Confundir al autor con el personaje
- **Zyra (personaje):** gatito negro, **macho** → siempre "él", "he/his" en inglés. En los prompts de Suno, nunca "she/her" (eso cambia la voz generada).
- **Zyra / Salchorizo (autor):** la persona que hace el mod.

### 13. Documentos viejos sobre voces
- `docs/adr/0004-...` y `docs/AI_VOICE_CHROMATIC_PIPELINE.md` describen un pipeline que ya **no se usa** (ahora es Suno). No los sigas como instrucciones. Ver `00_ESTADO_ACTUAL.md` §5.

### 14. La pantalla completa nativa en macOS impide la transparencia
- **Síntoma:** al pasar a pantalla completa el escritorio "se va a la derecha" y, aunque la transparencia esté activa, la ventana se ve negra.
- **Causa:** la pantalla completa nativa de macOS crea un **Space propio**, siempre opaco y sin escritorio detrás.
- **Qué hace ya el motor (parche de BE-7):** la bloquea en todas las ventanas y fija `SDL_VIDEO_MAC_FULLSCREEN_SPACES=0`, así que `FlxG.fullscreen`, Alt+Enter y Ctrl+Cmd+F dan una ventana sin bordes del tamaño del escritorio, **sin Space**, donde la transparencia funciona. No hace falta código especial en el mod.
- **Qué NO hacer:** no recoloques la ventana a mano (`window.x/y/width/height`, `borderless`): Stage Manager y AppKit la reubican y queda a medias. No dependas de `window.fullscreen` leído justo después de cambiarlo.
- **Regla obligatoria (`AGENTS.md` §0.11):** el juego se abre en ventana. `TitleState.hx` todavía hace `FlxG.fullscreen = true` al crearse (ahora sin Space); decidir si arranca en ventana está pendiente.

### 15. En modo `cne test` el motor busca los mods en `engine/mods/`, no en el `.app`
- **Síntoma:** el juego arranca con el menú de Story Mode de siempre; en el log sale `Mod "fnf-echoes" not found in mods list, switching to base game!` y el botón `DISABLE MODS` aparece solo.
- **Causa:** el `.app` está compilado con `-DTEST_BUILD` (`cne build`/`lime test`). En ese modo `ModsFolder.modsPath` es `./<pathBack>mods/`, que resuelve a `engine/mods/`, y la carpeta solo trae un `readme.txt`. El enlace de `Contents/Resources/mods` no se usa para la lista de mods.
- **Qué hacer (ajuste local, no se versiona):** `ln -s ../../mods/fnf-echoes engine/mods/fnf-echoes`. El submódulo no se ensucia porque su `.gitignore` ignora `mods/*`. Para ver el log al abrir: `open -n --stdout LOG --stderr LOG <app>`.

### 16. El shader VHS anula la transparencia
- **Causa:** `VHSShader.frag` termina en `gl_FragColor = vec4(col, 1.0)`: fuerza alfa 1 en toda la pantalla.
- **Qué hacer:** antes de usar transparencia en un estado con VHS, que el shader conserve el alfa de origen. Está pendiente como issue aparte.
