import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.backend.scripting.ModState;
import funkin.backend.scripting.Script;
import funkin.game.Character;
import openfl.Lib;

// Playground for the mist and the reflection under Zyra (BE-54): a black screen with the Limbo camera, Zyra in her place, and keys to try everything.
// Open it with the 9 key on the main menu.
//
//   the four note keys   play Zyra's poses                      ENTER  pose change: Zyra pushes the mist away (1.1 s, like the 27 frames of the animation)
//   1 / 2 / 3 / 4        light: warm / cool / violet / off      SPACE  flash (a memory lighting up)
//   B                    reflection glitch: off / low / mid / high   Z / X  mist density - / +
//   Q                    quality (steps per ray 4 / 6 / 8: lower is faster)      C / V  reflection opacity - / +               , / .  reflection gap (moves it up / down, set it per camera)
//   TAB                  Blender camera of the mist: Camera / Camera.002          G  3x3 grid      R reload      ESC back
//
// The camera is the one of the Limbo stage (centre 1000,600, zoom 0.9). The texts and the grid are drawn on a second camera that does not zoom.

var CHARACTER = "zyra";
var CENTER_X = 289 + 0.645 * 1422;     // where Zyra drew her (see AnimTestState / data/stages/black.hx)
var FEET_Y = 200 + 0.95 * 800;
var POSE_CHANGE_SECONDS = 27 / 24;     // pose change animation: frames 168-194 at 24 fps
var PUSH_STRENGTH = 1000.0;
var CAMERA_NAMES = ["Camera", "Camera.001", "Camera.002", "Camera.003"];     // the camera of each set of Zyra's frames (DS-2)
var LIGHTS = [0xFFE8E6E0, 0xFF9CB4FF, 0xFFC8A8FF];
var GLITCH_LEVELS = [0.0, 0.35, 0.7, 1.0];

var mist;
var char;
var uiCam;
var grid = [];
var gridOn = true;
var infoText;
var lightIndex = 0;
var glitchIndex = 1;

function create() {
	FlxG.camera.bgColor = FlxColor.BLACK;
	FlxG.camera.zoom = 0.9;
	FlxG.camera.scroll.set(1000 - FlxG.width / 2, 600 - FlxG.height / 2);

	uiCam = new FlxCamera();
	uiCam.bgColor = 0;
	FlxG.cameras.add(uiCam, false);

	if (FlxG.save.data.echoesMistCam == null) FlxG.save.data.echoesMistCam = 0;
	FlxG.save.data.echoesZyraSet = FlxG.save.data.echoesMistCam;          // her frames of that camera
	char = new Character(0, 0, CHARACTER, true);
	// her frames are the whole Blender render, and the render frame is what the stage shows: she goes to the corner of the stage (her sprite grows around its centre)
	char.x = 289.0 - char.frameWidth * (1 - char.scale.x) / 2;
	char.y = 200.0 - char.frameHeight * (1 - char.scale.y) / 2;

	// draw order: reflection, back mist, Zyra, front mist
	mist = Script.create(Paths.script('scripts/effects/mist'));
	mist.load();
	mist.call("setStageView", [CAMERA_NAMES[FlxG.save.data.echoesMistCam]]);
	mist.call("setInsertBefore", [null]);
	mist.call("setReflection", [0.2, 0.0]);
	mist.call("createReflection", [char, null]);
	mist.call("createBack", [null]);
	add(char);
	char.dance();
	mist.call("createFront", [null]);
	applyLight();

	for (i in 1...3) {
		var v = new FlxSprite(Math.round(FlxG.width * i / 3) - 1, 0).makeGraphic(2, FlxG.height, FlxColor.fromRGB(255, 255, 255, 90));
		var h = new FlxSprite(0, Math.round(FlxG.height * i / 3) - 1).makeGraphic(FlxG.width, 2, FlxColor.fromRGB(255, 255, 255, 90));
		for (s in [v, h]) { s.cameras = [uiCam]; s.scrollFactor.set(); add(s); grid.push(s); }
	}

	infoText = new FlxText(12, 10, FlxG.width - 24, "");
	infoText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, "left");
	infoText.cameras = [uiCam];
	infoText.scrollFactor.set();
	add(infoText);
}

function applyLight() {
	if (lightIndex < 0)
		mist.call("setLight", [0xFFFFFFFF, 0.0, 1000, 300, 650]);
	else
		mist.call("setLight", [LIGHTS[lightIndex], 1.0, 1000, 300, 650]);
}

function pressedDir() {
	if (controls.NOTE_LEFT_P) return 0;
	if (controls.NOTE_DOWN_P) return 1;
	if (controls.NOTE_UP_P) return 2;
	if (controls.NOTE_RIGHT_P) return 3;
	return -1;
}

function anyHeld() {
	return controls.NOTE_LEFT || controls.NOTE_DOWN || controls.NOTE_UP || controls.NOTE_RIGHT;
}

function update(elapsed) {
	if (FlxG.keys.justPressed.ESCAPE) {
		FlxG.switchState(new ModState("MainMenuState"));
		return;
	}
	if (FlxG.keys.justPressed.R) {
		FlxG.bitmap.clearCache();
		FlxG.switchState(new ModState("MistTestState"));
		return;
	}
	if (FlxG.keys.justPressed.TAB) {
		FlxG.save.data.echoesMistCam = (FlxG.save.data.echoesMistCam + 1) % CAMERA_NAMES.length;
		FlxG.switchState(new ModState("MistTestState"));
		return;
	}
	if (FlxG.keys.justPressed.G) {
		gridOn = !gridOn;
		for (s in grid) s.visible = gridOn;
	}

	if (FlxG.keys.justPressed.ONE) { lightIndex = 0; applyLight(); }
	if (FlxG.keys.justPressed.TWO) { lightIndex = 1; applyLight(); }
	if (FlxG.keys.justPressed.THREE) { lightIndex = 2; applyLight(); }
	if (FlxG.keys.justPressed.FOUR) { lightIndex = -1; applyLight(); }
	if (FlxG.keys.justPressed.SPACE) mist.call("flash", [1.0]);
	if (FlxG.keys.justPressed.ENTER) mist.call("push", [PUSH_STRENGTH, POSE_CHANGE_SECONDS]);
	if (FlxG.keys.justPressed.B) {
		glitchIndex = (glitchIndex + 1) % GLITCH_LEVELS.length;
		mist.call("setGlitch", [GLITCH_LEVELS[glitchIndex]]);
	}
	if (FlxG.keys.justPressed.Z) mist.call("setDensity", [Math.max(0.0, mist.call("getDensity") - 0.2)]);
	if (FlxG.keys.justPressed.X) mist.call("setDensity", [Math.min(3.0, mist.call("getDensity") + 0.2)]);
	if (FlxG.keys.justPressed.Q) mist.call("setQuality", [mist.call("getQuality") >= 8.0 ? 4.0 : mist.call("getQuality") + 2.0]);
	if (FlxG.keys.justPressed.C) mist.call("setReflection", [Math.max(0.0, mist.call("getReflectionAlpha") - 0.05), mist.call("getReflectionGap")]);
	if (FlxG.keys.justPressed.V) mist.call("setReflection", [Math.min(1.0, mist.call("getReflectionAlpha") + 0.05), mist.call("getReflectionGap")]);
	if (FlxG.keys.justPressed.COMMA) mist.call("setReflection", [mist.call("getReflectionAlpha"), mist.call("getReflectionGap") - 4]);
	if (FlxG.keys.justPressed.PERIOD) mist.call("setReflection", [mist.call("getReflectionAlpha"), mist.call("getReflectionGap") + 4]);

	// The poses and their hold/return logic live in data/characters/zyra.hx (BE-53); here the keys only play the pose and say "held".
	var d = pressedDir();
	if (d >= 0) {
		FlxG.save.data.echoesZyraPiece = false;
		char.playSingAnim(d);
		mist.call("pulse", [0.6]);            // the mist breathes with every hit
	}
	var held = [controls.NOTE_LEFT, controls.NOTE_DOWN, controls.NOTE_UP, controls.NOTE_RIGHT];
	for (i in 0...4) {
		if (held[i]) {
			FlxG.save.data.echoesZyraHoldAt = Lib.getTimer();
			FlxG.save.data.echoesZyraHoldDir = i;
		}
	}
	if (!anyHeld() && char.isAnimFinished() && (char.getAnimName() == null || char.getAnimName().indexOf("sing") != 0))
		char.dance();

	mist.call("update", [elapsed]);

	var lightNames = ["warm", "cool", "violet"];
	var lightName = lightIndex < 0 ? "off" : lightNames[lightIndex];
	infoText.text = "MIST TEST (BE-54) camera " + CAMERA_NAMES[FlxG.save.data.echoesMistCam] + " (TAB) - note keys: poses | ENTER pose change push | 1-4 light | SPACE flash | G grid | R reload | ESC back\n"
		+ "glitch " + mist.call("getGlitch") + " (B)   density " + Math.round(mist.call("getDensity") * 10) / 10 + " (Z/X)   light " + lightName
		+ "   reflection " + Math.round(mist.call("getReflectionAlpha") * 100) + "% (C/V)  gap " + mist.call("getReflectionGap") + " (, .)";
}
