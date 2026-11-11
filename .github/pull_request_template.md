<!--
Plantilla de PR de FNF Echoes. Vale para personas y para cualquier agente (Claude Code, OpenCode, Cursor, Codex, un modelo local).
Antes de abrir la PR, comprueba lo siguiente (detalle en AGENTS.md §0.6 y docs/GIT_WORKFLOW.md §6):
- La rama se llama zyra/<tipo>/<ID>-<descripcion> y nace de main (sin ramas apiladas).
- El título sigue el formato de un commit: "tipo: qué hace (ID)".
- La PR va en español, con lenguaje natural, y usa términos técnicos cuando ayudan a entender.
- El ADR de la rama está en docs/adr/, escrito con docs/adr/PLANTILLA.md, y ya en Accepted (ADR-0009).
- Sin firma de IA: nada de "Co-authored-by", "Hecho en pareja con..." ni "Generated with...". Si tu herramienta la añade sola, bórrala.
Estos comentarios no se ven en la PR: puedes dejarlos.
-->

Closes BE-XX
<!-- Si la PR solo hace parte de la issue: "Part of BE-XX" (no la cierra). -->

## Qué cambia

<!-- Cuéntalo como a una persona: qué se ve o qué funciona distinto, y en qué archivos o sistemas. -->

## Por qué

<!-- El problema o la petición de la que viene. Si la pidió Zyra, con sus palabras. -->

## Cómo se probó

<!-- Qué ejecutaste y qué viste, y en qué plataforma (macOS, Windows o VM). Si algo no se probó: "NO PROBADO, porque ...". -->

## ADR

<!-- Enlace al ADR de esta rama: docs/adr/NNNN-titulo.md. Va ya en Accepted (ADR-0009); solo en Proposed si Zyra aún tiene algo por decidir. -->

## Notas

<!-- Decisiones, riesgos y lo que Zyra debe saber antes de fusionar. Si no hay nada, escribe "Ninguna." -->

## Antes de fusionar

- [ ] Solo hay cambios de esta issue (ni reformateos ni archivos colados).
- [ ] No hay archivos ignorados, binarios grandes, audio ni secretos.
- [ ] Código en inglés, documentación en español.
- [ ] Probado, o marcado "NO PROBADO" con el motivo.
- [ ] El ADR de la rama está incluido, en Accepted.
- [ ] Los commits están limpios y sin firma de IA.
