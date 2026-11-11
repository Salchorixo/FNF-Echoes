# ADR-0011: Limbo, la función `project` que faltaba en `limboScene.hx`

**Estado:** Accepted (Zyra, 2026-11-10)
**Fecha:** 2026-11-10
**Decide:** Salchorizo (Zyra)
**Issue:** BE-68
**Rama:** `zyra/fix/BE-68-limbo-funcion-project`
**PR:** #51
**Relacionados:** ADR-0010 (donde se vio el error), receta V (`docs/agents/03_RECETAS.md`)

## Contexto

Al revisar el registro de una partida de Limbo (prueba del ADR-0010) apareció 338 veces este error:

```
limboScene.hx:295: Unknown variable: project
```

`updateWarp`, en `mods/fnf-echoes/songs/limboScene.hx`, llama a `project(x, y, z)` para saber en qué franja de la pantalla queda la fila de receptoras en la primera toma, y así suavizar ahí el velo ASCII. Esa función no existe en ninguna rama del repo: la llamada entró con BE-57 sin su definición.

El error salta en cada cuadro de la primera toma y corta `updateWarp` a la mitad. Por eso, en esa toma, no se llegan a fijar `flatMode`, `flatScale` ni `flatShiftY` del shader `PlaneWarp.frag`. Al empezar la canción no se nota, porque `flatMode` vale 0 por defecto, que es lo que toca en la primera toma.

## Decisión

Se escribe la función `project` en `limboScene.hx`. Proyecta un punto de la escena (en metros) a la pantalla de 1280×720 con la cámara de Blender de la primera toma (`CAM_POS`, `CAM_RIGHT`, `CAM_UP`, `CAM_FWD`, `FOCAL`, `HUD_PER_RENDER`), con la misma cuenta que `PlaneWarp.frag` y `scripts/effects/mist.hx`. Devuelve `x`, `y` y `k` (píxeles de pantalla por metro a esa profundidad), que es lo que `updateWarp` ya esperaba. No tiene en cuenta el zoom ni la inclinación de la cámara: para una franja aproximada no hace falta.

## Opciones consideradas

### Opción A: escribir la función que falta (ELEGIDA)
A favor: `updateWarp` queda como se diseñó y el velo ASCII tendrá su franja cuando Zyra lo vuelva a encender. En contra: la franja no se puede comprobar hoy, porque el velo está apagado (`ASCII_ON = false`).

### Opción B: saltarse el cálculo mientras el velo esté apagado
A favor: el cambio más pequeño. En contra: el error volvería al encender el velo. Descartada.

## Problemas encontrados y cómo se resolvieron

Ninguno.

## Cómo se probó

- `limboScene.hx` pasa el analizador de HScript del motor sin errores de sintaxis.
- La cuenta se repitió fuera del juego con los datos del script: el centro de la fila cae en (600, 621) de la pantalla, abajo y cerca de los pies de Zyra, como dice el comentario de `PLANE_Z`; la franja queda centrada en y = 621 con 64 px de media altura.
- Zyra jugó Limbo en macOS con el arreglo: el registro de esa partida ya no trae el error (antes, 338 veces) ni ningún otro, y no comentó ningún cambio en la fila.
- **NO PROBADO:** Windows.
- **NO PROBADO:** la franja del velo ASCII, porque el velo está apagado.

## Consecuencias

- **A favor:** el registro deja de llenarse en cada cuadro y `updateWarp` se ejecuta entera.
- **En contra o riesgos:** ahora `flatMode` se fija a 0 en cada cuadro de la primera toma. Si la canción vuelve a esa cámara después de pasar por otra, antes la fila se quedaba plana (por el corte del error) y ahora volverá al plano 3D, que es lo que el código pretendía. No sé si Limbo vuelve a esa cámara; se ve jugando la canción entera.
- **Lo que cambia para quien venga después:** `project` está disponible en `limboScene.hx` para colocar cosas sobre la escena de la primera toma.

## Pendiente

- [ ] Comprobar la franja del velo ASCII cuando Zyra lo vuelva a encender.
