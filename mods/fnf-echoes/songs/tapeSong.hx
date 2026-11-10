import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxTimer;
import funkin.backend.scripting.ModSubState;
import funkin.backend.scripting.Script;
import openfl.Lib;

// Every song is played back from the tape (BE-62; Zyra, 2026-11-08/09). Runs for every song (a script at the root of songs/).
//  - The tape (scripts/effects/vhsShader.hx) over all the cameras of the song, and the OSD: PLAY/PAUSE and SP on `deckCam`
//    (crisp, the deck's own text), the date and the time burned into the recording on `osdCam` (under the tape).
//  - At the start, ONCE per song, the track's card (design canvas, "1 v2"): TAPE 01 · SIDE A, TRACK nn, the title, the counter
//    and who recorded it. Then everything fades except one line, which walks to its place like a snake (square turns, one smooth
//    move, canvas "TransicionRec", approved by Zyra) and becomes the line of REC 01, at the bottom. The other parts of a song
//    (REC 02...) come without the snake: call showRec(n, note) from a song's own script.
//  - The pause is the tape's pause (canvas "Pausa · E"): transparent, the song frozen behind with the deck's two noise bars,
//    and the index of the pause (TapePauseSubState).
// Titles and credits per song are in TRACKS (Zyra: Limbo is his and Suno's). A song not in TRACKS shows no card.

var TRACKS = [
	{song: "limbo", title: "LIMBO", number: 1, recordedBy: "Salchorizo", musicWith: "Suno", recNote: ""}
];
var FONT = "IBMPlexMono-Regular.ttf";
var FONT_BOLD = "IBMPlexMono-SemiBold.ttf";
var WHITE = 0xFFF2F2EE;
var CLOCK_START = 23 * 3600 + 43 * 60 + 11;
// the snake's path (from the card's counter line to REC's line) and the length of its body at both ends
var PATH = [[530, 396], [770, 396], [770, 438], [510, 438], [510, 480], [770, 480], [770, 522], [510, 522], [510, 564], [770, 564]];
var BODY_START = 220;
var BODY_END = 260;
var CARD_HOLD = 1.8;
var CARD_FADE = 0.4;
var SNAKE_SECONDS = 1.2;
var REC_HOLD = 2.6;

var i18n;
var vhsFx;
var deckCam;
var osdCam;
var dateText;
var timeText;
var playGroup = [];
var pauseGroup = [];
var playArrow;
var card = [];
var rec = [];
var recDot;
var snake = [];
var snakeOn = false;
var snakeTime = 0.0;
var snakeThick = 3.0;
var track = null;

function postCreate() {
	i18n = Script.create(Paths.script('scripts/ui/translate'));
	i18n.load();
	for (t in TRACKS) if (t.song == PlayState.SONG.meta.name.toLowerCase()) track = t;

	osdCam = new FlxCamera();
	osdCam.bgColor = 0x00000000;
	FlxG.cameras.add(osdCam, false);
	deckCam = new FlxCamera();
	deckCam.bgColor = 0x00000000;
	FlxG.cameras.add(deckCam, false);

	dateText = osdText(64, FlxG.height - 118, 400, 32, "vcr.ttf", "left");
	timeText = osdText(64, FlxG.height - 84, 400, 32, "vcr.ttf", "left");
	buildDeck();
	if (track != null) buildCard();

	vhsFx = Script.create(Paths.script('scripts/effects/vhsShader'));
	vhsFx.load();
	vhsFx.call("exclude", [deckCam]);
	vhsFx.call("attach");
	updateClock(0);
}

function osdText(x, y, w, size, font, align) {
	var t = new FlxText(x, y, w, "");
	t.setFormat(Paths.font(font), size, WHITE, align);
	t.antialiasing = font != "vcr.ttf";
	t.cameras = [osdCam];
	add(t);
	return t;
}

function osdSprite(x, y, w, h, color) {
	var s = new FlxSprite(x, y).makeGraphic(w, h, color);
	s.cameras = [osdCam];
	add(s);
	return s;
}

// ---------------------------------------------------------------- the deck's text

function deckText(x, y, w, size, label, align, group) {
	for (k in 0...2) {
		var t = new FlxText(x + (k == 0 ? 2 : 0), y + (k == 0 ? 2 : 0), w, label);
		t.setFormat(Paths.font("vcr.ttf"), size, k == 0 ? 0xFF0A0A0A : WHITE, align);
		t.cameras = [deckCam];
		add(t);
		if (group != null) group.push(t);
	}
}

function buildDeck() {
	deckText(64, 40, 240, 40, "PLAY", "left", playGroup);
	playArrow = new FlxSprite(176, 46).makeGraphic(22, 28, 0x00000000, true);
	FlxSpriteUtil.drawPolygon(playArrow, [FlxPoint.get(0, 0), FlxPoint.get(22, 14), FlxPoint.get(0, 28)], WHITE);
	playArrow.cameras = [deckCam];
	add(playArrow);
	deckText(64, 40, 240, 40, "PAUSE", "left", pauseGroup);
	var bars = new FlxSprite(204, 46).makeGraphic(22, 28, 0x00000000, true);
	FlxSpriteUtil.drawRect(bars, 0, 0, 7, 28, WHITE);
	FlxSpriteUtil.drawRect(bars, 14, 0, 7, 28, WHITE);
	bars.cameras = [deckCam];
	add(bars);
	pauseGroup.push(bars);
	for (s in pauseGroup) s.visible = false;
	deckText(FlxG.width - 164, FlxG.height - 84, 100, 32, "SP", "right", null);
}

function setDeckPaused(on) {
	for (s in playGroup) s.visible = !on;
	playArrow.visible = !on;
	for (s in pauseGroup) s.visible = on;
}

// ---------------------------------------------------------------- the clock (shared with the menus)

function updateClock(elapsed) {
	var c = FlxG.save.data.echoesTapeClock;
	c = (c == null ? 0.0 : c) + elapsed;
	FlxG.save.data.echoesTapeClock = c;
	var sec = CLOCK_START + Std.int(c);
	var hours = Std.int(sec / 3600) % 24;
	var h = hours % 12 == 0 ? 12 : hours % 12;
	var m = Std.int(sec / 60) % 60;
	var s = sec % 60;
	dateText.text = "OCT. " + (27 + Std.int(sec / 86400)) + " 1997";
	timeText.text = h + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s + (hours >= 12 ? " PM" : " AM");
}

function timecode(seconds) {
	var s = Std.int(seconds);
	var h = Std.int(s / 3600);
	var m = Std.int(s / 60) % 60;
	var r = s % 60;
	return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m + ":" + (r < 10 ? "0" : "") + r;
}

// ---------------------------------------------------------------- the track's card and REC

function cardText(x, y, w, size, bold, align, value, alpha) {
	var t = osdText(x, y, w, size, bold ? FONT_BOLD : FONT, align);
	t.text = value;
	t.alpha = 0;
	card.push({obj: t, alpha: alpha});
	return t;
}

function cardSprite(x, y, w, h, color, alpha) {
	var s = osdSprite(x, y, w, h, color);
	s.alpha = 0;
	card.push({obj: s, alpha: alpha});
	return s;
}

function buildCard() {
	// a soft darkening behind the card so it reads on any picture
	var shade = cardSprite(290, 180, 700, 330, 0xFF000000, 0.35);
	cardText(0, 192, FlxG.width, 13, false, "center", i18n.call("get", ["TAPE SIDE"]), 0.8);
	var label = i18n.call("get", ["TRACK"]) + " " + (track.number < 10 ? "0" : "") + track.number;
	cardText(0, 226, FlxG.width, 15, true, "center", label, 1);
	cardSprite(430, 234, 1, 12, WHITE, 0.8);
	cardSprite(431, 239, 120, 1, WHITE, 0.6);
	cardSprite(729, 239, 120, 1, WHITE, 0.6);
	cardSprite(849, 234, 1, 12, WHITE, 0.8);
	cardText(0, 262, FlxG.width, 96, true, "center", track.title, 1);
	cardText(398, 383, 120, 24, false, "right", "00:00:00", 0.85);
	cardText(762, 383, 160, 24, false, "left", timecode(FlxG.sound.music.length / 1000), 0.85);
	cardSprite(530, 395, 220, 3, 0x40F2F2EE, 1);
	cardText(354, 440, 220, 11, false, "center", i18n.call("get", ["RECORDED BY"]), 0.75);
	cardText(354, 458, 220, 20, false, "center", track.recordedBy, 1);
	cardSprite(606, 440, 1, 44, WHITE, 0.45);
	cardText(638, 440, 220, 11, false, "center", i18n.call("get", ["MUSIC WITH"]), 0.75);
	cardText(638, 458, 220, 20, false, "center", track.musicWith, 1);
	for (i in 0...PATH.length - 1) {
		var s = osdSprite(0, 0, 1, 1, WHITE);
		s.visible = false;
		snake.push(s);
	}
	buildRec(1, track.recNote, 0.0);
}

// REC n: the index mark the deck writes at every new part of a recording (bottom centre). `at` is where it starts in the song.
function buildRec(n, note, at) {
	for (o in rec) remove(o.obj);
	rec = [];
	var marks = osdText(0, 466, FlxG.width, 26, "vcr.ttf", "center");
	marks.text = ">> INDEX " + n + " " + timecode(at);
	var label = osdText(0, 498, FlxG.width, 54, "vcr.ttf", "center");
	label.text = "  REC " + (n < 10 ? "0" : "") + n;
	recDot = osdSprite(FlxG.width / 2 - 112, 515, 22, 22, 0x00000000);
	recDot.makeGraphic(22, 22, 0x00000000, true);
	FlxSpriteUtil.drawCircle(recDot, 11, 11, 11, 0xFFE23A2E);
	var noteText = osdText(0, 576, FlxG.width, 16, FONT, "center");
	noteText.text = note;
	for (o in [marks, label, recDot, noteText]) {
		o.alpha = 0;
		rec.push({obj: o, alpha: o == marks ? 0.85 : 1});
	}
}

function fadeList(list, to, seconds) {
	for (o in list) FlxTween.tween(o.obj, {alpha: to == 0 ? 0 : o.alpha}, seconds);
}

// the walking line: the part of the path between (head - body) and head, drawn as one sprite per straight piece
function drawSnake(head, body, thick) {
	var start = 0.0;
	for (i in 0...snake.length) {
		var a = PATH[i];
		var b = PATH[i + 1];
		var len = Math.abs(b[0] - a[0]) + Math.abs(b[1] - a[1]);
		var from = Math.max(start, head - body);
		var to = Math.min(start + len, head);
		var s = snake[i];
		if (to <= from) s.visible = false;
		else {
			var dx = b[0] == a[0] ? 0 : (b[0] > a[0] ? 1 : -1);
			var dy = b[1] == a[1] ? 0 : (b[1] > a[1] ? 1 : -1);
			var x0 = a[0] + dx * (from - start);
			var y0 = a[1] + dy * (from - start);
			var x1 = a[0] + dx * (to - start);
			var y1 = a[1] + dy * (to - start);
			s.visible = true;
			s.x = Math.min(x0, x1) - (dx == 0 ? thick / 2 : 0);
			s.y = Math.min(y0, y1) - (dy == 0 ? thick / 2 : 0);
			s.scale.set(dx == 0 ? thick : Math.abs(x1 - x0) + (dy == 0 ? 0 : thick), dy == 0 ? thick : Math.abs(y1 - y0) + thick);
			s.origin.set(0, 0);
		}
		start += len;
	}
}

function pathLength() {
	var total = 0.0;
	for (i in 0...PATH.length - 1) total += Math.abs(PATH[i + 1][0] - PATH[i][0]) + Math.abs(PATH[i + 1][1] - PATH[i][1]);
	return total;
}

function onSongStart() {
	if (track == null) return;
	fadeList(card, 1, 0.3);
	drawSnake(BODY_START, BODY_START, 3);       // the bright line under the title: the one that will walk
	new FlxTimer().start(CARD_HOLD, (_) -> {
		fadeList(card, 0, CARD_FADE);           // everything goes but the line
		new FlxTimer().start(CARD_FADE, (_) -> {
			snakeOn = true;
			snakeTime = 0;
		});
	});
}

function updateSnake(elapsed) {
	if (!snakeOn) return;
	snakeTime += elapsed;
	var u = Math.min(1, snakeTime / SNAKE_SECONDS);
	var e = FlxEase.expoInOut(u);
	var total = pathLength();
	var body = BODY_START + (BODY_END - BODY_START) * e;
	var head = BODY_START + (total - BODY_START) * e;
	var thick = u < 1 ? 3 : Math.max(1, 3 - (snakeTime - SNAKE_SECONDS) * 8);
	drawSnake(head, body, thick);
	if (u >= 1 && snakeTime - SNAKE_SECONDS > 0.25 && rec.length > 0 && rec[0].obj.alpha == 0 && snakeTime < SNAKE_SECONDS + 0.3) {
		fadeList(rec, 1, 0.35);
		new FlxTimer().start(REC_HOLD, (_) -> {
			fadeList(rec, 0, 0.5);
			for (s in snake) FlxTween.tween(s, {alpha: 0}, 0.5);
			new FlxTimer().start(0.55, (_) -> snakeOn = false);
		});
	}
}

// For the other parts of a song: REC n appears without the snake, holds and goes (call it from a song's own script).
function showRec(n, note) {
	buildRec(n, note, Conductor.songPosition / 1000);
	fadeList(rec, 1, 0.35);
	new FlxTimer().start(REC_HOLD, (_) -> fadeList(rec, 0, 0.5));
}

// ---------------------------------------------------------------- the pause

function onGamePause(event) {
	event.cancel();
	persistentUpdate = false;
	persistentDraw = true;
	paused = true;
	setDeckPaused(true);
	vhsFx.call("setPause", [true]);
	openSubState(new ModSubState("TapePauseSubState"));
}

function onSubstateClose(event) {
	setDeckPaused(false);
	vhsFx.call("setPause", [false]);
}

function update(elapsed) {
	updateClock(elapsed);
	updateSnake(elapsed);
	playArrow.visible = !paused && Std.int(Lib.getTimer() / 500) % 2 == 0;
	if (recDot != null) recDot.visible = Std.int(Lib.getTimer() / 500) % 2 == 0;
}
