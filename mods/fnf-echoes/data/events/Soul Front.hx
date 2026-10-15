import flixel.FlxCamera;

// Event "Soul Front" (BE-46): draws Soul (the characters of the chart's first strumline) ABOVE the arrows, so the rows look like they
// go behind him. The arrows live on the HUD camera, which is drawn over the game camera, so a character cannot be put "between".
// Instead there is an extra transparent camera ABOVE the HUD one that copies the game camera's scroll and zoom every frame, and Soul
// is moved to it (on = Soul on the extra camera, off = back on the game camera). The camera is removed when the song ends.

var front = null;
var on = false;

function postCreate() {
	front = new FlxCamera();
	front.bgColor = 0x00000000;
	FlxG.cameras.add(front, false);
}

function onEvent(e) {
	if (e.event.name != "Soul Front") return;
	on = e.event.params[0] == true;
	for (char in strumLines.members[0].characters)
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
