// Stage "black" (DS-1): hides every character. The engine puts the characters of the chart in the stage even if the stage does not
// list them, so they are made invisible here. Their strumlines still work (arrows, notes, health bar icons).
function postCreate() {
	for (line in PlayState.instance.strumLines.members)
		for (char in line.characters)
			if (char != null)
				char.visible = false;
}
