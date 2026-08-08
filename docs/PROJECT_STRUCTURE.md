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
        │       └── StoryMapState.hx   # Tablero-mapa con nodos y progreso
        │
        ├── images/              # Sprites: personajes, escenarios, UI
        │   ├── characters/
        │   ├── stages/
        │   └── ui/
        │       └── mapa/          # Assets propios del tablero-mapa (nodos, ficha, tarjetas)
        │
        ├── scripts/              # Lógica de sistemas propios (softcoded, no toca el core)
        │   ├── map/
        │   │   ├── MapNode.hx       # Modelo de datos de un punto del tablero
        │   │   ├── MapToken.hx      # Ficha visual + movimiento entre nodos
        │   │   └── ProgressManager.hx  # Progreso guardado + lógica de desbloqueo
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
3. **Un sistema nuevo del juego = una carpeta dentro de `scripts/`**, con sus clases siguiendo POO/SRP (ver `CODING_STANDARDS.md`). El tablero-mapa ya sigue este patrón como ejemplo (`scripts/map/`).
4. Si se añade una carpeta de primer nivel nueva, se actualiza este documento en el mismo commit (regla fijada en `AGENTS.md`).
5. **No hay `meta.json` de mod** — Codename Engine no lee ningún archivo de metadata para mods (a diferencia de `songs/<song>/meta.json`, que sí existe pero es otro esquema, de canciones). El nombre del mod se declara en `[Common] NAME=` dentro de `modpack.ini`.
6. **Para probar localmente**, el `.app` compilado busca `mods/` junto a su propio ejecutable (`CodenameEngine.app/Contents/Resources/mods/`), no en la raíz del repo. Se enlaza (symlink) `mods/fnf-echoes/` del repo ahí — el repo sigue siendo la única fuente de verdad, y los cambios se reflejan sin recompilar el motor.
