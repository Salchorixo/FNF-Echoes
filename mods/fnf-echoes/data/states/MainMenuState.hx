import flixel.util.FlxColor;
import funkin.backend.scripting.ModState;
import funkin.backend.scripting.Script;
import funkin.menus.TitleState;
import funkin.menus.credits.CreditsMain;

// Credits reuses the engine's native screen — it's a utility screen, not
// narrative content, so there's no need to rebuild it yet. Options is our
// own build (see OptionsState.hx) since it needs mod-specific layout and
// behavior the native screen doesn't provide.
//
// cardLabels stays the stable English keys — confirmSelection() switches on
// these regardless of display language, so what's shown never affects the
// navigation logic. "ECHOES" is deliberately never routed through
// translate.hx: that name stays in English always, per project rule.
var cardLabels:Array<String> = ["ECHOES", "OPTIONS", "CREDITS"];
var cardMenu:Script;
var i18n:Script;

function create() {
	bgColor = FlxColor.BLACK;

	var vhsFx = Script.create(Paths.script('scripts/effects/vhsShader'));
	vhsFx.load();
	vhsFx.call('attach');

	i18n = Script.create(Paths.script('scripts/ui/translate'));
	i18n.load();

	var displayLabels = [for (label in cardLabels) label == "ECHOES" ? label : i18n.call("get", [label])];

	cardMenu = Script.create(Paths.script('scripts/ui/cardMenu'));
	cardMenu.load();
	cardMenu.call("create", [displayLabels]);
}

function confirmSelection() {
	switch (cardLabels[cardMenu.call("getSelectedIndex")]) {
		case "ECHOES": FlxG.switchState(new ModState("EchoSelectState"));
		case "OPTIONS": FlxG.switchState(new ModState("OptionsState"));
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
