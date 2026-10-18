import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.backend.shaders.CustomShader;
import funkin.game.HudCamera;

// Limbo's scene (BE-57, BE-56): the arrows of Zyra live INSIDE the scene, in the perspective of Zyra's real Blender camera.
//
// 1. FIRST SHOT (set 0 of her frames, the `Camera` of Blender, until the first camera cut): Zyra's row (strum line 1) is drawn by the engine as usual, but on its own
//    camera, and a shader (shaders/PlaneWarp.frag) lays that whole flat picture on a PLANE of the 3D scene: to the left of Zyra and further back than her, turned and
//    leaning as Zyra decides. The picture is really warped by the real camera (position, axes and focal length, the same numbers as scripts/effects/mist.hx): the
//    arrows are foreshortened, the lanes converge to a vanishing point and a long note leans with them. The notes fade in at the top. Zyra is drawn ABOVE the arrows
//    in this shot: her character goes to an extra camera over the arrows'.
// 2. THE RAISED ARM (pose 3, set 3): Zyra's body stays below the arrows and her arm, rendered apart (images/characters/zyra_arm), is drawn above them.
// 3. THE BEGINNING: the song starts all black (Zyra and the health bar are hidden, the arrows are there) and they are revealed in REVEAL_MS. Soul's row (strum line 0)
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
var REVEAL_MS = 2500.0;                      // Zyra and the health bar come out of the black during the first seconds of the song
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
	arrowCam.addShader(warp);

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

// ---- the plane --------------------------------------------------------------------------------------------------------------------------

// the final screen pivot of a strum (after the downscroll flip): x - offset + origin; y mirrored when downscroll
function pivotX(o) {
	return o.x - o.offset.x + o.origin.x;
}

function pivotY(o) {
	if (PlayState.instance.downscroll) return arrowCam.height - o.y - o.height - o.offset.y + o.origin.y;
	return o.y - o.offset.y + o.origin.y;
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
	warp.hset("planeO", [PLANE_X, PLANE_Y, PLANE_Z]);
	warp.hset("planeR", [cy, sy, 0.0]);
	warp.hset("planeU", [0.0 - sy * Math.sin(tilt), cy * Math.sin(tilt), Math.cos(tilt)]);
	warp.hset("flatCentre", [(x0 + x3) * 0.5, pivotY(line.members[0]) + arrowCam.y]);
	warp.hset("mpp", mpp);
	warp.hset("hudZoom", camHUD.zoom);
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
	if (hudSprites == null) findHud();
	if (revealDone) return;
	zyra().alpha = a;
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

// ---- every frame -------------------------------------------------------------------------------------------------------------------------

function postUpdate(elapsed) {
	if (!isLimbo) return;
	front.scroll.copyFrom(camGame.scroll);
	front.zoom = camGame.zoom;
	var t = Conductor.songPosition;
	reveal(t);
	soulRow(t);

	var set = FlxG.save.data.echoesZyraSet;
	if (set == null) set = 0;
	var z = zyra();

	if (set != lastSet) {
		// first shot: Zyra above the arrows, and the arrows on their own camera (warped); every other: below them, flat as the engine draws them (the arm, in pose 3, is above)
		z.cameras = (set == 0) ? [front] : [camGame];
		strumLines.members[1].cameras = [arrowCam];
		splashHandler.cameras = [arrowCam];
		lastSet = set;
	}
	tune(elapsed, set);
	updateWarp(set);

	// the arm of pose 3: same animation and frame as the body, over the arrows
	var cur = z.animation.curAnim;
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
	if (front != null && FlxG.cameras.list.contains(front)) FlxG.cameras.remove(front);
	if (arrowCam != null && FlxG.cameras.list.contains(arrowCam)) FlxG.cameras.remove(arrowCam);
	if (uiCam != null && FlxG.cameras.list.contains(uiCam)) FlxG.cameras.remove(uiCam);
}
