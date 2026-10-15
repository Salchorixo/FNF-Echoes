import funkin.options.Options;

// "Replica Note" (BE-49): Zyra falls into a small trance and has to REPLICATE what Soul sang. The replica notes are normal notes of Zyra's
// row (she animates and hits them as always), tinted light blue. A REPLICA PART is a group of them separated from the next by less than
// GAP ms (automatic, nothing to mark in the chart). Failing = letting one pass/missing it, and ALSO pressing a key with no note during the
// part ("pressing too much"). When the part ends: percentage = fails / total of that part (max 100%). If it is more than 0 the POISON
// starts: POISON_TICKS hits, one every POISON_EVERY seconds (both fixed), each taking `percentage x the WHOLE health bar`.
// Example: a part of 10 notes with 2 fails -> 20% of the bar every 2 s for 10 s (5 hits). Poisons of different parts add up.
// At 0 health the engine's game over runs. Provisional look: each hit flashes the HUD green (not with "Reduce flashes").

var GAP = 3000;          // ms without replica notes that closes a part
var SETTLE_AFTER = 600;  // ms after the last note of a part before it is settled
var POISON_EVERY = 2;    // seconds between hits (fixed)
var POISON_TICKS = 5;    // hits of one poison (fixed): 5 x 2 s = 10 s

var sections = [];       // {start, end, total, fails, settled}
var poisons = [];        // {ratio, left, t}
var hitFrame = [-1, -1, -1, -1];
var frame = 0;

// The chart is read once, when the song starts: how many replica notes there are and where each part begins and ends.
function postCreate() {
	var times = [];
	for (line in strumLines.members) {
		if (line.cpu) continue;
		for (n in line.data.notes) {
			var t = n.type;
			if (t > 0 && PlayState.SONG.noteTypes[t - 1] == "Replica Note")
				times.push(n.time);
		}
	}
	times.sort(function(a, b) return a < b ? -1 : (a > b ? 1 : 0));
	var cur = null;
	for (t in times) {
		if (cur == null || t - cur.end > GAP) {
			cur = {start: t, end: t, total: 0, fails: 0, settled: false};
			sections.push(cur);
		}
		cur.end = t;
		cur.total++;
	}
	trace('[Replica] parts: ' + sections.length + ' (notes per part: ' + [for (s in sections) s.total].join(', ') + ')');
}

function sectionAt(time) {
	for (s in sections)
		if (time >= s.start - 50 && time <= s.end + 50)
			return s;
	return null;
}

function onNoteCreation(event) {
	if (event.noteType != "Replica Note") return;
	event.note.color = 0xFF8FE9FF;
}

// Every hit marks its key for this frame, so that the same press is not counted again as "pressing too much".
function onPlayerHit(event) {
	hitFrame[event.note.noteData % 4] = frame;
}

function onPlayerMiss(event) {
	if (event.noteType != "Replica Note" || event.note == null || event.note.isSustainNote) return;
	var s = sectionAt(event.note.strumTime);
	if (s != null) s.fails++;
}

function postUpdate(elapsed) {
	var pos = Conductor.songPosition;

	// pressing too much: a key pressed with no note hit during a part
	var pressed = [controls.NOTE_LEFT_P, controls.NOTE_DOWN_P, controls.NOTE_UP_P, controls.NOTE_RIGHT_P];
	for (s in sections)
		if (!s.settled && pos >= s.start - 100 && pos <= s.end + 200)
			for (d in 0...4)
				if (pressed[d] && hitFrame[d] != frame)
					s.fails++;

	// a part that has ended: the percentage turns into a poison
	for (s in sections) {
		if (s.settled || pos <= s.end + SETTLE_AFTER) continue;
		s.settled = true;
		var ratio = Math.min(1, s.fails / s.total);
		trace('[Replica] part settled: ' + s.fails + ' fails of ' + s.total + ' -> ' + Math.round(ratio * 100) + '% per hit');
		if (ratio > 0) poisons.push({ratio: ratio, left: POISON_TICKS, t: POISON_EVERY});
	}

	// the poison hits
	var alive = [];
	for (p in poisons) {
		p.t -= elapsed;
		if (p.t <= 0) {
			p.t += POISON_EVERY;
			p.left--;
			PlayState.instance.health -= p.ratio * PlayState.instance.maxHealth;
			if (Options.flashingMenu) camHUD.flash(0x5522FF66, 0.35);
		}
		if (p.left > 0) alive.push(p);
	}
	poisons = alive;

	frame++;
}
