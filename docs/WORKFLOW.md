# Workflow — Cowork ↔ Claude Code (u otro editor con IA)

Este documento define cómo se reparte el trabajo entre herramientas de IA en este proyecto: **Cowork** (planeación/documentación) y **Claude Code u otro editor local con IA** (Cursor, Windsurf, Copilot en VS Code — construcción/compilación/pruebas). No es una preferencia de gustos: cada herramienta tiene una vuelta de feedback distinta, y el trabajo se asigna según cuál la tiene.

## División de responsabilidades

| | Cowork | Claude Code / editor local |
|---|---|---|
| Investigación (motor, licencias, legal) | ✅ | — |
| Decisiones de arquitectura (ADRs) | ✅ | ✅ (documenta lo decidido) |
| Documentación (`README`, `docs/`) | ✅ | ✅ (actualiza si algo cambió) |
| Entregables no-código (slides, avisos legales) | ✅ | — |
| Escribir código `.hx` / HScript | — | ✅ |
| Compilar y ver errores del compilador | — | ✅ |
| Correr el juego y validar visualmente (shaders, cámara, animaciones) | — | ✅ |
| Iterar rápido con feedback real | — | ✅ |

La razón de fondo: Cowork no puede compilar Haxe/OpenFL ni mostrarte si el shader VHS se ve bien en pantalla — no tiene esa vuelta de feedback. Claude Code (o el editor que uses) sí, porque corre en tu máquina real con el motor instalado.

## El puente entre herramientas: `AGENTS.md`

`AGENTS.md` en la raíz del repo es la fuente única de verdad, independiente de qué herramienta la lea. `CLAUDE.md` la importa (`@AGENTS.md`) para Claude Code. Si en algún momento se usa Cursor, Copilot u otro editor, el mismo patrón aplica: un archivo específico de esa herramienta que importe `AGENTS.md` en vez de duplicar las reglas (ver `context.md` para el razonamiento completo detrás de esta organización).

Esto significa que una decisión tomada en una sesión de Cowork (ej. "el motor es Codename Engine", "código en inglés") está disponible automáticamente la próxima vez que se abra Claude Code sobre el mismo repo — no hay que repetir contexto a mano.

## Sincronización: git, no magia

La carpeta del proyecto es literalmente la misma en disco para Cowork y para Claude Code (ambos operan sobre `~/FNF_Echoes`). No hay un paso de "sincronizar" — hay una disciplina:

1. **Antes de empezar a trabajar en cualquiera de las dos**, revisar `git log`/`git status` para partir del estado real, no de uno viejo.
2. **No trabajar en ambas herramientas al mismo tiempo** sobre los mismos archivos — mismo riesgo que dos personas editando el mismo archivo a la vez.
3. **Commitear antes de cambiar de herramienta.** Así la siguiente sesión (en la otra herramienta) arranca limpia.

## Regla de retroalimentación (la que más se olvida)

Si mientras se programa en Claude Code se toma una decisión de arquitectura no trivial — un cambio de enfoque, una limitación del motor descubierta a mitad de implementación, una razón de rendimiento para estructurar algo distinto a lo planeado — **esa decisión se documenta de vuelta** en `docs/adr/` (si es una decisión de arquitectura) o `docs/CODING_STANDARDS.md` (si es una convención). No se queda solo implícita en el código o en un mensaje de commit.

Sin esta regla, la documentación se desactualiza silenciosamente y la próxima sesión de planeación en Cowork parte de premisas incorrectas.

## Rutina práctica por sesión

**Al empezar** (en cualquiera de las dos): leer `AGENTS.md`, revisar si hay ADRs nuevos en `docs/adr/` desde la última sesión.

**Durante el trabajo**: seguir las reglas ya fijadas — softcoding en Codename Engine (contenido en scripts/datos, no en el core), POO/KISS/DRY, código en inglés y documentación en español (ver `docs/CODING_STANDARDS.md`).

**Al terminar**: commit con mensaje claro. Si hubo una decisión de arquitectura, actualizar `docs/adr/` o `CODING_STANDARDS.md` en el mismo commit o uno inmediato.

## Qué le toca a Claude Code ahora mismo

Los pendientes ya definidos en `docs/adr/0001-motor-y-stack-tecnologico.md` que requieren compilar/correr el juego, es decir, que le tocan a Claude Code y no a Cowork:

1. Clonar y compilar Codename Engine localmente (Windows y macOS).
2. Prototipar el shader VHS/distorsión como prueba de concepto aislada.
3. Prototipar `StoryMapState` (el tablero-mapa) como prueba de concepto aislada.
