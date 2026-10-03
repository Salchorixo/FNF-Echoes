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
- **Causa:** `lime` limpia cada frame a negro opaco desde su código nativo (ADR-0003).
- **Qué hacer:** no repitas ese intento. La vía nueva (color clave en Windows, ventana no opaca en macOS) requiere revisar el ADR-0003 antes de tocar `engine/`.

### 11. Traducir "ECHOES"
- **Regla fija:** "ECHOES" y "ECHO" no pasan nunca por `translate.hx`. Se quedan en inglés.

### 12. Confundir al autor con el personaje
- **Zyra (personaje):** gatito negro, **macho** → siempre "él", "he/his" en inglés. En los prompts de Suno, nunca "she/her" (eso cambia la voz generada).
- **Zyra / Salchorizo (autor):** la persona que hace el mod.

### 13. Documentos viejos sobre voces
- `docs/adr/0004-...` y `docs/AI_VOICE_CHROMATIC_PIPELINE.md` describen un pipeline que ya **no se usa** (ahora es Suno). No los sigas como instrucciones. Ver `00_ESTADO_ACTUAL.md` §5.
