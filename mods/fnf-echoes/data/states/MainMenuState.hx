import flixel.util.FlxColor;
import funkin.backend.scripting.ModState;
import funkin.backend.scripting.Script;
import funkin.menus.TitleState;
import funkin.menus.credits.CreditsMain;
import funkin.options.OptionsMenu;

// Options and Credits reuse the engine's native screens — they're utility
// screens, not narrative content, so there's no need to rebuild them yet.
var cardLabels:Array<String> = ["ECHOES", "OPTIONS", "CREDITS"];
var cardMenu:Script;

function create() {
	bgColor = FlxColor.BLACK;

	cardMenu = Script.create(Paths.script('scripts/ui/cardMenu'));
	cardMenu.load();
	cardMenu.call("create", [cardLabels]);
}

function confirmSelection() {
	switch (cardLabels[cardMenu.call("getSelectedIndex")]) {
		case "ECHOES": FlxG.switchState(new ModState("EchoSelectState"));
		case "OPTIONS": FlxG.switchState(new OptionsMenu());
		case "CREDITS": FlxG.switchState(new CreditsMain());
	}
}

function update(elapsed) {
	if (controls.LEFT_P)
		cardMenu.call("changeSelection", [-1]);
	else if (controls.RIGHT_P)
		cardMenu.call("changeSelection", [1]);

	if (controls.ACCEPT)
		confirmSelection();

	if (controls.BACK)
		FlxG.switchState(new TitleState());
}
