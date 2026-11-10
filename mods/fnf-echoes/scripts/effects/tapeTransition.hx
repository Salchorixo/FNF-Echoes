import flixel.FlxSprite;
import flixel.text.FlxText;
import funkin.backend.shaders.CustomShader;
import openfl.Lib;

// The tape's transitions between screens (BE-63; Zyra, 2026-11-10, mockups R1 and T4 of the design canvas). It is the
// engine's transition script (MusicBeatTransition.script, set by MainMenuState and by tapeUi.hx): the engine opens it twice,
// once in the screen that is left (newState != null) and once in the screen that arrives (newState == null). The leaving
// half leaves a note in FlxG.save.data.echoesTapeTrans so the arriving half knows what to finish.
//
// EDIT, every change between the tape's screens: the camcorder was paused and records again. The old picture simply stops;
// the new one arrives with a little vertical jump, a band of rainbow stripes at the bottom for three frames, its colour
// taking a moment to lock, and the burned clock jumps (time went by). It wears out with the story (Zyra's "progresiones"):
//   wear 1  clean
//   wear 2  a bigger jump, the colour takes longer, dropouts after the edit
//   wear 3  all that, and two frames of the place EMPTY (without Zyra) slip in before the new screen
// The wear is FlxG.save.data.echoesTapeWear (1..3, 1 when unset); the story will set it (one per Echo). Key 5 in the
// main menu cycles it for testing.
//
// CHEW, only when entering or leaving a song: the deck chews the tape. The old picture warps, tears into bands, goes grey,
// stretches and collapses into a white line; TRACKING on black; the new picture arrives still bent and snaps straight.
//
// Anything else (the title, the editors) keeps the engine's own transition. Only the cameras the tape covers bend (the
// ones with a filter: the deck's OSD, PLAY and SP, stays still, as on a real deck). Effects: shaders/TapeTransition.frag.

var TAPE_SCREENS = ["MainMenuState", "EchoSelectState", "StoryMapState", "TapeCreditsState"];
var PLACES = ["hills2", "pool", "hall"];
var CLOCK_JUMPS = [4, 9, 37, 152, 413, 1261, 2];
var F = 1 / 15;                                   // one picture of the tape's stepped look

// [jump in tape pixels, seconds for the colour to lock, dropouts, empty-place frames]
var WEAR = [[7, 0.25, 0.0, false], [12, 0.6, 0.6, false], [18, 1.0, 1.0, true]];

var kind = null;       // "edit" or "chew"
var leaving = false;
var active = false;
var ended = false;
var time = 0.0;
var wear = 1;
var seed = 0.0;
var shaders = [];
var cams = [];
var blackSpr;
var lineSpr;
var trackText;
var ghostSpr;

function className(state) {
	return state == null ? "" : Type.getClassName(Type.getClass(state));
}

function isSong(state) {
	return className(state) == "funkin.game.PlayState";
}

function isTapeScreen(state) {
	return className(state) == "funkin.backend.scripting.ModState" && TAPE_SCREENS.indexOf(state.scriptName) != -1;
}

// What happens when going from one screen to another; null = the engine's own transition.
function kindOf(from, to) {
	if (isSong(to) && !isSong(from)) return "chew";
	if (isSong(from) && !isSong(to)) return "chew";
	// Limbo is entered through its chart editor for now (BE-50): from the song list into the editor counts as entering it
	if (className(from) == "funkin.backend.scripting.ModState" && from.scriptName == "StoryMapState" && className(to) == "funkin.editors.charter.Charter") return "chew";
	if (isTapeScreen(from) && isTapeScreen(to)) return "edit";
	return null;
}

function wearLevel() {
	var w = FlxG.save.data.echoesTapeWear;
	if (w == null) return 1;
	return Std.int(Math.max(1, Math.min(3, w)));
}

function create(event) {
	leaving = event.newState != null;
	if (leaving) {
		kind = kindOf(FlxG.state, event.newState);
		if (kind == null) return;
		FlxG.save.data.echoesTapeTrans = kind;
	} else {
		kind = FlxG.save.data.echoesTapeTrans;
		FlxG.save.data.echoesTapeTrans = null;
		if (kind == null) return;
		// the chew arrives only where something is drawn on the tape (a song or a screen of the tape); elsewhere, nothing
		if (!isSong(FlxG.state) && className(FlxG.state) != "funkin.backend.scripting.ModState") {
			event.cancel();
			return;
		}
	}
	active = true;
	event.cancel(); // everything is drawn here; the engine's black swipe does not run
	wear = wearLevel();
	seed = Math.random() * 10;

	var w = transitionCamera.width;
	var h = transitionCamera.height;
	blackSpr = new FlxSprite().makeGraphic(1, 1, 0xFF000000);
	blackSpr.setGraphicSize(w, h);
	blackSpr.updateHitbox();
	blackSpr.visible = false;
	add(blackSpr);

	if (kind == "edit") {
		if (leaving) {
			// time went by between the two recordings
			var c = FlxG.save.data.echoesTapeClock;
			FlxG.save.data.echoesTapeClock = (c == null ? 0.0 : c) + CLOCK_JUMPS[FlxG.random.int(0, CLOCK_JUMPS.length - 1)];
			return;
		}
		if (WEAR[wear - 1][3]) {
			ghostSpr = new FlxSprite().loadGraphic(Paths.image("menus/tape/bg_" + PLACES[FlxG.random.int(0, PLACES.length - 1)]));
			ghostSpr.setGraphicSize(w, h);
			ghostSpr.updateHitbox();
			ghostSpr.color = 0xFF8C6E6E;
			ghostSpr.visible = false;
			add(ghostSpr);
		}
	} else {
		lineSpr = new FlxSprite().makeGraphic(1, 1, 0xFFFFFFFF);
		lineSpr.visible = false;
		add(lineSpr);
		trackText = new FlxText(0, h / 2 - 22, w, "TRACKING");
		trackText.setFormat(Paths.font("vcr.ttf"), 40, 0xFFF2F2EE, "center");
		trackText.visible = false;
		add(trackText);
	}
	attachShaders();
}

// The cameras the tape covers (they carry a filter); if the tape is not on yet, every camera but this one.
function attachShaders() {
	var list = [];
	for (cam in FlxG.cameras.list)
		if (cam != transitionCamera && cam.filters != null && cam.filters.length > 0) list.push(cam);
	if (list.length == 0)
		for (cam in FlxG.cameras.list)
			if (cam != transitionCamera) list.push(cam);
	for (cam in list) {
		var shader = new CustomShader("TapeTransition");
		cam.addShader(shader);
		cams.push(cam);
		shaders.push(shader);
	}
	setAll(0, 1, 0, 0, 0, 0, 0, 1, 0, 1);
}

function detachShaders() {
	for (i in 0...cams.length)
		if (cams[i] != null) cams[i].removeShader(shaders[i]);
	cams = [];
	shaders = [];
}

function setAll(jump, sat, rainbow, rainbowShift, drops, warp, tear, stretch, mono, bright) {
	for (s in shaders) {
		s.hset("time", Lib.getTimer() / 1000);
		s.hset("seed", seed);
		s.hset("jump", jump);
		s.hset("sat", sat);
		s.hset("rainbow", rainbow);
		s.hset("rainbowTop", 650 - (wear - 1) * 20);
		s.hset("rainbowH", 34 + (wear - 1) * 22);
		s.hset("rainbowShift", rainbowShift);
		s.hset("drops", drops);
		s.hset("warp", warp);
		s.hset("tear", tear);
		s.hset("stretch", stretch);
		s.hset("mono", mono);
		s.hset("bright", bright);
	}
}

// linear between keys [[t, value], ...]
function track(keys, t) {
	if (t <= keys[0][0]) return keys[0][1];
	for (i in 1...keys.length)
		if (t <= keys[i][0]) {
			var a = keys[i - 1];
			var b = keys[i];
			return a[1] + (b[1] - a[1]) * (t - a[0]) / (b[0] - a[0]);
		}
	return keys[keys.length - 1][1];
}

// ---------------------------------------------------------------- the edit point (arriving half only)

function editFrame(t) {
	var w = WEAR[wear - 1];
	var jumpPx = w[0];
	var lock = w[1];
	var t0 = w[3] ? 2 * F : 0.0;   // wear 3: the empty place first
	if (ghostSpr != null) ghostSpr.visible = t < t0;
	var e = t - t0;
	if (e < 0) {
		setAll(0, 1, 0, 0, 0, 0, 0, 1, 0, 1);
		return false;
	}
	var step = Std.int(e / F);
	var jump = step == 0 ? -jumpPx : (step == 1 ? jumpPx / 2 : (step == 2 ? -jumpPx / 4 : 0));
	var sat = e < 3 * F ? 0.1 + 0.4 * e / (3 * F) : Math.min(1, 0.5 + 0.5 * (e - 3 * F) / lock);
	var rainbow = step == 0 ? 1.0 : (step == 1 ? 0.8 : (step == 2 ? 0.4 : 0));
	var shift = step == 0 ? -14 : (step == 1 ? 10 : 0);
	var drops = (e > 3 * F && e < 3 * F + lock + 0.4) ? w[2] : 0;
	setAll(jump, sat, rainbow, shift, drops, 0, 0, 1, 0, 1);
	return e >= 3 * F + lock + 0.45;
}

// ---------------------------------------------------------------- the chewed tape

var CHEW_OUT = 1.0;
var CHEW_IN = 0.75;

function chewOutFrame(t) {
	var warp = track([[0, 0], [0.12, 0.3], [0.24, 0.6], [0.36, 1], [0.6, 1]], t);
	var tear = t > 0.18 && t < 0.5 ? 1.0 : 0.0;
	var mono = track([[0, 0], [0.12, 0.5], [0.36, 1]], t);
	var stretch = track([[0, 1], [0.12, 1.06], [0.3, 1.15], [0.42, 1.3], [0.5, 0.4], [0.56, 0.04], [0.6, 0.005]], t);
	var bright = track([[0, 1], [0.42, 1.3], [0.5, 1.6], [0.56, 3]], t);
	setAll(0, 1 - mono, 0, 0, 0.6, warp, tear, stretch, mono, bright);
	// the white line the picture collapsed into, then black with TRACKING
	var w = transitionCamera.width;
	lineSpr.visible = t >= 0.58 && t < 0.8;
	if (lineSpr.visible) {
		var lw = w * track([[0.58, 1], [0.7, 0.5], [0.8, 0.04]], t);
		lineSpr.setGraphicSize(lw, 4);
		lineSpr.updateHitbox();
		lineSpr.setPosition((w - lw) / 2, transitionCamera.height / 2 - 2);
	}
	blackSpr.visible = t >= 0.6;
	trackText.visible = t >= 0.66 && Std.int(t * 8) % 2 == 0;
	return t >= CHEW_OUT;
}

function chewInFrame(t) {
	blackSpr.visible = t < 0.35;
	trackText.visible = t < 0.35 && Std.int(t * 8) % 2 == 0;
	var u = t - 0.35;
	if (u < 0) {
		setAll(0, 1, 0, 0, 0, 0, 0, 1, 0, 1);
		return false;
	}
	var step = Std.int(u / F);
	var stretch = step == 0 ? 1.18 : (step == 1 ? 1.08 : (step == 2 ? 1.02 : 1));
	var warp = step == 0 ? 0.6 : (step == 1 ? 0.25 : (step == 2 ? 0.06 : 0));
	var mono = step == 0 ? 1 : (step == 1 ? 0.6 : (step == 2 ? 0.3 : 0));
	setAll(0, 1, 0, 0, step < 3 ? 0.6 : 0, warp, 0, stretch, mono, 1);
	return t >= CHEW_IN;
}

// ---------------------------------------------------------------- the loop

function update(elapsed) {
	if (!active || ended) return;
	var done = false;
	if (kind == "edit") {
		// leaving: the old picture just stops (the next one is the edit), so hand over at once
		done = leaving ? true : editFrame(time);
	} else {
		done = leaving ? chewOutFrame(time) : chewInFrame(time);
	}
	time += elapsed;
	if (done) {
		ended = true;
		if (!leaving) detachShaders();
		finish();
	}
}

function destroy() {
	detachShaders();
}
