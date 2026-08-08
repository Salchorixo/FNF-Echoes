# Estructura de carpetas — FNF_Echoes

Basada en la convención oficial de mods de Codename Engine (carpeta `./mods`), más las carpetas de documentación y entregables que exige el TFM.

```
FNF_Echoes/
├── AGENTS.md                  # Instrucciones para agentes IA (fuente de verdad)
├── CLAUDE.md                  # Import de AGENTS.md para Claude Code
├── README.md                  # Documentación oficial de entrega del TFM
├── TFM-Requisitos.md          # Checklist de requisitos de entrega (ya creado)
│
├── docs/
│   ├── CODING_STANDARDS.md    # POO, KISS, DRY, convenciones Haxe
│   ├── PROJECT_STRUCTURE.md   # Este documento
│   ├── DEPLOY.md              # Instrucciones de publicación en itch.io
│   └── adr/                   # Architecture Decision Records
│       └── 0001-motor-y-stack-tecnologico.md
│
├── engine/                    # Código fuente de Codename Engine — git submodule pineado a un
│                               # commit fijo (no sigue main). Ver docs/adr/0001-motor-y-stack-tecnologico.md.
│                               # NO SE EDITA salvo ADR que lo justifique
│
└── mods/
    └── fnf-echoes/             # El mod/juego en sí — todo el contenido y sistemas propios
        ├── songs/               # Canciones: Inst.ogg, Voices.ogg por dificultad
        │   └── <song-name>/
        │
        ├── charts/              # Charts (.json) por canción y dificultad
        │
        ├── data/                # Definiciones sin código + estados custom softcodeados
        │   ├── characters/         # XML de personajes
        │   ├── stages/             # XML de escenarios
        │   ├── config/
        │   │   └── modpack.ini       # Config del mod: [StateRedirects] (qué HScript reemplaza
        │   │                         # qué estado nativo), nombre del mod, etc.
        │   └── states/              # Pantallas custom — HScript plano (funciones sueltas
        │       │                    # create/update/destroy, SIN "class ... extends"),
        │       │                    # corrido vía ModState del motor. Path fijado por el motor,
        │       │                    # no elegible (Paths.script('data/states/$name')).
        │       ├── TitleState.hx      # Intro/boot (reemplaza el TitleState nativo)
        │       ├── MainMenuState.hx   # Menú de 3 tarjetas
        │       ├── EchoSelectState.hx # Selección de Echo/temporada (solo Echo 1 desbloqueado)
        │       ├── LoadingState.hx    # Pantalla de carga (Fase 4) — ojo estático + barra placeholder
        │       └── StoryMapState.hx   # Tablero-mapa con nodos y progreso
        │
        ├── images/              # Sprites: personajes, escenarios, UI
        │   ├── characters/
        │   ├── stages/
        │   └── ui/
        │       └── mapa/          # Assets propios del tablero-mapa (nodos, ficha, tarjetas)
        │
        ├── scripts/              # Lógica de sistemas propios (softcoded, no toca el core)
        │   ├── ui/
        │   │   ├── cardMenu.hx      # Grilla de tarjetas + selección, compartida vía
        │   │   │                    # Script.create() entre MainMenuState y EchoSelectState
        │   │   └── nodeArtPanel.hx  # Panel de arte del tablero-mapa (slide-in + fade),
        │   │                        # compartido igual, para cuando haya más de un mapa
        │   ├── effects/
        │   │   └── vhsShader.hx     # Adjunta VHSShader.frag a la cámara — cada estado lo
        │   │                        # llama en su propio create() (ver regla 7)
        │   └── gameplay/           # Scripts de gameplay (eventos, notetypes propios)
        │
        ├── shaders/               # Shaders GLSL propios
        │   └── VHSShader.frag      # Efecto de distorsión/VHS
        │
        ├── sounds/                # SFX de UI (selección de tarjeta, movimiento de ficha, etc.)
        ├── music/                 # Música de menú
        └── fonts/                 # Tipografías propias
```

## Reglas de esta estructura

1. **`engine/` es intocable** salvo decisión documentada en un ADR nuevo. Todo lo demás (contenido y sistemas propios) vive en `mods/fnf-echoes/`. Actualizar la versión del motor implica `git submodule update` a un nuevo commit + nota en el ADR-0001 — nunca editar archivos dentro de `engine/` directamente.
2. **`data/states/` y `scripts/` son código softcoded** (HScript), no requieren recompilar el motor — coherente con la arquitectura elegida en el ADR-0001. Para reemplazar completamente un estado nativo (no solo agregarle lógica), hace falta además la entrada correspondiente en `[StateRedirects]` de `data/config/modpack.ini`.
3. **No existen clases Haxe propias importables entre archivos de mod.** El contenido de un mod se carga en runtime como HScript, nunca pasa por el compilador de Haxe — `import MiClase;` sobre un archivo dentro de `mods/` no resuelve (`Type.resolveClass` solo ve el classpath compilado). La única forma real de compartir comportamiento entre estados/scripts es composición vía `Script.create(Paths.script('scripts/.../archivo'))` + `.call()/.get()/.set()` (el mismo mecanismo que usa el motor para `Character`/`Stage`), como `scripts/ui/cardMenu.hx` y `scripts/ui/nodeArtPanel.hx`. Si un sistema nuevo solo lo usa un estado, la lógica va inline en ese estado — separar en un script aparte recién cuando hay un segundo consumidor real.
4. Si se añade una carpeta de primer nivel nueva, se actualiza este documento en el mismo commit (regla fijada en `AGENTS.md`).
5. **No hay `meta.json` de mod** — Codename Engine no lee ningún archivo de metadata para mods (a diferencia de `songs/<song>/meta.json`, que sí existe pero es otro esquema, de canciones). El nombre del mod se declara en `[Common] NAME=` dentro de `modpack.ini`.
6. **Para probar localmente**, el `.app` compilado busca `mods/` junto a su propio ejecutable (`CodenameEngine.app/Contents/Resources/mods/`), no en la raíz del repo. Se enlaza (symlink) `mods/fnf-echoes/` del repo ahí — el repo sigue siendo la única fuente de verdad, y los cambios se reflejan sin recompilar el motor.
7. **El shader VHS se adjunta por-estado, no globalmente.** El motor tiene un hook pensado exactamente para esto (`data/global/LIB_$modName.hx`, disparado por `postStateSwitch`) pero en esta sesión nunca se ejecutó — ni ese hook ni un `update()` simple en el mismo archivo llegaron a dispararse, sin error ni explicación visible, con el archivo confirmado en el lugar correcto. Quedó sin diagnosticar. Mientras tanto, cada estado llama `Script.create(Paths.script('scripts/effects/vhsShader')).call('attach')` al inicio de su propio `create()` — mismo patrón de composición que `cardMenu`/`nodeArtPanel`, solo que repetido en cada estado en vez de centralizado. Si algún día se resuelve el misterio del global script, esto se puede consolidar ahí.
