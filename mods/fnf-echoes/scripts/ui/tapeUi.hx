import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxGradient;
import flixel.util.FlxSpriteUtil;
import funkin.backend.scripting.Script;
import funkin.backend.MusicBeatTransition;
import openfl.Lib;

// The screens of the tape (style E of the design canvas, BE-61): one of Limbo's places with Zyra's idle on top, the darker
// side where an index is read, the index itself (header, numbered entries with a timecode, a progress bar, a footer), and the
// OSD split like a camcorder recording played on a deck: PLAY/PAUSE and SP crisp on `deckCam` (the tape does not cover it),
// the date and the time burned into the recording. The clock keeps running from screen to screen (FlxG.save.data.echoesTapeClock).
// The main menu has its own copy of this (it came first, BE-60); the other screens use this script:
//
//   ui = Script.create(Paths.script('scripts/ui/tapeUi')); ui.load();
//   ui.call("buildScene", ["pool"]);                          // the place, Zyra, the shade (call first: it is the bottom layer)
//   ui.call("buildIndex", ["CINTAS ENCONTRADAS", "3", entries]);   // entries: [{label, time, dim}]
//   ui.call("buildOsd", ["PLAY"]);                            // and then attach vhsShader, excluding ui.call("deckCamera")
//   ui.call("update", [elapsed]); ui.call("select", [i]); ui.call("rowAt", [mx, my]); ui.call("setFooter", [left, right]);

var ZYRA_X = 738;
var ZYRA_Y = 370;
var LIST_X = 72;
var LIST_Y = 190;
var LIST_W = 520;
var ROW_H = 52;
var FONT = "IBMPlexMono-Regular.ttf";
var FONT_BOLD = "IBMPlexMono-SemiBold.ttf";
var WHITE = 0xFFF2F2EE;
var CLOCK_START = 23 * 3600 + 43 * 60 + 11;

var place = "pool";
var zyra;
var pose = 0;
var poseTime = 0.0;
var rows = [];
var barFill;
var footLeft;
var footRight;
var barY = 0;
var dateText;
var timeText;
var deckCam;
var playArrow;

function buildScene(placeName) {
	place = placeName;
	MusicBeatTransition.script = 'scripts/effects/tapeTransition';   // the tape's transitions (BE-63)
	FlxG.state.add(new FlxSprite().loadGraphic(Paths.image("menus/tape/bg_" + place)));
	zyra = new FlxSprite(ZYRA_X, ZYRA_Y).loadGraphic(Paths.image("menus/tape/zyra_" + place + "_0"));
	FlxG.state.add(zyra);
	FlxG.state.add(FlxGradient.createGradientFlxSprite(Std.int(FlxG.width * 0.62), FlxG.height, [0xB3000000, 0x40000000, 0x00000000], 1, 0));
}

function text(x, y, w, size, bold, align) {
	var t = new FlxText(x, y, w, "");
	t.setFormat(Paths.font(bold ? FONT_BOLD : FONT), size, WHITE, align);
	t.antialiasing = true;
	FlxG.state.add(t);
	return t;
}

function buildIndex(title, right, entries) {
	var h = text(LIST_X, LIST_Y - 4, LIST_W, 16, false, "left");
	h.text = title;
	h.alpha = 0.85;
	var hr = text(LIST_X, LIST_Y - 4, LIST_W, 16, false, "right");
	hr.text = right;
	hr.alpha = 0.85;
	FlxG.state.add(new FlxSprite(LIST_X, LIST_Y + 26).makeGraphic(LIST_W, 1, 0x66F2F2EE));
	// an entry with `thumb` (an image path) gets a small picture between its number and its label
	var hasThumbs = false;
	for (e in entries) if (e.thumb != null) hasThumbs = true;
	if (hasThumbs) ROW_H = 60;
	var labelX = LIST_X + 52 + (hasThumbs ? 88 : 0);
	for (i in 0...entries.length) {
		var y = LIST_Y + 40 + i * ROW_H;
		var row = {
			number: text(LIST_X, y + 10, 52, 18, false, "left"),
			label: text(labelX, y, LIST_X + LIST_W - 140 - labelX, 26, false, "left"),
			labelBold: text(labelX, y - 2, LIST_X + LIST_W - 140 - labelX, 30, true, "left"),
			time: text(LIST_X + LIST_W - 140, y + 10, 140, 18, false, "right"),
			thumb: null,
			y: y,
			dim: entries[i].dim == true
		};
		if (entries[i].thumb != null) {
			row.thumb = new FlxSprite(LIST_X + 52, y - 2).loadGraphic(Paths.image(entries[i].thumb));
			row.thumb.setGraphicSize(72, 44);
			row.thumb.updateHitbox();
			FlxG.state.add(row.thumb);
		}
		row.number.text = (i + 1 < 10 ? "0" : "") + (i + 1);
		row.label.text = row.labelBold.text = entries[i].label;
		row.time.text = entries[i].time;
		rows.push(row);
	}
	barY = LIST_Y + 40 + entries.length * ROW_H + 14;
	FlxG.state.add(new FlxSprite(LIST_X, barY).makeGraphic(LIST_W, 4, 0x40F2F2EE));
	barFill = new FlxSprite(LIST_X, barY).makeGraphic(LIST_W, 4, WHITE);
	barFill.origin.set(0, 0);
	FlxG.state.add(barFill);
	footLeft = text(LIST_X, barY + 10, LIST_W, 16, false, "left");
	footRight = text(LIST_X, barY + 10, LIST_W, 16, false, "right");
	footLeft.alpha = footRight.alpha = 0.85;
}

function rowTop(i) {
	return rows[i].y;
}

function setFooter(left, right) {
	footLeft.text = left;
	footRight.text = right;
}

function setTime(i, value) {
	rows[i].time.text = value;
}

function select(index) {
	for (i in 0...rows.length) {
		var on = i == index;
		rows[i].labelBold.visible = on;
		rows[i].label.visible = !on;
		var a = rows[i].dim ? (on ? 0.6 : 0.4) : (on ? 1.0 : 0.72);
		rows[i].label.alpha = rows[i].labelBold.alpha = rows[i].number.alpha = rows[i].time.alpha = a;
		if (rows[i].thumb != null) rows[i].thumb.alpha = rows[i].dim ? 0.55 : (on ? 1.0 : 0.8);
	}
	barFill.scale.x = (index + 1) / rows.length;
}

function rowAt(mx, my) {
	if (mx < LIST_X || mx > LIST_X + LIST_W) return -1;
	for (i in 0...rows.length)
		if (my >= rows[i].y && my < rows[i].y + ROW_H) return i;
	return -1;
}

// the deck's PLAY (or PAUSE) and SP, crisp; the date and the time burned into the recording
function buildOsd(mode) {
	dateText = new FlxText(64, FlxG.height - 118, 400, "");
	dateText.setFormat(Paths.font("vcr.ttf"), 32, WHITE, "left");
	FlxG.state.add(dateText);
	timeText = new FlxText(64, FlxG.height - 84, 400, "");
	timeText.setFormat(Paths.font("vcr.ttf"), 32, WHITE, "left");
	FlxG.state.add(timeText);
	deckCam = new FlxCamera();
	deckCam.bgColor = 0x00000000;
	FlxG.cameras.add(deckCam, false);
	deckText(64, 40, 240, 40, mode, "left");
	playArrow = new FlxSprite(64 + (mode == "PLAY" ? 112 : 140), 46).makeGraphic(22, 28, 0x00000000, true);
	if (mode == "PLAY") FlxSpriteUtil.drawPolygon(playArrow, [FlxPoint.get(0, 0), FlxPoint.get(22, 14), FlxPoint.get(0, 28)], WHITE);
	else {
		FlxSpriteUtil.drawRect(playArrow, 0, 0, 7, 28, WHITE);
		FlxSpriteUtil.drawRect(playArrow, 14, 0, 7, 28, WHITE);
	}
	playArrow.cameras = [deckCam];
	FlxG.state.add(playArrow);
	deckText(FlxG.width - 64 - 100, FlxG.height - 84, 100, 32, "SP", "right");
	updateClock(0);
}

function deckCamera() {
	return deckCam;
}

function deckText(x, y, w, size, label, align) {
	for (k in 0...2) {
		var t = new FlxText(x + (k == 0 ? 2 : 0), y + (k == 0 ? 2 : 0), w, label);
		t.setFormat(Paths.font("vcr.ttf"), size, k == 0 ? 0xFF0A0A0A : WHITE, align);
		t.cameras = [deckCam];
		FlxG.state.add(t);
	}
}

// the clock of the tape, shared by every screen; jump() moves it on (a camcorder edit)
function updateClock(elapsed) {
	var c = FlxG.save.data.echoesTapeClock;
	if (c == null) c = 0.0;
	c += elapsed;
	FlxG.save.data.echoesTapeClock = c;
	var sec = CLOCK_START + Std.int(c);
	var hours = Std.int(sec / 3600) % 24;
	var h = hours % 12 == 0 ? 12 : hours % 12;
	var m = Std.int(sec / 60) % 60;
	var s = sec % 60;
	dateText.text = "OCT. " + (27 + Std.int(sec / 86400)) + " 1997";
	timeText.text = h + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s + (hours >= 12 ? " PM" : " AM");
}

function jump(seconds) {
	var c = FlxG.save.data.echoesTapeClock;
	FlxG.save.data.echoesTapeClock = (c == null ? 0.0 : c) + seconds;
}

function update(elapsed) {
	poseTime += elapsed;
	if (poseTime >= 1 / 6) {
		poseTime -= 1 / 6;
		pose = (pose + 1) % 6;
		zyra.loadGraphic(Paths.image("menus/tape/zyra_" + place + "_" + pose));
	}
	updateClock(elapsed);
	playArrow.visible = Std.int(Lib.getTimer() / 500) % 2 == 0;
}
