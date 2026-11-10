// Stage "black" (DS-1): hides Soul's characters (strum line 0). Zyra (strum line 1) stays visible; her placement comes from her own frames: the Blender render
// frame is what this stage's camera shows (see songs/zyraPoses.hx, DS-2).
// The engine puts the characters of the chart in the stage even if the stage does not list them. Their strumlines still work.
function postCreate() {
	for (char in PlayState.instance.strumLines.members[0].characters)
		if (char != null)
			char.visible = false;
}

// The camera never moves: the frame of Zyra's Blender renders is what it shows (centre 1000,600, zoom 0.9 from black.xml), so the sprites stay where she drew them.
function onCameraMove(event) {
	event.position.set(1000.0, 600.0);
}
