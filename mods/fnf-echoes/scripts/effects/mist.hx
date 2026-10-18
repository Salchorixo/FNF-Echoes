import flixel.FlxSprite;
import flixel.util.FlxColor;
import funkin.backend.shaders.CustomShader;

// Dynamic mist and water reflection for the black stage of Limbo (BE-54), shared script. The look lives in two shaders:
//   shaders/MistFog.frag      the mist, drawn in the SAME 3D space as Zyra's Blender camera: for each pixel it rebuilds the ray of that camera and
//                             walks it through a layer of fog lying on the floor, so the mist has the camera's perspective (thicker towards the
//                             horizon, clouds that shrink with distance). One quad behind Zyra and one in front of her, split at her real depth.
//   shaders/WaterReflect.frag the reflection: a flipped copy of Zyra that looks like dark water (ripples, shimmer, fade) with short glitch bursts.
// This script only feeds them. The stage is black, so the mist is only really visible where light reaches it: setLight() brightens it around a
// source, flash() adds a pulse (the film frames of the memories flash into it, BE-55), push() opens the mist around Zyra (her pose change): it is
// thrown outwards and thinned, and comes back slowly. Everything is time driven, nothing reads pixels.
//
// Blender cameras: CAMERAS holds the data read from test.blend (position, axes, focal length in pixels of the 1920x1080 render). Zyra's feet are
// at FEET (metres) and, in the game, at the world point (anchorX, anchorY) with her sprite drawn at pxScale game pixels per render pixel.
//
// Draw order = the order of the calls: setView(), createReflection(), createBack(), [the state adds the character], createFront().
//
// Called from outside: setView(cameraName, anchorX, anchorY, pxScale), createReflection(char, cam), createBack(cam), createFront(cam), update(elapsed),
// setLight(color, level, x, y, radius), flash(amount), pulse(amount), push(strength, seconds), setDensity(d), setQuality(q), setGlitch(g), setReflection(alpha, gap),
// getDensity(), getQuality(), getGlitch(), getReflectionAlpha(), getReflectionGap().

var CAMERAS = [
	{name: "Camera", top: 1.8, pos: [0.6664, -9.8178, 2.7672], right: [1.0, 0.0, 0.0], up: [0.0, 0.0974, 0.99525], fwd: [0.0, 0.99525, -0.0974], focal: 2666.667},
	{name: "Camera.002", top: 1.2, pos: [-0.2251, 8.8094, 1.6906], right: [-0.97842, -0.20662, 0.0], up: [0.0, 0.0, 1.0], fwd: [0.20662, -0.97842, 0.0], focal: 6969.17}
];
var FEET = [1.608, 0.113, 0.0];  // where Zyra's feet are in the Blender scene (metres)
var QUAD_X = 200.0;              // the mist quad in game pixels: a little more than the screen at the stage zoom
var QUAD_Y = 120.0;
var QUAD_W = 1600.0;
var QUAD_H = 940.0;
var GROUND_H = 0.5;              // how fast the mist thins with height (metres)
var LIGHT_DIST = 16.0;           // distance from the camera at which the screen point of setLight() is placed in the world (metres)
var BASE_COLOR = 0xFF454A55;     // dark grey, the mist with no light on it
var TINT_MIX = 0.3;              // how much of a light's colour reaches the mist (it stays grey)
var PUSH_R = 4.0;                // how far a push reaches (metres)
var PUSH_METERS = 4.0;           // how far a full push throws the mist (metres)
var CLEAR_R = 2.0;               // radius of the clear air around Zyra (metres): no mist touches her
var RETURN_RATE = 1.4;           // how fast the pushed mist comes back (higher = faster)
var REFL_FADE = 0.55;            // the reflection fades to nothing over this share of the character's height
var REFL_TINT = [0.55, 0.75, 0.95];
var REFL_WAVE = 0.018;

var time = 0.0;
var density = 2.0;
var breath = 0.0;
var quality = 6.0;               // steps per ray, 3 to 8: lower is faster
var flowX = 0.0;                 // how far the wind has carried the clouds (metres), integrated so the gusts are smooth
var glitch = 0.35;
var level = 0.0;
var levelTarget = 0.0;
var flashEnv = 0.0;
var lightColor = 0xFFFFFFFF;
var light3 = [1.6, 5.0, 4.5];
var lightR = 6.0;
var pushes = [];

var cam3 = null;                 // the chosen entry of CAMERAS
var anchorX = 1000.0;
var anchorY = 960.0;
var pxScale = 1.0;
var feetPx = [0.0, 0.0];
var depthZ = 10.0;
var layers = [];                 // {spr, sh}

var refl = null;
var reflShader = null;
var reflChar = null;
var reflGap = 0.0;
var reflAlpha = 0.3;

function channel(color, shift) {
	return ((color >> shift) & 0xFF) / 255.0;
}

function dot3(a, b) {
	return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}

function setView(cameraName, ax, ay, scale) {
	for (c in CAMERAS) {
		if (c.name == cameraName) cam3 = c;
	}
	anchorX = ax;
	anchorY = ay;
	pxScale = scale;
	var d = [FEET[0] - cam3.pos[0], FEET[1] - cam3.pos[1], FEET[2] - cam3.pos[2]];
	depthZ = dot3(d, cam3.fwd);
	feetPx = [960.0 + cam3.focal * dot3(d, cam3.right) / depthZ, 540.0 - cam3.focal * dot3(d, cam3.up) / depthZ];
}

function makeFog(layerMode, seed, cam) {
	var spr = new FlxSprite(QUAD_X, QUAD_Y);
	spr.makeGraphic(Math.ceil(QUAD_W), Math.ceil(QUAD_H), 0xFFFFFFFF);
	var sh = new CustomShader("MistFog");
	sh.hset("layerMode", layerMode);
	sh.hset("seed", seed);
	sh.hset("quadRect", [QUAD_X, QUAD_Y, QUAD_W, QUAD_H]);
	sh.hset("pxScale", pxScale);
	sh.hset("camPos", cam3.pos);
	sh.hset("camRight", cam3.right);
	sh.hset("camUp", cam3.up);
	sh.hset("camFwd", cam3.fwd);
	sh.hset("focal", cam3.focal);
	sh.hset("renderHalf", [960.0, 540.0]);
	sh.hset("depthZ", depthZ);
	sh.hset("feetPx", feetPx);
	sh.hset("fogTop", cam3.top);       // each camera has its own: it must stay below the camera or the mist becomes a wall
	sh.hset("groundH", GROUND_H);
	sh.hset("pushR", PUSH_R);
	sh.hset("pushMeters", PUSH_METERS);
	sh.hset("clearR", CLEAR_R);
	sh.hset("tintMix", TINT_MIX);
	sh.hset("baseColor", [channel(BASE_COLOR, 16), channel(BASE_COLOR, 8), channel(BASE_COLOR, 0)]);
	spr.shader = sh;
	if (cam != null) spr.cameras = [cam];
	state.add(spr);
	layers.push({spr: spr, sh: sh});
}

function createBack(cam) {
	makeFog(0.0, 1.0, cam);
}

function createFront(cam) {
	// the part of the mist between the camera and Zyra: it passes in front of her legs, so she stands inside it
	makeFog(1.0, 1.0, cam);
}

function createReflection(char, cam) {
	reflChar = char;
	refl = new FlxSprite();
	refl.frames = char.frames;
	refl.flipY = true;
	refl.antialiasing = true;
	refl.alpha = reflAlpha;
	reflShader = new CustomShader("WaterReflect");
	reflShader.hset("fadeLen", REFL_FADE);
	reflShader.hset("wave", REFL_WAVE);
	reflShader.hset("tint", REFL_TINT);
	reflShader.hset("frameRect", [0.0, 0.0, 1.0, 1.0]);
	refl.shader = reflShader;
	if (cam != null) refl.cameras = [cam];
	state.add(refl);
}

function syncReflection() {
	if (refl == null || reflChar == null) return;
	refl.animation.frameIndex = reflChar.animation.frameIndex;
	refl.flipX = reflChar.flipX;
	refl.scale.set(reflChar.scale.x, reflChar.scale.y);
	refl.updateHitbox();
	refl.alpha = reflAlpha;
	refl.x = reflChar.x + reflChar.frameWidth * (1 - reflChar.scale.x) / 2;     // the character grows around its centre
	refl.y = anchorY + reflGap;
	var uv = refl.frame.uv;
	reflShader.hset("frameRect", [uv.left, uv.top, uv.right - uv.left, uv.bottom - uv.top]);
	reflShader.hset("time", time);
	reflShader.hset("glitch", glitch);
}

// gap moves the ground line of both the reflection and the mist (game pixels, + is down): the one number to set per camera
function setReflection(alpha, gap) {
	reflAlpha = alpha;
	reflGap = gap;
}

function setGlitch(g) {
	glitch = g;
}

function setDensity(d) {
	density = d;
}

function getReflectionAlpha() { return reflAlpha; }
function getReflectionGap() { return reflGap; }
function getDensity() { return density; }
function getQuality() { return quality; }

function setQuality(q) {
	quality = q;
}
function getGlitch() { return glitch; }

// x, y: where the light is on the screen (game pixels); radius in game pixels. The light is placed in the world on the camera ray through that
// point, LIGHT_DIST metres away, so the fog around it glows with the right perspective.
function setLight(color, lvl, x, y, radius) {
	lightColor = color;
	levelTarget = lvl;
	var rx = feetPx[0] + (x - anchorX) / pxScale;
	var ry = feetPx[1] + (y - (anchorY + reflGap)) / pxScale;
	var d = [cam3.fwd[0] * cam3.focal + cam3.right[0] * (rx - 960.0) + cam3.up[0] * (540.0 - ry),
		cam3.fwd[1] * cam3.focal + cam3.right[1] * (rx - 960.0) + cam3.up[1] * (540.0 - ry),
		cam3.fwd[2] * cam3.focal + cam3.right[2] * (rx - 960.0) + cam3.up[2] * (540.0 - ry)];
	var n = Math.sqrt(dot3(d, d));
	light3 = [cam3.pos[0] + d[0] / n * LIGHT_DIST, cam3.pos[1] + d[1] / n * LIGHT_DIST, cam3.pos[2] + d[2] / n * LIGHT_DIST];
	lightR = radius / (cam3.focal / LIGHT_DIST * pxScale);
}

// a short lift of density and glow (the mist "breathes" with a hit, a beat, a memory)
function pulse(amount) {
	breath = Math.max(breath, amount);
}

function flash(amount) {
	flashEnv = Math.max(flashEnv, amount);
}

// strength 1000 = the full push; seconds = how long Zyra keeps pushing (the mist then comes back by itself)
function push(strength, seconds) {
	pushes.push({str: strength / 1000.0, t: 0.0, dur: seconds});
}

function update(elapsed) {
	time += elapsed;
	level += (levelTarget - level) * Math.min(1, elapsed * 5);
	flashEnv *= Math.exp(-elapsed * 4.5);
	breath *= Math.exp(-elapsed * 3.0);
	flowX += elapsed * (0.06 + 0.05 * Math.sin(time * 0.37) + 0.03 * Math.sin(time * 0.91 + 1.0));      // wind with gusts

	// the strongest push drives the shader: it rises while Zyra pushes and then decays
	var amt = 0.0;
	var k = pushes.length - 1;
	while (k >= 0) {
		var pu = pushes[k];
		pu.t += elapsed;
		var env = 0.0;
		if (pu.t < pu.dur) env = Math.sin(Math.PI * 0.5 * pu.t / pu.dur);
		else env = Math.exp(-(pu.t - pu.dur) * RETURN_RATE);
		env *= pu.str;
		if (env > amt) amt = env;
		if (pu.t > pu.dur && env < 0.01) pushes.splice(k, 1);
		k--;
	}

	var lr = lightColor;
	for (l in layers) {
		var sh = l.sh;
		sh.hset("time", time);
		sh.hset("density", density);
		sh.hset("flowX", flowX);
		sh.hset("quality", quality);
		sh.hset("anchorWorld", [anchorX, anchorY + reflGap]);
		sh.hset("pushAmt", Math.min(1.0, amt));
		sh.hset("pushPos", [FEET[0], FEET[1], 0.25]);
		sh.hset("light3", light3);
		sh.hset("lightR", lightR);
		sh.hset("breath", breath);
		sh.hset("lightLevel", level);
		sh.hset("flash", flashEnv);
		sh.hset("lightColor", [channel(lr, 16), channel(lr, 8), channel(lr, 0)]);
	}
	syncReflection();
}
