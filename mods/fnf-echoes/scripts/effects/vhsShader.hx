import funkin.backend.shaders.CustomShader;
import openfl.Lib;

// The camcorder tape over the whole picture (BE-59): VHSShader.frag on every camera of the state (and on the cameras
// added later, like a HUD), the way a recording would cover everything. A filter on FlxG.game was tried first and
// does not draw in this engine (no error, simply nothing), so it goes camera by camera, one shader each (every
// camera has its own size uniforms). Call attach() from a state's create(); the tape then runs on its own (it ticks
// on FlxG.signals.postUpdate) and leaves by itself when the state changes. It is not hooked through the mod's global
// script because that hook never fired in testing (trap 1).
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
var cameras = [];
var excluded = [];
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
var tickFn;     // the same function objects are kept for add and remove: naming a script function twice may give two closures
var detachFn;
var cameraFn;

function attach() {
	start = Lib.getTimer() / 1000;
	seed = Math.random() * 6.28;
	cutSeed = Math.random();
	trackSeed = Math.random();
	for (cam in FlxG.cameras.list) addTo(cam);
	tickFn = function() tick();
	detachFn = function() detach();
	cameraFn = function(cam) addTo(cam);
	FlxG.signals.postUpdate.add(tickFn);
	FlxG.signals.preStateSwitch.add(detachFn);
	FlxG.cameras.cameraAdded.add(cameraFn);
	tick();
}

function addTo(cam) {
	if (cameras.indexOf(cam) != -1 || excluded.indexOf(cam) != -1) return;
	var shader = new CustomShader("VHSShader");
	shader.hset("lens", LENS);
	cam.addShader(shader);
	cameras.push(cam);
	shaders.push(shader);
}

function exclude(cam) {
	excluded.push(cam);
	var i = cameras.indexOf(cam);
	if (i == -1) return;
	cam.removeShader(shaders[i]);
	cameras.splice(i, 1);
	shaders.splice(i, 1);
}

// Takes the tape away (it also happens on its own when the state changes).
function detach() {
	if (tickFn != null) FlxG.signals.postUpdate.remove(tickFn);
	if (detachFn != null) FlxG.signals.preStateSwitch.remove(detachFn);
	if (cameraFn != null) FlxG.cameras.cameraAdded.remove(cameraFn);
	tickFn = null;
	detachFn = null;
	cameraFn = null;
	for (i in 0...cameras.length) cameras[i].removeShader(shaders[i]);
	cameras = [];
	shaders = [];
}

function now() {
	return Lib.getTimer() / 1000 - start;
}

function tick() {
	var t = now();
	var noise = FlxG.save.data.echoesTapeNoise;
	var trackLeft = trackUntil - t;
	var r = rollAt < 0 ? 1.0 : (t - rollAt) / ROLL_SECONDS;
	for (shader in shaders) {
		shader.hset("time", t);
		shader.hset("seed", seed);
		shader.hset("noise", noise == null ? 1.0 : noise);
		shader.hset("cutAge", cutAt < 0 ? -1.0 : t - cutAt);
		shader.hset("cutSeed", cutSeed);
		shader.hset("tracking", trackLeft > 0 ? trackStrength * Math.min(1, trackLeft / 0.3) : 0.0);
		shader.hset("trackSeed", trackSeed);
		shader.hset("pauseOn", paused ? 1.0 : 0.0);
		shader.hset("roll", r < 1 ? 1 - (1 - r) * (1 - r) : 0.0);
		shader.hset("satDrop", colourLoss);
	}
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
