import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.input.keyboard.FlxKey;
import funkin.backend.scripting.Script;
import funkin.backend.utils.CoolUtil;
import funkin.backend.utils.TranslationUtil;
import funkin.options.Options;

// Settings (BE-61, style E of the design canvas: an index in two columns): a SUB-STATE over the main menu, which keeps moving
// behind a dark veil and under the same tape (the menu's tape covers this camera too). Left: the categories; right: the settings
// of the open one, numbered "1.1", "1.2"... with their value, and a line that says what the chosen one does.
// Keys: UP/DOWN move, RIGHT or ENTER goes into a category, LEFT/RIGHT change a slider, ENTER toggles or captures a key, ESC goes
// back a level and then closes (saving). The mouse works too (hover selects, a click activates; on a slider, the left half
// lowers it and the right half raises it).
// The settings and how they are stored are the ones of the old Vista window (LegacyOptionsState.hx, BE-15), without the
// desktop themes (they do not exist any more) and with TAPE NOISE ("RUIDO DE LA CINTA", FlxG.save.data.echoesTapeNoise, 0..1).

var CATEGORIES = ["AUDIO", "CONTROLS", "GAMEPLAY", "SCREEN", "LANGUAGE"];
var DESCRIPTIONS = ["DESC AUDIO", "DESC CONTROLS", "DESC GAMEPLAY", "DESC SCREEN TAPE", "DESC LANGUAGE"];
var ROWS = [
	[
		{label: "VOLUME", kind: "volume"},
		{label: "MUSIC", kind: "slider", fieldName: "volumeMusic"},
		{label: "SOUND EFFECTS", kind: "slider", fieldName: "volumeSFX"}
	],
	[
		{label: "UP", kind: "keybind", controlName: "P1_UP"},
		{label: "DOWN", kind: "keybind", controlName: "P1_DOWN"},
		{label: "LEFT", kind: "keybind", controlName: "P1_LEFT"},
		{label: "RIGHT", kind: "keybind", controlName: "P1_RIGHT"}
	],
	[
		{label: "SCREEN QUALITY", kind: "quality"},
		{label: "DOWNSCROLL", kind: "bool", fieldName: "downscroll"},
		{label: "GHOST TAPPING", kind: "bool", fieldName: "ghostTapping"}
	],
	[
		{label: "TAPE NOISE", kind: "tape"},
		{label: "REDUCE FLASHES", kind: "flashes"},
		{label: "DESKTOP EFFECTS", kind: "pref", fieldName: "echoesDesktopEffects"}
	],
	[
		{label: "ENGLISH", kind: "language", code: "en"},
		{label: "ESPAÑOL", kind: "language", code: "es"}
	]
];
var X = 72;
var Y = 150;
var CAT_W = 300;
var SET_X = 430;
var SET_W = 780;
var ROW_H = 50;
var FONT = "IBMPlexMono-Regular.ttf";
var FONT_BOLD = "IBMPlexMono-SemiBold.ttf";
var WHITE = 0xFFF2F2EE;

var i18n;
var cam;
var header;
var headerRight;
var catRows = [];
var setRows = [];
var descText;
var category = 0;
var setting = 0;
var focus = "cats";          // cats, rows, capturing
var captureHeld = false;
var lastMouseX = 0;
var lastMouseY = 0;

function t(key) {
	return i18n.call("get", [key]);
}

function create() {
	i18n = Script.create(Paths.script('scripts/ui/translate'));
	i18n.load();
	cam = new FlxCamera();
	cam.bgColor = 0x00000000;
	FlxG.cameras.add(cam, false);

	put(new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x99050506));
	header = text(X, Y - 4, SET_X + SET_W - X, 16, false, "left");
	headerRight = text(X, Y - 4, SET_X + SET_W - X, 16, false, "right");
	header.alpha = headerRight.alpha = 0.85;
	put(new FlxSprite(X, Y + 26).makeGraphic(SET_X + SET_W - X, 1, 0x66F2F2EE));
	put(new FlxSprite(SET_X - 24, Y + 44).makeGraphic(1, 260, 0x4DF2F2EE));

	for (i in 0...CATEGORIES.length) {
		var y = Y + 44 + i * ROW_H;
		catRows.push({number: text(X, y + 8, 44, 16, false, "left"), label: text(X + 44, y, CAT_W, 24, false, "left"),
			labelBold: text(X + 44, y - 2, CAT_W, 26, true, "left"), y: y});
	}
	for (i in 0...4) {
		var y = Y + 44 + i * ROW_H;
		setRows.push({number: text(SET_X, y + 8, 52, 15, false, "left"), label: text(SET_X + 52, y + 2, SET_W - 52 - 280, 20, false, "left"),
			labelBold: text(SET_X + 52, y, SET_W - 52 - 280, 21, true, "left"), value: text(SET_X + SET_W - 280, y + 2, 280, 20, false, "right"), y: y});
	}
	descText = text(SET_X, Y + 44 + 4 * ROW_H + 16, SET_W, 15, false, "left");
	descText.alpha = 0.8;
	refreshTexts();
}

function put(obj) {
	obj.cameras = [cam];
	add(obj);
	return obj;
}

function text(x, y, w, size, bold, align) {
	var tx = new FlxText(x, y, w, "");
	tx.setFormat(Paths.font(bold ? FONT_BOLD : FONT), size, WHITE, align);
	tx.antialiasing = true;
	return put(tx);
}

// ---------------------------------------------------------------- values (as in the old window)

function sliderValue(row) {
	if (row.kind == "volume") return FlxG.sound.volume;
	if (row.kind == "tape") {
		var n = FlxG.save.data.echoesTapeNoise;
		return n == null ? 1.0 : n;
	}
	return Reflect.field(Options, row.fieldName);
}

function setSlider(row, value) {
	var v = Math.round(Math.max(0, Math.min(1, value)) * 10) / 10;
	if (row.kind == "volume") FlxG.sound.volume = v;
	else if (row.kind == "tape") FlxG.save.data.echoesTapeNoise = v;
	else {
		Reflect.setField(Options, row.fieldName, v);
		Options.applySettings();
	}
}

function boolValue(row) {
	if (row.kind == "flashes") return !Options.flashingMenu;
	if (row.kind == "pref") {
		var value = Reflect.field(FlxG.save.data, row.fieldName);
		return value == null ? true : value;
	}
	return Reflect.field(Options, row.fieldName);
}

function isSlider(row) {
	return row.kind == "volume" || row.kind == "slider" || row.kind == "tape";
}

function valueOf(row) {
	if (isSlider(row)) {
		var n = Math.round(sliderValue(row) * 10);
		var s = "";
		for (i in 0...10) s += i < n ? "#" : "-";
		return "[" + s + "] " + n * 10;
	}
	if (row.kind == "keybind") {
		var keys = Reflect.field(Options, row.controlName);
		return CoolUtil.keyToString(keys[0]);
	}
	if (row.kind == "quality") return t(Options.quality == 0 ? "PERFORMANCE" : "HIGH");
	if (row.kind == "language") return Options.language == row.code ? "<" : "";
	return t(boolValue(row) ? "ON" : "OFF");
}

function activate() {
	var row = ROWS[category][setting];
	if (row.kind == "keybind") {
		focus = "capturing";
		captureHeld = true;
		setRows[setting].value.text = t("PRESS A KEY...");
		return;
	}
	if (isSlider(row)) return;
	if (row.kind == "quality") {
		Options.quality = Options.quality == 0 ? 1 : 0;
		Options.applyQuality();
	} else if (row.kind == "language") {
		if (Options.language != row.code) TranslationUtil.setLanguage(row.code);
	} else if (row.kind == "flashes") Options.flashingMenu = !Options.flashingMenu;
	else if (row.kind == "pref") Reflect.setField(FlxG.save.data, row.fieldName, !boolValue(row));
	else Reflect.setField(Options, row.fieldName, !boolValue(row));
	FlxG.sound.play(Paths.sound("menu/confirm"), 0.5);
	refreshTexts();
}

function updateCapture() {
	if (captureHeld && controls.ACCEPT) return;
	captureHeld = false;
	var key = FlxG.keys.firstJustPressed();
	if (cast(key, Int) <= 0) return;
	if (key != FlxKey.ESCAPE) {
		Reflect.setField(Options, ROWS[category][setting].controlName, [key]);
		Options.applyKeybinds();
	}
	focus = "rows";
	refreshTexts();
}

// ---------------------------------------------------------------- drawing

function refreshTexts() {
	header.text = t("SETTINGS INDEX");
	headerRight.text = t("ESC BACK");
	for (i in 0...catRows.length) {
		var r = catRows[i];
		r.number.text = "0" + (i + 1);
		r.label.text = r.labelBold.text = t(CATEGORIES[i]) + (i == category ? "  >" : "");
		var on = i == category;
		r.labelBold.visible = on;
		r.label.visible = !on;
		r.label.alpha = r.number.alpha = on ? 1.0 : 0.65;
		r.labelBold.alpha = focus == "cats" ? 1.0 : 0.8;
	}
	var rows = ROWS[category];
	for (i in 0...setRows.length) {
		var r = setRows[i];
		var has = i < rows.length;
		r.number.visible = r.value.visible = has;
		var on = has && focus != "cats" && i == setting;
		r.labelBold.visible = on;
		r.label.visible = has && !on;
		if (!has) continue;
		r.number.text = (category + 1) + "." + (i + 1);
		r.label.text = r.labelBold.text = rows[i].kind == "language" ? rows[i].label : t(rows[i].label);
		if (!(focus == "capturing" && i == setting)) r.value.text = valueOf(rows[i]);
		r.label.alpha = r.number.alpha = r.value.alpha = on ? 1.0 : 0.75;
	}
	var row = rows[setting];
	descText.text = focus != "cats" && row.kind == "tape" ? t("DESC TAPE") : t(DESCRIPTIONS[category]);
}

// ---------------------------------------------------------------- input

function close2() {
	Options.save();
	Options.applySettings();
	FlxG.save.flush();
	close();
}

function update(elapsed) {
	if (focus == "capturing") {
		updateCapture();
		return;
	}
	updateMouse();
	var rows = ROWS[category];
	if (focus == "cats") {
		if (controls.UP_P || controls.DOWN_P) {
			category = (category + (controls.UP_P ? CATEGORIES.length - 1 : 1)) % CATEGORIES.length;
			setting = 0;
			FlxG.sound.play(Paths.sound("menu/scroll"), 0.5);
			refreshTexts();
		}
		if (controls.RIGHT_P || controls.ACCEPT) {
			focus = "rows";
			setting = 0;
			refreshTexts();
		} else if (controls.BACK) close2();
		return;
	}
	if (controls.UP_P || controls.DOWN_P) {
		setting = (setting + (controls.UP_P ? rows.length - 1 : 1)) % rows.length;
		FlxG.sound.play(Paths.sound("menu/scroll"), 0.5);
		refreshTexts();
	}
	var row = rows[setting];
	if (isSlider(row) && (controls.LEFT_P || controls.RIGHT_P)) {
		setSlider(row, sliderValue(row) + (controls.LEFT_P ? -0.1 : 0.1));
		FlxG.sound.play(Paths.sound("menu/scroll"), 0.4);
		refreshTexts();
	} else if (controls.LEFT_P || controls.BACK) {
		focus = "cats";
		refreshTexts();
	} else if (controls.ACCEPT) activate();
}

function updateMouse() {
	var mx = FlxG.mouse.screenX;
	var my = FlxG.mouse.screenY;
	var moved = mx != lastMouseX || my != lastMouseY;
	lastMouseX = mx;
	lastMouseY = my;
	var line = Std.int((my - (Y + 44)) / ROW_H);
	if (my < Y + 44 || line < 0) return;
	if (mx >= X && mx < X + CAT_W && line < CATEGORIES.length) {
		if (moved && (line != category || focus != "cats")) {
			category = line;
			setting = 0;
			focus = "cats";
			refreshTexts();
		}
		if (FlxG.mouse.justPressed) {
			focus = "rows";
			refreshTexts();
		}
	} else if (mx >= SET_X && mx < SET_X + SET_W && line < ROWS[category].length) {
		if (moved && (line != setting || focus != "rows")) {
			setting = line;
			focus = "rows";
			refreshTexts();
		}
		if (FlxG.mouse.justPressed) {
			var row = ROWS[category][setting];
			if (isSlider(row)) {
				setSlider(row, sliderValue(row) + (mx > SET_X + SET_W - 140 ? 0.1 : -0.1));
				refreshTexts();
			} else activate();
		}
	}
}

function destroy() {
	FlxG.cameras.remove(cam);
}
