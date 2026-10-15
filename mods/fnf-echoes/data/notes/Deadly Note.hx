// "Deadly Note" (BE-42, sketch): a note you must NOT press. If you hit it you die at once; if you let it pass it costs nothing
// (no miss, no health loss, the combo is not broken). Botplay never touches it (note.avoid). It is put in the chart from the chart
// editor: Note > note type > "Deadly Note"; the chart then lists it in its noteTypes and the engine loads this script by the name.
// Hooks (engine scripts, see engine/assets/data/notes/ for more examples): onNoteCreation / onPlayerHit / onPlayerMiss.
// Placeholder look: a dark red tint. The final art (skull), sound and death animation are a later job.

// Soul sings when a deadly note reaches the strums (BE-45). The deadly notes are Soul's, but they travel in Zyra's row, so the engine
// would never animate Soul for them. Every strumline reports each of its notes on every frame (onNoteUpdate signal); the first frame
// a deadly note is at/after its time, the characters of the OTHER row (Soul's: the first strumline of the chart) sing that direction.
// It happens once per note, hit or not, and Botplay or not.
function postCreate() {
	for (line in strumLines.members)
		line.onNoteUpdate.add(deadlyNoteUpdate);
}

function deadlyNoteUpdate(e) {
	var note = e.note;
	if (note.noteType != "Deadly Note" || note.extra.exists("sung")) return;
	if (note.strumTime > Conductor.songPosition) return;
	note.extra.set("sung", true);
	var soulRow = strumLines.members[0];
	if (note.strumLine == soulRow) return; // a deadly note in Soul's own row is animated by the engine as usual
	for (char in soulRow.characters)
		if (char != null)
			char.playSingAnim(note.strumID);
}

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
