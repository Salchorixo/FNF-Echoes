# ADR-0001: Motor de juego y stack tecnológico de FNF_Echoes

**Status:** Accepted
**Date:** 2026-07-29
**Deciders:** Salchorixo

## Contexto

FNF_Echoes es un mod/juego basado en Friday Night Funkin' (rhythm game), desarrollado como Trabajo de Fin de Máster (Máster de Desarrollo con IA). El proyecto debe cumplir 4 criterios técnicos no negociables:

1. Jugable en **Windows y macOS**.
2. Soporte de **transparencia de ventana**, **pantalla completa**, y efectos de **cámara** (shake, movimiento suave) sin romperse en ninguno de los dos sistemas operativos — con el nivel de calidad que ya demuestra el mod *Sonic.exe Rewrite*.
3. Motor **potente y moderno**, capaz de manejar chartings y animaciones exigentes sin lag en dispositivos modestos.
4. El código debe poder escribirse siguiendo **POO, KISS y DRY** de forma real y demostrable — requisito clave porque el TFM se evalúa también en calidad de ingeniería, no solo en el resultado visual.

Adicionalmente, el proyecto añade dos requisitos funcionales propios que condicionan la elección de motor:

- Efectos visuales de **VHS / distorsión** (scanlines, ruido, aberración cromática, glitches).
- Un **menú principal no estándar**: 3 tarjetas seleccionables; la primera abre un **tablero-mapa** con varios puntos (2-3 canciones por punto); al completar un punto, una ficha se desplaza al siguiente punto del tablero; al completar todo el tablero se desbloquea otra de las 3 tarjetas.

## Decisión

Se usará **Codename Engine** (Haxe + HaxeFlixel + OpenFL) como motor base del proyecto.

## Opciones consideradas

### Opción A: Codename Engine

| Dimensión | Evaluación |
|---|---|
| Multiplataforma | Build oficial de Windows, macOS y Linux ya resuelto y distribuido (fnf-cne-devs.github.io) |
| Rendimiento | Diseñado desde cero con optimización como prioridad; usa forks propios de librerías para mejor rendimiento |
| Arquitectura | Softcoding (scripts HScript) — el contenido nuevo no requiere tocar el código fuente del motor; separación limpia entre motor y contenido |
| Shaders/VFX | Sistema propio `CustomShader` (fragment + vertex), compatible con shaders GLSL tipo VHS/CRT |
| Mantenimiento | Desarrollo activo (CodenameCrew, 2026) |
| Curva de aprendizaje | Media — requiere entender HScript además de Haxe |
| Comunidad/documentación | Menor que Psych Engine, pero con wiki oficial propia (codename-engine.com) |

**Pros:** arquitectura más limpia y modular (mejor encaje con POO/KISS/DRY), mejor rendimiento, macOS resuelto oficialmente, shaders de primera clase.
**Contras:** comunidad y tutoriales más reducidos que Psych Engine; menos ejemplos de terceros para copiar directamente.

### Opción B: Psych Engine

| Dimensión | Evaluación |
|---|---|
| Multiplataforma | Windows sólido; soporte macOS descrito por los propios desarrolladores como "planeado, con problemas pendientes" (issues reportados de builds que no abren) |
| Rendimiento | Orientado a "casual play" y facilidad de modding, no a optimización como prioridad de diseño |
| Arquitectura | Para añadir estados o funcionalidades fuera del gameplay estándar hay que editar directamente el código fuente del motor (más hardcodeado) |
| Shaders/VFX | Soporta shaders vía OpenFL/HaxeFlixel (misma base que Codename); es el motor que usa *Sonic.exe Rewrite*, la referencia visual dada |
| Mantenimiento | Motor más popular y usado del ecosistema FNF |
| Curva de aprendizaje | Baja — enorme cantidad de tutoriales y scripts de terceros ya hechos |
| Comunidad/documentación | La más grande de todo el ecosistema de mods de FNF |

**Pros:** comunidad y documentación masivas, es literalmente el motor de la referencia visual dada (Sonic.exe Rewrite), curva de entrada más baja.
**Contras:** soporte de macOS no resuelto de forma oficial (riesgo directo sobre el criterio 1), arquitectura más hardcodeada (roza el criterio 4).

## Análisis de trade-offs

El criterio decisivo es el cruce entre el criterio 1 (macOS obligatorio) y el criterio 4 (arquitectura limpia demostrable). Psych Engine gana en comunidad y es el origen directo del efecto visual de referencia, pero su soporte de macOS es la debilidad más citada por su propia comunidad — riesgo real de incumplir un requisito no negociable del proyecto. Codename Engine resuelve macOS de forma oficial y su arquitectura softcoded encaja de forma natural con POO/KISS/DRY, que es justamente lo que se necesita documentar para la evaluación del TFM.

Los efectos visuales de la referencia (transparencia, shake, movimiento de cámara) no son exclusivos de Psych Engine: son técnicas del framework OpenFL/HaxeFlixel subyacente, compartido por ambos motores, por lo que son igualmente reproducibles en Codename Engine.

## Consecuencias

- Se gana: arquitectura más limpia y mantenible, macOS resuelto sin trabajo extra de packaging/firma, mejor rendimiento base para charts/animaciones exigentes.
- Se pierde: menos tutoriales de terceros directamente copiables; habrá que traducir soluciones documentadas para Psych Engine al equivalente en Codename Engine en algunos casos puntuales.
- A revisar más adelante: rendimiento real en dispositivos modestos una vez el tablero-mapa y los shaders VHS estén implementados (validar con perfilado, no solo con la decisión teórica).

## Action Items

1. [~] Clonar y compilar Codename Engine localmente (Windows y macOS) para validar el build antes de empezar contenido. **macOS: [x] validado 2026-08-07** — build nativo arm64, compila/linkea/corre sin crashear ni colgarse (confirmado visualmente). Ver "Actualización 2026-08-07" y "Receta completa" abajo para el detalle y los 3 parches necesarios. **Windows: [ ] pendiente**, no intentado en esta sesión (sin hardware Windows disponible).
2. [ ] Prototipar el shader VHS/distorsión como prueba de concepto aislada.
3. [ ] Prototipar la pantalla de tablero-mapa (`StoryMapState`) como prueba de concepto aislada, antes de integrarla al flujo completo.
4. [ ] Definir estructura de carpetas del proyecto (ver documento de estructura, en curso).
5. [ ] Documentar convenciones de código (POO/KISS/DRY) en `CODING_STANDARDS.md` (en curso).

## Actualización 2026-08-07: intento de build en macOS (Apple Silicon)

**Vendoring del motor:** se resolvió la ambigüedad "submódulo o vendored" mencionada en `PROJECT_STRUCTURE.md` — `engine/` es **git submodule**, pineado a un commit fijo de `CodenameCrew/CodenameEngine` (no sigue `main`), para tener reproducibilidad y un paso explícito de upgrade en vez de arrastrar cambios upstream silenciosamente.

**Lo que sí quedó validado en esta máquina (macOS, Apple Silicon / arm64):**
- Haxe 4.3.7 (versión exacta requerida por el motor) instalado y verificado.
- `engine/` añadido como submódulo, pineado al commit `fb54e50b2740f973615e52a67562742e58650a42`.
- `building/setup-unix.sh` corrió limpio: las 17 dependencias de `libs.xml` (hxcpp, lime, flixel, openfl, flixel-addons, flixel-animate, hscript-improved, etc.) se instalaron y `hxcpp` compiló localmente sin errores.

**Lo que quedó bloqueado:** `haxelib run lime test mac` (compilar + lanzar el juego) falla. Causa raíz confirmada, no es un problema de esta máquina en particular:
- El `lime.ndll` precompilado que trae la versión de `lime` pineada por el motor (8.1.2) es **x86_64-only**; esta Mac es Apple Silicon (arm64) → `dlopen` falla por arquitectura incompatible.
- Reconstruirlo nativo en arm64 no es viable sin más trabajo: el paquete de `lime` instalado vía haxelib **no trae el código C++ fuente**, solo los binarios precompilados + la interfaz Haxe. El soporte arm64 real de `lime` requirió parches (SDL, PNG, pixman, OpenAL, hxcpp) que solo se mergearon de cara a la versión 8.2.0 — confirmado en [openfl/lime#1640](https://github.com/openfl/lime/issues/1640).
- Como workaround se armó un toolchain universal propio (Haxe/haxelib/neko oficiales, sin tocar Homebrew) para correr todo bajo Rosetta 2 (`arch -x86_64`, ya instalado en la máquina). Esto sí resuelve la carga del `.ndll`, pero la llamada nativa CFFI para generar el ícono de la app (`IconHelper` → `Image.hx`) termina en **segmentation fault**. `otool -L` descarta dependencias de Homebrew faltantes (el `.ndll` solo linkea contra frameworks de sistema de Apple). `-Ddisable_cffi` no aplica porque es una directiva de compilación — el `run.n` del CLI de lime ya viene precompilado por CodenameCrew, no se puede activar en runtime.

**Decisión tomada por Juan David (2026-08-07):** opción (a) — compilar `lime` desde su fuente completo, en vez de depender de que CodenameEngine actualice su `libs.xml` río arriba (posiblemente en meses) o de mantener el workaround de Rosetta.

### Intento de compilar `lime` nativo desde fuente (opción a)

**Progreso real, en un espacio de build aislado (no toca `engine/.haxelib` del proyecto salvo para el swap final del binario):**

1. Se instalaron `lime`, `swf` y `hxcpp` **oficiales** (no los forks de CodenameCrew) vía `haxelib git` en un repo haxelib separado — según [openfl/lime#1640](https://github.com/openfl/lime/issues/1640), todos los parches arm64 ya están mergeados a las ramas principales desde julio 2024.
2. Primer intento compilando desde `main` (HEAD actual de `lime`): compiló y produjo un `.ndll` arm64 real, pero al reemplazarlo el juego compiló pero **crasheó en runtime** con `Error : lime_font_set_size does not have signature oiv` — la API nativa de `lime` cambió (drift de ~2 años) respecto a lo que el código del motor, compilado contra `lime` 8.1.2, espera.
3. Se cambió el checkout a la **tag exacta `8.2.0`** (primer release de `lime` con soporte arm64 confirmado, y con `Font.hx` idéntico a 8.1.2 — buena señal de compatibilidad de API). Recompilando desde ahí aparecieron dos errores de compilación **no relacionados a arm64**, sino a versiones viejas de librerías C de terceros (pineadas por esa tag de `lime` como submódulos) chocando con el SDK moderno de Xcode:
   - `libpng` 1.6.37: intentaba incluir `<fp.h>` (header de Mac clásico/PowerPC) por un guard `defined(TARGET_OS_MAC)` que hoy es siempre verdadero en cualquier build de Apple.
   - `zlib`: mismo patrón, un `#define fdopen(...)` bajo el mismo guard obsoleto rompía la declaración real de `fdopen` del SDK.
   - Ambos se resolvieron con un parche de una línea (`0 &&` antepuesto a la condición, forzando la rama moderna que ya existía como `#else`) **solo en la copia de build aislada**, sin tocar `engine/`.
4. Con esos dos parches, `lime` compiló limpio (arm64 real, confirmado con `file`). Se reemplazó el binario en `engine/.haxelib/lime/8,1,2/ndll/Mac64/lime.ndll` **y** `ndll/Mac/lime.ndll` (el motor busca en ambas rutas según el punto del build).
5. `haxelib run lime test mac` esta vez **compiló, linkeó y lanzó el proceso** (`CodenameEngine` llegó a correr, confirmado con `pgrep`) — pero crasheó casi de inmediato:
   ```
   Link: ApplicationMain
   Could not find primitive lime_joystick_get_num_trackballs__prime.
   AL lib: (EE) Failed to open /proc/cpuinfo, cannot check for NEON support
   Assertion failed: (bits == (allocated_var_bits & bits)), function assert_var, file hb-buffer.hh, line 178.
   ```
   Las dos primeras líneas parecen benignas (un primitivo opcional de joystick no encontrado; un chequeo de OpenAL específico de Linux que falla silenciosamente en macOS). La tercera — un **assertion failure dentro de HarfBuzz** (la librería de shaping de texto que `lime` empaqueta, usada para renderizar fuentes) — es la que mata el proceso (`abort()`). No es el mismo tipo de problema que los anteriores (rutas de archivo, versiones de librería obsoleta): es un crash real durante la inicialización, probablemente al cargar/renderizar una fuente.

### Diagnóstico del crash de HarfBuzz (con lldb) y resolución

Se investigó el crash con `lldb` (correr el `.app` compilado bajo el debugger y capturar `bt`/`thread backtrace all` al momento del `abort()`). El backtrace real mostró la causa exacta:

```
frame #12: lime.ndll`FT_Load_Glyph + 596
frame #13: lime.ndll`FT_Get_Advances + 220
```

El crash ocurre dentro de **FreeType** (`FT_Load_Glyph`), no en el motor ni en el código del juego: FreeType 2.12.1 (pineado por el submódulo de `lime` en la tag 8.2.0) tiene una integración interna opcional con HarfBuzz 6.0.0 (también pineado ahí) para mejorar el autohinting/GDEF de ciertas fuentes, y esa integración específica está rota en esta combinación exacta de versiones.

**Primer intento de fix — deshabilitar HarfBuzz por completo** (flag oficial `LIME_HARFBUZZ` en `project/Build.xml`, ya desactivada por defecto en target `winrt`): eliminó el crash, pero el juego quedó **colgado** en el arranque (proceso vivo, 100% CPU, cursor de carga infinito). Causa: el propio motor (Codename Engine / lime) llama activamente decenas de funciones `lime_hb_*` (la API pública de HarfBuzz que expone `lime` para shaping de texto) — no es un detalle interno opcional de FreeType, es una dependencia real del sistema de texto del juego. Al quitar `LIME_HARFBUZZ` por completo, esas funciones dejaron de existir y el juego se quedó esperando indefinidamente algo que nunca iba a resolver.

**Fix correcto — separar ambas integraciones:**
1. `LIME_HARFBUZZ` se mantiene **activada** en `project/Build.xml` (así la API `lime_hb_*` que el motor necesita sigue compilada).
2. Se deshabilita **solo** la integración interna de FreeType con HarfBuzz, directamente en `project/lib/custom/freetype/include/freetype/config/ftoption.h`, envolviendo en `#if 0` el bloque que define `FT_CONFIG_OPTION_USE_HARFBUZZ` (ese `#define` es lo único que activa el código problemático dentro de `FT_Load_Glyph`).

Con ambos cambios: el `.ndll` resultante (7.75 MB, entre los 6.8 MB de la versión sin HarfBuzz y los 8.8 MB originales) compiló limpio, y el juego **arrancó, cargó el idioma, y corrió estable** — confirmado visualmente por Juan David (2026-08-07 21:48). Sin `Assertion failed`, sin `Could not find primitive lime_hb_*`, uso de CPU normal (no spinning).

### Receta completa (macOS, Apple Silicon) — de principio a fin

1. `brew install haxe` (4.3.7 exacto, requerido por el motor).
2. `git submodule add https://github.com/CodenameCrew/CodenameEngine engine`, pineado al commit `fb54e50b2740f973615e52a67562742e58650a42`.
3. `engine/building/setup-unix.sh --ignore-sum --silent-progress` — instala las 17 dependencias del motor (hxcpp, lime, flixel, openfl, etc., todas en `engine/.haxelib/`, repo local del proyecto, ya gitignorado).
4. En un espacio de build **aislado** (no toca `engine/.haxelib`): instalar `lime`, `swf`, `hxcpp` **oficiales** vía `haxelib git`, hacer `git checkout 8.2.0` dentro del clon de `lime` (primer release con soporte arm64; `main` tiene demasiado drift de API respecto al 8.1.2 que pinea el motor) y sincronizar submódulos (`git submodule update --init --recursive`).
5. Compilar el `hxcpp.n` oficial (`cd tools/hxcpp && haxe compile.hxml`).
6. Aplicar 3 parches mínimos, todos en la copia aislada de `lime`, ninguno en `engine/`:
   - `project/lib/png/pngpriv.h`: neutralizar el guard obsoleto `defined(TARGET_OS_MAC)` que intenta incluir `<fp.h>` (header de Mac clásico que no existe hoy).
   - `project/lib/zlib/zutil.h`: mismo patrón, neutralizar el guard que redefine `fdopen` y choca con la declaración real del SDK.
   - `project/lib/custom/freetype/include/freetype/config/ftoption.h`: deshabilitar `FT_CONFIG_OPTION_USE_HARFBUZZ` (ver diagnóstico arriba) sin tocar `LIME_HARFBUZZ` en `Build.xml`.
7. `haxelib run lime rebuild mac` (con `-clean` tras cada cambio de Build.xml/ftoption.h) → produce `ndll/MacArm64/lime.ndll` (arm64 real, confirmado con `file`).
8. Copiar ese `.ndll` sobre **ambas** rutas dentro de `engine/.haxelib/lime/8,1,2/ndll/`: `Mac64/lime.ndll` (usada por la herramienta CLI de lime) y `Mac/lime.ndll` (usada al linkear el juego compilado) — el motor busca en las dos según la etapa del build.
9. `haxelib run lime test mac -release -clean` desde `engine/`, con `HAXE_STD_PATH` apuntando al Homebrew arm64 nativo (sin Rosetta) → compila, linkea y lanza el juego nativo en Apple Silicon.

**Limitación conocida:** con `FT_CONFIG_OPTION_USE_HARFBUZZ` deshabilitado, se pierde la mejora de autohinting/GDEF que FreeType obtiene internamente de HarfBuzz para ciertas fuentes complejas — el shaping de texto en sí (`lime_hb_*`, usado activamente por el motor) sigue intacto y funcionando. No debería notarse en la práctica para texto latino estándar de UI; a revisar si en algún momento se usan fuentes con features OpenType avanzadas.

**Pendiente:** validación en Windows (no intentada, sin hardware disponible en esta sesión).
