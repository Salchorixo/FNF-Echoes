import flixel.FlxSprite;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.backend.scripting.ModState;
import funkin.backend.scripting.Script;
import funkin.backend.utils.NativeAPI;

// Playground for the camcorder tape (BE-59): the places of the new menu under scripts/effects/vhsShader, with keys for
// every event the game can trigger. Open it with the 6 key on the main menu.
//
//   LEFT / RIGHT   change place, with a camcorder edit (the way the menu will change them)
//   C              an edit on the same place          T   3 s of bad tracking
//   P              pause bars on / off                V   the vertical hold slips (one roll)
//   G              colour loss: none / half / grey    N   tape noise ("RUIDO DE LA CINTA"): 1 / 0.5 / 0
//   W              transparent window on / off: the place is drawn only on the left half, so the desktop shows on the
//                  right under the tape (BE-8: the tape keeps the alpha)
//   H              hide / show this help           ESC back to the menu
//
// The help text is drawn on the same picture, so it goes through the tape too.

var PLACES = ["hills2", "pool", "hall"];
var NOISE_LEVELS = [1.0, 0.5, 0.0];
var COLOUR_LOSS = [0.0, 0.5, 1.0];

var vhsFx;
var place;
var placeIndex = 0;
var helpText;
var helpBack;
var paused = false;
var colourIndex = 0;
var transparent = false;

function create() {
	FlxG.camera.scroll.set(0, 0);
	FlxG.camera.bgColor = FlxColor.BLACK;

	place = new FlxSprite();
	add(place);
	showPlace();

	helpBack = new FlxSprite(0, 0).makeGraphic(FlxG.width, 56, FlxColor.fromRGB(0, 0, 0, 150));
	helpBack.y = 70;                     // below the top of the picture, which the tape bends (flagging)
	add(helpBack);
	helpText = new FlxText(16, 80, FlxG.width - 32, "");
	helpText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, "left");
	add(helpText);
	refreshHelp();

	vhsFx = Script.create(Paths.script('scripts/effects/vhsShader'));
	vhsFx.load();
	vhsFx.call('attach');
}

function showPlace() {
	place.loadGraphic(Paths.image("menus/vhsTest/" + PLACES[placeIndex]));
	place.setGraphicSize(FlxG.width, FlxG.height);
	place.updateHitbox();
	if (transparent) place.clipRect = new FlxRect(0, 0, place.frameWidth / 2, place.frameHeight);
	else place.clipRect = null;
}

function refreshHelp() {
	var noise = FlxG.save.data.echoesTapeNoise;
	helpText.text = "VHS TEST (BE-59)   place: " + PLACES[placeIndex] + "   noise: " + (noise == null ? 1.0 : noise)
		+ "   colour loss: " + COLOUR_LOSS[colourIndex] + "   pause: " + (paused ? "on" : "off") + "   transparent: " + (transparent ? "on" : "off")
		+ "\nLEFT/RIGHT place + edit   C edit   T tracking   P pause   V roll   G colour   N noise   W transparent   H help   ESC back";
}

function setTransparent(on) {
	transparent = on;
	FlxG.stage.color = on ? null : 0x000000;
	FlxG.camera.useBgAlphaBlending = on;
	FlxG.camera.bgColor = on ? 0x00000000 : 0xFF000000;
	NativeAPI.setWindowTransparent(on);
	showPlace();
}

function update(elapsed) {
	if (FlxG.keys.justPressed.ESCAPE) {
		if (transparent) setTransparent(false);
		FlxG.switchState(new ModState("MainMenuState"));
		return;
	}
	if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT) {
		placeIndex = (placeIndex + (FlxG.keys.justPressed.LEFT ? PLACES.length - 1 : 1)) % PLACES.length;
		showPlace();
		vhsFx.call("cut");
	}
	if (FlxG.keys.justPressed.C) vhsFx.call("cut");
	if (FlxG.keys.justPressed.T) vhsFx.call("badTracking", [3.0]);
	if (FlxG.keys.justPressed.P) {
		paused = !paused;
		vhsFx.call("setPause", [paused]);
	}
	if (FlxG.keys.justPressed.V) vhsFx.call("rollOnce");
	if (FlxG.keys.justPressed.G) {
		colourIndex = (colourIndex + 1) % COLOUR_LOSS.length;
		vhsFx.call("setColourLoss", [COLOUR_LOSS[colourIndex]]);
	}
	if (FlxG.keys.justPressed.N) {
		var noise = FlxG.save.data.echoesTapeNoise;
		var i = NOISE_LEVELS.indexOf(noise == null ? 1.0 : noise);
		FlxG.save.data.echoesTapeNoise = NOISE_LEVELS[(i + 1) % NOISE_LEVELS.length];
	}
	if (FlxG.keys.justPressed.W) setTransparent(!transparent);
	if (FlxG.keys.justPressed.H) helpBack.visible = helpText.visible = !helpText.visible;
	refreshHelp();
}
