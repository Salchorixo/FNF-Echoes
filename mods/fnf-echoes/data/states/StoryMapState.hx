import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.backend.scripting.ModState;

// Placeholder for Fase 5 (tablero-mapa: nodos, ficha, progreso). Reached
// from EchoSelectState by confirming the unlocked "ECHO 1" card.
var placeholderText:FlxText;
var canContinue:Bool = false;

function create() {
	placeholderText = new FlxText(0, 0, FlxG.width, "STORY MAP\n(Fase 5 — próximamente)\n\npress any key to go back");
	placeholderText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, "center");
	placeholderText.screenCenter();
	add(placeholderText);

	new FlxTimer().start(0.2, (_) -> canContinue = true);
}

function update(elapsed) {
	if (canContinue && FlxG.keys.justPressed.ANY)
		FlxG.switchState(new ModState("EchoSelectState"));
}
