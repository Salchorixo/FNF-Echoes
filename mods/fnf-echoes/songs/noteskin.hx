import flixel.FlxSprite;
import flixel.math.FlxRect;

// Zyra's noteskin (BE-52), for every song. Strum line 1 is Zyra's (the player); strum line 0 keeps the engine's own look until Soul gets his.
//   images/game/notes/zyra.png/.xml        her four arrows, the dark grey receptors (idle, pressed, confirm) and the hold pieces
//   the hit is a tape skip: the receptor breaks into bands that jump sideways for three frames and a white line crosses the row
//   while a long note is held the tracking trembles: a couple of bands slip a few pixels, in steps; on release, a short skip (BE-69)
// Everything is drawn here with the receptor's own "confirm" frame cut into bands; nothing in the engine is touched.

var ZYRA_LINE = 1;
var KEEP_ENGINE_SKIN = [];    // note types that keep the engine's look even in Zyra's row (e.g. Soul's notes that glitch into her row); empty until Zyra decides
var HOLD_GRACE = 130.0;       // ms without a hold piece being hit before the hold effect stops

var SKIP_FPS = 24.0;          // the skips are counted in frames at this rate
var SKIP_BANDS = 6;           // 156 px frame / 6 = bands of 26 px, no seams
var SKIP_JUMP = [0.23, 0.13, 0.06];   // the hit: how far the bands jump on each frame, as a fraction of the receptor's width
var SKIP_LINE = [0.75, 0.3];  // opacity of the line across the row on the first two frames of the hit
var SKIP_GROW = 1.06;         // the white first frame of the hit is slightly bigger
var RELEASE_JUMP = [0.1, 0.04];       // letting go of a long note (or its end): a shorter, smaller skip, no white and no line
var HOLD_FPS = 12.0;          // while a long note is held the bands change this many times a second
var HOLD_JUMP = 0.06;         // ... and slip at most this far (fraction of the receptor's width)
var HOLD_SLIPS = 2;           // ... at most this many of them at once; the rest stay in place
var CONFIRM_FRAME = ["left confirm0000", "down confirm0000", "up confirm0000", "right confirm0000"];

var lastHold = [-99999.0, -99999.0, -99999.0, -99999.0];
var wasActive = [false, false, false, false];
var skip = [null, null, null, null];   // per direction: {bands, line, off, age, frame, on, hid, lineOff, jumps, white, lined, holdAge}

function onStrumCreation(event) {
	if (event.player == ZYRA_LINE)
		event.sprite = "game/notes/zyra";
}

function onNoteCreation(event) {
	if (event.strumLineID != ZYRA_LINE) return;
	if (KEEP_ENGINE_SKIN.contains(event.noteType)) return;
	if (event.noteSprite == "game/notes/default")
		event.noteSprite = "game/notes/zyra";
}

function onPlayerHit(event) {
	if (event.note == null) return;
	if (event.note.isSustainNote) {
		lastHold[event.note.strumID] = Conductor.songPosition;
		return;
	}
	// the engine decides when a hit deserves a splash (rating and the player's option); Zyra's notes get the tape skip instead of an atlas splash
	if (!event.showSplash || event.note.strumLine != strumLines.members[ZYRA_LINE]) return;
	if (KEEP_ENGINE_SKIN.contains(event.noteType)) return;
	event.showSplash = false;
	startSkip(event.note.strumID, SKIP_JUMP, true, true);
}

// the bands and the line of one direction, made the first time they are needed and reused
function skipOf(i) {
	var s = skip[i];
	if (s != null) return s;
	var strum = strumLines.members[ZYRA_LINE].members[i];
	s = {bands: [], line: new FlxSprite(), off: [], age: 0.0, frame: -1, on: false, hid: false, lineOff: 0.0, jumps: SKIP_JUMP, white: false, lined: false, holdAge: 0.0};
	for (k in 0...SKIP_BANDS) {
		var b = new FlxSprite();
		b.frames = strum.frames;
		b.animation.frameName = CONFIRM_FRAME[i];
		var bh = b.frameHeight / SKIP_BANDS;
		b.clipRect = new FlxRect(0, k * bh, b.frameWidth, bh);
		b.antialiasing = true;
		b.scrollFactor.set();
		b.visible = false;
		add(b);
		s.bands.push(b);
		s.off.push(0.0);
	}
	s.line.makeGraphic(1, 1, 0xFFFFFFFF);
	s.line.scrollFactor.set();
	s.line.visible = false;
	add(s.line);
	skip[i] = s;
	return s;
}

// a skip: the bands jump jumps[frame] for as many frames as the list has; white = the first frame is white and bigger; lined = with the line across the row
function startSkip(i, jumps, white, lined) {
	if (strumLines.members[ZYRA_LINE].members[i] == null) return;
	var s = skipOf(i);
	s.age = 0.0;
	s.frame = -1;
	s.on = true;
	s.jumps = jumps;
	s.white = white;
	s.lined = lined;
	s.lineOff = FlxG.random.float(-0.3, 0.3);
}

// the bands replace the receptor while they are drawn; only hide it if it was showing, so a receptor hidden by a scene stays hidden (and gets no bands)
function drawBands(s, strum, cam, grow, white) {
	if (!s.hid) {
		if (!strum.visible) return;
		strum.visible = false;
		s.hid = true;
	}
	var w = white ? 255 : 0;
	for (k in 0...SKIP_BANDS) {
		var b = s.bands[k];
		b.cameras = [cam];
		b.scale.set(strum.scale.x * grow, strum.scale.y * grow);
		b.updateHitbox();
		b.x = strum.x + (strum.width - b.width) / 2 + s.off[k];
		b.y = strum.y + (strum.height - b.height) / 2;
		b.setColorTransform(1, 1, 1, strum.alpha, w, w, w, 0);    // last: setting alpha or color afterwards drops the white offsets
		b.visible = true;
	}
}

function rest(s, strum) {
	for (b in s.bands) b.visible = false;
	s.line.visible = false;
	if (s.hid) {
		strum.visible = true;
		s.hid = false;
	}
	s.frame = -1;
}

function postUpdate(elapsed) {
	var row = strumLines.members[ZYRA_LINE];
	var cam = row.cameras[0];     // the camera of the ROW (the group's, not a strum's own: a strum without its own camera reports the default one). A scene script may move the row to another camera and the effect must follow it
	var songPos = Conductor.songPosition;
	for (i in 0...4) {
		var active = (songPos - lastHold[i]) < HOLD_GRACE;
		if (wasActive[i] && !active) startSkip(i, RELEASE_JUMP, false, false);     // released or finished
		wasActive[i] = active;

		var s = skip[i];
		if (s == null) {
			if (!active) continue;
			s = skipOf(i);
		}
		var strum = row.members[i];
		if (!row.visible) {
			s.on = false;
			rest(s, strum);
			continue;
		}

		if (s.on) {
			var f = Std.int(s.age * SKIP_FPS);
			s.age += elapsed;
			if (f < s.jumps.length) {
				if (f != s.frame) {
					s.frame = f;
					for (k in 0...SKIP_BANDS)
						s.off[k] = FlxG.random.float(-1, 1) * s.jumps[f] * strum.width;
				}
				var first = s.white && f == 0;
				drawBands(s, strum, cam, first ? SKIP_GROW : 1.0, first);
				if (s.lined && f < SKIP_LINE.length) {
					var a = row.members[0];
					var z = row.members[row.members.length - 1];
					var margin = strum.width;
					s.line.cameras = [cam];
					s.line.scale.set(z.x + z.width - a.x + margin * 2, 3);
					s.line.updateHitbox();
					s.line.x = a.x - margin;
					s.line.y = strum.y + strum.height * (0.5 + s.lineOff);
					s.line.alpha = SKIP_LINE[f] * strum.alpha;
					s.line.visible = true;
				} else
					s.line.visible = false;
				continue;
			}
			s.on = false;
			s.frame = -1;
		}

		if (active) {
			// held: most bands sit still and one or two slip a little, re-rolled in steps
			var h = Std.int(s.holdAge * HOLD_FPS);
			s.holdAge += elapsed;
			if (h != s.frame) {
				s.frame = h;
				for (k in 0...SKIP_BANDS) s.off[k] = 0.0;
				for (n in 0...FlxG.random.int(1, HOLD_SLIPS))
					s.off[FlxG.random.int(0, SKIP_BANDS - 1)] = FlxG.random.float(-1, 1) * HOLD_JUMP * strum.width;
			}
			drawBands(s, strum, cam, 1.0, false);
			s.line.visible = false;
		} else {
			s.holdAge = 0.0;
			rest(s, strum);
		}
	}
}
