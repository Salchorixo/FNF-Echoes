# Plantilla de ADR (Architecture Decision Record)

> **Para cualquier agente** (Claude Code, OpenCode, Cursor, Codex, un modelo local) **y para personas.** Cada rama trae su ADR, dentro de la misma PR (ADR-0005). Copia el bloque de abajo a `docs/adr/NNNN-titulo-en-kebab-case.md` y rellénalo. Lee antes las **reglas de escritura**: un ADR mal escrito se nota enseguida.

---

## Reglas de escritura

**Qué es un ADR aquí.** Es el registro de **lo que se decidió en una rama y por qué**, incluidos los problemas que aparecieron y cómo se arreglaron. Lo leen Zyra, los evaluadores del TFM y los agentes que vengan después. Tiene que poder entenderse sin abrir el código.

**Qué SÍ va:**
- La decisión, sus alternativas reales y por qué se eligió una.
- Los problemas que **cambiaron una decisión o el diseño**, cada uno con su síntoma, su causa y su arreglo, en pocas líneas.
- Cómo se probó, con lo que **no** se pudo probar dicho claramente ("NO PROBADO" y el motivo).
- Lo que queda pendiente o abierto.

**Qué NO va:**
- Un diario de la sesión ("probé esto, luego esto otro, cambié un número"). Si un intento fallido no cambió nada, no va.
- Recetas paso a paso para programar: van en `docs/agents/03_RECETAS.md`, y el ADR las enlaza.
- Detalles de un error para quien programe ("si ves X, haz Y"): van en `docs/agents/04_TRAMPAS_CONOCIDAS.md`, y el ADR enlaza la trampa por su número.
- Decisiones de historia, arte o música: esas las decide Zyra y van en Notion (`AGENTS.md` §5).
- Cualquier firma de IA (`Co-authored-by`, "Hecho en pareja con...", "Generated with...").

**Estilo:**
- En **español**, con lenguaje natural, como si se lo contaras a una persona. Usa los términos técnicos (archivos, funciones, shaders, estados del motor) cuando ayuden a entender, con su ruta entre comillas invertidas: `mods/fnf-echoes/scripts/effects/tapeTransition.hx`.
- **Corto:** apunta a una o dos pantallas. Si crece mucho, probablemente la rama hacía más de una cosa.
- **Nada inventado:** cita los errores **literalmente** (copia y pega) y no rellenes con suposiciones; si algo no lo sabes, escribe "no lo sé" y cómo comprobarlo (`AGENTS.md` §6).
- Si una sección no aplica, déjala con **"Ninguno."** o **"No aplica."**: no la borres, así se ve que se pensó.

**Número y nombre:**
- Usa el número siguiente al último de `docs/adr/` (el 0004 se saltó a propósito). Si otra rama abierta cogió el mismo número, el segundo que llegue a `main` renumera el suyo al rebasar.
- El nombre es `NNNN-titulo-en-kebab-case.md`, en español.

**Estados y cambios:**
- Va en su PR **ya en Accepted** (ADR-0009): Zyra sigue cada decisión entera en la sesión, así que el ADR llega aceptado. Se escribe `Accepted (Zyra, AAAA-MM-DD)`.
- Si Zyra todavía no ha decidido algo (por ejemplo, el ADR de una rama a medias), el ADR se queda en **Proposed** hasta que decida, y la PR lo dice.
- Una vez **Accepted**, no se reescribe. Hay dos excepciones:
  - Una **actualización** pequeña al final, con fecha (`## Actualización AAAA-MM-DD`), cuando se completa algo pendiente o se prueba lo que no se había probado. Ejemplo: ADR-0003.
  - Cambiar el **estado**.
- Si la decisión cambia, se escribe un **ADR nuevo**. El nuevo dice "Reemplaza al ADR-NNNN" y el viejo pasa a **Superseded por ADR-MMMM**.
- Si la rama se abandona, el ADR pasa a **Rejected** con una frase de por qué y se queda en el repo: también es historia.

---

## El bloque para copiar

```markdown
# ADR-NNNN: Título corto de la decisión

**Estado:** Accepted (Zyra, AAAA-MM-DD)
**Fecha:** AAAA-MM-DD
**Decide:** Salchorizo (Zyra)
**Issue:** BE-XX (o DS-XX)
**Rama:** `zyra/<tipo>/<ID>-<descripcion>`
**PR:** #NN (se rellena al abrirla)
**Relacionados:** ADR-NNNN, receta X, trampa nº N (o "Ninguno.")

## Contexto

Qué problema o necesidad hay, y por qué ahora. Qué se sabía antes de empezar. Si viene de una petición de Zyra, dilo con sus palabras.

## Decisión

Qué se decidió, en una o dos frases claras, y después el detalle necesario para entenderlo: qué archivos o sistemas toca y cómo encaja con lo que ya existía.

## Opciones consideradas

### Opción A: nombre (ELEGIDA)
Qué es, a favor y en contra.

### Opción B: nombre
Qué es, a favor y en contra, y por qué se descartó.

(Solo las opciones reales. Si no había alternativa, dilo y explica por qué.)

## Problemas encontrados y cómo se resolvieron

Solo los que cambiaron una decisión o el diseño. Uno por bloque:

- **Síntoma:** qué se veía (con el error literal, si lo hubo).
  **Causa:** por qué pasaba.
  **Arreglo:** qué se hizo, y la trampa nº N si se documentó.

(Si no hubo ninguno: "Ninguno.")

## Cómo se probó

- Qué se ejecutó y qué se vio, en qué plataforma (macOS, Windows o VM).
- **NO PROBADO:** lo que falta y por qué.

## Consecuencias

- **A favor:** qué se gana.
- **En contra o riesgos:** qué se pierde, qué podría romperse y qué cuesta mantener.
- **Lo que cambia para quien venga después:** convenciones nuevas, archivos que hay que conocer.

## Pendiente

- [ ] Lo que queda por hacer, con su issue si ya existe.
- [ ] Lo que Zyra debe ver o probar antes de fusionar (o "Ninguno.").
```
