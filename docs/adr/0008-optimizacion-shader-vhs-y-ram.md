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

Optimizar internamente sin alterar el píxel de salida:

1. **`shaders/VHSShader.frag`:** reutilizar `l1.r` y `l2.r` (ya leídos para luma) en los bordes de color (fringe), ahorrando 2 lecturas de textura por píxel; precalcular la constante `1.0 - exp(-1.34)` como `TONE_DEN`.
2. **`scripts/effects/vhsShader.hx`:** en `tick()`, rastrear el último valor emitido por uniform y saltar `hset()` cuando no cambió (7 de 11 uniforms cambian rara vez: `seed`, `noise`, `cutSeed`, `trackSeed`, `pauseOn`, `satDrop`; solo `time`, `cutAge`, `tracking`, `roll` se actualizan cada frame).

No se toca `engine/`. No se desactiva el VHS en canciones. No se excluyen cámaras que alteren el look visual.

## Opciones consideradas

### Opción A: Optimización interna, misma salida (ELEGIDA)
Menos taps de textura y menos llamadas `hset()` por frame. Look idéntico. Bajo riesgo.

### Opción B: Modo "ligero" vinculado al ajuste de calidad
Menos taps cuando "Calidad de pantalla" = PERFORMANCE o "RUIDO DE LA CINTA" = 0. Requeriría UI y ramas de código; mayor riesgo de divergencia visual. Descartada por ahora: Zyra pidió que se vea igual siempre.

### Opción C: Excluir camHUD del shader en canciones
Ahorra una de las tres cámaras, pero las notas/flechas perderían el look VHS. Cambia la salida visual. Descartada.

### Opción D: Desactivar VHS en canciones
Rompe la estética aprobada en BE-59. Descartada.

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

## Cómo se probó

- Juego abierto en Limbo con los cambios (2026-11-10): sin errores nuevos en el log (solo el ya conocido `limboScene.hx:295: Unknown variable: project`). En una captura la cinta (ruido, franjas de color y barras de pausa) cubre todas las cámaras, incluido el HUD.
- RAM medida con `footprint` (tabla de arriba).
- **NO PROBADO:** FPS antes/después con la ventana en primer plano, ni comparación píxel a píxel del shader.
- Los cambios se revisaron leyendo los archivos modificados para confirmar que la semántica del shader no se altera: `l1.r` y `l2.r` ya se leían para luma; `TONE_DEN` es una constante equivalente a `1.0 - exp(-1.34)`; el `tick()` reestructurado solo omite `hset()` cuando el valor es idéntico al último enviado.

## Consecuencias

- **A favor:** menos lecturas de textura por píxel (fringe: de 3 a 1 tap), menos reflexión de Haxe por frame (7 `hset()` condicionales en lugar de 11 incondicionales).
- **En contra o riesgos:** sin medición real no se puede cuantificar la mejora. Si `shader.data` no fuera accesible para cachear `ShaderParameter` (opción no implementada por falta de confirmación), el ahorro de CPU se limita al cambio de valores en `tick()`.
- **Lo que cambia para quien venga después:** `tick()` de `vhsShader.hx` lleva variables `last*` que deben actualizarse si se añaden nuevos uniforms al bucle.

## Pendiente

- [x] Rama `zyra/feature/OPT-shader-ram`.
- [x] Medir RAM base y pico al entrar a una canción (macOS).
- [ ] Medir FPS antes/después en una canción con VHS activo.
- [ ] Comparación visual (capturas/diff) en Title, MainMenu, EchoSelect, canción y VHSTestState.
- [x] Identificar consumidor real de RAM: los atlas de Zyra (~600 MB ×2).
- [ ] Zyra decide cómo bajar los atlas (resolución, cargar los sets por partes u otra opción) y se aplica en esta rama.
- [ ] Zyra pasa este ADR a **Accepted** al aprobar la PR.
