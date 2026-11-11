# ADR-0012: Las notas sostenidas de Zyra tiemblan como una cinta con mal tracking

**Estado:** Accepted (Zyra, 2026-11-10)
**Fecha:** 2026-11-10
**Decide:** Salchorizo (Zyra)
**Issue:** BE-69
**Rama:** `zyra/feature/BE-69-notas-sostenidas-temblor`
**PR:** (se rellena al abrirla)
**Relacionados:** ADR-0010 (el salto de cinta del acierto), receta S (`docs/agents/03_RECETAS.md`)

## Contexto

El acierto de Zyra pasó a ser un salto de cinta (ADR-0010). Las notas sostenidas seguían con el efecto anterior: un anillo fino que late y unas astillas que suben hacia la receptora, con un anillo y más astillas al soltar. Al lado del golpe nuevo desentonaban, y Zyra lo señaló al probar: "faltan las notas sostenidas".

## Decisión

Las sostenidas usan la misma idea que el acierto, en pequeño. Todo sale de `mods/fnf-echoes/songs/noteskin.hx`, con las mismas seis franjas de la receptora:

- **Mientras se mantiene:** la receptora se queda con su cuadro encendido y el tracking tiembla. Doce veces por segundo, una o dos franjas se corren unos píxeles (`HOLD_JUMP`, 6 % del ancho) y las demás se quedan en su sitio.
- **Al soltar o al terminar:** un salto corto de dos cuadros (`RELEASE_JUMP`), más pequeño que el del acierto, sin el cuadro blanco y sin la línea que cruza la fila. El golpe fuerte sigue siendo el de la nota.

El script ya no usa `images/game/holdfx/ring.png` ni `sliver.png`, y se quitó todo el código que los dibujaba. El salto del acierto no cambia de aspecto; su código se reordenó para compartir las franjas (`skipOf`, `startSkip`, `drawBands`, `rest`).

De paso, si una escena oculta una receptora o la fila entera, las franjas tampoco se dibujan.

## Opciones consideradas

### Opción A: temblor de tracking con las mismas franjas (ELEGIDA)
A favor: un solo lenguaje para acierto y sostenida, sin imágenes ni sprites nuevos. En contra: mientras dura, la receptora real está oculta y la sustituyen las franjas.

### Opción B: dejar el anillo y las astillas
Sin trabajo, pero es justo lo que desentonaba. Descartada.

## Problemas encontrados y cómo se resolvieron

Ninguno.

## Cómo se probó

- `noteskin.hx` pasa el analizador de HScript del motor sin errores de sintaxis.
- Zyra lo jugó en Limbo en macOS y lo aprobó ("hermoso"). El registro de esa partida no trae ningún error.
- **NO PROBADO:** Windows, y no sé si Zyra lo vio en upscroll y en downscroll.

## Consecuencias

- **A favor:** acierto y sostenida hablan igual; menos código y dos imágenes menos en uso.
- **En contra o riesgos:** el archivo `noteskin.hx` se reescribió casi entero, así que el salto del acierto hay que volver a verlo. La fuerza del temblor está puesta a ojo.
- **Lo que cambia para quien venga después:** el efecto de sostenida se ajusta con `HOLD_FPS`, `HOLD_JUMP`, `HOLD_SLIPS` y `RELEASE_JUMP`.

## Pendiente

- [ ] Decidir si se borran `images/game/holdfx/`, el atlas viejo del splash y el mockup v2.
