import funkin.backend.shaders.CustomShader;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.filters.ShaderFilter;
import openfl.geom.Rectangle;

// The camcorder tape over the whole picture (BE-59): VHSShader.frag ONCE over everything the game draws, the way a
// recording covers everything (OPT-shader-ram, ADR-0008). It is a filter on FlxG.game, clipped to the window
// (scrollRect: without it the filter's picture takes the size of everything in the game, off-screen cameras included,
// and the tape lands out of place). Cameras added later (a HUD, a transition) are covered with no extra work.
// It used to go camera by camera (one shader each): the same tape was drawn 6 times in a song (half the FPS, ~350 MB).
// The first try with FlxG.game drew nothing because the shader asked for the camera's size (_camSize), which the
// engine only fills on cameras: in this mode the shader reads the picture directly (uniform wholeGame).
// A camera that must stay crisp (the deck's OSD: PLAY, SP) is lifted out of FlxG.game to a layer right above it.
// Call attach() from a state's create(); the tape then runs on its own (it ticks on FlxG.signals.postUpdate) and leaves
// by itself when the state changes. It is not hooked through the mod's global script because that hook never fired in
// testing (trap 1).
//
//   var vhsFx = Script.create(Paths.script('scripts/effects/vhsShader'));
//   vhsFx.load();
//   vhsFx.call('attach');
//   vhsFx.call('cut');                 // a camcorder edit: the recording stops and starts again somewhere else
//   vhsFx.call('badTracking', [2.0]);  // seconds of bad tracking (an optional second value: strength 0..1)
//   vhsFx.call('setPause', [true]);    // the deck's pause bars (false to take them away)
//   vhsFx.call('rollOnce');            // the vertical hold slips and the picture rolls once
//   vhsFx.call('setColourLoss', [0.5]);  // extra loss of colour, 0 = none, 1 = grey
//   vhsFx.call('exclude', [cam]);      // a camera the tape must not cover (the deck's own OSD: PLAY, SP), before or after attach
//
// How worn the tape is comes from the setting "RUIDO DE LA CINTA" (FlxG.save.data.echoesTapeNoise, 0..1, default 1:
// the look Zyra approved). At 0 the picture keeps the tape's softness and colour but loses the noise, the wobble and
// the dropouts; the edits and the other events still happen, they are part of the story.
// The shader keeps the alpha of what it draws, so a transparent window stays transparent under the tape (BE-8).

var LENS = 0.07;                 // the camcorder's wide lens (barrel), as in the mockup
var ROLL_SECONDS = 0.55;

var shaders = [];
var excluded = [];
var gameShader = null;
var clip = null;          // the window's rectangle, FlxG.game.scrollRect
var deckLayer = null;     // above FlxG.game: the excluded cameras, out of the tape
var start = 0.0;
var seed = 0.0;
var cutSeed = 0.0;
var trackSeed = 0.0;
var cutAt = -1.0;
var trackUntil = -1.0;
var trackStrength = 1.0;
var rollAt = -1.0;
var paused = false;
var colourLoss = 0.0;
// last values emitted to shaders, so hset() is skipped when a uniform did not change
var lastSeed:Float = -1.0;
var lastNoise:Float = -1.0;
var lastCutSeed:Float = -1.0;
var lastTrackSeed:Float = -1.0;
var lastPaused:Bool = false;
var lastColourLoss:Float = -1.0;
var sendAll = true;   // a new shader starts with every uniform at 0: the next tick sends it everything
var tickFn;    // the same function objects are kept for add and remove: naming a script function twice may give two closures
var detachFn;
var removedFn;

function attach() {
	start = Lib.getTimer() / 1000;
	seed = Math.random() * 6.28;
	cutSeed = Math.random();
	trackSeed = Math.random();
	gameShader = new CustomShader("VHSShader");
	gameShader.hset("lens", LENS);
	gameShader.hset("wholeGame", 1.0);
	shaders.push(gameShader);
	sendAll = true;
	fitClip();
	FlxG.game.setFilters([new ShaderFilter(gameShader)]);   // setFilters: FlxGame puts its own list back every frame, so `filters =` is lost
	for (cam in excluded) lift(cam);
	tickFn = function() tick();
	detachFn = function() detach();
	removedFn = function(cam) drop(cam);
	FlxG.signals.postUpdate.add(tickFn);
	FlxG.signals.preStateSwitch.add(detachFn);
	FlxG.cameras.cameraRemoved.add(removedFn);
	tick();
}

// keeps FlxG.game clipped to the window (it changes size with fullscreen and with windowFx)
function fitClip() {
	var w = FlxG.stage.stageWidth;
	var h = FlxG.stage.stageHeight;
	if (clip != null && clip.width == w && clip.height == h) return;
	clip = new Rectangle(0, 0, w, h);
	FlxG.game.scrollRect = clip;
}

function exclude(cam) {
	if (excluded.indexOf(cam) == -1) excluded.push(cam);
	if (gameShader != null) lift(cam);
}

// moves a camera out of the tape: to a layer right above FlxG.game (Flixel's own removeChild on FlxG.game then simply does nothing)
function lift(cam) {
	if (cam == null || cam.flashSprite == null) return;
	if (deckLayer == null) {
		deckLayer = new Sprite();
		var host = FlxG.game.parent;
		host.addChildAt(deckLayer, host.getChildIndex(FlxG.game) + 1);
	}
	deckLayer.addChild(cam.flashSprite);
}

function drop(cam) {
	if (deckLayer != null && cam != null && cam.flashSprite != null && cam.flashSprite.parent == deckLayer) deckLayer.removeChild(cam.flashSprite);
	excluded.remove(cam);
}

// Takes the tape away (it also happens on its own when the state changes).
function detach() {
	if (tickFn != null) FlxG.signals.postUpdate.remove(tickFn);
	if (detachFn != null) FlxG.signals.preStateSwitch.remove(detachFn);
	if (removedFn != null) FlxG.cameras.cameraRemoved.remove(removedFn);
	tickFn = null;
	detachFn = null;
	removedFn = null;
	if (gameShader != null) {
		FlxG.game.setFilters([]);
		FlxG.game.scrollRect = null;
		gameShader = null;
		clip = null;
	}
	if (deckLayer != null) {
		// a lifted camera that is still alive goes back into the game, where Flixel keeps its cameras (under its input layer)
		while (deckLayer.numChildren > 0) FlxG.game.addChildAt(deckLayer.getChildAt(0), FlxG.game.getChildIndex(FlxG.game._inputContainer));
		if (deckLayer.parent != null) deckLayer.parent.removeChild(deckLayer);
		deckLayer = null;
	}
	shaders = [];
}

function now() {
	return Lib.getTimer() / 1000 - start;
}

function tick() {
	fitClip();
	if (deckLayer != null) { deckLayer.x = FlxG.game.x; deckLayer.y = FlxG.game.y; }
	var t = now();
	var noise = FlxG.save.data.echoesTapeNoise;
	var trackLeft = trackUntil - t;
	var r = rollAt < 0 ? 1.0 : (t - rollAt) / ROLL_SECONDS;
	var cutAge = cutAt < 0 ? -1.0 : t - cutAt;
	var tracking = trackLeft > 0 ? trackStrength * Math.min(1, trackLeft / 0.3) : 0.0;
	var rollVal = r < 1 ? 1 - (1 - r) * (1 - r) : 0.0;
	var pauseVal = paused ? 1.0 : 0.0;
	var noiseVal = noise == null ? 1.0 : noise;
	// the rare uniforms are decided once for ALL the shaders (deciding inside the loop sent them only to the first one)
	var sendSeed = sendAll || seed != lastSeed;
	var sendNoise = sendAll || noiseVal != lastNoise;
	var sendCutSeed = sendAll || cutSeed != lastCutSeed;
	var sendTrackSeed = sendAll || trackSeed != lastTrackSeed;
	var sendPause = sendAll || paused != lastPaused;
	var sendColourLoss = sendAll || colourLoss != lastColourLoss;
	for (shader in shaders) {
		// these change every frame
		shader.hset("time", t);
		shader.hset("cutAge", cutAge);
		shader.hset("tracking", tracking);
		shader.hset("roll", rollVal);
		// these change rarely: only sent when they did
		if (sendSeed) shader.hset("seed", seed);
		if (sendNoise) shader.hset("noise", noiseVal);
		if (sendCutSeed) shader.hset("cutSeed", cutSeed);
		if (sendTrackSeed) shader.hset("trackSeed", trackSeed);
		if (sendPause) shader.hset("pauseOn", pauseVal);
		if (sendColourLoss) shader.hset("satDrop", colourLoss);
	}
	lastSeed = seed;
	lastNoise = noiseVal;
	lastCutSeed = cutSeed;
	lastTrackSeed = trackSeed;
	lastPaused = paused;
	lastColourLoss = colourLoss;
	sendAll = false;
}

function cut() {
	cutAt = now();
	cutSeed = Math.random();
}

function badTracking(seconds, ?strength) {
	trackUntil = now() + seconds;
	trackStrength = strength == null ? 1.0 : strength;
	trackSeed = Math.random();
}

function setPause(on) {
	paused = on;
}

function rollOnce() {
	rollAt = now();
}

function setColourLoss(amount) {
	colourLoss = amount;
}
