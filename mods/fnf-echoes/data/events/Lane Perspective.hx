import flixel.tweens.FlxTween;
import funkin.backend.utils.CoolUtil;

// Event "Lane Perspective" (BE-46): a fake perspective for the NOTES of a row. The further a note is from its arrow, the smaller it is
// and the closer to the row's vanishing point (the middle of the row), like a road that goes away. Strength 0 = flat, 1 = strong.
// The arrows (strums) are not changed. It is done after the engine has placed every note each frame (postUpdate), by scaling the note
// around its centre and moving that centre towards the vanishing point. Sustains only get thinner (their length comes from the engine).

var strength = []; // per strumline: {v: current strength}

function postCreate() {
	for (i in 0...strumLines.members.length)
		strength.push({v: 0.0});
}

function onEvent(e) {
	if (e.event.name != "Lane Perspective") return;
	var p = e.event.params;
	var id = Std.int(p[0]);
	if (id < 0 || id >= strength.length) return;
	FlxTween.cancelTweensOf(strength[id]);
	var seconds = (Conductor.stepCrochet / 1000) * p[2];
	if (seconds <= 0) strength[id].v = p[1];
	else FlxTween.tween(strength[id], {v: p[1]}, seconds, {ease: CoolUtil.flxeaseFromString(p[3], p[4])});
}

function postUpdate(elapsed) {
	for (id in 0...strumLines.members.length) {
		var line = strumLines.members[id];
		var k = strength[id].v;
		if (k <= 0.001 && !line.extra.exists("perspective")) continue; // nothing to undo either
		line.extra.set("perspective", k > 0.001);
		var vx = 0.0;
		for (strum in line.members)
			vx += strum.x + strum.width / 2;
		vx /= line.members.length;
		for (note in line.notes.members) {
			if (note == null || !note.exists || !note.alive) continue;
			var strum = line.members[note.noteData];
			if (strum == null) continue;
			if (!note.extra.exists("bsx")) {
				note.extra.set("bsx", note.scale.x);
				note.extra.set("bsy", note.scale.y);
			}
			var depth = Math.min(1, Math.abs(note.y - strum.y) / (FlxG.height * 0.75));
			var s = 1 - 0.65 * k * depth;
			var cx = note.x + note.origin.x;
			note.scale.x = note.extra.get("bsx") * s;
			if (!note.isSustainNote)
				note.scale.y = note.extra.get("bsy") * s;
			note.x += (vx + (cx - vx) * s) - cx;
		}
	}
}
