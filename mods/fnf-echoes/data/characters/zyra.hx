import openfl.Lib;

// Zyra's poses (BE-53, DS-2). Each pose is one animation with a KEY FRAME (the peak of the note, PEAK below: the 4th frame, counting from 0) before
// which she attacks and after which she comes back:
//   - a short note plays the whole pose (peak and return), never cut;
//   - a long note plays up to the peak, then stays exactly on that frame for as long as the note is held (with a tiny breathing, below), and when it
//     ends she plays the second half and returns.
// The engine alone would cut the pose after `holdTime` steps (tryDance), so the xml sets holdTime to a huge value and this script sends her back
// to the idle itself once the pose has finished. "Held" comes from the song script (songs/zyraPoses.hx) or the playground (AnimTestState.hx):
//   FlxG.save.data.echoesZyraHoldAt  = Lib.getTimer() of the last long-note piece / key-down frame, FlxG.save.data.echoesZyraHoldDir = direction (0..3).
//
// CAMERA SETS (DS-2). The first song cuts between Blender cameras, and every cut has its own frames of the same animations. They all live in this one
// character: set 0 (Camera) uses the plain names (idle, singUP...), set 1 (Camera.001) adds _b, set 2 (Camera.002) _c and set 3 (the pose change and pose 3)
// _d. The song script (or the playground) only writes FlxG.save.data.echoesZyraSet; every animation asked for is redirected to the current set, and when the
// set changes the animation that is playing continues, on the same frame, in the new set. Entering set 3 from set 2 plays the pose change first
// ("poseChange"); while it plays the notes still count but do not cut it (Zyra's pose change must finish).
var self = this;
var PEAK = 3;                    // key frame of every pose, counting from 0 (Zyra's Blender frames 105, 120, 135 and 150 of poses that start at 102, 117, 132, 147)
var BREATH_X = 0.8;              // while a long note is held she stays on the key frame and only breathes: a sub-pixel movement of the sprite (pixels)
var BREATH_Y = 1.6;              // (cycling through the frames next to the peak looked like a slow return)
var LEAD_FRAMES = 2;             // a note's pose starts this many frames in, so its key frame lands sooner (24 fps: 2 frames = 83 ms; 3 = on the beat); not for the last set (pose 3)
var HOLD_GRACE = 130.0;          // ms without a piece before the note counts as released
var SUFFIX = ["", "_b", "_c", "_d"];
var shakeClock = 0.0;
var inHold = false;
var lastSet = -1;

function currentSet() {
	var s = FlxG.save.data.echoesZyraSet;
	if (s == null) return 0;
	return Std.int(Math.max(0, Math.min(3, s)));
}

// "singUP_c" -> "singUP"
function baseName(name) {
	if (name == null) return "";
	var n = name.length;
	if (n > 2 && name.charAt(n - 2) == "_" && (name.charAt(n - 1) == "b" || name.charAt(n - 1) == "c" || name.charAt(n - 1) == "d"))
		return name.substr(0, n - 2);
	return name;
}

function isPlainPose(base) {
	return base == "idle" || base == "singUP" || base == "singDOWN" || base == "singLEFT" || base == "singRIGHT";
}

function poseDir(name) {
	var b = baseName(name);
	if (b == "singLEFT") return 0;
	if (b == "singDOWN") return 1;
	if (b == "singUP") return 2;
	if (b == "singRIGHT") return 3;
	return -1;
}

function holdingDir() {
	var at = FlxG.save.data.echoesZyraHoldAt;
	if (at == null) return -1;
	if (Lib.getTimer() - at > HOLD_GRACE) return -1;
	return FlxG.save.data.echoesZyraHoldDir;
}

// How a long note looks while it is held (Zyra is choosing, FlxG.save.data.echoesZyraHoldStyle, 0 to 3):
//   0  still on the key frame, only breathing (a sub-pixel movement)
//   1  the pose creeps forward very slowly (3 frames per second, up to 4 frames past the key frame) and then stays
//   2  a slow loop of her own frames around the key frame (key, +1, +2, +1 at 8 fps)
//   3  still on the key frame, with a stronger pulse (a push of about 3 pixels, twice a second)
function holdStyle() {
	var h = FlxG.save.data.echoesZyraHoldStyle;
	if (h == null) return 0;
	return h;
}

function poseChangePlaying() {
	var cur = self.animation.curAnim;
	return cur != null && cur.name == "poseChange" && !cur.finished;
}

// Rules (Zyra):
//  1. any note starts its pose from the pose's first frame and the pose is never cut, except by another note, whose pose also starts from its first frame;
//  2. a short note plays its pose from start to end;
//  3. a long note plays up to the key frame, stays there while it is held, and when it ends the pose goes on until it finishes.
// The engine does not restart a pose that is already playing (Force is off by default) and asks for the pose again on every piece of a long note, so:
//  - a request that comes from a PIECE of a long note while that same pose is playing is cancelled (the song script flags it: echoesZyraPiece);
//  - any other request (a note's first hit) is forced, so it always starts from frame 0, even if the same pose was still playing.
function onPlayAnim(event) {
	var base = baseName(event.animName);
	if (isPlainPose(base)) {
		if (poseChangePlaying()) { event.cancel(); return; }       // the pose change finishes first
		event.animName = base + SUFFIX[currentSet()];
	}
	var d = poseDir(event.animName);
	if (d < 0) return;
	var cur = self.animation.curAnim;
	if (FlxG.save.data.echoesZyraPiece == true && cur != null && cur.name == event.animName) {
		event.cancel();
		return;
	}
	event.force = true;
	event.startingFrame = (currentSet() == 3) ? 0 : LEAD_FRAMES;
	inHold = false;
	shakeClock = 0.0;
}

// The idle loops by itself: the beat would restart it every few beats and cut it, and the songs change tempo.
function postCreate() {
	self.danceOnBeat = false;
}

// The set changes are played straight on the animation controller (not through playAnim): they must keep the frame, and they are not a note.
function changeSet(set) {
	var cur = self.animation.curAnim;
	if (lastSet == 2 && set == 3) {
		// entering the last set from the middle one: the pose change, from its first frame
		self.animation.play("poseChange", true);
		inHold = false;
	} else if (cur != null && cur.name != "poseChange") {
		var base = baseName(cur.name);
		if (isPlainPose(base)) {
			// the same animation, on the same frame, seen from the new camera
			self.animation.play(base + SUFFIX[set], true, false, cur.curFrame);
		}
	}
	lastSet = set;
}

function postUpdate(elapsed) {
	var set = currentSet();
	if (set != lastSet) changeSet(set);

	var cur = self.animation.curAnim;
	if (cur == null) { inHold = false; return; }
	if (cur.name == "poseChange") {
		inHold = false;
		if (cur.finished) self.dance();
		return;
	}
	var d = poseDir(cur.name);
	if (d < 0) {
		inHold = false;
		if (baseName(cur.name) == "idle" && cur.finished) self.dance();
		return;
	}

	var n = cur.numFrames;
	var peak = Std.int(Math.min(PEAK, n - 1));
	var held = (holdingDir() == d);

	if (held && (inHold || cur.curFrame >= peak)) {
		// at the peak of a long note: stop the animation and show the hold style Zyra chose
		inHold = true;
		cur.paused = true;
		shakeClock += elapsed;
		var style = holdStyle();
		var f = peak;
		var oy = Math.sin(shakeClock * 8.2 + 1.0) * BREATH_Y;
		if (style == 1) {
			f = peak + Std.int(Math.min(4.0, shakeClock * 3.0));
		} else if (style == 2) {
			var seq = [0, 1, 2, 1];
			f = peak + seq[Std.int(shakeClock * 8.0) % 4];
		} else if (style == 3) {
			oy = 0.0 - Math.pow(Math.abs(Math.sin(shakeClock * 6.2832)), 3.0) * 3.0;
		}
		cur.curFrame = Std.int(Math.max(0, Math.min(n - 1, f)));
		self.offset.set(Math.sin(shakeClock * 4.4) * BREATH_X, oy);
		return;
	}
	if (inHold) {                     // the note ended: continue from where it is, into the second half
		inHold = false;
		shakeClock = 0.0;
		self.offset.set(0, 0);
		cur.paused = false;
		if (cur.curFrame < peak) cur.curFrame = peak;
	}
	if (cur.finished)                 // the pose is over (short note, or the return of a long one): back to the idle
		self.dance();
}
