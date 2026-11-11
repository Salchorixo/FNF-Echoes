# ADR-0008: Optimización del shader VHS y reducción de RAM al entrar a una canción

**Estado:** Proposed
**Fecha:** 2026-11-10
**Decide:** Salchorizo (Zyra)
**Issue:** Ninguno (tarea de optimización solicitada directamente)
**Rama:** `zyra/feature/OPT-shader-ram`
**PR:** Ninguna aún
**Relacionados:** `shaders/VHSShader.frag`, `scripts/effects/vhsShader.hx`, ADR-0005, BE-59

## Contexto

Zyra pidió optimizar el juego: el consumo de RAM sube a ~1 GB al entrar a una canción y el shader VHS se percibe como pesado. Dos problemas distintos:

1. **RAM al entrar a una canción:** un shader no retiene memoria por frame que crezca hasta 1 GB. Sospechosos reales (sin confirmar): audio decodado (Inst + Voices), atlases de textura (poses de Zyra de DS-2 apuntan a ~400 MB en `docs/agents/00_ESTADO_ACTUAL.md:116`), notas del chart.
2. **Shader VHS por frame:** `VHSShader.frag` corre en cada cámara del estado (camGame, camHUD, osdCam durante una canción, véase `tapeSong.hx:68-83`), con ~10 lecturas de textura por píxel y cámara. `vhsShader.hx:tick()` llama `hset()` para 11 uniforms por shader y frame, incurriendo en reflexión de Haxe cada vez.

BE-59 estableció que el look VHS es la estética aprobada del juego y no debe cambiarse. La optimización debe ser **interna**: misma salida visual, menos coste.

## Decisión

Tres cambios, sin tocar `engine/` ni el look aprobado de la cinta:

1. **La cinta se dibuja una sola vez sobre todo el juego** (`scripts/effects/vhsShader.hx`): es un filtro en `FlxG.game` (`setFilters`), recortado a la ventana con `scrollRect`, en vez de un shader en cada cámara. El OSD de la casetera (PLAY, SP), que debe quedar nítido, se saca a una capa justo encima de `FlxG.game` (`exclude` → `lift`). La API para las pantallas no cambia (`attach`, `exclude`, `cut`, `badTracking`...). Por qué antes no funcionaba: trampa nº 30.
2. **El shader se salta el trabajo donde no hay nada** (`shaders/VHSShader.frag`): si el píxel es transparente y no hay un evento que pinte el vacío (bandas de tracking, nieve, blanking), sale con `vec4(0)` tras 1 lectura en vez de 11. El resultado es idéntico (el color se multiplica por un alfa 0). También se reutilizan `l1.r`/`l2.r` en las franjas de color y se precalcula `TONE_DEN`. Los uniforms que cambian poco solo se mandan cuando cambian.
3. **Los atlas de Zyra pasan al 50 %** (decisión de Zyra, 2026-11-10, viendo capturas del juego al 100, 75 y 50 %: bajo la cinta no se nota). La escala de `data/characters/zyra.xml` pasa de 1.2344 a 2.4688; los ojos, el brazo y el reflejo copian la escala del personaje. Herramienta privada: `FNF_Echoes_Production/01_Characters/Zyra/sprites/tools/AI_rescale_atlas.py`, que reescala fotograma a fotograma y vuelve a empaquetar.

## Opciones consideradas

### Opción A: Una sola cinta sobre el juego + salida temprana + atlas al 50 % (ELEGIDA)
Ataca las dos causas reales medidas: la cinta repetida en 6 cámaras (FPS) y los atlas gigantes (RAM). El look se mantiene.

### Opción B: Solo optimizar el shader por dentro (lo que hizo el primer commit de la rama)
Menos lecturas y menos `hset()`, pero la cinta seguía 6 veces por frame. Ganancia mínima. Se conserva como parte de A.

### Opción C: Quitar la cinta del HUD o de las cámaras de encima
Ahorra, pero las flechas y el texto dejarían de verse grabados. Cambia el look. Descartada.

### Opción D: Cargar las poses de Zyra por partes a mitad de canción
Zyra la descartó: cargar a mitad de canción da tirones. En su lugar irá una caché por partes que carga en momentos seguros (pendiente, ver abajo).

### Opción E: `Options.gpuOnlyBitmaps`
Medida: en Mac no ahorra (el driver vuelve a copiar las imágenes). Descartada.

## Problemas encontrados y cómo se resolvieron

- **El primer `tick()` optimizado solo actualizaba la primera cámara.** Comprobaba y guardaba el valor `last*` dentro del bucle de shaders, así que la segunda y la tercera cámara (camHUD, osdCam) nunca recibían `seed`, `noise`, `cutSeed`, `trackSeed`, `pauseOn` ni `satDrop`, y se quedaban a 0 (una cinta "limpia" en el HUD). Ahora se decide una vez qué mandar, se manda a todos los shaders y se guarda después del bucle; una cámara nueva (`addTo`) fuerza a mandar todo en el siguiente frame (`sendAll`).

## Medición (2026-11-10, macOS Apple Silicon, `footprint`)

Entrando directo a Limbo con un estado temporal (no commiteado), ventana normal:

| Momento | Footprint (lo que muestra el Monitor de Actividad) |
|---|---|
| Antes de la canción | ~210 MB |
| Limbo, ya cargada (30–45 s) | **~2,4 GB** (≈1,0 GB gráficos + ≈1,0 GB `Malloc Large`) |
| Limbo con `Options.gpuOnlyBitmaps = true` | ~2,3 GB (≈1,6 GB gráficos): en Mac el driver vuelve a copiar; **no sirve** |

**El culpable de la RAM son los atlas de Zyra, no el shader.** Al descomprimirse en RGBA ocupan:

| Atlas | Tamaño | En memoria |
|---|---|---|
| `characters/zyra/1.png` | 8170×1024 | 33 MB |
| `characters/zyra/2.png` | 8140×2986 | 97 MB |
| `characters/zyra/3.png` | 8055×3500 | 113 MB |
| `characters/zyra/4.png` | 8039×4135 | 133 MB |
| `characters/zyra_arm/1.png` | 8163×1876 | 61 MB |
| `characters/zyra_eyes/1.png` | 8044×5102 | 164 MB |
| **Total** | | **~600 MB**, una vez en RAM y otra en la gráfica |

Los atlas ya están bien empaquetados (76–92 % de uso, sin fotogramas repetidos por posición). El shader no guarda memoria por frame: su coste es de GPU (11 lecturas de textura por píxel y cámara).

## Resultado (Limbo a los ~8 s, Mac en modo ahorro de batería, 5 s de muestra, 2–3 pasadas por caso)

| Versión | FPS | Footprint |
|---|---|---|
| Atlas al 100 %, cinta en cada cámara (antes) | — | ~2,4 GB |
| Atlas al 50 %, cinta en cada cámara | 16 | 1,62 GB |
| + salida temprana en píxeles vacíos | 22 | 1,62 GB |
| + una sola cinta sobre el juego (sin recorte) | 35 | 1,62 GB |
| **+ recorte a la ventana (final)** | **40** | **1,33 GB** |
| Referencia: sin cinta | 43 | 1,28 GB |

Sin ahorro de batería, la misma prueba daba 32 FPS con la cinta por cámara y 63 sin cinta. En los menús, con la versión final: ~55–64 FPS y 350–550 MB.

## Cómo se probó

- Un estado temporal (no commiteado) entra directo a Limbo o a una pantalla y una canción temporal congela o sale de la canción en un instante fijo. FPS contados dentro del juego; RAM con `footprint`; capturas con `screencapture -l`. Nada de teclas simuladas. El guardado de Zyra se respaldó y se restauró al terminar.
- **Visto en capturas, sin errores nuevos en el log** (solo el ya conocido `limboScene.hx:295: Unknown variable: project`): Limbo jugando, la pausa de la cinta (barras y "PAUSE ‖" nítido), la salida de la canción con la cinta mordida hasta el selector, el menú principal, EchoSelect, el selector de canciones, los créditos y `VHSTestState` con la **ventana transparente** (la mitad sin dibujo sale con alfa 0: BE-8 sigue resuelto).
- Comparación 100/75/50 % de los atlas con el juego congelado en el mismo instante (capturas enviadas a Zyra).
- **NO PROBADO:** pantalla completa, la coreografía de ventana (`windowFx`) con la cinta puesta, Windows, y el visto bueno de Zyra en su pantalla.

## Consecuencias

- **A favor:** Limbo pasa de ~2,4 GB a 1,33 GB y la cinta cuesta ~3 FPS en vez de la mitad. Toda pantalla que llama a `attach()` gana lo mismo sin cambios.
- **En contra o riesgos:**
  - Durante las transiciones de la cinta (`tapeTransition.hx`) el OSD de la casetera también se ondula. La transición busca "las cámaras con filtro" y, como ya ninguna lo tiene, se aplica a todas. Antes el OSD quedaba quieto. Si Zyra lo quiere quieto, la transición debe saltarse las cámaras de `exclude`.
  - El ruido y las franjas se calculan sobre la imagen ya compuesta, no capa por capa. Es más fiel a una grabación real; en las capturas no se aprecia diferencia.
  - `FlxG.game.scrollRect` se fija mientras la cinta está puesta y se quita en `detach()`. Si otro código usa `scrollRect` o `setFilters` en `FlxG.game`, chocará con la cinta.
- **Lo que cambia para quien venga después:** un efecto de pantalla completa va como un filtro en `FlxG.game` (trampa nº 30), no en cada cámara. Al exportar atlas nuevos de Zyra, pasa la herramienta de reescalado al 50 % y deja la escala 2.4688.

## Pendiente

- [x] Rama `zyra/feature/OPT-shader-ram`.
- [x] Medir RAM y FPS en Limbo (macOS, con ahorro de batería).
- [x] Identificar los consumidores reales: los atlas de Zyra (RAM) y la cinta repetida por cámara (FPS).
- [x] Atlas al 50 % (decisión de Zyra).
- [x] La cinta una sola vez sobre el juego.
- [ ] **Caché por partes** (pedido de Zyra): cada canción carga todo lo de una parte de una vez, en la cutscene del inicio o en la de entre las dos partes, y libera lo que ya no se usa (en Limbo, las hojas 1–3 de Zyra después de 12,4 s). Nunca carga a mitad de música. Liberar al entrar a una canción lo del menú, y viceversa.
- [ ] La canción carga sin usarlos `characters/dad.png` (22 MB), las salpicaduras y las notas por defecto.
- [ ] Probar en pantalla completa, con `windowFx` y en Windows.
- [ ] Zyra lo ve en su pantalla y pasa este ADR a **Accepted** al aprobar la PR.
