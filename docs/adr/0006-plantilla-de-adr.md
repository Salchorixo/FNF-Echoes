# ADR-0006: Plantilla de ADR con problemas, pruebas y reglas para cualquier agente

**Estado:** Proposed
**Fecha:** 2026-11-10
**Decide:** Salchorizo (Zyra)
**Issue:** BE-65
**Rama:** `zyra/docs/BE-65-plantilla-de-adr`
**PR:** (se rellena al abrirla)
**Relacionados:** ADR-0005 (un ADR por rama), ADR-0003 (ejemplo de ADR con un intento fallido y su actualización), receta H

## Contexto

El ADR-0005 dejó la regla de que cada rama trae su ADR. Zyra explicó qué es lo que más le importa de ellos: que se vean **las decisiones, los problemas que aparecieron y cómo se arreglaron**.

La receta H solo pedía Contexto, Decisión, Opciones, Consecuencias y Action Items. No había ningún sitio obligado para los problemas ni para las pruebas. El único modelo era copiar un ADR existente, y no todos tienen la misma forma.

Además, la plantilla no es solo para Claude: la tiene que poder seguir cualquier agente que trabaje en el repo (OpenCode, Cursor, Codex, un modelo local pequeño), con el mismo resultado.

## Decisión

Hay una plantilla única, **`docs/adr/PLANTILLA.md`**, que trae dos cosas:

1. **Reglas de escritura**: qué es un ADR aquí, qué sí y qué no va, el estilo (español natural, corto, errores literales, nada inventado), el número y el nombre, y cómo se actualiza o se reemplaza un ADR aceptado.
2. **Un bloque para copiar** con estas secciones:
   - Una cabecera con estado, fecha, quién decide, issue, rama, PR y relacionados.
   - Contexto, Decisión y Opciones consideradas.
   - **Problemas encontrados y cómo se resolvieron**, con síntoma, causa y arreglo.
   - **Cómo se probó**, con el NO PROBADO explícito.
   - Consecuencias y Pendiente.

La receta H, `AGENTS.md` (en el router) y `docs/GIT_WORKFLOW.md` mandan a esta plantilla. Los ADR anteriores (0001, 0002, 0003 y 0005) se quedan como están: no se reescribe un ADR aceptado.

## Opciones consideradas

### Opción A: ADR "de libro", solo con la decisión
Es la forma clásica: corta y estable. Pero los problemas y sus arreglos se quedarían fuera, y eso es justo lo que Zyra quiere ver. Se descarta.

### Opción B: ADR como diario completo de la rama
Lo guarda todo, pero se vuelve largo y es difícil encontrar la decisión. También repite lo que ya cuentan las recetas y las trampas. Se descarta.

### Opción C: ADR con la decisión más los problemas que la cambiaron (ELEGIDA)
Cuenta la historia completa de la rama en una o dos pantallas: qué se decidió, por qué, qué se rompió y cómo se arregló. El detalle técnico se queda en `04_TRAMPAS_CONOCIDAS.md`, y el ADR lo enlaza por número. Es el modelo que ya seguía bien el ADR-0003.

## Problemas encontrados y cómo se resolvieron

- **Síntoma:** al pedir "problemas y arreglos" en el ADR, se corre el riesgo de convertirlo en un diario.
  **Causa:** sin una regla clara, cada agente decide cuánto contar.
  **Arreglo:** la plantilla define qué SÍ y qué NO va: solo los problemas que cambiaron una decisión o el diseño, con síntoma, causa y arreglo en pocas líneas. El detalle va como trampa.

## Cómo se probó

- Es solo documentación. Se releyó el diff y se comprobó que un agente que entra por `AGENTS.md` llega a la plantilla, a través del router y de la regla 6.
- **NO PROBADO:** que otro agente distinto de Claude (OpenCode, Cursor o un modelo local) escriba un ADR con ella. Se verá con el primer ADR que escriba otro agente.

## Consecuencias

- **A favor:** todos los ADR tendrán la misma forma, y cada uno contará sus problemas y sus pruebas. El TFM gana un registro legible de cómo se trabajó con agentes.
- **En contra o riesgos:** escribir un ADR completo cuesta más en las ramas pequeñas. Por eso se permite "Ninguno." en las secciones que no aplican.
- **Lo que cambia para quien venga después:** antes de abrir una PR, hay que rellenar `PLANTILLA.md` entera. Los ADR nuevos usan cabeceras en español (Estado, Fecha, Decide); los viejos conservan las suyas (Status, Date, Deciders).

## Pendiente

- [ ] Escribir los ADR que faltan para las ramas que ya están en `main` (la cinta, el menú, las transiciones, la HUD, la réplica, Limbo...), si Zyra lo decide.
- [ ] Zyra pasa este ADR a **Accepted** al aprobar la PR.
