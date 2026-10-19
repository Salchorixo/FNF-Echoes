import funkin.backend.scripting.Script;

// Zyra's alternative eyes in the song (DS-2): the layer itself is scripts/effects/zyraEyes.hx. A note is "alt" when its note type is "Alt Eyes" (chart editor:
// Note > note type > "Alt Eyes", data/notes/Alt Eyes.hx) or when the strum line has the chart's "Alt Animation Toggle" on (the engine then asks for the "-alt" suffix).
// The pieces of a long note keep what its first hit decided, a miss clears it, and the next note decides again. Only Limbo. The song script runs BEFORE the
// characters sing, so the flag is ready when the pose starts.
var ALT_NOTE_TYPE = "Alt Eyes";
var isLimbo = false;
var eyes = null;

function postCreate() {
	var name = PlayState.SONG.meta.name;
	isLimbo = (name != null && name.toLowerCase() == "limbo");
	if (!isLimbo) return;
	eyes = Script.create(Paths.script('scripts/effects/zyraEyes'));
	eyes.load();
	eyes.call("attach", [strumLines.members[1].characters[0]]);
}

function onPlayerHit(event) {
	if (!isLimbo) return;
	if (event.note != null && event.note.isSustainNote) return;
	eyes.call("setAlt", [event.noteType == ALT_NOTE_TYPE || event.animSuffix == "-alt"]);
}

function onPlayerMiss(event) {
	if (!isLimbo) return;
	eyes.call("setAlt", [false]);
}

function postUpdate(elapsed) {
	if (!isLimbo) return;
	eyes.call("update");
}
