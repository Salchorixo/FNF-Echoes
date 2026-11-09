import funkin.backend.shaders.CustomShader;
import openfl.Lib;
import openfl.filters.ShaderFilter;

// The camcorder tape over the whole picture (BE-59): VHSShader.frag as a filter on FlxG.game, so it covers every
// camera of the state (the HUD too), the way a recording would. Call attach() from a state's create(); the tape then
// runs on its own (it ticks on FlxG.signals.postUpdate) and leaves by itself when the state changes. It is not hooked
// through the mod's global script because that hook never fired in testing (trap 1).
//
//   var vhsFx = Script.create(Paths.script('scripts/effects/vhsShader'));
//   vhsFx.load();
//   vhsFx.call('attach');
//   vhsFx.call('cut');                 // a camcorder edit: the recording stops and starts again somewhere else
//   vhsFx.call('badTracking', [2.0]);  // seconds of bad tracking (an optional second value: strength 0..1)
//   vhsFx.call('setPause', [true]);    // the deck's pause bars (false to take them away)
//   vhsFx.call('rollOnce');            // the vertical hold slips and the picture rolls once
//   vhsFx.call('setColourLoss', [0.5]);  // extra loss of colour, 0 = none, 1 = grey
//
// How worn the tape is comes from the setting "RUIDO DE LA CINTA" (FlxG.save.data.echoesTapeNoise, 0..1, default 1:
// the look Zyra approved). At 0 the picture keeps the tape's softness and colour but loses the noise, the wobble and
// the dropouts; the edits and the other events still happen, they are part of the story.
// The shader keeps the alpha of the game, so a transparent window stays transparent under the tape (BE-8).

var LENS = 0.07;                 // the camcorder's wide lens (barrel), as in the mockup
var ROLL_SECONDS = 0.55;

var shader;
var filter;
var start = 0.0;
var cutAt = -1.0;
var trackUntil = -1.0;
var trackStrength = 1.0;
var rollAt = -1.0;
var paused = false;
var colourLoss = 0.0;
var tickFn;     // the same function objects are kept for add and remove: naming a script function twice may give two closures
var detachFn;

function attach() {
	shader = new CustomShader("VHSShader");
	filter = new ShaderFilter(shader);
	start = Lib.getTimer() / 1000;
	shader.hset("seed", Math.random() * 6.28);
	shader.hset("lens", LENS);
	shader.hset("cutSeed", Math.random());
	shader.hset("trackSeed", Math.random());
	tick();
	FlxG.game.filters = [filter];
	tickFn = function() tick();
	detachFn = function() detach();
	FlxG.signals.postUpdate.add(tickFn);
	FlxG.signals.preStateSwitch.add(detachFn);
}

// Takes the tape away (it also happens on its own when the state changes).
function detach() {
	if (tickFn != null) FlxG.signals.postUpdate.remove(tickFn);
	if (detachFn != null) FlxG.signals.preStateSwitch.remove(detachFn);
	tickFn = null;
	detachFn = null;
	if (FlxG.game.filters != null && FlxG.game.filters.indexOf(filter) != -1) FlxG.game.filters = [];
}

function now() {
	return Lib.getTimer() / 1000 - start;
}

function tick() {
	var t = now();
	var noise = FlxG.save.data.echoesTapeNoise;
	shader.hset("time", t);
	shader.hset("noise", noise == null ? 1.0 : noise);
	shader.hset("cutAge", cutAt < 0 ? -1.0 : t - cutAt);
	var trackLeft = trackUntil - t;
	shader.hset("tracking", trackLeft > 0 ? trackStrength * Math.min(1, trackLeft / 0.3) : 0.0);
	shader.hset("pauseOn", paused ? 1.0 : 0.0);
	var r = rollAt < 0 ? 1.0 : (t - rollAt) / ROLL_SECONDS;
	shader.hset("roll", r < 1 ? 1 - (1 - r) * (1 - r) : 0.0);
	shader.hset("satDrop", colourLoss);
}

function cut() {
	cutAt = now();
	shader.hset("cutSeed", Math.random());
}

function badTracking(seconds, ?strength) {
	trackUntil = now() + seconds;
	trackStrength = strength == null ? 1.0 : strength;
	shader.hset("trackSeed", Math.random());
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
