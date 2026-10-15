// "Deadly Note" (BE-42, sketch): a note you must NOT press. If you hit it you die at once; if you let it pass it costs nothing
// (no miss, no health loss, the combo is not broken). Botplay never touches it (note.avoid). It is put in the chart from the chart
// editor: Note > note type > "Deadly Note"; the chart then lists it in its noteTypes and the engine loads this script by the name.
// Hooks (engine scripts, see engine/assets/data/notes/ for more examples): onNoteCreation / onPlayerHit / onPlayerMiss.
// Placeholder look: a dark red tint. The final art (skull), sound and death animation are a later job.

function onNoteCreation(event) {
	if (event.noteType != "Deadly Note") return;
	event.note.avoid = true;
	event.note.color = 0xFFFF1F3D;
	event.note.extra.set("deadly", true);
}

// You pressed it: instant death (the engine's game over runs when the health reaches 0).
function onPlayerHit(event) {
	if (event.noteType != "Deadly Note") return;
	PlayState.instance.health = 0;
}

// It went past you: nothing happens. The miss is cancelled (so no health loss, no combo break, no miss sound) and the note is removed
// by hand, because a cancelled miss leaves it in the strumline.
function onPlayerMiss(event) {
	if (event.noteType != "Deadly Note") return;
	event.cancel();
	if (event.note != null)
		event.note.strumLine.deleteNote(event.note);
}
