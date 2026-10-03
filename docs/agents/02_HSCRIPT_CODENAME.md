# 02 — HScript en Codename Engine (cómo se escribe código en este mod)

Todo lo de `mods/fnf-echoes/` es **HScript**: Haxe interpretado en tiempo de
ejecución. Se parece a Haxe, pero tiene límites importantes. Este documento
muestra **los patrones que ya usa el repo**. Cópialos; no inventes otros.

---

## 1. Las 5 reglas que más se rompen

1. **No hay `class ... extends ...`** en los archivos de estado. Un estado es una lista de funciones sueltas: `create()`, `update(elapsed)`, `destroy()`.
2. **No hay `import` entre archivos del mod.** `import MiScript;` no funciona. Para compartir código se usa `Script.create(...)` (§3).
3. **Los `import` solo sirven para clases del motor o de librerías** (`flixel.*`, `funkin.*`). Antes de importar algo, confirma que existe: `grep -rn "class NombreClase" engine/source`.
4. **Código y comentarios en inglés.**
5. **Cada pantalla resetea su cámara** al inicio de `create()`: `FlxG.camera.scroll.set(0, 0);` (ver `04_TRAMPAS_CONOCIDAS.md`).

## 2. Esqueleto de un estado (pantalla)

Basado en `data/states/MainMenuState.hx`:

```haxe
import flixel.util.FlxColor;
import funkin.backend.scripting.ModState;
import funkin.backend.scripting.Script;

// Short English comment explaining WHY this screen exists.
var myHelper:Script;

function create() {
	FlxG.camera.scroll.set(0, 0); // every screen resets its own camera
	bgColor = FlxColor.BLACK;

	// VHS effect is attached per state (the global hook never fired, see traps doc)
	var vhsFx = Script.create(Paths.script('scripts/effects/vhsShader'));
	vhsFx.load();
	vhsFx.call('attach');
}

function update(elapsed) {
	if (controls.ACCEPT)
		FlxG.switchState(new ModState("OtherState"));

	if (controls.BACK)
		FlxG.switchState(new ModState("MainMenuState"));
}
```

- Archivo: `mods/fnf-echoes/data/states/NombreState.hx` (la ruta la fija el motor; no se puede cambiar).
- Para abrir una pantalla propia: `FlxG.switchState(new ModState("NombreState"));`
- Controles que ya usa el repo: `controls.LEFT_P`, `controls.RIGHT_P`, `controls.ACCEPT`, `controls.BACK`. Para otros, busca primero: `grep -rn "_P" mods/fnf-echoes/data/states`.

## 3. Compartir código: `Script.create`

Patrón exacto del repo (no te saltes `.load()`):

```haxe
var cardMenu:Script;

function create() {
	cardMenu = Script.create(Paths.script('scripts/ui/cardMenu'));
	cardMenu.load();
	cardMenu.call("create", [labels]);           // call a function with arguments
}

function update(elapsed) {
	var index = cardMenu.call("getSelectedIndex"); // call returns a value
}
```

- La ruta va **sin** `.hx`: `Paths.script('scripts/ui/cardMenu')`.
- Las funciones del script compartido son funciones sueltas en ese archivo (`function create(labels) { ... }`).
- **Antes de llamar una función de un script, abre el script y confirma su nombre y sus argumentos.** No adivines.
- Regla de cuándo crear un script compartido: **solo cuando dos pantallas lo usan de verdad.** Si solo lo usa una, va dentro de esa pantalla.

Scripts compartidos que existen hoy:

| Script | Funciones que se llaman desde fuera | Para qué |
|---|---|---|
| `scripts/ui/cardMenu.hx` | `create(labels)`, `changeSelection(dir)`, `getSelectedIndex()` | Grilla de tarjetas (menú principal, selección de Echo) |
| `scripts/ui/translate.hx` | `get(key)` | Textos EN/ES de la UI |
| `scripts/ui/nodeArtPanel.hx` | (ábrelo y revisa) | Panel de arte del tablero-mapa |
| `scripts/effects/vhsShader.hx` | `attach()` | Pone el shader VHS en la cámara |

Si esta tabla no coincide con los archivos, **mandan los archivos**: corrige la tabla.

## 4. Reemplazar una pantalla nativa del motor

Si tu pantalla debe **sustituir** a una del motor (no solo existir), añádela en
`mods/fnf-echoes/data/config/modpack.ini`:

```ini
[StateRedirects]
TitleState="TitleState"
MainMenuState="MainMenuState"
```

Formato: `EstadoNativo="TuEstado"`. Si tu pantalla es nueva (no reemplaza
nada), **no** hace falta tocar este archivo: se abre con `new ModState(...)`.

## 5. Textos e idioma

- Los textos que ve el jugador pasan por `translate.hx`: `i18n.call("get", ["KEY"])`.
- **"ECHOES" y "ECHO" nunca se traducen.** Se quedan en inglés siempre.
- Las claves (`"OPTIONS"`, `"CREDITS"`) son estables y en inglés; la lógica compara claves, nunca el texto mostrado (ver `MainMenuState.hx`).

## 6. Cómo confirmar que algo existe antes de usarlo

```bash
grep -rn "function nombre" engine/source           # ¿existe en el motor?
grep -rn "nombre" mods/fnf-echoes                    # ¿ya lo usa el mod?
ls engine/assets/<carpeta>                           # ¿cómo lo organiza el motor?
```

Documentación oficial (si tienes internet): https://codename-engine.com/wiki/
y https://codename-engine.com/api-docs/. Si la documentación y el código del
motor se contradicen, **manda el código de `engine/source/`** (está pineado a
un commit concreto).
