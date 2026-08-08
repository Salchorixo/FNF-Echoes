import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.backend.scripting.ModState;
import funkin.menus.MainMenuState;

// Placeholder for Fase 3 (selección de Echo/temporada). Only Echo 1 will be
// unlockable there; Echo 2 and 3 are reserved for a future full version.
var placeholderText:FlxText;

// Guards against the key press that opened this state still being
// "justPressed" on this state's very first update() — without this, the
// same physical key press that confirmed "ECHOES" would immediately bounce
// back to the menu.
var canContinue:Bool = false;

function create() {
	placeholderText = new FlxText(0, 0, FlxG.width, "ECHO SELECT\n(Fase 3 — próximamente)\n\npress any key to go back");
	placeholderText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, "center");
	placeholderText.screenCenter();
	add(placeholderText);

	new FlxTimer().start(0.2, (_) -> canContinue = true);
}

function update(elapsed) {
	if (canContinue && FlxG.keys.justPressed.ANY)
		FlxG.switchState(new ModState("MainMenuState"));
}
