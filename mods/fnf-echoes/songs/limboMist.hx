import funkin.backend.scripting.Script;

// Limbo's water (BE-54): scripts/effects/mist.hx inside the song, with shaders/WaterSurface.frag. Only in Limbo. It replaces the mist (the mist code stays in the script).
// Calm, TRANSPARENT water on the floor: it has no body, only the ripples catch light (glitter of the cool light and a dim sky) and Zyra's reflection is only seen through them.
// It lives in the same 3D space as Zyra's Blender camera, so it follows the camera cuts of her frames (songs/zyraPoses.hx, DS-2). The floor behind Zyra and her reflection are drawn
// BEFORE her, the floor in front of her AFTER her (and on her camera when she is in front of the arrows: songs/limboScene.hx, BE-57); her boots are a little under the water.
// Rings leave her feet every few seconds, a bigger one when the pose change starts, and the arrow that is hit drops a coloured ring on the water (limboScene.hx publishes where the
// arrows are). Like Zyra, the water comes out of the black during the first seconds of the song.

var REFLECTION_ALPHA = 0.6;       // Zyra's reflection must be seen well (her call)
var LIGHT_COLOR = 0xFFB4B8C0;      // a pale grey light (the water was blue), high in the picture: the memories of the carousel will take its place (BE-55)
var REVEAL_MS = 2500.0;            // the same as in limboScene.hx
var CUT_FRAME = 9;                 // the pose change cuts to its last camera on this frame of the animation (the same as in limboScene.hx)
var WATER_FADE_S = 1.0;            // after that cut the water goes away softly over this long, it does not vanish at once (Zyra's call)
var CAMERA_NAMES = ["Camera", "Camera.001", "Camera.002", "Camera.003"];

var isLimbo = false;
var mist = null;
var lastSet = -1;
var cutDone = false;
var fadeT = 0.0;
var lastView = -1;

function zyra() {
	return strumLines.members[1].characters[0];
}

function postCreate() {
	var name = PlayState.SONG.meta.name;
	isLimbo = (name != null && name.toLowerCase() == "limbo");
	if (!isLimbo) return;
	var z = zyra();
	mist = Script.create(Paths.script('scripts/effects/mist'));
	mist.load();
	mist.call("setStageView", ["Camera"]);
	mist.call("setInsertBefore", [z]);
	mist.call("setReflection", [REFLECTION_ALPHA, 0.0]);
	mist.call("setWaterAmount", [0.0]);
	mist.call("createReflection", [z, null]);
	mist.call("createWaterBack", [null]);
	mist.call("createWaterFront", [null]);
	mist.call("setLight", [LIGHT_COLOR, 1.0, 1000.0, 300.0, 650.0]);
}

function postUpdate(elapsed) {
	if (!isLimbo) return;
	var set = FlxG.save.data.echoesZyraSet;
	if (set == null) set = 0;
	if (set != lastSet) {
		if (lastSet == 2 && set == 3) mist.call("push", [1000.0, 0.625]);        // the pose change: Zyra opens the mist
		cutDone = (set == 3 && lastSet != 2);              // a start from the middle of the song: already in the last shot
		fadeT = cutDone ? WATER_FADE_S : 0.0;
		if (set != 3) cutDone = false;
		lastSet = set;
	}
	// the pose change starts with the camera of the shot before (the floor is still there) and cuts to the close one on its tenth frame: the water follows the cut
	var view = set;
	if (set == 3 && !cutDone) {
		var cur = zyra().animation.curAnim;
		if (cur != null && cur.name == "poseChange" && cur.curFrame < CUT_FRAME) view = 2;
		else cutDone = true;
	}
	if (view != lastView) {
		mist.call("setStageView", [CAMERA_NAMES[view]]);
		lastView = view;
	}
	if (set == 3 && cutDone) fadeT = Math.min(WATER_FADE_S, fadeT + elapsed);
	var keep = 1.0;
	if (set == 3) { var k = fadeT / WATER_FADE_S; keep = 1.0 - k * k * (3.0 - 2.0 * k); }
	// the mist in front of Zyra goes on the camera she is on
	mist.call("setFrontCamera", [zyra().cameras[0]]);

	var a = Math.max(0.0, Math.min(1.0, Conductor.songPosition / REVEAL_MS));
	a = a * a * (3.0 - 2.0 * a);
	mist.call("setWaterAmount", [a * keep]);
	mist.call("setReflection", [REFLECTION_ALPHA * a * keep, 0.0]);
	mist.call("update", [elapsed]);
}

function onPlayerHit(event) {
	if (!isLimbo) return;
		if (event.note != null) mist.call("hitLane", [event.note.strumID, 1.0]);       // the arrow that was hit drops a ring on the water
}
