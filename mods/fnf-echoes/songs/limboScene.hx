import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.backend.shaders.CustomShader;
import funkin.game.HudCamera;
import openfl.Lib;

// Limbo's scene (BE-57, BE-56): the arrows of Zyra live INSIDE the scene, in the perspective of Zyra's real Blender camera.
//
// 1. FIRST SHOT (set 0 of her frames, the `Camera` of Blender, until the first camera cut): Zyra's row (strum line 1) is drawn by the engine as usual, but on its own
//    camera, and a shader (shaders/PlaneWarp.frag) lays that whole flat picture on a PLANE of the 3D scene: to the left of Zyra and further back than her, turned and
//    leaning as Zyra decides. The picture is really warped by the real camera (position, axes and focal length, the same numbers as scripts/effects/mist.hx): the
//    arrows are foreshortened, the lanes converge to a vanishing point and a long note leans with them. The notes fade in at the top. Zyra is drawn ABOVE the arrows
//    in this shot: her character goes to an extra camera over the arrows'.
// 2. THE RAISED ARM (pose 3, set 3): Zyra's body stays below the arrows and her arm, rendered apart (images/characters/zyra_arm), is drawn above them.
// 3. THE BEGINNING: the song starts all black (Zyra and the health bar are hidden, the arrows are there) and they are revealed in REVEAL_MS; the row of arrows slides in from the left
//    and lands in its place as Zyra finishes appearing (SLIDE_IN); the receptors have full opacity and are uncovered by glitching on and off, and some of the first notes
//    tremble in opacity (introGlitch). Soul's row (strum line 0)
//    is hidden until a little before his first note: the first part is Zyra's alone.
// The other shots keep the flat arrows of the engine until Zyra says how she wants them. Only in Limbo.
//
// The arrows' camera is a HudCamera like the game's own, so the downscroll flip keeps working: the shader reads the final, already flipped picture.
//
// While Zyra decides, the keys Z X (left, right), C V (closer, farther), COMMA PERIOD (down, up), G H (turn), U I (tilt) and B N (lane spacing) move the plane
// and the numbers are shown at the top left; she gives them to Claude and they become the constants below.

var CAM_POS = [0.6664, -9.8178, 2.7672];     // Blender camera "Camera" (same data as scripts/effects/mist.hx)
var CAM_RIGHT = [1.0, 0.0, 0.0];
var CAM_UP = [0.0, 0.0974, 0.99525];
var CAM_FWD = [0.0, 0.99525, -0.0974];
var FOCAL = 2666.667;                        // pixels of the 1920x1080 render
var HUD_PER_RENDER = 1280.0 / 1920.0;        // the render frame is what the stage shows: 1920 render pixels are 1280 HUD pixels

// The plane of the arrows in the first shot (metres and degrees): a wall turned, its left side closer to the camera and its right side farther away and next to Zyra,
// whose feet are at (1.608, 0.113, 0). Zyra tuned x, depth, turn and tilt by eye with the keys (x 0.44, depth 0.13, turn 24.77, tilt 0).
var PLANE_X = 0.44;                          // the middle of the row of arrows (x grows to the right of the screen)
var PLANE_Y = 0.13;                          // depth of the middle of the row (y grows away from the camera)
var PLANE_Z = 0.3;                           // height of the receptors: low on the screen, next to Zyra's feet
var PLANE_YAW = 24.77;                       // turn of the row around the vertical axis (positive: the right lanes are farther away)
var PLANE_TILT = 0.0;                        // how much the plane leans back, away from the camera: 0 = a wall, 90 = lying flat on the floor
var LANE_SPACING = 0.59;                     // distance between two lanes
// The other shots: the row is drawn flat as the engine does, only smaller and lower (Zyra's call; the first numbers are Claude's guess).
var FLAT_SCALE = 0.94;                       // size of the flat row (1 = the engine's)
var FLAT_DOWN = 24.0;                        // how many pixels lower it sits
var EXTRA_PX = 900.0;                        // the camera of the arrows is this much taller than the screen, so the notes are already there when they cross its top
var FADE_START = 1.6;                        // the notes fade between this share of the screen height away from their arrow and ... (far beyond the screen: it only hides the cut)
var FADE_END = 2.0;                          // ... this one
var SHOW_HEALTH_HUD = false;                 // Zyra: the health bar is out for now
var DESAT = 0.3;                             // the common palette of the arrows: pulled towards grey ...
var TINT = [0.93, 0.97, 1.08];               // ... and towards the cool tone of the scene
var ASCII_ON = false;                        // Zyra took the ASCII veil out for now (shaders/AsciiVeil.frag and images/game/ascii stay; true brings it back)
var ASCII_ARROWS = 0.3;                      // the veil of ASCII characters: over the arrows (strength 0..1) ...
var ASCII_RECEPTORS = 0.3;                   // over the row of receptors (the fixed arrows) the veil is only this share of what it is over the notes
var ASCII_WORLD = 0.08;                      // ... and, very light, over the mist and Zyra
var ASCII_CELL = [8.0, 14.0];                // one character, in pixels of the screen
var ASCII_INK = [0.72, 0.84, 1.0];           // the colour of the characters, mixed with the colour of what they are over
var LEAN_ROLL = 1.0;                         // the camera LEANS with the notes: how many degrees it rolls towards the side of the note (left, right) ...
var LEAN_SHIFT = 11.0;                       // ... and how many pixels it moves (to the side of the note; up and down only move)
var LEAN_HOLD_MS = 280.0;                    // a note holds the lean this long (a long note keeps renewing it); then the camera comes back
var LEAN_IN = 5.0;                           // how fast it leans (1/s) and how fast it comes back
var LEAN_OUT = 3.5;
var WHIP_ON = false;                         // the throw, roll and zoom of the camera at every cut: OFF (Zyra's call: it did not feel continuous); true brings it back
var WHIP_MS = 800.0;                         // a camera cut throws the camera and it LANDS softly: how long it takes to settle
// each cut: how far it is thrown (pixels), how much it rolls (degrees) and how much it zooms in when the new shot arrives. [camera.001, camera.002, pose change, inside the pose change]
var WHIPS = [[70.0, 0.0, 1.0, 0.025], [-70.0, 0.0, -1.0, 0.025], [0.0, -35.0, 0.0, 0.03], [90.0, 18.0, 1.4, 0.035]];
var MIRROR_ALPHA = 0.32;                     // the arrows are reflected in the floor, like Zyra: how strong the reflection is (0 = none) ...
var MIRROR_FADE = 2.2;                       // ... how deep it goes before it is gone (metres) ...
var MIRROR_WAVE = 0.02;                      // ... the ripples of the water (metres) and the short sideways jumps (the same glitch as Zyra's reflection)
var MIRROR_GLITCH = 0.35;
var MIRROR_TINT = [0.78, 0.8, 0.84];        // grey water (it was blue)
var REVEAL_MS = 2500.0;                      // Zyra and the health bar come out of the black during the first seconds of the song
var SLIDE_IN = 1.6;                          // at the very beginning the row slides in from the left and lands as Zyra finishes appearing: it starts with its middle at a quarter of the screen (the middle of the left half), 1.6 m along the row from its place
var GLITCH_MS = 2500.0;                      // the receptors are uncovered by glitching on and off (full opacity, no fade) during this long, while the row slides in
var GLOW_PEAK = 0.8;                         // while a receptor is still transparent it lights up a little with the notes of its OWN lane: how bright at most (alpha)
var GLOW_LEAD_MS = 350.0;                    // it starts to rise this long before each note reaches it and fades out after
var TREMBLE_END_MS = 4700.0;                 // some of the falling notes tremble in opacity (only the opacity) until the first camera cut
var TREMBLE_SHARE = 0.25;                    // how many of them (0..1)
var SOUL_LEAD_MS = 2000.0;                   // Soul's row appears this long before his first note
var TUNE = true;                             // the keys that move the plane

var isLimbo = false;
var front = null;
var arrowCam = null;
var warp = null;
var uiCam = null;
var tuneText = null;
var armSpr = null;
var lastSet = -1;
var leanTX = 0.0;
var leanTY = 0.0;
var leanX = 0.0;
var leanY = 0.0;
var leanMidX = 0.0;       // the lean goes through two smoothings in a row: it starts and stops softly (an ease), it does not snap
var leanMidY = 0.0;
var leanLast = -99999.0;
var whipT = 99.0;
var whipDX = 0.0;
var whipDY = 0.0;
var whipRoll = 0.0;
var innerCut = false;
var asciiShaders = [];
var asciiArrows = null;
var asciiTime = 0.0;
var hudSprites = null;        // the sprites of the health HUD (scripts can not see each other's variables: they are found by their image)
var soulShowAt = null;
var soulShown = false;
var revealDone = false;

function zyra() {
	return strumLines.members[1].characters[0];
}

function postCreate() {
	var name = PlayState.SONG.meta.name;
	isLimbo = (name != null && name.toLowerCase() == "limbo");
	if (!isLimbo) return;

	// the camera of the arrows: a HudCamera (the downscroll flip) with the warp shader, over the HUD one; the camera of Zyra in front goes over it
	arrowCam = new HudCamera();
	arrowCam.downscroll = PlayState.instance.downscroll;
	arrowCam.bgColor = 0x00000000;
	arrowCam.setSize(1280, 720 + Std.int(EXTRA_PX));
	arrowCam.y = PlayState.instance.downscroll ? 0.0 - EXTRA_PX : 0.0;     // downscroll: the notes come from ABOVE the screen; upscroll: from below it
	FlxG.cameras.add(arrowCam, false);
	warp = new CustomShader("PlaneWarp");
	warp.hset("camPos", CAM_POS);
	warp.hset("camRight", CAM_RIGHT);
	warp.hset("camUp", CAM_UP);
	warp.hset("camFwd", CAM_FWD);
	warp.hset("focal", FOCAL);
	warp.hset("hudPerRender", HUD_PER_RENDER);
	warp.hset("hudSize", [1280.0, 720.0]);
	warp.hset("camSize", [1280.0, 720.0 + EXTRA_PX]);
	warp.hset("camOffset", [0.0, arrowCam.y]);
	warp.hset("fadeStart", FADE_START);
	warp.hset("fadeEnd", FADE_END);
	warp.hset("mirrorAlpha", MIRROR_ALPHA);
	warp.hset("mirrorFade", MIRROR_FADE);
	warp.hset("mirrorWave", MIRROR_WAVE);
	warp.hset("mirrorGlitch", MIRROR_GLITCH);
	warp.hset("mirrorTint", MIRROR_TINT);
	warp.hset("time", 0.0);
	warp.hset("rollRad", 0.0);
	warp.hset("shiftPx", [0.0, 0.0]);
	warp.hset("desat", DESAT);
	warp.hset("tint", TINT);
	arrowCam.addShader(warp);
	// the veil of characters over the arrows (a taller camera that sits partly off the screen) and, much lighter, over the world camera
	if (ASCII_ON) {
		asciiArrows = makeAscii([1280.0, 720.0 + EXTRA_PX], [0.0, arrowCam.y], ASCII_ARROWS);
		asciiArrows.hset("quiet", ASCII_RECEPTORS);
		arrowCam.addShader(asciiArrows);
		camGame.addShader(makeAscii([1280.0, 720.0], [0.0, 0.0], ASCII_WORLD));
	}

	// a camera above the arrows' one that copies the game camera (scroll and zoom) every frame: what is drawn there is in front of the arrows
	front = new FlxCamera();
	front.bgColor = 0x00000000;
	FlxG.cameras.add(front, false);

	// the arm of pose 3, rendered apart; it plays the same animation and frame as the body
	armSpr = new FlxSprite();
	armSpr.frames = Paths.getFrames("characters/zyra_arm");
	var names = ["idle", "singUP", "singDOWN", "singLEFT", "singRIGHT"];
	for (n in names)
		armSpr.animation.addByPrefix(n + "_d", "d_" + n, 24, false);
	armSpr.antialiasing = true;
	armSpr.cameras = [front];
	armSpr.visible = false;
	add(armSpr);

	if (TUNE) {
		uiCam = new FlxCamera();
		uiCam.bgColor = 0x00000000;
		FlxG.cameras.add(uiCam, false);
		tuneText = new FlxText(10, 8, 900, "");
		tuneText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, "left");
		tuneText.cameras = [uiCam];
		tuneText.scrollFactor.set();
		add(tuneText);
	}
	// black from the very first frame (the countdown too)
	zyra().alpha = 0.0;
}

// The note that is hit sets where the camera leans: 0 left, 1 down, 2 up, 3 right (a long note renews it with every piece)
function onPlayerHit(event) {
	if (!isLimbo || event.note == null) return;
	var d = event.note.strumID;
	leanTX = (d == 0) ? -1.0 : ((d == 3) ? 1.0 : 0.0);
	leanTY = (d == 2) ? -1.0 : ((d == 1) ? 1.0 : 0.0);
	leanLast = Lib.getTimer();
}

// a camera cut: the new shot arrives thrown to one side, rolled and zoomed in, and the camera lands in place with a soft deceleration
function startWhip(i) {
	if (!WHIP_ON) return;
	var w = WHIPS[i];
	whipDX = w[0];
	whipDY = w[1];
	whipRoll = w[2];
	whipT = 0.0;
	camGame.zoom += w[3];                  // the engine brings the zoom back to the stage's by itself
}

// the lean of the world cameras (the arrows that live in the scene follow it through the shader)
function updateLean(elapsed, set) {
	var active = (Lib.getTimer() - leanLast) < LEAN_HOLD_MS;
	var tx = active ? leanTX : 0.0;
	var ty = active ? leanTY : 0.0;
	var rate = active ? LEAN_IN : LEAN_OUT;
	var f = Math.min(1.0, elapsed * rate);
	leanMidX += (tx - leanMidX) * f;
	leanMidY += (ty - leanMidY) * f;
	leanX += (leanMidX - leanX) * f;
	leanY += (leanMidY - leanY) * f;
	// the camera rolls towards the side of the note and moves towards it, so what it sees moves the other way
	whipT += elapsed;
	var u = Math.min(1.0, whipT / (WHIP_MS / 1000.0));
	var land = Math.pow(1.0 - u, 4.0);       // fast at the start, a long soft landing at the end
	camGame.angle = leanX * LEAN_ROLL + whipRoll * land;
	camGame.x = 0.0 - leanX * LEAN_SHIFT + whipDX * land;
	camGame.y = 0.0 - leanY * LEAN_SHIFT + whipDY * land;
	front.angle = camGame.angle;
	front.x = camGame.x;
	front.y = camGame.y;
	warp.hset("rollRad", camGame.angle * 0.017453292);
	warp.hset("shiftPx", [camGame.x, camGame.y]);
}

function makeAscii(camSize, camOffset, strength) {
	var sh = new CustomShader("AsciiVeil");
	sh.hset("glyphs", FlxG.bitmap.add(Paths.image("game/ascii/ramp")));      // Paths.image gives the PATH; the shader wants the loaded picture
	sh.hset("camSize", camSize);
	sh.hset("camOffset", camOffset);
	sh.hset("cell", ASCII_CELL);
	sh.hset("count", 10.0);
	sh.hset("strength", strength);
	sh.hset("minLuma", 0.05);
	sh.hset("gain", 1.5);
	sh.hset("inkMix", 0.85);
	sh.hset("time", 0.0);
	sh.hset("inkColor", ASCII_INK);
	sh.hset("quietY", 0.0);
	sh.hset("quietH", 1.0);
	sh.hset("quiet", 1.0);
	asciiShaders.push(sh);
	return sh;
}

// ---- the plane --------------------------------------------------------------------------------------------------------------------------

// the final screen pivot of a strum (after the downscroll flip): x - offset + origin; y mirrored when downscroll
function pivotX(o) {
	return o.x - o.offset.x + o.origin.x;
}

function pivotY(o) {
	if (PlayState.instance.downscroll) return arrowCam.height - o.y - o.height - o.offset.y + o.origin.y;
	return o.y - o.offset.y + o.origin.y;
}

// how far to the left of its place the row is (metres along the row): only at the start of the song, while Zyra comes out of the black
function slideOffset() {
	var a = Math.max(0.0, Math.min(1.0, Conductor.songPosition / REVEAL_MS));
	var e = 1.0 - Math.pow(1.0 - a, 3.0);       // it arrives fast and settles softly
	return 0.0 - SLIDE_IN * (1.0 - e);
}

function updateWarp(set) {
	var line = strumLines.members[1];
	var x0 = pivotX(line.members[0]);
	var x3 = pivotX(line.members[3]);
	var spacingPx = Math.abs(x3 - x0) / 3.0;
	if (spacingPx < 1) spacingPx = 112.0;
	var mpp = LANE_SPACING / spacingPx;

	// the plane: the row turned by the yaw, and the direction the notes travel, leaning back by the tilt
	var yaw = PLANE_YAW * 0.017453292;
	var tilt = PLANE_TILT * 0.017453292;
	var cy = Math.cos(yaw);
	var sy = Math.sin(yaw);
	var slide = slideOffset();
	warp.hset("planeO", [PLANE_X + cy * slide, PLANE_Y + sy * slide, PLANE_Z]);
	warp.hset("planeR", [cy, sy, 0.0]);
	warp.hset("planeU", [0.0 - sy * Math.sin(tilt), cy * Math.sin(tilt), Math.cos(tilt)]);
	warp.hset("flatCentre", [(x0 + x3) * 0.5, pivotY(line.members[0]) + arrowCam.y]);
	warp.hset("mpp", mpp);
	warp.hset("hudZoom", set == 0 ? camGame.zoom / PlayState.instance.defaultCamZoom : camHUD.zoom);       // in the scene the arrows zoom with the world
	// where the row of receptors is on the screen, for the veil to be quieter there
	var qy = 0.0;
	var qh = 40.0;
	if (set == 0) {
		var p0 = project(PLANE_X, PLANE_Y, PLANE_Z);
		var yaw2 = PLANE_YAW * 0.017453292;
		var pa = project(PLANE_X - Math.cos(yaw2) * 1.5 * LANE_SPACING, PLANE_Y - Math.sin(yaw2) * 1.5 * LANE_SPACING, PLANE_Z);
		var pb = project(PLANE_X + Math.cos(yaw2) * 1.5 * LANE_SPACING, PLANE_Y + Math.sin(yaw2) * 1.5 * LANE_SPACING, PLANE_Z);
		qy = (pa.y + pb.y) * 0.5;
		qh = Math.max(pa.k, pb.k) * LANE_SPACING * 0.6;
	} else {
		qy = pivotY(line.members[0]) + arrowCam.y + FLAT_DOWN;
		qh = 55.0 * FLAT_SCALE;
	}
	if (asciiArrows != null) {
		asciiArrows.hset("quietY", qy);
		asciiArrows.hset("quietH", qh);
	}
	warp.hset("flatMode", set == 0 ? 0.0 : 1.0);
	warp.hset("flatScale", FLAT_SCALE);
	warp.hset("flatShiftY", FLAT_DOWN);
}

// ---- the beginning: black, then revealed; and Soul's row ------------------------------------------------------------------------------------

// the sprites of the health HUD (BE-51) are added by its own script: they are found once by the image they use
function findHud() {
	hudSprites = [];
	for (m in members) {
		try {
			if (m != null && m.graphic != null && m.graphic.key != null && m.graphic.key.indexOf("game/hud/") >= 0)
				hudSprites.push(m);
		} catch (e:Dynamic) {}
	}
}

function reveal(t) {
	var a = Math.max(0.0, Math.min(1.0, t / REVEAL_MS));
	a = a * a * (3.0 - 2.0 * a);
	if (hudSprites == null) {
		findHud();
		for (s in hudSprites) s.visible = SHOW_HEALTH_HUD;
	}
	if (revealDone) return;
	zyra().alpha = a;
	if (SHOW_HEALTH_HUD)
		for (s in hudSprites) s.alpha = a;
	if (a >= 1.0) revealDone = true;
}

function soulRow(t) {
	if (soulShowAt == null) {
		var first = 99999999.0;
		for (n in strumLines.members[0].notes.members)
			if (n != null && n.strumTime < first) first = n.strumTime;
		soulShowAt = first - SOUL_LEAD_MS;
	}
	// hidden until a little before his first note; after that the row is left alone (the "Strum Move" events of the chart may hide or move it)
	if (!soulShown) {
		if (t >= soulShowAt) {
			strumLines.members[0].visible = true;
			soulShown = true;
		} else {
			strumLines.members[0].visible = false;
		}
	}
}

// ---- the beginning: the receptors glitch on and some notes tremble -------------------------------------------------------------------------------

var trembling = null;
var trembleDone = false;
var glitchDone = false;
var laneTimes = null;                        // the strum times of the notes of each lane, for the glow of the transparent receptors

function hash1(a, b) {
	var v = Math.sin(a * 127.1 + b * 311.7) * 43758.5453;
	return v - Math.floor(v);
}

// The engine fades the receptors in by itself (alpha 0 -> 1 in a second): here they have FULL opacity and instead they are uncovered by glitching, lane by lane,
// each one on and off in 60 ms ticks that are on more and more often until it stays on. Some of the first notes tremble in opacity (alpha only, no movement).
// how much a transparent receptor glows now: it rises as a note of its lane comes, peaks as it reaches the receptor and fades out
function laneGlow(lane, t) {
	var g = 0.0;
	for (nt in laneTimes[lane]) {
		var dt = t - nt;
		var v = 0.0;
		if (dt < 0.0) {
			if (dt > 0.0 - GLOW_LEAD_MS) {
				var k = 1.0 + dt / GLOW_LEAD_MS;
				v = k * k * GLOW_PEAK;
			}
		} else {
			v = Math.exp(0.0 - dt / 320.0) * GLOW_PEAK;
		}
		if (v > g) g = v;
	}
	return g;
}

function introGlitch(t) {
	var line = strumLines.members[1];
	if (laneTimes == null) {
		laneTimes = [[], [], [], []];
		for (n in line.notes.members)
			if (n != null && n.strumTime < GLITCH_MS + 500.0 && n.strumID >= 0 && n.strumID < 4) laneTimes[n.strumID].push(n.strumTime);
	}
	if (!glitchDone) {
		var p = t / GLITCH_MS;
		for (i in 0...line.members.length) {
			var q = Math.max(0.0, Math.min(1.0, (p - 0.4 - 0.1 * i) / 0.3));      // completely transparent at first (it only glows with its notes), then lane by lane
			var a = 1.0;
			if (q < 1.0) {
				a = 0.0;
				if (q > 0.0) {
					var h = hash1(i + 1.0, Math.floor(t / 60.0));
					if (h < q * 0.75) a = 1.0;
					else if (h < q * 0.75 + 0.1) a = 0.2;
				}
			}
			if (a < 1.0 && t < GLITCH_MS) a = Math.max(a, laneGlow(i, t));
			line.members[i].alpha = a;
		}
		if (t > GLITCH_MS + 1500.0) glitchDone = true;           // a little later than the glitch: the engine's own fade has finished by then
	}
	if (trembleDone) return;
	if (trembling == null) {
		trembling = [];
		for (n in line.notes.members)
			if (n != null && !n.isSustainNote && n.strumTime < TREMBLE_END_MS + 3000.0 && hash1(n.strumTime * 0.001, n.strumID + 3.0) < TREMBLE_SHARE)
				trembling.push(n);
	}
	var tick = Math.floor(t / 70.0);
	for (n in trembling) {
		if (t >= TREMBLE_END_MS) n.alpha = 1.0;
		else n.alpha = (hash1(n.strumTime * 0.01 + n.strumID, tick) < 0.3) ? 0.6 : 1.0;
	}
	if (t >= TREMBLE_END_MS) trembleDone = true;
}

// ---- every frame -------------------------------------------------------------------------------------------------------------------------

function postUpdate(elapsed) {
	if (!isLimbo) return;
	front.scroll.copyFrom(camGame.scroll);
	front.zoom = camGame.zoom;
	asciiTime += elapsed;
	for (a in asciiShaders) a.hset("time", asciiTime);
	warp.hset("time", asciiTime);
	var t = Conductor.songPosition;
	reveal(t);
	soulRow(t);
	introGlitch(t);

	var set = FlxG.save.data.echoesZyraSet;
	if (set == null) set = 0;
	var z = zyra();

	if (set != lastSet) {
		if (lastSet == 0) startWhip(0);
		else if (lastSet == 1) startWhip(1);
		else if (lastSet == 2) startWhip(2);
		// first shot: Zyra above the arrows, and the arrows on their own camera (warped); every other: below them, flat as the engine draws them (the arm, in pose 3, is above)
		z.cameras = (set == 0) ? [front] : [camGame];
		strumLines.members[1].cameras = [arrowCam];
		splashHandler.cameras = [arrowCam];
		lastSet = set;
	}
	tune(elapsed, set);
	updateWarp(set);
	updateLean(elapsed, set);
	publishArrowLights(set);

	// the pose change cuts to its last camera on its tenth frame (the render's frame 177): that cut gets its own throw
	var cur = z.animation.curAnim;
	if (cur != null && cur.name == "poseChange") {
		if (!innerCut && cur.curFrame >= 9) {
			startWhip(3);
			innerCut = true;
		}
	} else {
		innerCut = false;
	}

	// the arm of pose 3: same animation and frame as the body, over the arrows
	if (set == 3 && cur != null && cur.name != "poseChange" && armSpr.animation.getByName(cur.name) != null) {
		if (armSpr.animation.name != cur.name) armSpr.animation.play(cur.name, true);
		armSpr.animation.curAnim.paused = true;
		armSpr.animation.curAnim.curFrame = Std.int(Math.min(cur.curFrame, armSpr.animation.curAnim.numFrames - 1));
		armSpr.scale.set(z.scale.x, z.scale.y);
		armSpr.x = z.x;
		armSpr.y = z.y;
		armSpr.offset.set(z.offset.x, z.offset.y);
		armSpr.flipX = z.flipX;
		armSpr.alpha = z.alpha;
		armSpr.visible = true;
	} else {
		armSpr.visible = false;
	}
}

// where the four receptors are in the scene (metres), for the mist to take their light (songs/limboMist.hx, BE-54); null when the row is not on the plane
function publishArrowLights(set) {
	if (set != 0) {
		FlxG.save.data.echoesArrowLights = null;
		return;
	}
	var yaw = PLANE_YAW * 0.017453292;
	var slide = slideOffset();
	var lights = [];
	for (i in 0...4) {
		var along = (i - 1.5) * LANE_SPACING;
		lights.push([PLANE_X + Math.cos(yaw) * (along + slide), PLANE_Y + Math.sin(yaw) * (along + slide), PLANE_Z + 0.15]);
	}
	FlxG.save.data.echoesArrowLights = lights;
}

function tune(elapsed, set) {
	if (!TUNE) return;
	var k = FlxG.keys;
	if (set == 0) {
		if (k.pressed.Z) PLANE_X -= 0.6 * elapsed;
		if (k.pressed.X) PLANE_X += 0.6 * elapsed;
		if (k.pressed.C) PLANE_Y -= 1.0 * elapsed;
		if (k.pressed.V) PLANE_Y += 1.0 * elapsed;
		if (k.pressed.B) LANE_SPACING = Math.max(0.1, LANE_SPACING - 0.3 * elapsed);
		if (k.pressed.N) LANE_SPACING += 0.3 * elapsed;
		if (k.pressed.COMMA) PLANE_Z -= 0.6 * elapsed;
		if (k.pressed.PERIOD) PLANE_Z += 0.6 * elapsed;
		if (k.pressed.G) PLANE_YAW -= 30.0 * elapsed;
		if (k.pressed.H) PLANE_YAW += 30.0 * elapsed;
		if (k.pressed.U) PLANE_TILT = Math.max(0.0, PLANE_TILT - 30.0 * elapsed);
		if (k.pressed.I) PLANE_TILT = Math.min(88.0, PLANE_TILT + 30.0 * elapsed);
		tuneText.text = "ARROWS PLANE (first shot)  x " + r2(PLANE_X) + "  depth " + r2(PLANE_Y) + "  height " + r2(PLANE_Z) + "  turn " + r2(PLANE_YAW) + "  tilt " + r2(PLANE_TILT) + "  spacing " + r2(LANE_SPACING)
			+ "\nZ X left/right | C V closer/farther | COMMA PERIOD down/up | G H turn | U I tilt | B N spacing";
	} else {
		if (k.pressed.B) FLAT_SCALE = Math.max(0.2, FLAT_SCALE - 0.4 * elapsed);
		if (k.pressed.N) FLAT_SCALE = Math.min(1.5, FLAT_SCALE + 0.4 * elapsed);
		if (k.pressed.COMMA) FLAT_DOWN += 120.0 * elapsed;
		if (k.pressed.PERIOD) FLAT_DOWN -= 120.0 * elapsed;
		tuneText.text = "FLAT ARROWS (other shots)  size " + r2(FLAT_SCALE) + "  lower by " + r2(FLAT_DOWN) + " px\nB N smaller/bigger | COMMA PERIOD lower/higher";
	}
}

function r2(v) {
	return Math.round(v * 100) / 100;
}

function destroy() {
	FlxG.save.data.echoesArrowLights = null;
	if (front != null && FlxG.cameras.list.contains(front)) FlxG.cameras.remove(front);
	if (arrowCam != null && FlxG.cameras.list.contains(arrowCam)) FlxG.cameras.remove(arrowCam);
	if (uiCam != null && FlxG.cameras.list.contains(uiCam)) FlxG.cameras.remove(uiCam);
}
