import flixel.util.FlxColor;
import funkin.backend.scripting.ModState;
import funkin.backend.scripting.Script;

// Choosing an Echo (BE-61, style E of the design canvas): the Echoes are tapes found, in the tape's index. Echo 1 is the only
// one recovered; Echo 2 is locked and Echo 3 damaged (they can be chosen, but they only shake). Under the tape, like every
// screen (scripts/ui/tapeUi.hx). The old screen (three Vista windows, chains, ink) is kept, unused, in LegacyEchoSelectState.hx.

var i18n;
var ui;
var vhsFx;
var selected = 0;
var lastMouseX = 0;
var lastMouseY = 0;
var shakeTime = 0.0;

function create() {
	FlxG.camera.scroll.set(0, 0);
	bgColor = FlxColor.BLACK;
	i18n = Script.create(Paths.script('scripts/ui/translate'));
	i18n.load();
	ui = Script.create(Paths.script('scripts/ui/tapeUi'));
	ui.load();
	ui.call("buildScene", ["hills2"]);
	ui.call("buildIndex", [i18n.call("get", ["TAPES FOUND"]), "3", [
		{label: "ECHO 1", time: "00:43:12", dim: false},
		{label: "ECHO 2", time: i18n.call("get", ["LOCKED"]), dim: true},
		{label: "E▒HO 3", time: i18n.call("get", ["DAMAGED"]), dim: true}
	]]);
	ui.call("setFooter", [i18n.call("get", ["RECOVERED"]), i18n.call("get", ["ESC BACK"])]);
	ui.call("buildOsd", ["PLAY"]);
	vhsFx = Script.create(Paths.script('scripts/effects/vhsShader'));
	vhsFx.load();
	vhsFx.call("exclude", [ui.call("deckCamera")]);
	vhsFx.call("attach");
	FlxG.mouse.visible = true;
	ui.call("select", [selected]);
}

function choose() {
	if (selected == 0) {
		FlxG.sound.play(Paths.sound("menu/confirm"), 0.6);
		FlxG.switchState(new ModState("StoryMapState"));
		return;
	}
	// a locked or damaged tape will not play: the deck chews it a little
	FlxG.sound.play(Paths.sound("menu/cancel"), 0.6);
	vhsFx.call("badTracking", [0.5, 0.9]);
	shakeTime = 0.3;
}

function update(elapsed) {
	ui.call("update", [elapsed]);
	if (shakeTime > 0) {
		shakeTime -= elapsed;
		FlxG.camera.scroll.x = shakeTime > 0 ? FlxG.random.float(-4, 4) : 0;
	}
	var moved = FlxG.mouse.screenX != lastMouseX || FlxG.mouse.screenY != lastMouseY;
	lastMouseX = FlxG.mouse.screenX;
	lastMouseY = FlxG.mouse.screenY;
	var over = ui.call("rowAt", [FlxG.mouse.screenX, FlxG.mouse.screenY]);
	if (moved && over != -1 && over != selected) {
		selected = over;
		ui.call("select", [selected]);
	}
	if (controls.UP_P || controls.DOWN_P) {
		selected = (selected + (controls.UP_P ? 2 : 1)) % 3;
		FlxG.sound.play(Paths.sound("menu/scroll"), 0.5);
		ui.call("select", [selected]);
	}
	if (controls.ACCEPT || (FlxG.mouse.justPressed && over != -1)) choose();
	if (controls.BACK) FlxG.switchState(new ModState("MainMenuState"));
}

function destroy() {
	FlxG.mouse.visible = false;
}
