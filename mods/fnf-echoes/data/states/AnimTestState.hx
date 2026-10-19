import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.backend.scripting.ModState;
import funkin.backend.scripting.Script;
import funkin.game.Character;
import openfl.Lib;

// Playground for Zyra's animations (BE-53, DS-2): no song, just her on a black screen at the same place and size as in Limbo, and the four keys to play
// her sing poses by hand (hold a key: the pose stays; release: she goes back to the idle). Open it with the 8 key on the main menu.
//
//   the four note keys  play singLEFT / singDOWN / singUP / singRIGHT      R  reload the character (after exporting new frames)
//   E  alternative eyes on / off (Zyra's hand-drawn eyes, for the poses that have them: set 3 all four notes, set 4 left and down)
//   S  swap left and right in the camera set that is showing (the info line says which sets are swapped)
//   5 6 7 8  how a held long note looks: still / creeping forward / slow loop / pulse (tell Zyra's choice to Claude)
//   1 2 3 4  the camera set of her frames: Camera / Camera.001 / Camera.002 / pose 3 (going from 3 to 4 plays the pose change first)
//   G  3x3 grid (Zyra's placement guide)                                    ESC  back to the menu
//
// The camera is the one of the Limbo stage (centre 1000,600, zoom 0.9), so what you see here is what you get in the song. The grid, the keys and the
// text are drawn on a second camera that does not zoom.

var CHARACTER = "zyra";
var STAGE_LEFT = 289.0;                 // her frames are the 1920x1080 Blender renders and the render frame is what the camera shows: world 289..1711 x 200..1000
var STAGE_TOP = 200.0;

var char;
var uiCam;
var grid = [];
var gridOn = true;
var infoText;
var keySprites = [];
var singDir = -1;
var eyes;
var altOn = false;

function create() {
	FlxG.camera.bgColor = FlxColor.BLACK;
	FlxG.camera.zoom = 0.9;
	FlxG.camera.scroll.set(1000 - FlxG.width / 2, 600 - FlxG.height / 2);

	uiCam = new FlxCamera();
	uiCam.bgColor = 0;
	FlxG.cameras.add(uiCam, false);

	FlxG.save.data.echoesZyraSet = 0;
	char = new Character(0, 0, CHARACTER, true);
	char.x = STAGE_LEFT - char.frameWidth * (1 - char.scale.x) / 2;      // the sprite grows around its centre: move its corner back
	char.y = STAGE_TOP - char.frameHeight * (1 - char.scale.y) / 2;
	add(char);
	char.dance();
	eyes = Script.create(Paths.script('scripts/effects/zyraEyes'));
	eyes.load();
	eyes.call("attach", [char]);

	// grid: thirds of the 1280x720 screen
	for (i in 1...3) {
		var v = new FlxSprite(Math.round(FlxG.width * i / 3) - 1, 0).makeGraphic(2, FlxG.height, FlxColor.fromRGB(255, 255, 255, 90));
		var h = new FlxSprite(0, Math.round(FlxG.height * i / 3) - 1).makeGraphic(FlxG.width, 2, FlxColor.fromRGB(255, 255, 255, 90));
		for (s in [v, h]) { s.cameras = [uiCam]; s.scrollFactor.set(); add(s); grid.push(s); }
	}

	makeKeys();

	infoText = new FlxText(12, 10, FlxG.width - 24, "");
	infoText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, "left");
	infoText.cameras = [uiCam];
	infoText.scrollFactor.set();
	add(infoText);
}

// The four receptors of the noteskin as feedback for the keys (a plain square when the noteskin is not in this build).
function makeKeys() {
	var names = ["LEFT", "DOWN", "UP", "RIGHT"];
	var pre = ["left", "down", "up", "right"];
	for (i in 0...4) {
		var spr = new FlxSprite(FlxG.width / 2 - 2 * 112 + i * 112 + 4, FlxG.height - 130);
		var ok = true;
		try {
			spr.frames = Paths.getFrames("game/notes/zyra");
			spr.animation.addByPrefix("static", "arrow" + names[i]);
			spr.animation.addByPrefix("pressed", pre[i] + " press", 24, false);
			spr.animation.addByPrefix("confirm", pre[i] + " confirm", 24, false);
			spr.animation.play("static");
			spr.scale.set(0.7, 0.7);
			spr.updateHitbox();
		} catch (e:Dynamic) {
			ok = false;
		}
		if (!ok || spr.frames == null)
			spr.makeGraphic(90, 90, FlxColor.fromRGB(90, 92, 106));
		spr.cameras = [uiCam];
		spr.scrollFactor.set();
		add(spr);
		keySprites.push(spr);
	}
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
		FlxG.switchState(new ModState("AnimTestState"));
		return;
	}
	if (FlxG.keys.justPressed.ONE) FlxG.save.data.echoesZyraSet = 0;
	if (FlxG.keys.justPressed.TWO) FlxG.save.data.echoesZyraSet = 1;
	if (FlxG.keys.justPressed.THREE) FlxG.save.data.echoesZyraSet = 2;
	if (FlxG.keys.justPressed.FOUR) FlxG.save.data.echoesZyraSet = 3;
	if (FlxG.keys.justPressed.S) {
		// swap left and right for the camera set that is showing (to find out which way Zyra wants it)
		var cur = FlxG.save.data.echoesZyraSwap;
		if (cur == null) cur = [false, false, true, false];
		var set = FlxG.save.data.echoesZyraSet;
		cur[set] = !cur[set];
		FlxG.save.data.echoesZyraSwap = cur;
	}
	if (FlxG.keys.justPressed.FIVE) FlxG.save.data.echoesZyraHoldStyle = 0;
	if (FlxG.keys.justPressed.SIX) FlxG.save.data.echoesZyraHoldStyle = 1;
	if (FlxG.keys.justPressed.SEVEN) FlxG.save.data.echoesZyraHoldStyle = 2;
	if (FlxG.keys.justPressed.EIGHT) FlxG.save.data.echoesZyraHoldStyle = 3;
	if (FlxG.keys.justPressed.E) {
		altOn = !altOn;
		eyes.call("setAlt", [altOn]);
	}
	if (FlxG.keys.justPressed.G) {
		gridOn = !gridOn;
		for (s in grid) s.visible = gridOn;
	}

	// The poses and their hold/return logic live in data/characters/zyra.hx; here the keys only play the pose and say "held" while they are down.
	var d = pressedDir();
	if (d >= 0) {
		singDir = d;
		FlxG.save.data.echoesZyraPiece = false;          // a key press is a first hit, never a piece of a long note
		char.playSingAnim(d);
	}
	var held = [controls.NOTE_LEFT, controls.NOTE_DOWN, controls.NOTE_UP, controls.NOTE_RIGHT];
	for (i in 0...4) {
		if (held[i]) {
			FlxG.save.data.echoesZyraHoldAt = Lib.getTimer();
			FlxG.save.data.echoesZyraHoldDir = i;
		}
	}
	if (!anyHeld() && char.isAnimFinished() && (char.getAnimName() == null || char.getAnimName().indexOf("sing") != 0))
		char.dance();                                // the idle loops by itself

	var dirs = [controls.NOTE_LEFT, controls.NOTE_DOWN, controls.NOTE_UP, controls.NOTE_RIGHT];
	var justs = [controls.NOTE_LEFT_P, controls.NOTE_DOWN_P, controls.NOTE_UP_P, controls.NOTE_RIGHT_P];
	for (i in 0...4) {
		var spr = keySprites[i];
		if (spr.animation == null || spr.animation.getByName("static") == null) {
			spr.alpha = dirs[i] ? 1.0 : 0.55;
		} else if (justs[i]) {
			spr.animation.play("confirm", true);
		} else if (!dirs[i] && spr.animation.name != "static") {
			spr.animation.play("static", true);
		}
	}

	eyes.call("update");
	var anim = char.getAnimName();
	var frame = (char.animation.curAnim != null) ? char.animation.curAnim.curFrame : 0;
	var swapText = "3";
	if (FlxG.save.data.echoesZyraSwap != null) {
		swapText = "";
		for (i in 0...4)
			if (FlxG.save.data.echoesZyraSwap[i] == true) swapText += (i + 1) + " ";
	}
	infoText.text = "ANIMATION TEST - the note keys play the poses (hold = pose stays) | 1-4 camera set | R reload | G grid | ESC back\n" + anim + "  frame " + frame + "   set " + (FlxG.save.data.echoesZyraSet + 1) + "   hold style " + (FlxG.save.data.echoesZyraHoldStyle == null ? 1 : FlxG.save.data.echoesZyraHoldStyle + 1) + " (5-8)   swapped sets: " + swapText + " (S)   alt eyes: " + (altOn ? "ON" : "off") + " (E)";
}
