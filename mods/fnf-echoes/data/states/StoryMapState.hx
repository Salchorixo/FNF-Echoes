import flixel.util.FlxColor;
import funkin.backend.scripting.ModState;
import funkin.backend.scripting.Script;
import funkin.editors.charter.Charter;
import openfl.Lib;

// The songs of Echo 1 (BE-61, style E of the design canvas): the tracks of the tape. Limbo is recorded; Dopamine and Placebo
// are "not recorded" yet (they can be chosen, but they only shake). ENTER on Limbo opens the chart editor with the song, as the
// old node did (BE-50); from there Enter starts the playtest. Under the tape, like every screen (scripts/ui/tapeUi.hx).
// The old screen (the vertical path with the sphere nodes and the moods) is kept, unused, in LegacyStoryMapState.hx.

var SONGS = ["LIMBO", "DOPAMINE", "PLACEBO"];

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
	ui.call("buildScene", ["hall"]);
	var notYet = i18n.call("get", ["NOT RECORDED"]);
	ui.call("buildIndex", [i18n.call("get", ["TRACKS"]), i18n.call("get", ["SIDE A"]), [
		{label: SONGS[0], time: "00:00:00", dim: false},
		{label: SONGS[1], time: notYet, dim: true},
		{label: SONGS[2], time: notYet, dim: true}
	]]);
	ui.call("setFooter", [i18n.call("get", ["ENTER PLAY"]), i18n.call("get", ["ESC BACK"])]);
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
		// the editors leave through the main menu, which reads this mark (kept from the old screen)
		FlxG.save.data.echoesMenuReturn = Math.round((Date.now().getTime() - Lib.getTimer()) / 1000);
		FlxG.switchState(new Charter("limbo", "hard", ""));
		return;
	}
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
		selected = (selected + (controls.UP_P ? SONGS.length - 1 : 1)) % SONGS.length;
		FlxG.sound.play(Paths.sound("menu/scroll"), 0.5);
		ui.call("select", [selected]);
	}
	if (controls.ACCEPT || (FlxG.mouse.justPressed && over != -1)) choose();
	if (controls.BACK) FlxG.switchState(new ModState("EchoSelectState"));
}

function destroy() {
	FlxG.mouse.visible = false;
}
