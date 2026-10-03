# Context — Organización de la documentación del proyecto

Este documento explica, para quien esté revisando este Proyecto, cómo está organizada la documentación técnica del repositorio y por qué se estructuró así. No es el README del proyecto (eso es `README.md`) — es la explicación de la metodología de trabajo con agentes de IA usada durante el desarrollo, que es parte de lo que este Proyecto (TFM) busca demostrar.

## El problema que resuelve esta organización

Este proyecto se desarrolló con apoyo de agentes de IA (Claude, y potencialmente otras herramientas compatibles). Sin una estructura definida, es habitual que cada herramienta de IA acabe con su propio archivo de instrucciones (`CLAUDE.md`, `.cursorrules`, `.github/copilot-instructions.md`...) duplicando y, con el tiempo, contradiciendo las mismas reglas. Además, sin una convención, las decisiones técnicas importantes suelen quedar solo en el historial de una conversación de chat — invisibles para quien revise el código después.

La organización de este repositorio sigue el estándar **AGENTS.md**, adoptado en 2026 por más de 30 herramientas de agentes de código (Claude Code, Cursor, GitHub Copilot, OpenAI Codex, Gemini CLI, Windsurf, entre otras), más el patrón de **Architecture Decision Records (ADR)** para dejar rastro explícito de las decisiones técnicas relevantes.

## Mapa de documentos

| Documento | Para quién | Contenido |
|---|---|---|
| `README.md` | Personas | Entregable oficial para el TFM: descripción, stack, instalación, funcionalidades. |
| `AGENTS.md` | Cualquier agente de IA | Fuente única de verdad: reglas de trabajo, principios de código, qué no se debe tocar. Markdown plano, sin sintaxis especial, para que cualquier herramienta lo entienda. |
| `CLAUDE.md` | Claude Code específicamente | Una sola línea: `@AGENTS.md` (importa el archivo anterior). Evita mantener dos copias de las mismas reglas. |
| `docs/adr/000X-*.md` | Personas y agentes | Registro de decisiones técnicas (ej. elección de motor de juego): contexto, opciones consideradas, trade-offs, consecuencias. |
| `docs/CODING_STANDARDS.md` | Agentes y personas | Metodología de programación exigida: POO, KISS, DRY, convenciones de Haxe, con ejemplos aplicados al propio proyecto. |
| `docs/PROJECT_STRUCTURE.md` | Agentes y personas | Mapa de carpetas del repositorio y qué va en cada una. |
| `docs/agents/*.md` | Cualquier agente de IA | Manual operativo: estado actual del proyecto, protocolo de sesión y relevo, guía de HScript, recetas paso a paso, trampas conocidas y glosario. Pensado para que cualquier agente, incluso un modelo local pequeño, retome una sesión a medias sin adivinar. |
| `context.md` | Personas (evaluadores) | Este documento. |
| `TFM-Requisitos.md` | Solo uso personal | Checklist de los requisitos de entrega del máster. Excluido del repositorio vía `.gitignore` — no forma parte del entregable público. |

## Por qué no está todo en un único archivo

`AGENTS.md` intencionalmente **no** contiene detalle de arquitectura, ni convenciones de código, ni estructura de carpetas — eso vive en `docs/`. Un archivo de instrucciones para agentes que crece sin límite pierde eficacia: el modelo aplica peor las reglas cuanto más largo y disperso es el documento. La recomendación general (y la seguida aquí) es mantener cada archivo de contexto enfocado en un único propósito y por debajo de ~150-200 líneas.

## Política de crecimiento (jerarquía de contexto)

Ahora mismo todo el contexto vive en la raíz del repositorio porque el proyecto es pequeño. La política definida para cuando crezca (por ejemplo, al integrar el motor en `engine/` o al crecer el contenido en `mods/fnf-echoes/`) es:

- Si una carpeta acumula reglas propias claramente distintas a las del resto del proyecto, se crea un `AGENTS.md` anidado dentro de esa carpeta.
- Los agentes leen primero el archivo de contexto más cercano al código que están editando; el de la raíz aporta las reglas globales, los anidados aportan las específicas de esa zona.
- Un archivo nuevo no se crea "por si acaso" — solo cuando el archivo raíz empieza a mezclar reglas de ámbitos distintos (aplicando el mismo principio KISS que rige el código, aplicado a la documentación).

## Por qué esto es relevante para la evaluación

El objetivo no era solo que el código funcionara, sino demostrar una forma de trabajar con agentes de IA que sea auditable, reproducible y alineada con las convenciones que la industria fue adoptando en 2026 — en vez de improvisar instrucciones sueltas para cada herramienta. Las decisiones técnicas del proyecto (por ejemplo, la elección del motor de juego) están documentadas como ADR, no solo "decididas en el chat", precisamente para que este razonamiento quede visible y evaluable.

## Fuentes consultadas para esta organización

- [agents.md](https://agents.md/) — especificación oficial del estándar AGENTS.md.
- [Anthropic — Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [AGENTS.md vs CLAUDE.md vs Cursor Rules — comparativa 2026](https://www.morphllm.com/agents-md-guide)
