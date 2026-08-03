# Estándares de código — FNF_Echoes

Este documento es de obligado cumplimiento para todo el código del proyecto (propio o generado con ayuda de IA). Si un cambio no cumple esto, no se hace merge.

## Principios base

### KISS (Keep It Simple, Stupid)
La solución más simple que resuelve el problema es la correcta. Nada de abstracciones "por si acaso" para casos que no existen todavía.
- Una función hace una cosa.
- Si una clase necesita un comentario para explicar qué hace, probablemente hace demasiado.
- Preferir código explícito y legible sobre código "ingenioso".

### DRY (Don't Repeat Yourself)
Ninguna lógica se copia y pega. Si el mismo bloque aparece dos veces, se extrae a una función, clase o script compartido.
- Ejemplo en este proyecto: la lógica de "desplazar la ficha de un punto a otro del tablero" vive en un único lugar (`MapToken`), no se reimplementa por cada tablero o nivel.
- Datos repetidos (posiciones de nodos, canciones por punto) van en estructuras de datos (JSON/arrays), no hardcodeados en múltiples archivos.

### POO (Programación Orientada a Objetos)
Cada sistema del juego se modela como una clase con responsabilidad única (principio SRP de SOLID). Ejemplo aplicado a los sistemas propios de FNF_Echoes:

| Clase | Responsabilidad única |
|---|---|
| `StoryMapState` | Renderizar y controlar la pantalla del tablero-mapa |
| `MapNode` | Representar un punto del tablero: posición, canciones asociadas, estado (bloqueado/completado) |
| `MapToken` | La ficha visual y su animación/movimiento entre nodos |
| `ProgressManager` | Guardar y leer el progreso del jugador; decide cuándo se desbloquea una tarjeta |
| `VHSShader` | Encapsular el shader de distorsión, sin lógica de gameplay dentro |

Ninguna de estas clases debe conocer los detalles internos de las otras — se comunican por métodos públicos claros, no accediendo a variables internas ajenas.

### Principios SOLID (extensión de POO, aplicar donde tenga sentido)
- **S** — Cada clase, una responsabilidad (ver tabla arriba).
- **O** — Nuevo contenido (canciones, nodos, personajes) se añade sin modificar el código ya probado, mediante datos/scripts (softcoding, ver abajo).
- **D** — Los sistemas dependen de interfaces/contratos simples, no de implementaciones concretas de otros sistemas, cuando haya más de una implementación posible.

No hace falta aplicar los 5 principios SOLID de forma dogmática — el criterio es siempre KISS primero.

## Idioma

Regla fija del proyecto, sin excepciones:

- **Código en inglés**: nombres de clases, variables, funciones, parámetros, y comentarios dentro del código (`.hx`, HScript). Es el estándar de la industria y el idioma en el que están los repos de referencia usados en este proyecto (Codename Engine, Haxe Foundation).
- **Documentación en español**: `README.md`, ADRs, este documento, `context.md`, mensajes de commit. El TFM y sus evaluadores son de habla hispana.
- No mezclar: nada de `nombrePersonaje` ni `player_score` a medias — o todo el identificador en inglés, o no se hace merge.

## Por qué NO Clean Architecture / Hexagonal (y qué se usa en su lugar)

Clean Architecture y Hexagonal (Ports & Adapters) resuelven un problema que este proyecto no tiene: proteger la lógica de negocio de que cambien la base de datos, el framework web, o el proveedor externo. Aquí el motor (Codename Engine) es una decisión permanente, no una pieza a intercambiar — y las capas de abstracción que exige ese estilo (interfaces por todos lados, inyección de dependencias, repositorios) cuestan rendimiento real, justo lo que el criterio de "sin lag en dispositivos modestos" pide cuidar.

En su lugar, este proyecto usa los patrones propios de desarrollo de juegos:

- **Arquitectura basada en estados/escenas**: ya la trae HaxeFlixel (`FlxState`, `FlxSubState`). `StoryMapState` es un ejemplo directo, no algo que haya que inventar.
- **Observer para eventos**: por ejemplo, que `ProgressManager` avise "nodo completado" sin que el tablero pregunte constantemente (ver [HaxeFoundation/code-cookbook](https://github.com/HaxeFoundation/code-cookbook)).
- **ECS**: deliberadamente no se usa — es para juegos con muchísimas entidades dinámicas; con las pocas entidades bien definidas de este proyecto sería sobre-ingeniería.

Lo que sí se toma prestado de Hexagonal, aplicado solo donde aporta: sistemas que son lógica/datos puros (`ProgressManager`, `MapNode`) se escriben como clases Haxe sin depender de `FlxSprite` ni de renderizado. Eso los hace testeables y portables sin necesidad de adoptar el patrón completo — la idea de fondo, no la ceremonia.

## Testing: selectivo, no total

No se testea todo el juego — no tiene sentido ni es práctico. Lo que se ve/siente (shaders, animaciones, sincronía audio-nota) se valida jugando, no con asserts.

Sí se testean las piezas de lógica pura, exactamente las mismas que se aislaron del motor en la sección anterior: `ProgressManager` (reglas de desbloqueo), `MapNode` (transiciones de estado), y cualquier lógica de guardado/carga. Son baratas de testear porque ya están separadas del motor, y un bug ahí es silencioso (ej. una tarjeta que se desbloquea con solo 2 de 3 canciones) — el tipo de error que un playtest manual puede no notar nunca.

Herramienta: [utest](https://github.com/haxe-utest/utest), la librería de testing más usada en Haxe.

## Convenciones específicas de Haxe

- Un archivo `.hx` por clase, el nombre del archivo coincide exactamente con el nombre de la clase (mayúsculas incluidas).
- Formateo automático con [`haxe-formatter`](https://github.com/HaxeCheckstyle/haxe-formatter) — no discutir estilo de llaves/espacios a mano, lo decide el formatter.
- Nombres: `PascalCase` para clases, `camelCase` para variables/funciones, `UPPER_SNAKE_CASE` para constantes.
- Tipado explícito en firmas públicas de funciones (evitar `Dynamic` salvo que sea estrictamente necesario por la API del motor).

## Arquitectura: softcoding con Codename Engine

Codename Engine permite añadir contenido (canciones, personajes, escenarios, notetypes, eventos) mediante **HScript**, sin tocar el código fuente del motor. Regla del proyecto:

- Si es contenido (una canción nueva, un personaje, un nodo del mapa) → va en datos o script (HScript), **no** en el core.
- Si es un sistema nuevo del juego (el tablero-mapa, el manager de progreso) → va en clases Haxe propias, documentadas, dentro de una carpeta separada del motor (ver documento de estructura de carpetas).
- Nunca se edita el código fuente de Codename Engine directamente salvo necesidad justificada y documentada en un ADR.

Referencia oficial de scripting: [Codename Engine Wiki — Scripting](https://codename-engine.com/wiki/modding/scripting/) y [API Docs](https://codename-engine.com/api-docs/).

## Referencias externas (repos públicos usados como guía)

- [HaxeFoundation/code-cookbook](https://github.com/HaxeFoundation/code-cookbook) — patrones de diseño oficiales en Haxe (Observer, Factory, Singleton, etc.), mantenido por la Haxe Foundation.
- [midorikocak/haxe-design-patterns](https://github.com/midorikocak/haxe-design-patterns) — ejemplos prácticos de patrones de diseño en Haxe.
- [AmrMosallem/Clean-Code-and-Design-Patterns](https://github.com/AmrMosallem/Clean-Code-and-Design-Patterns) — referencia de Clean Code y SOLID, agnóstica de lenguaje, útil para justificar decisiones en la memoria del TFM.
- [CodenameCrew/CodenameEngine](https://github.com/CodenameCrew/CodenameEngine) — código fuente del motor base, para entender qué es "core" y qué es "contenido".

## Checklist antes de dar por cerrada una funcionalidad

1. [ ] ¿Cada clase nueva tiene una única responsabilidad clara?
2. [ ] ¿Hay lógica o datos duplicados que se puedan extraer?
3. [ ] ¿La solución es la más simple posible para el problema actual (no para un futuro hipotético)?
4. [ ] ¿El contenido (no el sistema) está en scripts/datos y no hardcodeado en el core?
5. [ ] ¿Pasó el formatter (`haxe-formatter`)?
