import flixel.FlxCamera;

// Event "Character Front" (BE-46): draws the characters of ONE strumline (0 = Soul, 1 = Zyra, any other line of the chart) ABOVE the
// arrows, so the rows look like they go behind them. Every row is independent: Zyra in front, then Soul, then both, then none...
// The arrows live on the HUD camera, which is drawn over the game camera, so a character cannot be put "between". Instead there is an
// extra transparent camera ABOVE the HUD one that copies the game camera's scroll and zoom every frame, and the characters are moved
// to it (on = extra camera, off = back on the game camera). The camera is removed when the song ends.

var front = null;

function postCreate() {
	front = new FlxCamera();
	front.bgColor = 0x00000000;
	FlxG.cameras.add(front, false);
}

function onEvent(e) {
	if (e.event.name != "Character Front") return;
	var id = Std.int(e.event.params[0]);
	if (id < 0 || id >= strumLines.members.length) return;
	var on = e.event.params[1] == true;
	for (char in strumLines.members[id].characters)
		if (char != null)
			char.cameras = on ? [front] : [camGame];
}

function postUpdate(elapsed) {
	if (front == null) return;
	front.scroll.copyFrom(camGame.scroll);
	front.zoom = camGame.zoom;
}

function destroy() {
	if (front != null && FlxG.cameras.list.contains(front))
		FlxG.cameras.remove(front);
}
