import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import funkin.backend.utils.CoolUtil;

// Event "Strum Move" (BE-44): slides a row of arrows to the left / centre / right of the screen and fades it in or out. It is put in
// the chart from the chart editor (events lane). Params (see Strum Move.json): Strumline (0 = Soul / the opponent row, 1 = Zyra /
// the player row), Position (Default = the row's own place, Left = where the opponent row normally is, Right = where the player row
// normally is, Center = centred on the screen), Opacity (0 hides the row, 1 shows it), Duration (steps) and the easing.
// The notes follow their strums (the engine copies the strum position to each note), so they slide with the arrows.
// Limbo uses it so that Zyra plays in the middle while Soul slips into her row with deadly notes (BE-42), then to slide left and right.

var defaults = []; // per strumline: x of every strum when the song starts

function postCreate() {
	for (line in strumLines.members) {
		var xs = [];
		for (strum in line.members)
			xs.push(strum.x);
		defaults.push(xs);
	}
}

function onEvent(e) {
	if (e.event.name != "Strum Move") return;
	var p = e.event.params;
	var id = Std.int(p[0]);
	if (id < 0 || id >= strumLines.members.length) return;
	var line = strumLines.members[id];
	var own = defaults[id];
	var count = own.length;
	var width = own[count - 1] - own[0] + line.members[count - 1].width; // width of the row as it starts

	var left = defaults[0][0];
	var right = defaults[strumLines.members.length > 1 ? 1 : 0][0];
	var first = own[0];
	if (p[1] == "Left") first = left;
	else if (p[1] == "Right") first = right;
	else if (p[1] == "Center") first = (FlxG.width - width) / 2;

	var seconds = (Conductor.stepCrochet / 1000) * p[3];
	var ease = CoolUtil.flxeaseFromString(p[4], p[5]);
	for (i in 0...count) {
		var strum = line.members[i];
		var target = first + (own[i] - own[0]);
		FlxTween.cancelTweensOf(strum, ["x", "alpha"]);
		if (seconds <= 0) {
			strum.x = target;
			strum.alpha = p[2];
		} else {
			FlxTween.tween(strum, {x: target, alpha: p[2]}, seconds, {ease: ease});
		}
	}
}
