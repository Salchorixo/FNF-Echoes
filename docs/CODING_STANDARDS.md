# Estándares de código — FNF_Echoes

Este documento es de obligado cumplimiento para todo el código del proyecto (propio o generado con ayuda de IA). Si un cambio no cumple esto, no se hace merge.

## Principios base

### KISS (Keep It Simple, Stupid)
La solución más simple que resuelve el problema es la correcta. Nada de abstracciones "por si acaso" para casos que no existen todavía.
- Una función hace una cosa.
- Si una clase necesita un comentario para explicar qué hace, probablemente hace demasiado.
- Preferir código explícito y legible sobre código "ingenioso".

### DRY (Don't Repeat Yourself)
Ninguna lógica se copia y pega. Si el mismo bloque aparece dos veces, se extrae a un script compartido.
- Ejemplo real en este proyecto: la grilla de tarjetas vive en un único lugar (`scripts/ui/cardMenu.hx`), compartida por `MainMenuState` y `EchoSelectState` vía `Script.create()` — no se reimplementa por cada pantalla.
- Datos repetidos (posiciones de nodos, canciones por punto) van en estructuras de datos (objetos/arrays), no hardcodeados en múltiples archivos.

### POO (Programación Orientada a Objetos)

El contenido de mod en Codename Engine es **HScript puro, interpretado en runtime** — no pasa por el compilador de Haxe. Esto tiene una consecuencia real que cambia cómo se aplica POO aquí, distinta de lo planeado al inicio del proyecto: **HScript no puede declarar clases ni typedefs propios, ni importar entre archivos de mod** (ver `docs/PROJECT_STRUCTURE.md`, regla 3). No existe `class MapNode { ... }` posible dentro de `mods/fnf-echoes/`.

Responsabilidad única se sigue aplicando — a nivel de **archivo/script**, no de clase:

| Archivo | Responsabilidad única |
|---|---|
| `data/states/StoryMapState.hx` | Controlar la pantalla del tablero-mapa: navegación entre nodos, desbloqueo |
| `data/states/OptionsState.hx` | Controlar la pantalla de Options: cinta de categorías + panel de la categoría abierta |
| `scripts/ui/cardMenu.hx` | Grilla de tarjetas + selección (+ paneo leve de cámara), reutilizada por cualquier estado que necesite tarjetas |
| `scripts/ui/nodeArtPanel.hx` | Panel de arte del nodo seleccionado (slide-in + fade), reutilizado por cualquier mapa |
| `scripts/ui/translate.hx` | Diccionario EN/ES de textos propios de la UI, consultado por cualquier pantalla con texto traducible |
| `scripts/effects/vhsShader.hx` | Adjuntar el shader de distorsión a la cámara, sin lógica de gameplay dentro |

Regla de cuándo separar en un script aparte vs. dejar inline en el estado: **solo cuando hay un segundo consumidor real**. Datos usados por una sola pantalla (como los nodos del tablero en `StoryMapState`, o las filas de Controls/Gameplay en `OptionsState`) van como objeto anónimo ahí mismo — crear un archivo aparte para eso sería peso muerto, no POO. `cardMenu.hx`, `nodeArtPanel.hx` y `translate.hx` están separados porque a la fecha ya los usa o va a usar más de una pantalla — `translate.hx` puntualmente nació así: vivía inline en `OptionsState.hx` hasta que `MainMenuState` necesitó las mismas cadenas para sus propias tarjetas.

La comunicación entre scripts se hace por composición explícita (`Script.create(Paths.script('...'))` + `.call()`/`.get()`/`.set()`), nunca accediendo a variables internas de otro script — el mismo espíritu de encapsulamiento de POO, con la herramienta que el motor realmente ofrece.

### Principios SOLID (extensión de POO, aplicar donde tenga sentido)
- **S** — Cada script/archivo, una responsabilidad (ver tabla arriba).
- **O** — Nuevo contenido (canciones, nodos, personajes) se añade sin modificar el código ya probado, mediante datos/scripts (softcoding, ver abajo).
- **D** — Los sistemas se comunican por el contrato de `Script.create()`/`.call()`, no accediendo a variables internas de otro script, cuando haya más de una implementación posible.

No hace falta aplicar los 5 principios SOLID de forma dogmática — el criterio es siempre KISS primero.

## Idioma

Regla fija del proyecto, sin excepciones:

- **Código en inglés**: nombres de variables, funciones, parámetros, y **comentarios dentro del código** (`.hx`, HScript) — sí, esto incluye los comentarios, no solo los identificadores. Es el estándar de la industria y el idioma en el que están los repos de referencia usados en este proyecto (Codename Engine, Haxe Foundation). Un archivo dentro de `mods/` con comentarios en inglés está cumpliendo la regla correctamente, no es una excepción ni un error a corregir.
- **Documentación en español**: archivos `.md` en la raíz y en `docs/` (`README.md`, ADRs, este documento, `context.md`), y mensajes de commit. El TFM y sus evaluadores son de habla hispana. Esta regla aplica a documentos separados del código, no a lo que hay dentro de un archivo `.hx`/HScript.
- No mezclar dentro del código: nada de `nombrePersonaje` ni `player_score` a medias — o todo el identificador en inglés, o no se hace merge.

## Por qué NO Clean Architecture / Hexagonal (y qué se usa en su lugar)

Clean Architecture y Hexagonal (Ports & Adapters) resuelven un problema que este proyecto no tiene: proteger la lógica de negocio de que cambien la base de datos, el framework web, o el proveedor externo. Aquí el motor (Codename Engine) es una decisión permanente, no una pieza a intercambiar — y las capas de abstracción que exige ese estilo (interfaces por todos lados, inyección de dependencias, repositorios) cuestan rendimiento real, justo lo que el criterio de "sin lag en dispositivos modestos" pide cuidar.

En su lugar, este proyecto usa los patrones propios de desarrollo de juegos:

- **Arquitectura basada en estados/escenas**: ya la trae HaxeFlixel (`FlxState`, `FlxSubState`). `StoryMapState` es un ejemplo directo, no algo que haya que inventar.
- **Observer para eventos**: por ejemplo, que el script de un nodo avise "nodo completado" vía `.call()` sin que el tablero pregunte constantemente (ver [HaxeFoundation/code-cookbook](https://github.com/HaxeFoundation/code-cookbook)).
- **ECS**: deliberadamente no se usa — es para juegos con muchísimas entidades dinámicas; con las pocas entidades bien definidas de este proyecto sería sobre-ingeniería.

La idea original era ir más lejos y tomar prestado de Hexagonal el aislar lógica/datos puros (reglas de desbloqueo, progreso) en clases Haxe compiladas, separadas de `FlxSprite`/renderizado, para que fueran testeables. **Eso no resultó viable tal cual**: como se explica en la sección de POO, el contenido de mod (`mods/fnf-echoes/`) es HScript interpretado, sin classpath compilado propio — no hay dónde poner esas clases sin agregar una fuente Haxe nueva al build del motor. La idea de fondo (separar reglas de datos del código de render) se mantiene, pero hoy se expresa como scripts/funciones HScript ordenados por responsabilidad (ver `confirmSelection()` en `StoryMapState.hx`), no como clases Haxe aisladas.

## Testing: por qué hoy es manual, no automatizado

No se testea todo el juego — no tiene sentido ni es práctico. Lo que se ve/siente (shaders, animaciones, sincronía audio-nota) se valida jugando, no con asserts.

El plan original era testear con `utest` la lógica pura (reglas de desbloqueo, transiciones de estado) aislada en clases Haxe compiladas. Al implementar se confirmó que eso no es posible sin trabajo adicional: el contenido de mod es HScript sin classpath compilado propio, y `utest` solo puede testear clases Haxe reales, no funciones HScript sueltas dentro de un estado.

Mientras eso no cambie: la lógica de estado (¿se desbloquea el nodo correcto?, ¿la ficha llega al índice esperado?) se valida **manual, jugando** — y cualquier bug de este tipo se documenta en el commit que lo arregla, no se pretende tener cobertura automatizada que hoy no es alcanzable sin romper KISS. Si en algún momento se justifica agregar un classpath Haxe compilado propio (fuera de `mods/`, fuera de `engine/`) específicamente para lógica testeable con `utest`, esa decisión se documenta como ADR nuevo antes de implementarse — es un cambio del mismo calibre que el parche de transparencia de ventana (ver ADR-0003), no un ajuste de estilo.

## Convenciones específicas de Haxe

- Un archivo `.hx` por clase, el nombre del archivo coincide exactamente con el nombre de la clase (mayúsculas incluidas).
- Formateo automático con [`haxe-formatter`](https://github.com/HaxeCheckstyle/haxe-formatter) — no discutir estilo de llaves/espacios a mano, lo decide el formatter.
- Nombres: `PascalCase` para clases, `camelCase` para variables/funciones, `UPPER_SNAKE_CASE` para constantes.
- Tipado explícito en firmas públicas de funciones (evitar `Dynamic` salvo que sea estrictamente necesario por la API del motor).

## Arquitectura: softcoding con Codename Engine

Codename Engine permite añadir contenido (canciones, personajes, escenarios, notetypes, eventos) mediante **HScript**, sin tocar el código fuente del motor. Regla del proyecto:

- Si es contenido (una canción nueva, un personaje, un nodo del mapa) → va en datos o script (HScript), **no** en el core.
- Si es un sistema nuevo del juego (el tablero-mapa, paneles reutilizables) → va en HScript dentro de `mods/fnf-echoes/scripts/`, compuesto vía `Script.create()` cuando lo usa más de una pantalla; inline en el estado si solo lo usa esa pantalla (ver sección de POO arriba y `docs/PROJECT_STRUCTURE.md`, regla 3).
- Nunca se edita el código fuente de Codename Engine directamente salvo necesidad justificada y documentada en un ADR.

Referencia oficial de scripting: [Codename Engine Wiki — Scripting](https://codename-engine.com/wiki/modding/scripting/) y [API Docs](https://codename-engine.com/api-docs/).

## Referencias externas (repos públicos usados como guía)

- [HaxeFoundation/code-cookbook](https://github.com/HaxeFoundation/code-cookbook) — patrones de diseño oficiales en Haxe (Observer, Factory, Singleton, etc.), mantenido por la Haxe Foundation.
- [midorikocak/haxe-design-patterns](https://github.com/midorikocak/haxe-design-patterns) — ejemplos prácticos de patrones de diseño en Haxe.
- [AmrMosallem/Clean-Code-and-Design-Patterns](https://github.com/AmrMosallem/Clean-Code-and-Design-Patterns) — referencia de Clean Code y SOLID, agnóstica de lenguaje, útil para justificar decisiones en la memoria del TFM.
- [CodenameCrew/CodenameEngine](https://github.com/CodenameCrew/CodenameEngine) — código fuente del motor base, para entender qué es "core" y qué es "contenido".

## Checklist antes de dar por cerrada una funcionalidad

1. [ ] ¿Cada script/módulo nuevo tiene una única responsabilidad clara?
2. [ ] ¿Hay lógica o datos duplicados que se puedan extraer?
3. [ ] ¿La solución es la más simple posible para el problema actual (no para un futuro hipotético)?
4. [ ] ¿El contenido (no el sistema) está en scripts/datos y no hardcodeado en el core?
5. [ ] ¿Pasó el formatter (`haxe-formatter`)?
