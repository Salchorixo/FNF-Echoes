# ADR-0013: Se borra el arte viejo del splash y de las sostenidas de Zyra

**Estado:** Accepted (Zyra, 2026-11-10)
**Fecha:** 2026-11-10
**Decide:** Salchorizo (Zyra)
**Issue:** BE-70
**Rama:** `zyra/chore/BE-70-borrar-arte-viejo-del-splash`
**PR:** #53
**Relacionados:** ADR-0010 (salto de cinta), ADR-0012 (temblor de las sostenidas), receta S

## Contexto

Desde el ADR-0010 y el ADR-0012, el acierto y las notas sostenidas de Zyra los dibuja `mods/fnf-echoes/songs/noteskin.hx` con la propia receptora. El atlas del estallido viejo, las dos imágenes del anillo y las astillas y el primer mockup (v2, descartado) quedaron en el repo sin que nada los usara. Los dos ADR dejaron pendiente decidir si se borraban, y Zyra dijo que sí.

## Decisión

Se borran:

- `mods/fnf-echoes/images/game/splashes/zyra.png` y `zyra.xml` (atlas de 1500×3322).
- `mods/fnf-echoes/data/splashes/zyra.xml`.
- `mods/fnf-echoes/images/game/holdfx/ring.png` y `sliver.png`.
- `docs/BE-52-splash-mockup.html` (mockup v2). El v3, del que salió el salto de cinta, se queda.

Se quita la línea del comentario de `noteskin.hx` que los nombraba y se actualiza la receta S. Los ADR-0010 y ADR-0012 no se tocan: ya están aceptados y cuentan la historia como fue.

## Opciones consideradas

### Opción A: borrarlos (ELEGIDA)
A favor: el mod no arrastra cerca de 1,1 MB de archivos muertos ni archivos que confunden a quien llegue. Siguen en el historial de git si hicieran falta.

### Opción B: dejarlos
Sin riesgo, pero invitan a creer que el splash se configura en `data/splashes/zyra.xml`. Descartada por Zyra.

## Problemas encontrados y cómo se resolvieron

Ninguno.

## Cómo se probó

- Búsqueda en `mods/fnf-echoes/` y `docs/`: ningún script, XML ni receta en uso referencia esos archivos (solo los ADR-0010 y ADR-0012, como historia).
- **NO PROBADO:** en el juego. Falta abrir Limbo y ver que carga sin errores en el registro.

## Consecuencias

- **A favor:** menos archivos y una sola fuente de verdad para el splash (`noteskin.hx`).
- **En contra o riesgos:** el script privado que hornea la noteskin (`AI_export_noteskin.py`, carpeta de producción) podría volver a generar el atlas del splash y las imágenes de `holdfx`. No lo sé: hay que mirarlo antes de volver a ejecutarlo.
- **Lo que cambia para quien venga después:** `data/splashes/` y `images/game/holdfx/` ya no existen en el mod.

## Pendiente

- [ ] Revisar `AI_export_noteskin.py` para que no regenere los archivos borrados.
