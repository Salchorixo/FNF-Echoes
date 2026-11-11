# ADR-0009: El ADR de cada rama va en su PR ya en Accepted

**Estado:** Accepted (Zyra, 2026-11-10)
**Fecha:** 2026-11-10
**Decide:** Salchorizo (Zyra)
**Issue:** BE-67
**Rama:** `zyra/docs/BE-67-adr-aceptado-en-la-pr`
**PR:** #49
**Relacionados:** ADR-0005 (reglas de ramas, PR y ADR), ADR-0006 (plantilla de ADR), ADR-0007 (plantilla de PR)

## Contexto

El ADR-0005 dice que cada rama trae su ADR, que nace en **Proposed** y que Zyra lo pasa a **Accepted** al aprobar la PR. En la práctica eso pedía un commit más después de cada PR (los de BE-65 y BE-66 se llaman "el ADR-000N pasa a Accepted").

Al abrir la PR #48 (optimización de las canciones), Zyra lo dijo así: "el adr incluyelo si o si en cada PR que se haga.... a la final, siempre voy a estar de acuerdo con el adr porque a la final tuvimos el seguimiento completo aquí en chat".

## Decisión

El ADR de cada rama va en su PR **ya en Accepted**, con la forma `Accepted (Zyra, AAAA-MM-DD)`. Zyra sigue la decisión entera en la sesión, así que no hace falta esperar a la PR para aceptarlo.

Solo se deja en **Proposed** si Zyra todavía tiene algo por decidir (por ejemplo, una rama a medias), y la PR lo dice.

Se actualizan los sitios que decían lo contrario:

- `docs/adr/PLANTILLA.md`: la regla de estados, el estado del bloque para copiar y su última casilla de pendientes.
- La receta H de `docs/agents/03_RECETAS.md`.
- `.github/pull_request_template.md` y su copia en `docs/GIT_WORKFLOW.md` §6.
- El ADR-0005 recibe una actualización con fecha. Está Accepted y no se reescribe, y solo cambia una parte de su regla 2, así que no pasa a Superseded.

## Opciones consideradas

### Opción A: el ADR llega ya en Accepted (ELEGIDA)
Es lo que pidió Zyra. Quita un commit y un paso manual de cada PR, y cualquier agente lo hace igual porque está en las plantillas.

### Opción B: dejarlo como estaba (Proposed y Zyra lo acepta al aprobar)
Daría un último control antes de fusionar. Zyra no lo necesita: ese control ya ocurre en la sesión.

### Opción C: que el agente lo pase a Accepted después de fusionar
Seguiría pidiendo un commit extra, ahora sobre `main`, y eso las reglas no lo permiten.

## Problemas encontrados y cómo se resolvieron

Ninguno.

## Cómo se probó

- Se buscaron en el repo todas las menciones del ciclo Proposed → Accepted (`git grep "Proposed\|Accepted"`). Las que describían la regla vieja se cambiaron; las de los ADR antiguos se dejan, porque son historia.
- Se releyó el diff.
- Primer uso real: el ADR-0008 (PR #48) ya pasó a Accepted dentro de su PR.

## Consecuencias

- **A favor:** una PR = un ADR aceptado, sin commits de seguimiento. Las plantillas lo recuerdan a cualquier agente.
- **En contra o riesgos:** si un agente escribe un ADR que Zyra no vio en la sesión, llegaría "aceptado" sin que él lo sepa. Por eso la excepción: si algo no está decidido con él, va en Proposed y la PR lo dice.
- **Lo que cambia para quien venga después:** al escribir un ADR, el estado es `Accepted (Zyra, fecha)` desde el principio.

## Pendiente

- Ninguno.
