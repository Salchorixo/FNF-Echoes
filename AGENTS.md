# AGENTS.md — FNF_Echoes

Instrucciones para cualquier agente de IA (Claude, Copilot, Cursor, etc.) que trabaje en este repositorio.

## Qué es este proyecto

Mod/juego de ritmo basado en Friday Night Funkin', TFM del Máster de Desarrollo con IA. Motor: **Codename Engine** (Haxe + HaxeFlixel + OpenFL). Decisión documentada en `docs/adr/0001-motor-y-stack-tecnologico.md`.

## Antes de escribir código

1. Lee `docs/CODING_STANDARDS.md` — POO, KISS, DRY son obligatorios, no sugerencias.
2. Lee `docs/adr/` antes de proponer un cambio de arquitectura o motor. Si tomas una decisión técnica relevante, documéntala ahí como nuevo ADR — no la dejes solo en el historial de commits.
3. Contenido (canciones, personajes, nodos del mapa, escenarios) va en HScript/datos. Código de sistemas (el tablero-mapa, el manager de progreso, shaders) va en clases Haxe propias. Nunca mezcles ambos.

## Reglas duras (no negociables)

- No se edita el código fuente del motor Codename Engine directamente. Si algo parece requerirlo, para y pregunta — probablemente hay una forma vía scripting.
- No se duplica lógica. Si vas a copiar/pegar un bloque de código, extráelo primero.
- No se añaden dependencias/librerías nuevas sin justificar por qué no basta con lo que ya ofrece el motor.
- Todo commit debe compilar en Windows y macOS (o dejarlo explícito si algo es plataforma-específico y por qué).

## Workflow esperado

- Commits pequeños y descriptivos, en español o inglés pero consistente dentro del mismo commit.
- Antes de dar una tarea por cerrada: pasar el checklist de `docs/CODING_STANDARDS.md`.
- Cambios de arquitectura (nuevo sistema, cambio de motor, cambio de enfoque de una feature grande como el tablero-mapa) → ADR nuevo en `docs/adr/`, numerado secuencialmente.
- La estructura de carpetas vive documentada en `docs/PROJECT_STRUCTURE.md` — si creas una carpeta nueva de primer nivel, actualiza ese documento en el mismo cambio.

## Estilo de comunicación esperado del agente

- Directo, sin relleno. Si hay algo ambiguo o una decisión que le corresponde al autor del proyecto (Juan David), pregunta antes de asumir — especialmente en decisiones de arquitectura o de diseño de juego.
- Explicar el porqué de una decisión técnica, no solo el qué, cuando se documenta.

## Referencias

- `docs/adr/0001-motor-y-stack-tecnologico.md` — por qué Codename Engine.
- `docs/CODING_STANDARDS.md` — reglas de código.
- `docs/PROJECT_STRUCTURE.md` — estructura de carpetas.
- [Codename Engine Wiki](https://codename-engine.com/wiki/) — docs oficiales del motor.
