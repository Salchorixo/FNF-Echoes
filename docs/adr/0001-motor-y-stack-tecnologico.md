# ADR-0001: Motor de juego y stack tecnológico de FNF_Echoes

**Status:** Accepted
**Date:** 2026-07-29
**Deciders:** Salchorixo

## Contexto

FNF_Echoes es un mod/juego basado en Friday Night Funkin' (rhythm game), desarrollado como Trabajo de Fin de Máster (Máster de Desarrollo con IA). El proyecto debe cumplir 4 criterios técnicos no negociables:

1. Jugable en **Windows y macOS**.
2. Soporte de **transparencia de ventana**, **pantalla completa**, y efectos de **cámara** (shake, movimiento suave) sin romperse en ninguno de los dos sistemas operativos — con el nivel de calidad que ya demuestra el mod *Sonic.exe Rewrite*.
3. Motor **potente y moderno**, capaz de manejar chartings y animaciones exigentes sin lag en dispositivos modestos.
4. El código debe poder escribirse siguiendo **POO, KISS y DRY** de forma real y demostrable — requisito clave porque el TFM se evalúa también en calidad de ingeniería, no solo en el resultado visual.

Adicionalmente, el proyecto añade dos requisitos funcionales propios que condicionan la elección de motor:

- Efectos visuales de **VHS / distorsión** (scanlines, ruido, aberración cromática, glitches).
- Un **menú principal no estándar**: 3 tarjetas seleccionables; la primera abre un **tablero-mapa** con varios puntos (2-3 canciones por punto); al completar un punto, una ficha se desplaza al siguiente punto del tablero; al completar todo el tablero se desbloquea otra de las 3 tarjetas.

## Decisión

Se usará **Codename Engine** (Haxe + HaxeFlixel + OpenFL) como motor base del proyecto.

## Opciones consideradas

### Opción A: Codename Engine

| Dimensión | Evaluación |
|---|---|
| Multiplataforma | Build oficial de Windows, macOS y Linux ya resuelto y distribuido (fnf-cne-devs.github.io) |
| Rendimiento | Diseñado desde cero con optimización como prioridad; usa forks propios de librerías para mejor rendimiento |
| Arquitectura | Softcoding (scripts HScript) — el contenido nuevo no requiere tocar el código fuente del motor; separación limpia entre motor y contenido |
| Shaders/VFX | Sistema propio `CustomShader` (fragment + vertex), compatible con shaders GLSL tipo VHS/CRT |
| Mantenimiento | Desarrollo activo (CodenameCrew, 2026) |
| Curva de aprendizaje | Media — requiere entender HScript además de Haxe |
| Comunidad/documentación | Menor que Psych Engine, pero con wiki oficial propia (codename-engine.com) |

**Pros:** arquitectura más limpia y modular (mejor encaje con POO/KISS/DRY), mejor rendimiento, macOS resuelto oficialmente, shaders de primera clase.
**Contras:** comunidad y tutoriales más reducidos que Psych Engine; menos ejemplos de terceros para copiar directamente.

### Opción B: Psych Engine

| Dimensión | Evaluación |
|---|---|
| Multiplataforma | Windows sólido; soporte macOS descrito por los propios desarrolladores como "planeado, con problemas pendientes" (issues reportados de builds que no abren) |
| Rendimiento | Orientado a "casual play" y facilidad de modding, no a optimización como prioridad de diseño |
| Arquitectura | Para añadir estados o funcionalidades fuera del gameplay estándar hay que editar directamente el código fuente del motor (más hardcodeado) |
| Shaders/VFX | Soporta shaders vía OpenFL/HaxeFlixel (misma base que Codename); es el motor que usa *Sonic.exe Rewrite*, la referencia visual dada |
| Mantenimiento | Motor más popular y usado del ecosistema FNF |
| Curva de aprendizaje | Baja — enorme cantidad de tutoriales y scripts de terceros ya hechos |
| Comunidad/documentación | La más grande de todo el ecosistema de mods de FNF |

**Pros:** comunidad y documentación masivas, es literalmente el motor de la referencia visual dada (Sonic.exe Rewrite), curva de entrada más baja.
**Contras:** soporte de macOS no resuelto de forma oficial (riesgo directo sobre el criterio 1), arquitectura más hardcodeada (roza el criterio 4).

## Análisis de trade-offs

El criterio decisivo es el cruce entre el criterio 1 (macOS obligatorio) y el criterio 4 (arquitectura limpia demostrable). Psych Engine gana en comunidad y es el origen directo del efecto visual de referencia, pero su soporte de macOS es la debilidad más citada por su propia comunidad — riesgo real de incumplir un requisito no negociable del proyecto. Codename Engine resuelve macOS de forma oficial y su arquitectura softcoded encaja de forma natural con POO/KISS/DRY, que es justamente lo que se necesita documentar para la evaluación del TFM.

Los efectos visuales de la referencia (transparencia, shake, movimiento de cámara) no son exclusivos de Psych Engine: son técnicas del framework OpenFL/HaxeFlixel subyacente, compartido por ambos motores, por lo que son igualmente reproducibles en Codename Engine.

## Consecuencias

- Se gana: arquitectura más limpia y mantenible, macOS resuelto sin trabajo extra de packaging/firma, mejor rendimiento base para charts/animaciones exigentes.
- Se pierde: menos tutoriales de terceros directamente copiables; habrá que traducir soluciones documentadas para Psych Engine al equivalente en Codename Engine en algunos casos puntuales.
- A revisar más adelante: rendimiento real en dispositivos modestos una vez el tablero-mapa y los shaders VHS estén implementados (validar con perfilado, no solo con la decisión teórica).

## Action Items

1. [ ] Clonar y compilar Codename Engine localmente (Windows y macOS) para validar el build antes de empezar contenido.
2. [ ] Prototipar el shader VHS/distorsión como prueba de concepto aislada.
3. [ ] Prototipar la pantalla de tablero-mapa (`StoryMapState`) como prueba de concepto aislada, antes de integrarla al flujo completo.
4. [ ] Definir estructura de carpetas del proyecto (ver documento de estructura, en curso).
5. [ ] Documentar convenciones de código (POO/KISS/DRY) en `CODING_STANDARDS.md` (en curso).
