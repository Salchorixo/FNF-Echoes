import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxSpriteUtil;
import funkin.backend.system.Flags;
import funkin.editors.EditorPicker;
import funkin.backend.scripting.ModState;
import funkin.backend.scripting.ModSubState;
import funkin.backend.scripting.Script;
import funkin.backend.utils.CoolUtil;
import openfl.Lib;
import funkin.menus.TitleState;

// Main menu (BE-60; Zyra, 2026-10-27 to 2026-11-09): a camcorder tape found somewhere. The picture is one of Limbo's places
// (the hills, the pool, the hall), rendered in Blender without Zyra; it changes by itself at irregular times and every change
// is an EDIT of the recording (the tape loses sync, rolls, loses its colour: scripts/effects/vhsShader.hx). Now and then the old
// recording underneath shows through: a grey ghost of another place, or of one of its things (a lamp, a house, the lockers).
// Zyra is a layer of his own on top, always doing his idle, with the light of the place behind him (version A of mockup v05).
// The menu is the tape's index (style E of the design canvas): numbered entries with a timecode, a progress bar, where you are.
// The OSD is split like a real camcorder recording played on a deck: PLAY and SP belong to the deck (crisp, on `deckCam`,
// which the tape does not cover); the date and the time were burned into the recording (under the tape), and the clock jumps
// at every edit (time went by between the two recordings).
// The old menu (themes Vista/XP/98/Mac, the sofa, the buttons) is kept, unused, in LegacyMainMenuState.hx.
//
// Keys: UP/DOWN choose, ENTER opens, ESC back to the title. Test shortcuts as before: 6 tape, 7 editors, 8 animations, 9 mist.

var PLACES = ["hills2", "pool", "hall"];
var HOLDS = [1.9, 2.6, 3.4, 4.2, 5.5];                    // seconds a place stays before the next edit (one at random)
var CLOCK_JUMPS = [4, 9, 37, 152, 413, 1261, 2];          // seconds between two recordings, one at random at every edit
var CLOCK_START = 23 * 3600 + 43 * 60 + 11;               // OCT. 27 1997, 11:43:11 PM
var ZYRA_X = 738;                                          // where Zyra's cut-out frames sit (images/menus/tape/zyra_<place>_<n>.png)
var ZYRA_Y = 370;
var ZYRA_POSE_SECONDS = 1 / 6;                             // his idle is on twos: 6 poses, the loop lasts a second
// the things of each place that can slip into another as a ghost (boxes in 1280x720, where they sit in their own place)
function thingsOf(place) {
	if (place == "hills2") return [[80, 30, 280, 390], [700, 180, 200, 240], [1180, 60, 100, 320]];
	if (place == "pool") return [[300, 60, 200, 110], [610, 460, 130, 100]];
	return [[1090, 300, 190, 420], [620, 330, 280, 90], [620, 620, 100, 80], [420, 0, 180, 720]];
}
var ENTRIES = [
	{key: "PLAY", time: "00:00:00"},
	{key: "SETTINGS", time: "00:43:12"},
	{key: "CREDITS", time: "01:27:40"},
	{key: "FOLDER", time: "--:--:--"}
];
var LIST_X = 72;
var LIST_Y = 210;
var LIST_W = 470;
var ROW_H = 52;
var FONT = "IBMPlexMono-Regular.ttf";
var FONT_BOLD = "IBMPlexMono-SemiBold.ttf";
var WHITE = 0xFFF2F2EE;
var SONG_BPM = 122;
var MUSIC_ID = 9071;

var i18n;
var vhsFx;
var deckCam;
var uiCam;            // the index and its shade: it fades away while Settings is open, so the window reads on its own
var bg;
var ghost;
var zyra;
var placeIndex = 0;
var holdLeft = 3.0;
var poseTime = 0.0;
var pose = 0;
var ghostTime = 0.0;
var ghostLength = 0.0;
var ghostWait = 3.0;
var ghostPeak = 0.2;
var trackingWait = 9.0;
var rows = [];
var selected = 0;
var header;
var headerRight;
var bar;
var barFill;
var whereText;
var musicText;
var dateText;
var timeText;
var playArrow;
var playArrowOn = true;
var lastMouseX = 0;
var lastMouseY = 0;

function create() {
	FlxG.camera.scroll.set(0, 0);
	bgColor = FlxColor.BLACK;
	i18n = Script.create(Paths.script('scripts/ui/translate'));
	i18n.load();

	if (FlxG.sound.music == null || !FlxG.sound.music.playing || FlxG.sound.music.ID != MUSIC_ID) {
		CoolUtil.playMusic(Paths.music('menuLoop'), true, 1, true, SONG_BPM);
		FlxG.sound.music.ID = MUSIC_ID;
	}

	placeIndex = FlxG.random.int(0, PLACES.length - 1);
	bg = new FlxSprite();
	add(bg);
	ghost = new FlxSprite();
	ghost.visible = false;
	add(ghost);
	zyra = new FlxSprite(ZYRA_X, ZYRA_Y);
	add(zyra);
	showPlace();

	uiCam = new FlxCamera();
	uiCam.bgColor = 0x00000000;
	FlxG.cameras.add(uiCam, false);
	// the darker side where the index is read
	var shade = FlxGradient.createGradientFlxSprite(Std.int(FlxG.width * 0.62), FlxG.height, [0xA6000000, 0x33000000, 0x00000000], 1, 0);
	shade.cameras = [uiCam];
	add(shade);

	buildIndex();
	buildBurnedOsd();

	// the deck's own text, crisp, on a camera of its own that the tape does not cover
	deckCam = new FlxCamera();
	deckCam.bgColor = 0x00000000;
	FlxG.cameras.add(deckCam, false);
	buildDeckOsd();

	vhsFx = Script.create(Paths.script('scripts/effects/vhsShader'));
	vhsFx.load();
	vhsFx.call('exclude', [deckCam]);
	vhsFx.call('attach');

	FlxG.mouse.visible = true;
	updateRows();
}

// ---------------------------------------------------------------- the picture

function showPlace() {
	var place = PLACES[placeIndex];
	bg.loadGraphic(Paths.image("menus/tape/bg_" + place));
	showPose();
	if (whereText != null) whereText.text = i18n.call("get", ["YOU ARE IN"]) + ": " + i18n.call("get", ["PLACE " + place]);
}

function showPose() {
	zyra.loadGraphic(Paths.image("menus/tape/zyra_" + PLACES[placeIndex] + "_" + pose));
}

// a camcorder edit: the recording stops and starts again somewhere else, a while later
function cutToNextPlace() {
	var next = FlxG.random.int(0, PLACES.length - 2);
	if (next >= placeIndex) next++;
	placeIndex = next;
	showPlace();
	vhsFx.call("cut");
	var c = FlxG.save.data.echoesTapeClock;
	FlxG.save.data.echoesTapeClock = (c == null ? 0.0 : c) + CLOCK_JUMPS[FlxG.random.int(0, CLOCK_JUMPS.length - 1)];
	holdLeft = HOLDS[FlxG.random.int(0, HOLDS.length - 1)];
	ghost.visible = false;
	ghostTime = ghostLength;
}

// the old recording underneath: a grey ghost of another place (all of it, or one of its things), a little out of line
function startGhost() {
	var others = [for (p in PLACES) if (p != PLACES[placeIndex]) p];
	var place = others[FlxG.random.int(0, others.length - 1)];
	ghost.loadGraphic(Paths.image("menus/tape/ghost_" + place));
	ghost.x = FlxG.random.int(-24, 24);
	if (FlxG.random.bool(60)) {
		var things = thingsOf(place);
		var t = things[FlxG.random.int(0, things.length - 1)];
		ghost.clipRect = new FlxRect(t[0] - ghost.x, t[1], t[2], t[3]);
		ghostPeak = FlxG.random.float(0.25, 0.42);
	} else {
		ghost.clipRect = null;
		ghostPeak = FlxG.random.float(0.1, 0.24);
	}
	ghostLength = [0.3, 0.6, 1.1, 1.6][FlxG.random.int(0, 3)];
	ghostTime = 0;
	ghost.visible = true;
}

function updatePicture(elapsed) {
	holdLeft -= elapsed;
	if (holdLeft <= 0) cutToNextPlace();

	poseTime += elapsed;
	if (poseTime >= ZYRA_POSE_SECONDS) {
		poseTime -= ZYRA_POSE_SECONDS;
		pose = (pose + 1) % 6;
		showPose();
	}

	ghostWait -= elapsed;
	if (ghostWait <= 0) {
		startGhost();
		ghostWait = FlxG.random.float(2.0, 6.0);
	}
	if (ghost.visible) {
		ghostTime += elapsed;
		if (ghostTime >= ghostLength) ghost.visible = false;
		else ghost.alpha = ghostPeak * Math.sin(Math.PI * ghostTime / ghostLength) * FlxG.random.float(0.75, 1.0);
	}

	trackingWait -= elapsed;
	if (trackingWait <= 0) {
		vhsFx.call("badTracking", [FlxG.random.float(0.6, 1.6), FlxG.random.float(0.4, 0.8)]);
		trackingWait = FlxG.random.float(8.0, 15.0);
	}
}

// ---------------------------------------------------------------- the index

function text(x, y, w, size, bold, align) {
	var t = new FlxText(x, y, w, "");
	t.setFormat(Paths.font(bold ? FONT_BOLD : FONT), size, WHITE, align);
	t.antialiasing = true;
	t.cameras = [uiCam];
	add(t);
	return t;
}

function buildIndex() {
	header = text(LIST_X, LIST_Y - 4, LIST_W, 16, false, "left");
	header.text = i18n.call("get", ["TAPE INDEX"]);
	header.alpha = 0.85;
	headerRight = text(LIST_X, LIST_Y - 4, LIST_W, 16, false, "right");
	headerRight.text = "ECHOES";
	headerRight.alpha = 0.85;
	var rule = new FlxSprite(LIST_X, LIST_Y + 26).makeGraphic(LIST_W, 1, 0x66F2F2EE);
	rule.cameras = [uiCam];
	add(rule);

	for (i in 0...ENTRIES.length) {
		var y = LIST_Y + 40 + i * ROW_H;
		var row = {
			number: text(LIST_X, y + 10, 52, 18, false, "left"),
			label: text(LIST_X + 52, y, LIST_W - 52 - 128, 26, false, "left"),
			labelBold: text(LIST_X + 52, y - 2, LIST_W - 52 - 128, 30, true, "left"),
			time: text(LIST_X + LIST_W - 128, y + 10, 128, 18, false, "right"),
			y: y
		};
		row.number.text = (i + 1 < 10 ? "0" : "") + (i + 1);
		row.label.text = row.labelBold.text = i18n.call("get", [ENTRIES[i].key]);
		row.time.text = ENTRIES[i].time;
		rows.push(row);
	}

	var barY = LIST_Y + 40 + ENTRIES.length * ROW_H + 14;
	bar = new FlxSprite(LIST_X, barY).makeGraphic(LIST_W, 4, 0x40F2F2EE);
	bar.cameras = [uiCam];
	add(bar);
	barFill = new FlxSprite(LIST_X, barY).makeGraphic(LIST_W, 4, WHITE);
	barFill.origin.set(0, 0);
	barFill.cameras = [uiCam];
	add(barFill);
	whereText = text(LIST_X, barY + 10, LIST_W, 16, false, "left");
	whereText.alpha = 0.85;
	musicText = text(LIST_X, barY + 10, LIST_W, 16, false, "right");
	musicText.text = i18n.call("get", ["MENU MUSIC"]);
	musicText.alpha = 0.85;
	showPlace();
}

function updateRows() {
	for (i in 0...rows.length) {
		var on = i == selected;
		rows[i].labelBold.visible = on;
		rows[i].label.visible = !on;
		var a = on ? 1.0 : 0.72;
		rows[i].label.alpha = rows[i].number.alpha = rows[i].time.alpha = a;
	}
	barFill.scale.x = (selected + 1) / rows.length;
}

function moveSelection(delta) {
	selected = (selected + delta + rows.length) % rows.length;
	FlxG.sound.play(Paths.sound("menu/scroll"), 0.5);
	updateRows();
}

function confirmSelection() {
	switch (ENTRIES[selected].key) {
		case "PLAY":
			FlxG.switchState(new ModState("EchoSelectState"));
		case "SETTINGS":
			openSettings();
		case "CREDITS":
			FlxG.switchState(new ModState("TapeCreditsState"));
		case "FOLDER":
			// the art gallery does not exist yet
			rows[selected].time.text = i18n.call("get", ["NOT YET"]);
	}
}

function rowAt(mx, my) {
	if (mx < LIST_X || mx > LIST_X + LIST_W) return -1;
	for (i in 0...rows.length)
		if (my >= rows[i].y && my < rows[i].y + ROW_H) return i;
	return -1;
}

function updateMouse() {
	var moved = FlxG.mouse.screenX != lastMouseX || FlxG.mouse.screenY != lastMouseY;
	lastMouseX = FlxG.mouse.screenX;
	lastMouseY = FlxG.mouse.screenY;
	var over = rowAt(FlxG.mouse.screenX, FlxG.mouse.screenY);
	if (moved && over != -1 && over != selected) {
		selected = over;
		updateRows();
	}
	if (FlxG.mouse.justPressed && over != -1) confirmSelection();
}

// ---------------------------------------------------------------- the OSD

// the date and the time the camcorder burned into the recording (under the tape)
function buildBurnedOsd() {
	dateText = new FlxText(64, FlxG.height - 118, 400, "");
	dateText.setFormat(Paths.font("vcr.ttf"), 32, WHITE, "left");
	add(dateText);
	timeText = new FlxText(64, FlxG.height - 84, 400, "");
	timeText.setFormat(Paths.font("vcr.ttf"), 32, WHITE, "left");
	add(timeText);
	updateClock(0);
}

function updateClock(elapsed) {
	// the clock of the tape is shared by every screen (scripts/ui/tapeUi.hx)
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

// PLAY with its blinking arrow and SP: the deck's own text, crisp, over the tape
function buildDeckOsd() {
	deckText(64, 40, 200, 40, "PLAY", "left");
	playArrow = new FlxSprite(64 + 112, 46).makeGraphic(22, 28, 0x00000000, true);
	FlxSpriteUtil.drawPolygon(playArrow, [FlxPoint.get(0, 0), FlxPoint.get(22, 14), FlxPoint.get(0, 28)], WHITE);
	playArrow.cameras = [deckCam];
	add(playArrow);
	deckText(FlxG.width - 64 - 100, FlxG.height - 84, 100, 32, "SP", "right");
}

// a line of the deck's text with its hard shadow
function deckText(x, y, w, size, label, align) {
	for (k in 0...2) {
		var t = new FlxText(x + (k == 0 ? 2 : 0), y + (k == 0 ? 2 : 0), w, label);
		t.setFormat(Paths.font("vcr.ttf"), size, k == 0 ? 0xFF0A0A0A : WHITE, align);
		t.cameras = [deckCam];
		add(t);
	}
}

// ---------------------------------------------------------------- the loop

function update(elapsed) {
	updatePicture(elapsed);
	updateClock(elapsed);
	playArrow.visible = Std.int(Lib.getTimer() / 500) % 2 == 0;
	if (subState != null) return;     // Settings (or the editors) open over the menu: the picture moves, the keys are theirs

	if (FlxG.keys.justPressed.SEVEN && !Flags.DISABLE_EDITORS) openEditors();
	if (FlxG.keys.justPressed.EIGHT && !Flags.DISABLE_EDITORS) FlxG.switchState(new ModState("AnimTestState"));
	if (FlxG.keys.justPressed.NINE && !Flags.DISABLE_EDITORS) FlxG.switchState(new ModState("MistTestState"));
	if (FlxG.keys.justPressed.SIX && !Flags.DISABLE_EDITORS) FlxG.switchState(new ModState("VHSTestState"));

	if (controls.UP_P) moveSelection(-1);
	if (controls.DOWN_P) moveSelection(1);
	updateMouse();
	if (controls.ACCEPT) confirmSelection();
	if (controls.BACK) FlxG.switchState(new TitleState());
}

// The engine's editor picker (chart editor...) on the 7 key (BE-40, BE-43): the physical key, not controls.DEV_ACCESS.
function openEditors() {
	persistentUpdate = false;
	persistentDraw = true;
	openSubState(new EditorPicker());
}

// Settings is a window over this menu (BE-20); the menu keeps moving behind it.
function openSettings() {
	persistentUpdate = true;
	FlxTween.cancelTweensOf(uiCam);
	FlxTween.tween(uiCam, {alpha: 0}, 0.25);
	var sub = new ModSubState("TapeOptionsState");
	sub.closeCallback = () -> onSettingsClosed();
	openSubState(sub);
}

// the language may have changed
function onSettingsClosed() {
	persistentUpdate = false;
	FlxTween.cancelTweensOf(uiCam);
	FlxTween.tween(uiCam, {alpha: 1}, 0.25);
	header.text = i18n.call("get", ["TAPE INDEX"]);
	musicText.text = i18n.call("get", ["MENU MUSIC"]);
	for (i in 0...rows.length) rows[i].label.text = rows[i].labelBold.text = i18n.call("get", [ENTRIES[i].key]);
	showPlace();
}

function destroy() {
	FlxG.mouse.visible = false;
}

// The Settings window still asks the screen behind it for the old menu's desktop themes (BE-28, BE-29); this menu has none.
function channelParams() {
	return null;
}

function channelTime() {
	return 0.0;
}

function chooseTheme(newTheme) {}
