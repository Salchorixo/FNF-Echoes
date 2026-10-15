// "Hurt Note" (BE-45): the gentler sibling of "Deadly Note". A note of Soul's that escapes into Zyra's row while Soul HAS his own row
// again: touching it does not kill, it takes half of the health bar. Letting it pass costs nothing and Botplay never touches it.
// Soul sings when it reaches the strums, like with the deadly note (same code, copied because mod scripts cannot import each other).
// Put it in the chart from the editor: Note > Edit Note Types List > add "Hurt Note", then pick it in Note > Note Types List.

function postCreate() {
	for (line in strumLines.members)
		line.onNoteUpdate.add(hurtNoteUpdate);
}

function hurtNoteUpdate(e) {
	var note = e.note;
	if (note.noteType != "Hurt Note" || note.extra.exists("sung")) return;
	if (note.strumTime > Conductor.songPosition) return;
	note.extra.set("sung", true);
	var soulRow = strumLines.members[0];
	if (note.strumLine == soulRow) return;
	for (char in soulRow.characters)
		if (char != null)
			char.playSingAnim(note.strumID);
}

function onNoteCreation(event) {
	if (event.noteType != "Hurt Note") return;
	event.note.avoid = true;
	event.note.color = 0xFFFF9A1F; // naranja: not as deadly as the red one
	event.note.extra.set("hurt", true);
}

// You pressed it: half of the health bar goes away (if you had less than that, you die, as the engine does at 0).
function onPlayerHit(event) {
	if (event.noteType != "Hurt Note") return;
	PlayState.instance.health -= PlayState.instance.maxHealth / 2;
}

// It went past you: nothing happens (same as the deadly note: cancel the miss and remove the note by hand).
function onPlayerMiss(event) {
	if (event.noteType != "Hurt Note") return;
	event.cancel();
	if (event.note != null)
		event.note.strumLine.deleteNote(event.note);
}
