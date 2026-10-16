import flixel.FlxSprite;

// Zyra's noteskin (BE-52), for every song. Strum line 1 is Zyra's (the player); strum line 0 keeps the engine's own look until Soul gets his.
//   images/game/notes/zyra.png/.xml        her four arrows, the dark grey receptors (idle, pressed, confirm) and the hold pieces
//   images/game/splashes/zyra.png + data/splashes/zyra.xml   the hit burst (flash, thin rings, straight cracks, slivers)
//   images/game/holdfx/ring.png, sliver.png   the effect while a long note is held: a slow heartbeat ring and slivers running into the receptor
// The hold effect is drawn here, with the two white images tinted per direction; nothing else in the engine is touched.

var ZYRA_LINE = 1;
var KEEP_ENGINE_SKIN = [];    // note types that keep the engine's look even in Zyra's row (e.g. Soul's notes that glitch into her row); empty until Zyra decides
var TINTS = [0xFF9682EB, 0xFF6EA0FF, 0xFF78E6C8, 0xFFF08CBE];   // left, down, up, right (the same hues as her arrows, lighter)
var HOLD_GRACE = 130.0;       // ms without a hold piece being hit before the effect stops
var RING_EVERY = 0.25;        // seconds between heartbeat rings
var RING_LIFE = 0.5;
var SLIVER_EVERY = 0.09;
var SLIVER_LIFE = 0.42;

var lastHold = [-99999.0, -99999.0, -99999.0, -99999.0];
var wasActive = [false, false, false, false];
var ringTimer = [0.0, 0.0, 0.0, 0.0];
var sliverTimer = [0.0, 0.0, 0.0, 0.0];
var fx = [];                  // live effects: {spr, age, life, kind, ...}

function onStrumCreation(event) {
	if (event.player == ZYRA_LINE)
		event.sprite = "game/notes/zyra";
}

function onNoteCreation(event) {
	if (event.strumLineID != ZYRA_LINE) return;
	if (KEEP_ENGINE_SKIN.contains(event.noteType)) return;
	if (event.noteSprite == "game/notes/default")
		event.noteSprite = "game/notes/zyra";
	event.note.splash = "zyra";
}

function onPlayerHit(event) {
	if (event.note != null && event.note.isSustainNote)
		lastHold[event.note.strumID] = Conductor.songPosition;
}

function strumCenter(i) {
	var strum = strumLines.members[ZYRA_LINE].members[i];
	return {x: strum.x + strum.width / 2, y: strum.y + strum.height / 2};
}

function spawn(kind, i, angle) {
	var c = strumCenter(i);
	var spr = new FlxSprite();
	spr.loadGraphic(Paths.image(kind == "ring" ? "game/holdfx/ring" : "game/holdfx/sliver"));
	spr.antialiasing = true;
	spr.scrollFactor.set();
	spr.cameras = [camHUD];
	spr.color = TINTS[i];
	spr.alpha = 0;
	add(spr);
	fx.push({spr: spr, age: 0.0, life: kind == "ring" ? RING_LIFE : SLIVER_LIFE, kind: kind, i: i, cx: c.x, cy: c.y, angle: angle, off: FlxG.random.float(-14, 14), big: false});
	return fx[fx.length - 1];
}

function postUpdate(elapsed) {
	var songPos = Conductor.songPosition;
	var down = PlayState.instance.downscroll;
	for (i in 0...4) {
		var active = (songPos - lastHold[i]) < HOLD_GRACE;
		if (active) {
			ringTimer[i] -= elapsed;
			sliverTimer[i] -= elapsed;
			if (ringTimer[i] <= 0) { spawn("ring", i, 0); ringTimer[i] = RING_EVERY; }
			if (sliverTimer[i] <= 0) { spawn("sliver", i, 1); sliverTimer[i] = SLIVER_EVERY; }
		} else if (wasActive[i]) {
			// released or finished: one clean ring and a few slivers leaving, smaller than the hit burst
			var r = spawn("ring", i, 0); r.big = true;
			for (k in 0...5) {
				var s = spawn("sliver", i, 0);
				s.angle = -Math.PI / 2 + FlxG.random.float(-1.2, 1.2);
				s.life = 0.35;
				s.kind = "burst";
			}
			ringTimer[i] = 0.0;
			sliverTimer[i] = 0.0;
		}
		wasActive[i] = active;
	}

	var j = fx.length - 1;
	while (j >= 0) {
		var e = fx[j];
		e.age += elapsed;
		var p = e.age / e.life;
		if (p >= 1) {
			remove(e.spr, true);
			e.spr.destroy();
			fx.splice(j, 1);
		} else if (e.kind == "ring") {
			var base = e.big ? 0.82 : 0.84;
			var grow = e.big ? 0.55 : 0.3;
			var s = base * (1 + grow * (1 - Math.pow(1 - p, 2)));
			e.spr.scale.set(s, s);
			e.spr.x = e.cx - e.spr.frameWidth / 2;
			e.spr.y = e.cy - e.spr.frameHeight / 2;
			e.spr.alpha = Math.pow(1 - p, 1.1);
		} else if (e.kind == "sliver") {
			// runs from the body towards the receptor and fades as it arrives. The HUD camera mirrors positions in downscroll (sprites stay
			// unflipped), so in positions the body is always at +y.
			var dist = 95 * (1 - p);
			e.spr.scale.set(0.8, 0.8);
			e.spr.x = e.cx + e.off * 0.7 - e.spr.frameWidth / 2;
			e.spr.y = e.cy + dist - e.spr.frameHeight / 2;
			e.spr.alpha = Math.sin(Math.PI * Math.min(1, p * 1.15)) * 0.95;
		} else {
			// release burst: slivers thrown outwards; e.angle is the angle on screen (up = -PI/2), positions are mirrored in downscroll
			var d = 18 + 70 * (1 - Math.pow(1 - p, 2));
			e.spr.scale.set(0.7, 0.7);
			e.spr.angle = (e.angle + Math.PI / 2) * 180 / Math.PI;
			e.spr.x = e.cx + Math.cos(e.angle) * d - e.spr.frameWidth / 2;
			e.spr.y = e.cy + (down ? -1 : 1) * Math.sin(e.angle) * d - e.spr.frameHeight / 2;
			e.spr.alpha = Math.pow(1 - p, 1.2);
		}
		j--;
	}
}
