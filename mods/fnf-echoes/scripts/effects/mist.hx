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
// Called from outside: setView(cameraName, anchorX, anchorY, pxScale) or setStageView(cameraName), setInsertBefore(char), setFrontCamera(cam), hitLane(lane, amount), createReflection(char, cam), createBack(cam), createFront(cam), update(elapsed),
// setLight(color, level, x, y, radius), flash(amount), pulse(amount), push(strength, seconds), setDensity(d), setQuality(q), setGlitch(g), setReflection(alpha, gap),
// getDensity(), getQuality(), getGlitch(), getReflectionAlpha(), getReflectionGap().

var CAMERAS = [
	{name: "Camera", top: 1.8, feet: [1.608, 0.113], pos: [0.6664, -9.8178, 2.7672], right: [1.0, 0.0, 0.0], up: [0.0, 0.0974, 0.99525], fwd: [0.0, 0.99525, -0.0974], focal: 2666.667},
	{name: "Camera.001", top: 1.0, feet: [1.608, 0.113], pos: [-3.4873, -1.9451, 1.3935], right: [0.46014, -0.88785, 0.0], up: [0.0, 0.0, 1.0], fwd: [0.88785, 0.46014, 0.0], focal: 3672.6},
	{name: "Camera.002", top: 1.2, feet: [1.608, 0.113], pos: [-0.2251, 8.8094, 1.6906], right: [-0.97842, -0.20662, 0.0], up: [0.0, 0.0, 1.0], fwd: [0.20662, -0.97842, 0.0], focal: 6969.17},
	{name: "Camera.003", top: 0.9, feet: [1.635, 0.118], pos: [-1.705, 0.1171, 0.203], right: [0.0, -1.0, 0.0], up: [-0.45518, 0.0, 0.8904], fwd: [0.8904, 0.0, 0.45518], focal: 3254.7}
];
var STAGE_LEFT = 289.0;          // the stage shows world 289..1711 x 200..1000: the Blender render frame (1920x1080) covers exactly that
var STAGE_TOP = 200.0;
var STAGE_PX_PER_RENDER = 1422.0 / 1920.0;
var FEET = [1.608, 0.113, 0.0];  // where Zyra's feet are in the Blender scene (metres); each camera entry has its own x and y
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
var REFL_TINT = [0.72, 0.74, 0.78];      // grey water (it was blue)
var REFL_WAVE = 0.018;
// the arrows give off light (songs/limboScene.hx publishes where they are): the colours of the lanes pulled towards grey (the common palette), a steady glow and a flash with every hit
var ARROW_COLORS = [[0.59, 0.51, 0.92], [0.43, 0.63, 1.0], [0.47, 0.90, 0.78], [0.94, 0.55, 0.75]];
var ARROW_GREY = 0.35;
var ARROW_AMBIENT = 0.22;
var ARROW_HIT = 0.9;
var ARROW_R = 0.85;              // how far the light of an arrow reaches into the mist (metres)

// the water (shaders/WaterSurface.frag): calm and transparent, only ripples catch light. Zyra's boots are WATER_SINK metres in it
var WATER_SINK = 0.07;
var WATER_ZYRA_RING_EVERY = 3.4;       // seconds between the rings that leave her feet
var REFL_PATCH = 0.3;                  // 0 = her reflection is a full mirror, 1 = it only shows through the ripples (Zyra's call: it must be seen well)
var WATER_RING_GREY = 0.6;             // how much the colour of an arrow's ring is pulled towards grey

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
var arrowEnv = [0.0, 0.0, 0.0, 0.0];
var waterAmount = 1.0;
var ringPos = [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]];     // where each ring was born on the floor (metres): lanes 0-3 and Zyra's feet
var ringAge = [0.0, 0.0, 0.0, 0.0, 0.0];
var ringAmp = [0.0, 0.0, 0.0, 0.0, 0.0];
var zyraRingT = 99.0;
var waters = [];                 // the shaders of the water layers

var cam3 = null;                 // the chosen entry of CAMERAS
var lightScreen = null;          // where the light is on the screen (x, y, radius), to place it again when the camera changes
var insertBefore = null;         // the character: the reflection and the mist behind her are drawn before it
var frontLayer = null;
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

// applies one of the cameras: the data the shaders need and where Zyra's feet are on it
function applyCamera(c) {
	cam3 = c;
	FEET[0] = c.feet[0];
	FEET[1] = c.feet[1];
	var d = [FEET[0] - c.pos[0], FEET[1] - c.pos[1], FEET[2] - c.pos[2]];
	depthZ = dot3(d, c.fwd);
	feetPx = [960.0 + c.focal * dot3(d, c.right) / depthZ, 540.0 - c.focal * dot3(d, c.up) / depthZ];
}

// the test room places Zyra where it likes: it says where her feet are in the game (ax, ay) and how big the render is there (scale)
function setView(cameraName, ax, ay, scale) {
	for (c in CAMERAS) {
		if (c.name == cameraName) applyCamera(c);
	}
	anchorX = ax;
	anchorY = ay;
	pxScale = scale;
}

// in the song, the Blender render frame IS the stage: Zyra's feet are where the camera projects them, no need to say it
function setStageView(cameraName) {
	for (c in CAMERAS) {
		if (c.name == cameraName) applyCamera(c);
	}
	pxScale = STAGE_PX_PER_RENDER;
	anchorX = STAGE_LEFT + feetPx[0] * pxScale;
	anchorY = STAGE_TOP + feetPx[1] * pxScale;
	if (lightScreen != null) setLight(lightColor, levelTarget, lightScreen[0], lightScreen[1], lightScreen[2]);   // the light is in the picture: it follows the cut
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
	if (layerMode < 0.5 && insertBefore != null) state.insert(state.members.indexOf(insertBefore), spr);
	else state.add(spr);
	if (layerMode > 0.5) frontLayer = spr;
	layers.push({spr: spr, sh: sh});
}

// the water: one quad per layer, like the mist (behind Zyra / in front of her)
function makeWater(layerMode, cam) {
	var spr = new FlxSprite(QUAD_X, QUAD_Y);
	spr.makeGraphic(Math.ceil(QUAD_W), Math.ceil(QUAD_H), 0xFFFFFFFF);
	var sh = new CustomShader("WaterSurface");
	sh.hset("layerMode", layerMode);
	sh.hset("quadRect", [QUAD_X, QUAD_Y, QUAD_W, QUAD_H]);
	sh.hset("renderHalf", [960.0, 540.0]);
	sh.hset("sink", WATER_SINK);
	for (i in 0...4) {
		var c = ARROW_COLORS[i];
		var g = (c[0] + c[1] + c[2]) / 3.0;
		sh.hset("rc" + i, [c[0] + (g - c[0]) * WATER_RING_GREY, c[1] + (g - c[1]) * WATER_RING_GREY, c[2] + (g - c[2]) * WATER_RING_GREY]);
	}
	spr.shader = sh;
	if (cam != null) spr.cameras = [cam];
	if (layerMode < 0.5 && insertBefore != null) state.insert(state.members.indexOf(insertBefore), spr);
	else state.add(spr);
	if (layerMode > 0.5) frontLayer = spr;
	waters.push(sh);
}

function createWaterBack(cam) {
	makeWater(0.0, cam);
}

function createWaterFront(cam) {
	makeWater(1.0, cam);
}

function setWaterAmount(a) {
	waterAmount = a;
}

// a ring is born at (x, y) on the floor
function ring(i, x, y, amp) {
	ringPos[i] = [x, y];
	ringAge[i] = 0.0;
	ringAmp[i] = amp;
}

// the reflection and the mist behind Zyra go before her in the draw order, the mist in front of her goes after
function setInsertBefore(obj) {
	insertBefore = obj;
}

// the mist in front of Zyra has to be on the camera above the arrows when she is (she is drawn there in the first shot)
function setFrontCamera(cam) {
	if (frontLayer != null) frontLayer.cameras = [cam];
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
	reflShader.hset("pat", REFL_PATCH);
	reflShader.hset("frameRect", [0.0, 0.0, 1.0, 1.0]);
	refl.shader = reflShader;
	if (cam != null) refl.cameras = [cam];
	if (insertBefore != null) state.insert(state.members.indexOf(insertBefore), refl);
	else state.add(refl);
}

function syncReflection() {
	if (refl == null || reflChar == null) return;
	refl.animation.frameIndex = reflChar.animation.frameIndex;
	refl.flipX = reflChar.flipX;
	refl.scale.set(reflChar.scale.x, reflChar.scale.y);
	refl.updateHitbox();
	refl.alpha = reflAlpha;
	refl.x = reflChar.x + reflChar.frameWidth * (1 - reflChar.scale.x) / 2;     // the character grows around its centre
	// the flipped frame is the whole render frame: its feet-line must land on the ground line, so its top is the mirror of the character's bottom
	refl.y = 2.0 * (anchorY + reflGap) - (reflChar.y + reflChar.frameHeight * (1.0 + reflChar.scale.y) / 2.0);
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
	lightScreen = [x, y, radius];
	var rx = feetPx[0] + (x - anchorX) / pxScale;
	var ry = feetPx[1] + (y - (anchorY + reflGap)) / pxScale;
	var d = [cam3.fwd[0] * cam3.focal + cam3.right[0] * (rx - 960.0) + cam3.up[0] * (540.0 - ry),
		cam3.fwd[1] * cam3.focal + cam3.right[1] * (rx - 960.0) + cam3.up[1] * (540.0 - ry),
		cam3.fwd[2] * cam3.focal + cam3.right[2] * (rx - 960.0) + cam3.up[2] * (540.0 - ry)];
	var n = Math.sqrt(dot3(d, d));
	light3 = [cam3.pos[0] + d[0] / n * LIGHT_DIST, cam3.pos[1] + d[1] / n * LIGHT_DIST, cam3.pos[2] + d[2] / n * LIGHT_DIST];
	lightR = radius / (cam3.focal / LIGHT_DIST * pxScale);
}

// an arrow was hit: its light flashes
function hitLane(lane, amount) {
	if (lane >= 0 && lane < 4) {
		arrowEnv[lane] = Math.max(arrowEnv[lane], amount);
		var lights = FlxG.save.data.echoesArrowLights;
		if (lights != null) ring(lane, lights[lane][0], lights[lane][1], 0.9 * amount);       // the arrow that was hit drops a ring on the water
	}
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
	ring(4, FEET[0], FEET[1], 1.6);                 // the pose change shakes the water around her
	zyraRingT = 0.0;
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

	// the light of the four arrows (null positions: the row is not in the scene, no light)
	var lights = FlxG.save.data.echoesArrowLights;
	var aPos = [[0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]];
	var aCol = [[0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]];
	for (i in 0...4) {
		arrowEnv[i] *= Math.exp(-elapsed * 4.0);
		if (lights != null && level > 0.01) {
			aPos[i] = lights[i];
			var kk = (ARROW_AMBIENT + ARROW_HIT * arrowEnv[i]) * level;
			var c = ARROW_COLORS[i];
			var g = (c[0] + c[1] + c[2]) / 3.0;
			aCol[i] = [(c[0] + (g - c[0]) * ARROW_GREY) * kk, (c[1] + (g - c[1]) * ARROW_GREY) * kk, (c[2] + (g - c[2]) * ARROW_GREY) * kk];
		}
	}
	var lr = lightColor;
	for (l in layers) {
		var sh = l.sh;
		sh.hset("time", time);
		sh.hset("camPos", cam3.pos);
		sh.hset("camRight", cam3.right);
		sh.hset("camUp", cam3.up);
		sh.hset("camFwd", cam3.fwd);
		sh.hset("focal", cam3.focal);
		sh.hset("depthZ", depthZ);
		sh.hset("feetPx", feetPx);
		sh.hset("fogTop", cam3.top);
		sh.hset("pxScale", pxScale);
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
		sh.hset("aPos0", aPos[0]);
		sh.hset("aPos1", aPos[1]);
		sh.hset("aPos2", aPos[2]);
		sh.hset("aPos3", aPos[3]);
		sh.hset("aCol0", aCol[0]);
		sh.hset("aCol1", aCol[1]);
		sh.hset("aCol2", aCol[2]);
		sh.hset("aCol3", aCol[3]);
		sh.hset("aR", ARROW_R);
	}
	// the rings: they age, and Zyra's feet send a small one every few seconds
	for (i in 0...5) ringAge[i] += elapsed;
	zyraRingT += elapsed;
	if (zyraRingT > WATER_ZYRA_RING_EVERY) {
		zyraRingT = 0.0;
		ring(4, FEET[0], FEET[1], 0.5);
	}
	var wl = lightColor;
	for (ws in waters) {
		ws.hset("time", time);
		ws.hset("camPos", cam3.pos);
		ws.hset("camRight", cam3.right);
		ws.hset("camUp", cam3.up);
		ws.hset("camFwd", cam3.fwd);
		ws.hset("focal", cam3.focal);
		ws.hset("depthZ", depthZ);
		ws.hset("feetPx", feetPx);
		ws.hset("pxScale", pxScale);
		ws.hset("anchorWorld", [anchorX, anchorY + reflGap]);
		ws.hset("light3", light3);
		ws.hset("lightColor", [channel(wl, 16), channel(wl, 8), channel(wl, 0)]);
		ws.hset("amount", waterAmount);
		ws.hset("ring0", [ringPos[0][0], ringPos[0][1], ringAge[0], ringAmp[0]]);
		ws.hset("ring1", [ringPos[1][0], ringPos[1][1], ringAge[1], ringAmp[1]]);
		ws.hset("ring2", [ringPos[2][0], ringPos[2][1], ringAge[2], ringAmp[2]]);
		ws.hset("ring3", [ringPos[3][0], ringPos[3][1], ringAge[3], ringAmp[3]]);
		ws.hset("ring4", [ringPos[4][0], ringPos[4][1], ringAge[4], ringAmp[4]]);
	}
	syncReflection();
}
