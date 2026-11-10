# ADR-0005: Ramas `zyra/<tipo>/...`, PR en español natural, sin firma de IA y un ADR por rama

**Status:** Proposed
**Date:** 2026-11-10
**Deciders:** Salchorizo

> El número 0004 se salta a propósito: lo usó un ADR del antiguo pipeline de voces que nunca se aprobó y se borró (ver `docs/agents/00_ESTADO_ACTUAL.md` §5). Reutilizarlo confundiría las referencias viejas.

## Contexto

El 2026-11-10 se integró en `main` todo el trabajo pendiente: la cinta (BE-60 a BE-63), cinco PR de octubre que seguían en borrador, el chart de Limbo (DS-1) y trabajo que nunca se había commiteado. El repo quedó limpio, pero hacer limpieza destapó varios problemas de organización:

- Ramas **apiladas** unas sobre otras (BE-61 → BE-62 → BE-63) que hubo que rebasar a mano para que llegaran a `main`.
- Trabajo **sin commitear durante semanas** en worktrees (DS-1, BE-53, BE-58), a punto de perderse.
- Ramas con nombres que no dicen de quién son ni qué tipo de cambio traen, lo que se nota más con varios agentes trabajando a la vez.
- Decisiones técnicas que solo quedaron en el código o en un comentario de Linear, sin un registro que se pueda leer después.
- Mensajes de commit y de PR con firmas de IA (`Co-authored-by: Claude`, "Hecho en pareja con Claude") que Zyra ya no quiere.

Zyra quiere empezar de nuevo, ahora sí mucho más organizado.

## Decisión

1. **Toda tarea, por pequeña que sea, va en su propia rama**, creada desde `main` actualizada. El nombre es:

   ```
   zyra/<tipo>/<ID>-<descripcion-corta-en-kebab-case>
   ```

   - `zyra/` va siempre delante: es el espacio de ramas de Zyra y de los agentes que trabajan para él.
   - `<tipo>` es lo que se está haciendo: `feature`, `fix`, `docs`, `chore` o `refactor`.
   - `<ID>` es la issue de Linear (`BE-65`, `DS-4`). Linear la reconoce en cualquier parte del nombre y así enlaza la rama sola.
   - Ejemplos: `zyra/feature/BE-65-pantalla-de-carga`, `zyra/fix/BE-66-parpadeo-de-la-cinta`, `zyra/docs/BE-64-reglas-de-ramas-pr-y-adr`.

2. **Cada rama trae su ADR**, en `docs/adr/NNNN-titulo.md` y en la misma PR. El ADR explica qué se decidió en esa rama, por qué, qué otras opciones había y qué consecuencias tiene. Si la rama es muy pequeña (un arreglo de una línea), el ADR es corto, pero existe. Nace como **Proposed**; Zyra lo pasa a **Accepted** cuando aprueba la PR.

3. **Las PR se escriben en español, con lenguaje natural**: se le cuenta a una persona qué cambia, por qué y cómo se probó. Los términos técnicos (nombres de archivos, funciones, shaders, estados del motor) se usan cuando ayudan a entender, no para rellenar. El título sigue el formato de los commits: `tipo: qué hace (ID)`.

4. **Sin firma de IA.** Ni en commits ni en PR: nada de `Co-authored-by: Claude`, "Hecho en pareja con Claude", "Generated with Claude Code" o parecidos. Los mensajes van limpios. Las descripciones de las PR que ya existían se limpian; los commits viejos de `main` **no** se reescriben, porque eso exigiría un force-push que cambia todos los hashes y no se puede deshacer.

## Opciones consideradas

### Opción A: Mantener `tipo/ID-descripcion` (lo que había)
Funcionaba con Linear, pero no distingue de quién es la rama y no evitó el desorden. Se descarta.

### Opción B: `zyra/<tipo>/<ID>-<descripcion>` (ELEGIDA)
Mantiene el tipo y el ID (y por tanto la integración con Linear) y agrupa todas las ramas bajo `zyra/`. En GitHub y en `git branch` se ven ordenadas por tipo.

### Opción C: ADR solo para decisiones grandes (lo que había)
Es lo habitual en la industria, pero aquí las decisiones "pequeñas" se perdían. Zyra prefiere un ADR por rama: el TFM gana un registro completo de cómo se tomó cada decisión con agentes de IA.

### Opción D: Reescribir todo el historial de `main` para quitar las firmas
Se descarta: es irreversible, rompe los enlaces a commits que ya existen (Linear, PR, documentos) y la protección de `main` prohíbe el force-push.

## Consecuencias

- Más archivos en `docs/adr/`. Para encontrarlos rápido, el título del ADR lleva el ID de la issue y la rama.
- Dos ramas abiertas a la vez pueden escoger el mismo número de ADR. La segunda que llegue a `main` renumera el suyo al rebasar.
- Los agentes que lean esto antes de una tarea ya no añaden trailers de coautoría, aunque su herramienta lo sugiera: manda la regla del repo (`AGENTS.md` §8).
- Las ramas que ya existían con el formato viejo (BE-58) se pueden quedar como están hasta que se fusionen.

## Action Items

- [x] `AGENTS.md`, `docs/GIT_WORKFLOW.md`, `docs/agents/01_PROTOCOLO_DE_SESION.md` y la receta H de `docs/agents/03_RECETAS.md` con las reglas nuevas.
- [x] Quitar la firma de IA de las descripciones de las PR existentes.
- [ ] Zyra pasa este ADR a **Accepted** al aprobar la PR.
