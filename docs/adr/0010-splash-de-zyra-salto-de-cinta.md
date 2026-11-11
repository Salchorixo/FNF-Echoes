# ADR-0010: El splash de Zyra es un salto de cinta dibujado por script

**Estado:** Accepted (Zyra, 2026-11-10)
**Fecha:** 2026-11-10
**Decide:** Salchorizo (Zyra)
**Issue:** BE-52
**Rama:** `zyra/feature/BE-52-flechas-splash`
**PR:** #50
**Relacionados:** receta S (`docs/agents/03_RECETAS.md`), trampa nº 21 (`docs/agents/04_TRAMPAS_CONOCIDAS.md`)

## Contexto

El splash de acierto de la fila de Zyra era un estallido horneado en un atlas (destello, anillos finos, grietas y astillas). Se hizo antes de que el juego entero pasara a verse como una cinta VHS de videocámara (BE-59), y ya no encajaba con ese ambiente.

Un primer mockup en esta rama (`docs/BE-52-splash-mockup.html`) probó un contorno corrupto con tinta, manchas que se acumulan y un eco blanco. Zyra pidió otra cosa: "algo simple, pero que tenga un impacto verdadero", sin un montón de efectos.

## Decisión

El acierto es un **salto de cinta**: durante tres cuadros (a 24 por segundo) la receptora se parte en seis franjas horizontales que se desplazan hacia los lados y vuelven a su sitio; el primer cuadro va en blanco y un poco más grande, y una línea blanca cruza la fila los dos primeros cuadros. Zyra lo eligió entre tres propuestas de `docs/BE-52-splash-mockup-v3.html` (Eco, Quemadura y Salto de cinta).

Lo dibuja `mods/fnf-echoes/songs/noteskin.hx`, sin atlas propio:

- En `onPlayerHit`, si el motor iba a mostrar un splash en una nota de la fila de Zyra, el script lo anula (`event.showSplash = false`) y llama a `tapeSkip`. El motor sigue decidiendo cuándo toca splash (la valoración del golpe y la opción del jugador).
- Las franjas son seis sprites por dirección que usan el mismo cuadro "confirm" de la receptora, cada uno recortado con `clipRect`. Se crean en el primer golpe de cada dirección y se reutilizan.
- Mientras saltan, la receptora real se oculta (`visible`) y vuelve al terminar.
- Las notas ya no piden el splash `zyra`, así que el atlas viejo (`images/game/splashes/zyra.png`, 1500×3322) deja de cargarse.

## Opciones consideradas

### Opción A: dibujarlo por script con la propia receptora (ELEGIDA)
A favor: cada golpe salta distinto (los desplazamientos son al azar), coincide siempre con el tamaño, la posición y la cámara de la fila, y no carga ninguna textura nueva. En contra: son 28 sprites pequeños más en la canción y la lógica vive en el script.

### Opción B: hornear el salto en un atlas de splash del motor
A favor: usa el sistema de splashes tal cual. En contra: el salto sería idéntico en cada golpe (o pediría varias variantes por dirección), la línea que cruza la fila no cabe en un cuadro de 300 px y la receptora seguiría viéndose debajo de las franjas. Descartada.

## Problemas encontrados y cómo se resolvieron

- **Síntoma:** ninguno visto en el juego; es un riesgo detectado al leer flixel.
  **Causa:** `FlxSprite.updateColorTransform` (lo llaman los setters de `alpha` y `color`) recalcula `useColorTransform` sin mirar los desplazamientos de color, así que el blanco del primer cuadro se perdería si se toca `alpha` después.
  **Arreglo:** el blanco y la opacidad se ponen juntos con `setColorTransform`, como última llamada de cada cuadro.

## Cómo se probó

- El mockup v3 se abrió en el navegador y las tres propuestas se animan sin errores.
- `noteskin.hx` pasa el analizador de HScript del motor (`hscript-improved`) sin errores de sintaxis.
- Zyra lo jugó en Limbo en macOS y lo aprobó ("simplemente hermoso"). El registro de esa partida no trae ningún error de `noteskin.hx`.
- **NO PROBADO:** Windows, y no sé si Zyra lo vio en upscroll y en downscroll ni en qué tomas de Limbo; para comprobarlo hay que jugar la canción con cada opción.
- **NO PROBADO:** el encogimiento de la receptora que muestra el mockup. No se implementó (ver Pendiente).

## Consecuencias

- **A favor:** un solo gesto, seco, que encaja con la cinta; menos memoria de vídeo al no cargar el atlas viejo.
- **En contra o riesgos:** el script oculta la receptora tres cuadros con `visible`; una escena que también cambie `visible` de una receptora suelta (hoy ninguna lo hace) chocaría con esto. El efecto de nota larga sigue siendo el de antes (anillo y astillas) y ahora desentona.
- **Lo que cambia para quien venga después:** el splash de Zyra ya no se toca en `data/splashes/zyra.xml`, sino en las constantes `SKIP_*` de `noteskin.hx`.

## Pendiente

- [ ] Decidir si la receptora se encoge un instante con el golpe, como en el mockup. No se hizo porque las escenas (Limbo) también escalan las receptoras.
- [ ] Decidir si se borran el atlas viejo (`images/game/splashes/zyra.*`, `data/splashes/zyra.xml`) y el mockup v2.
- [ ] Rehacer el efecto de nota larga con la misma idea, si Zyra quiere.
- [ ] Arreglar un error que ya estaba en Limbo y no es de esta rama: el registro repite `limboScene.hx:295: Unknown variable: project` durante la canción.
