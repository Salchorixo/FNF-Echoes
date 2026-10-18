import openfl.Lib;

// Zyra in the song (BE-53, DS-2). Two jobs, both talking to her character script (data/characters/zyra.hx) through FlxG.save.data:
//
// 1. Long notes (BE-53): every piece of a long note that is hit refreshes the time; when the pieces stop arriving she plays the second half of the pose
//    and returns. The song script runs BEFORE the characters sing, so the character already knows it is a held note when the engine asks for the pose again.
//
// 2. The camera cuts of Limbo (DS-2). Zyra's frames are the 1920x1080 Blender renders and the render frame IS what the stage camera shows (centre 1000,600,
//    zoom 0.9: world 289..1711 x 200..1000), so she is placed once and every set of frames lands where it was drawn. The set depends only on the song time:
//        0 s    set 0  Camera      5 s    set 1  Camera.001      7 s    set 2  Camera.002
//        12.375 s  set 3  the pose change (27 frames at 24 fps), which ends at 13.5 s, when the last pose (pose 3, Camera.003) begins.
//    All the cuts are moved CUT_LEAD ms earlier (100 ms: 4.9 s, 6.9 s and 12.275 s, so pose 3 begins at 13.4 s).
//    The cuts are stateless (computed from the time), so a restart or a playtest from the middle of the song also shows the right set.
var STAGE_LEFT = 289.0;
var STAGE_TOP = 200.0;
var CUT_LEAD = 100.0;            // every cut comes this much earlier (ms): at the exact time it felt late (Zyra's call)
var CUT_B = 5000.0 - CUT_LEAD;
var CUT_C = 7000.0 - CUT_LEAD;
var CUT_POSE_CHANGE = 13500.0 - 27.0 / 24.0 * 1000.0 - CUT_LEAD;

var isLimbo = false;

function zyra() {
	return strumLines.members[1].characters[0];
}

function postCreate() {
	FlxG.save.data.echoesZyraSet = 0;
	var name = PlayState.SONG.meta.name;
	isLimbo = (name != null && name.toLowerCase() == "limbo");
	if (!isLimbo) return;
	var z = zyra();
	// the sprite is the whole render frame and grows around its centre, so its corner is moved back so that the visible frame starts at the stage's corner
	z.x = STAGE_LEFT - z.frameWidth * (1 - z.scale.x) / 2;
	z.y = STAGE_TOP - z.frameHeight * (1 - z.scale.y) / 2;
}

function update(elapsed) {
	if (!isLimbo) return;
	var t = Conductor.songPosition;
	var set = 0;
	if (t >= CUT_POSE_CHANGE) set = 3;
	else if (t >= CUT_C) set = 2;
	else if (t >= CUT_B) set = 1;
	if (FlxG.save.data.echoesZyraSet != set) FlxG.save.data.echoesZyraSet = set;
}

function onPlayerHit(event) {
	// Marks the hit that is about to ask for the pose: true only for the pieces of a long note (they must not restart it), false for the first hit of any note.
	FlxG.save.data.echoesZyraPiece = (event.note != null && event.note.isSustainNote);
	if (event.note != null && event.note.isSustainNote) {
		FlxG.save.data.echoesZyraHoldAt = Lib.getTimer();
		FlxG.save.data.echoesZyraHoldDir = event.note.strumID;
	}
}

// A miss is not a piece of a long note: its pose must start from the first frame.
function onPlayerMiss(event) {
	FlxG.save.data.echoesZyraPiece = false;
}
