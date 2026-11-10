# ADR-0007: Plantilla de PR de GitHub para personas y cualquier agente

**Estado:** Proposed
**Fecha:** 2026-11-10
**Decide:** Salchorizo (Zyra)
**Issue:** BE-66
**Rama:** `zyra/docs/BE-66-plantilla-de-pr`
**PR:** (se rellena al abrirla)
**Relacionados:** ADR-0005 (reglas de ramas, PR y firma), ADR-0006 (plantilla de ADR)

## Contexto

El ADR-0005 fijó cómo se nombran las ramas, cómo se escriben las PR y que no se firma con IA. Zyra pidió que todo eso sirva **para cualquier agente**, no solo para Claude.

Las reglas ya están en `AGENTS.md`, que es el archivo que leen por defecto Codex, Cursor y OpenCode (Claude lo lee a través de `CLAUDE.md`). Pero la plantilla de la descripción de una PR solo existía dentro de `docs/GIT_WORKFLOW.md` §6. Un agente que abre la PR sin leer esa sección, o una persona desde la web, no la ve.

## Decisión

Se añade **`.github/pull_request_template.md`**. Es el archivo que GitHub carga solo en el cuerpo de cada PR nueva que se abre desde la web. Contiene:

- Un comentario oculto con las reglas que hay que cumplir antes de abrir la PR: el nombre de la rama, el título, el idioma y el tono, el ADR y la ausencia de firma, incluso si la herramienta la añade sola.
- Las secciones de `GIT_WORKFLOW.md` §6: `Closes BE-XX`, Qué cambia, Por qué, Cómo se probó, ADR y Notas.
- El checklist "Antes de fusionar".

`AGENTS.md` (regla 6b) y `GIT_WORKFLOW.md` §6 mandan a ese archivo, y explican que las PR abiertas por terminal (`gh pr create --body-file`) copian la misma estructura.

## Opciones consideradas

### Opción A: plantilla de PR en `.github/` (ELEGIDA)
GitHub la aplica sola, sin importar quién abra la PR. Es la forma estándar y no depende de que el agente lea la documentación.

### Opción B: un hook de git que revise la rama y los mensajes
Bloquearía las ramas mal nombradas y las firmas en cualquier herramienta. Zyra no la eligió por ahora.

### Opción C: archivos de aviso para otras herramientas (Copilot, Gemini CLI)
Archivos mínimos del tipo "lee AGENTS.md". Zyra no los eligió por ahora.

## Problemas encontrados y cómo se resolvieron

- **Síntoma:** la plantilla de GitHub no se aplica cuando la PR se abre por terminal con `gh pr create --body-file`, que es como suelen abrirlas los agentes.
  **Causa:** GitHub solo rellena el cuerpo en la web, o cuando `gh` abre el editor sin cuerpo.
  **Arreglo:** `AGENTS.md` y `GIT_WORKFLOW.md` piden copiar la estructura del archivo cuando la PR se abre por terminal. La plantilla es la fuente única de esa estructura.

## Cómo se probó

- Se releyó el diff. La plantilla coincide con la de `GIT_WORKFLOW.md` §6.
- **NO PROBADO:** que GitHub la cargue sola. Se verá en la primera PR que se abra desde la web después de fusionar esta.

## Consecuencias

- **A favor:** cualquier PR nueva, la abra quien la abra, empieza con la misma estructura en español y con los recordatorios del ADR y de la firma.
- **En contra o riesgos:** la plantilla y `GIT_WORKFLOW.md` §6 tienen que mantenerse iguales. Si cambia una, se cambia la otra.
- **Lo que cambia para quien venga después:** el sitio de la estructura de una PR es `.github/pull_request_template.md`.

## Pendiente

- [ ] Comprobar en la primera PR desde la web que la plantilla aparece.
- [ ] Zyra pasa este ADR a **Accepted** al aprobar la PR.
