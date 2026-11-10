import flixel.util.FlxColor;
import funkin.backend.scripting.ModState;
import funkin.backend.scripting.Script;

// The credits (BE-61, style E of the design canvas): the tape's label, one entry per name with the timecode where it was
// recorded; the footer says what the chosen one did. Replaces the engine's credits screen (CreditsMain) for this mod.
// Names and roles agreed with Zyra so far; more go at the end of CREDITS.

var CREDITS = [
	{name: "Salchorizo (Zyra)", role: "ROLE SALCHORIZO", time: "00:00:00"},
	{name: "Suno", role: "ROLE SUNO", time: "00:31:07"},
	{name: "Codename Engine", role: "ROLE ENGINE", time: "00:48:19"},
	{name: "IBM Plex Mono", role: "ROLE FONT", time: "01:02:55"}
];

var i18n;
var ui;
var vhsFx;
var selected = 0;
var lastMouseX = 0;
var lastMouseY = 0;

function create() {
	FlxG.camera.scroll.set(0, 0);
	bgColor = FlxColor.BLACK;
	i18n = Script.create(Paths.script('scripts/ui/translate'));
	i18n.load();
	ui = Script.create(Paths.script('scripts/ui/tapeUi'));
	ui.load();
	ui.call("buildScene", ["pool"]);
	ui.call("buildIndex", [i18n.call("get", ["CREDITS INDEX"]), "", [for (c in CREDITS) {label: c.name, time: c.time, dim: false}]]);
	ui.call("buildOsd", ["PLAY"]);
	vhsFx = Script.create(Paths.script('scripts/effects/vhsShader'));
	vhsFx.load();
	vhsFx.call("exclude", [ui.call("deckCamera")]);
	vhsFx.call("attach");
	FlxG.mouse.visible = true;
	show(0);
}

function show(i) {
	selected = i;
	ui.call("select", [selected]);
	ui.call("setFooter", [i18n.call("get", [CREDITS[selected].role]), i18n.call("get", ["ESC BACK"])]);
}

function update(elapsed) {
	ui.call("update", [elapsed]);
	var moved = FlxG.mouse.screenX != lastMouseX || FlxG.mouse.screenY != lastMouseY;
	lastMouseX = FlxG.mouse.screenX;
	lastMouseY = FlxG.mouse.screenY;
	var over = ui.call("rowAt", [FlxG.mouse.screenX, FlxG.mouse.screenY]);
	if (moved && over != -1 && over != selected) show(over);
	if (controls.UP_P || controls.DOWN_P) {
		FlxG.sound.play(Paths.sound("menu/scroll"), 0.5);
		show((selected + (controls.UP_P ? CREDITS.length - 1 : 1)) % CREDITS.length);
	}
	if (controls.BACK) FlxG.switchState(new ModState("MainMenuState"));
}

function destroy() {
	FlxG.mouse.visible = false;
}
