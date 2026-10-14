import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import funkin.backend.scripting.ModState;
import funkin.backend.scripting.Script;
import funkin.backend.utils.CoolUtil;
import funkin.backend.utils.TranslationUtil;
import funkin.options.Options;

// Settings screen (BE-15), from Zyra's sketch in the common language of the menus: a floating Windows
// Vista "explorer" window (glass frame, pixel art at 3x, pencil outline) over the main menu. The LEFT pane
// lists five categories (AUDIO, CONTROLS, GAMEPLAY, SCREEN, LANGUAGE); the RIGHT pane shows the open
// category's settings as tiles in two columns (icon + name + control) with a description box under them.
// The window art has NO text (images/menus/options/vista_window.png, from AI_export_settings_vista.py in
// the private art folder): every label is a FlxText drawn on top, so it goes through translate.hx.
// All positions below are absolute screen pixels (native pixel x 3) read from that script.
//
// Navigation: Up/Down move through the categories; Right or Accept goes into the tiles; Arrows move over
// the tile grid (Left from the left column returns to the categories); Accept activates the tile:
// a slider enters "adjust" (Left/Right change it, Accept/Back leave), a key starts a capture, a checkbox or
// the quality toggles, a language selects it. Back goes one level up, then out to the main menu. The
// mouse works too (hover selects, click activates, a click on a slider sets it, the blue orb and the red
// cross go back).
//
// Settings that exist in the engine keep using it: master volume is FlxG.sound.volume, music and effects
// are Options.volumeMusic/volumeSFX, the keys are Options.P1_*, quality/downscroll/ghost tapping are
// Options fields, language goes through TranslationUtil. "Reduce flashes" is Options.flashingMenu inverted.
// "Background changes" and "Desktop effects" are NEW preferences saved in FlxG.save.data
// (echoesBackgroundChanges, echoesDesktopEffects, both on by default): nothing reads them yet, they are for
// the theme system and the final sequence.

// ---------------------------------------------------------------- data

var categoryKeys:Array<String> = ["AUDIO", "CONTROLS", "GAMEPLAY", "SCREEN", "LANGUAGE"];

// Rows are data-driven on purpose: a future setting is one more entry here. artSheet picks the sheet of
// images/menus/options/ (icons: 8 cells, keycaps: 4, badges: 2) and art the cell in it.
var rowsByCategory:Array<Array<Dynamic>> = [
	[
		{label: "VOLUME", kind: "volume", artSheet: "icons", art: 0},
		{label: "MUSIC", kind: "slider", fieldName: "volumeMusic", artSheet: "icons", art: 1},
		{label: "SOUND EFFECTS", kind: "slider", fieldName: "volumeSFX", artSheet: "icons", art: 2}
	],
	[
		{label: "UP", kind: "keybind", controlName: "P1_UP", artSheet: "keycaps", art: 0},
		{label: "DOWN", kind: "keybind", controlName: "P1_DOWN", artSheet: "keycaps", art: 1},
		{label: "LEFT", kind: "keybind", controlName: "P1_LEFT", artSheet: "keycaps", art: 2},
		{label: "RIGHT", kind: "keybind", controlName: "P1_RIGHT", artSheet: "keycaps", art: 3}
	],
	[
		{label: "SCREEN QUALITY", kind: "quality", artSheet: "icons", art: 3},
		{label: "DOWNSCROLL", kind: "bool", fieldName: "downscroll", artSheet: "icons", art: 4},
		{label: "GHOST TAPPING", kind: "bool", fieldName: "ghostTapping", artSheet: "icons", art: 5}
	],
	[
		{label: "REDUCE FLASHES", kind: "flashes", artSheet: "icons", art: 6},
		{label: "BACKGROUND CHANGES", kind: "pref", fieldName: "echoesBackgroundChanges", artSheet: "icons", art: 7},
		{label: "DESKTOP EFFECTS", kind: "pref", fieldName: "echoesDesktopEffects", artSheet: "icons", art: 7}
	],
	[
		{label: "ENGLISH", kind: "language", code: "en", artSheet: "badges", art: 0},
		{label: "ESPAÑOL", kind: "language", code: "es", artSheet: "badges", art: 1}
	]
];

// Language names stay in their own language always (standard convention).
var languageCodes:Array<String> = ["en", "es"];

var i18n:Script;

function t(key:String):String {
	return i18n.call("get", [key]);
}

// ---------------------------------------------------------------- layout (screen pixels)

var catPillX:Float = 387;
var catPillY:Float = 165;
var catStep:Float = 72;
var catPillW:Float = 309;
var catPillH:Float = 63;
var catLabelX:Float = 456;

var tileX0:Float = 729;
var tileY0:Float = 216;
var tileStepX:Float = 204;
var tileStepY:Float = 162;
var tileW:Float = 192;
var tileH:Float = 150;

var sliderTrackX:Float = 18; // inside a tile
var sliderTrackW:Float = 159;
var sliderKnobW:Float = 21;
var controlY:Float = 98; // inside a tile; 14 more when the name takes two lines

var ink:Int = 0xFF1C3A6E;
var softInk:Int = 0xFF607096;
var accent:Int = 0xFF286EBE;

// ---------------------------------------------------------------- state

// "strip" = browsing categories, "panel" = browsing the tiles, "adjust" = changing a slider,
// "capturing" = waiting for a new key to rebind a Controls tile.
var focusMode:String = "strip";
var categoryIndex:Int = 0;
var tileIndex:Int = 0;

var pillCategory:FlxSprite;
var pillTile:FlxSprite;
var categoryTexts:Array<FlxText> = [];
var titleShadow:FlxText;
var titleText:FlxText;
var addressText:FlxText;
var paneTitle:FlxText;
var detailText:FlxText;
var statusText:FlxText;

// What was built for the open category: every sprite/text (to clear them) and one object per tile.
var tileObjects:Array<Dynamic> = [];
var tiles:Array<Dynamic> = [];

var capturingStillPressed:Bool = false;
var canConfirm:Bool = false;
var lastMouseX:Float = -1;
var lastMouseY:Float = -1;

function create() {
	bgColor = FlxColor.WHITE;
	FlxG.camera.scroll.set(0, 0); // every screen resets its own camera

	i18n = Script.create(Paths.script('scripts/ui/translate'));
	i18n.load();

	var backdrop = new FlxSprite();
	backdrop.loadGraphic(Paths.image('menus/options/vista_backdrop'));
	add(backdrop);

	var window = new FlxSprite();
	window.loadGraphic(Paths.image('menus/options/vista_window'));
	add(window);

	buildChrome();
	buildCategories();
	setCategory(0, false);

	FlxG.mouse.visible = true;
	// Start from where the pointer already is, so a mouse resting on something at entry does not count as hover.
	lastMouseX = FlxG.mouse.screenX;
	lastMouseY = FlxG.mouse.screenY;
	FlxG.camera.fade(FlxColor.WHITE, 0.25, true);
	new FlxTimer().start(0.2, (_) -> canConfirm = true);
}

// ---------------------------------------------------------------- building

function makeText(x:Float, y:Float, width:Float, size:Int, color:Int, align:String):FlxText {
	var text = new FlxText(x, y, width, "");
	text.setFormat(Paths.font("vcr.ttf"), size, color, align);
	add(text);
	return text;
}

// The texts of the window header, the right pane and the bottom bars.
function buildChrome() {
	titleShadow = makeText(395, 74, 300, 24, 0xFF143C78, "left");
	titleText = makeText(393, 71, 300, 24, FlxColor.WHITE, "left");
	titleShadow.text = t("SETTINGS");
	titleText.text = t("SETTINGS");
	addressText = makeText(468, 114, 600, 18, ink, "left");
	paneTitle = makeText(735, 166, 420, 30, accent, "left");
	detailText = makeText(744, 538, 396, 16, ink, "left");
	statusText = makeText(396, 622, 740, 16, softInk, "left");
	statusText.text = t("STATUS HINT");

	pillTile = new FlxSprite();
	pillTile.loadGraphic(Paths.image('menus/options/vista_pill_tile'));
	pillTile.antialiasing = false;
	pillTile.visible = false;
	add(pillTile);
}

function buildCategories() {
	pillCategory = new FlxSprite();
	pillCategory.loadGraphic(Paths.image('menus/options/vista_pill_category'));
	pillCategory.antialiasing = false;
	add(pillCategory);

	// the icons go above the pill (the window art has none: they would be hidden by the selection)
	for (i in 0...categoryKeys.length) {
		var icon = new FlxSprite(396, catPillY + i * catStep + 9);
		icon.loadGraphic(Paths.image('menus/options/vista_cat_icons'), true, 48, 48);
		icon.animation.frameIndex = i;
		icon.antialiasing = false;
		add(icon);

		var label = makeText(catLabelX, catPillY + i * catStep + catPillH / 2 - 17, 230, 28, ink, "left");
		categoryTexts.push(label);
	}
	refreshCategoryText();
}

function refreshCategoryText() {
	for (i in 0...categoryTexts.length)
		categoryTexts[i].text = t(categoryKeys[i]);
}

function tileX(i:Int):Float {
	return tileX0 + tileStepX * (i % 2);
}

function tileY(i:Int):Float {
	return tileY0 + tileStepY * Std.int(i / 2);
}

function track(obj:Dynamic) {
	tileObjects.push(obj);
	return obj;
}

// Builds the tiles of the open category: art, name and control (slider, checkbox, key name, value or radio).
function buildTiles() {
	clearTiles();
	var rows = rowsByCategory[categoryIndex];

	for (i in 0...rows.length) {
		var row = rows[i];
		var x = tileX(i);
		var y = tileY(i);
		var tile = {row: row, x: x, y: y, valueText: null, check: null, knob: null};

		var art = new FlxSprite();
		var cellW = row.artSheet == "keycaps" ? 66 : 48;
		var cellH = row.artSheet == "keycaps" ? 54 : 48;
		art.loadGraphic(Paths.image('menus/options/vista_' + row.artSheet), true, cellW, cellH);
		art.animation.frameIndex = row.art;
		art.antialiasing = false;
		art.setPosition(x + (tileW - cellW) / 2, y + (row.artSheet == "keycaps" ? 9 : 15));
		add(art);
		track(art);

		var name = makeText(x + 6, y + 64, tileW - 12, 19, ink, "center");
		name.text = row.kind == "language" ? row.label : t(row.label);
		track(name);
		var controlTop = name.height > 30 ? controlY + 14 : controlY; // a two-line name pushes the control down

		if (row.kind == "volume" || row.kind == "slider") {
			var groove = new FlxSprite(x + sliderTrackX, y + controlTop);
			groove.loadGraphic(Paths.image('menus/options/vista_slider_track'));
			groove.antialiasing = false;
			add(groove);
			track(groove);
			var knob = new FlxSprite(x + sliderTrackX, y + controlTop);
			knob.loadGraphic(Paths.image('menus/options/vista_slider_knob'));
			knob.antialiasing = false;
			add(knob);
			track(knob);
			tile.knob = knob;
		} else if (row.kind == "bool" || row.kind == "flashes" || row.kind == "pref") {
			var box = new FlxSprite(x + 42, y + controlTop);
			box.loadGraphic(Paths.image('menus/options/vista_checkbox'), true, 33, 33);
			box.antialiasing = false;
			add(box);
			track(box);
			tile.check = box;
			tile.valueText = track(makeText(x + 84, y + controlTop + 6, 90, 18, ink, "left"));
		} else if (row.kind == "language") {
			var radio = new FlxSprite(x + (tileW - 33) / 2, y + controlTop);
			radio.loadGraphic(Paths.image('menus/options/vista_radio'), true, 33, 33);
			radio.antialiasing = false;
			add(radio);
			track(radio);
			tile.check = radio;
		} else {
			// keybind and quality: a line of text under the name
			tile.valueText = track(makeText(x + 6, y + controlTop + 6, tileW - 12, 18, row.kind == "keybind" ? softInk : accent, "center"));
		}

		tiles.push(tile);
		refreshTile(i);
	}
}

function clearTiles() {
	for (obj in tileObjects) {
		remove(obj);
		obj.destroy();
	}
	tileObjects = [];
	tiles = [];
}

// ---------------------------------------------------------------- values

function sliderValue(row:Dynamic):Float {
	if (row.kind == "volume")
		return FlxG.sound.volume;
	return Reflect.field(Options, row.fieldName);
}

function setSlider(row:Dynamic, value:Float) {
	var v = Math.round(Math.max(0, Math.min(1, value)) * 10) / 10;
	if (row.kind == "volume") {
		FlxG.sound.volume = v;
	} else {
		Reflect.setField(Options, row.fieldName, v);
		Options.applySettings(); // the music volume is heard at once
	}
}

function boolValue(row:Dynamic):Bool {
	if (row.kind == "flashes")
		return !Options.flashingMenu;
	if (row.kind == "pref") {
		var value = Reflect.field(FlxG.save.data, row.fieldName);
		return value == null ? true : value;
	}
	return Reflect.field(Options, row.fieldName);
}

function toggleBool(row:Dynamic) {
	var now = !boolValue(row);
	if (row.kind == "flashes")
		Options.flashingMenu = !now;
	else if (row.kind == "pref")
		Reflect.setField(FlxG.save.data, row.fieldName, now);
	else
		Reflect.setField(Options, row.fieldName, now);
}

function keyName(row:Dynamic):String {
	var keys:Array<FlxKey> = Reflect.field(Options, row.controlName);
	return CoolUtil.keyToString(keys[0]);
}

// Puts a tile's control in the state of the current value.
function refreshTile(i:Int) {
	var tile = tiles[i];
	var row = tile.row;

	if (row.kind == "volume" || row.kind == "slider") {
		tile.knob.x = tile.x + sliderTrackX + sliderValue(row) * (sliderTrackW - sliderKnobW);
	} else if (row.kind == "bool" || row.kind == "flashes" || row.kind == "pref") {
		var on = boolValue(row);
		tile.check.animation.frameIndex = on ? 1 : 0;
		tile.valueText.text = t(on ? "ON" : "OFF");
	} else if (row.kind == "language") {
		tile.check.animation.frameIndex = Options.language == row.code ? 1 : 0;
	} else if (row.kind == "quality") {
		tile.valueText.text = t(Options.quality == 0 ? "PERFORMANCE" : "HIGH");
	} else if (row.kind == "keybind") {
		tile.valueText.text = keyName(row);
	}
}

// ---------------------------------------------------------------- selection

function setCategory(index:Int, animate:Bool) {
	categoryIndex = index;
	pillCategory.setPosition(catPillX, catPillY + index * catStep);
	var key = categoryKeys[index];
	paneTitle.text = t(key);
	addressText.text = t("SETTINGS") + " > " + t(key);
	detailText.text = t("DESC " + key);
	buildTiles();
	refreshSelection();
}

// The category pill is always shown (a little faded while the tiles have the focus); the tile pill only
// while a tile is selected.
function refreshSelection() {
	pillCategory.alpha = focusMode == "strip" ? 1 : 0.65;
	pillTile.visible = focusMode != "strip" && tiles.length > 0;
	if (pillTile.visible)
		pillTile.setPosition(tileX(tileIndex), tileY(tileIndex));
}

function changeCategory(delta:Int) {
	var index = categoryIndex + delta;
	if (index < 0 || index >= categoryKeys.length)
		return;
	setCategory(index, true);
}

function enterPanel() {
	focusMode = "panel";
	tileIndex = 0;
	refreshSelection();
}

function exitToStrip() {
	focusMode = "strip";
	refreshSelection();
}

function moveTile(dx:Int, dy:Int) {
	var column = tileIndex % 2;
	if (dx < 0 && column == 0) {
		exitToStrip();
		return;
	}

	var target = tileIndex + dx + dy * 2;
	if (dx != 0 && Std.int(target / 2) != Std.int(tileIndex / 2))
		return; // Right from the right column does not wrap
	if (target < 0 || target >= tiles.length)
		return;

	tileIndex = target;
	refreshSelection();
}

// ---------------------------------------------------------------- activating

// mouseX >= 0 when a click activated the tile (a slider is then set from the position of the pointer).
function activateTile(mouseX:Float) {
	var tile = tiles[tileIndex];
	var row = tile.row;

	if (row.kind == "volume" || row.kind == "slider") {
		if (mouseX >= 0) {
			var from = tile.x + sliderTrackX + sliderKnobW / 2;
			setSlider(row, (mouseX - from) / (sliderTrackW - sliderKnobW));
			refreshTile(tileIndex);
		} else {
			focusMode = "adjust";
		}
	} else if (row.kind == "keybind") {
		beginCapture();
	} else if (row.kind == "quality") {
		Options.quality = Options.quality == 0 ? 1 : 0;
		Options.applyQuality();
		refreshTile(tileIndex);
	} else if (row.kind == "language") {
		selectLanguage(row.code);
	} else {
		toggleBool(row);
		refreshTile(tileIndex);
	}
}

function selectLanguage(code:String) {
	if (Options.language == code)
		return;
	TranslationUtil.setLanguage(code);

	// Re-render everything on screen in the new language: that is what makes the choice visible.
	titleShadow.text = t("SETTINGS");
	titleText.text = t("SETTINGS");
	statusText.text = t("STATUS HINT");
	refreshCategoryText();
	var keep = tileIndex;
	setCategory(categoryIndex, false);
	tileIndex = keep;
	refreshSelection();
}

function beginCapture() {
	focusMode = "capturing";
	capturingStillPressed = true;
	tiles[tileIndex].valueText.text = t("PRESS A KEY...");
}

function updateCapture() {
	if (capturingStillPressed && controls.ACCEPT)
		return;
	capturingStillPressed = false;

	var key:FlxKey = FlxG.keys.firstJustPressed();
	if (cast(key, Int) <= 0)
		return;

	var row = tiles[tileIndex].row;
	if (key != FlxKey.ESCAPE) {
		Reflect.setField(Options, row.controlName, [key]);
		Options.applyKeybinds();
	}

	focusMode = "panel";
	refreshTile(tileIndex);
}

function exitToMainMenu() {
	Options.save();
	Options.applySettings();
	FlxG.save.flush();
	FlxG.switchState(new ModState("MainMenuState"));
}

// ---------------------------------------------------------------- input

function inRect(px:Float, py:Float, x:Float, y:Float, w:Float, h:Float):Bool {
	return px >= x && px < x + w && py >= y && py < y + h;
}

// Hover only counts while the mouse actually moves: a pointer resting on something must not undo what the
// keyboard just selected.
function updateMouse() {
	var mx = FlxG.mouse.screenX;
	var my = FlxG.mouse.screenY;
	var moved = mx != lastMouseX || my != lastMouseY;
	lastMouseX = mx;
	lastMouseY = my;
	var clicked = FlxG.mouse.justPressed;

	// the blue orb (back) and the red cross (close) of the window
	var dx = mx - 408;
	var dy = my - 123;
	if (clicked && (dx * dx + dy * dy <= 24 * 24 || inRect(mx, my, 1092, 66, 60, 36))) {
		exitToMainMenu();
		return;
	}

	for (i in 0...categoryKeys.length) {
		if (inRect(mx, my, catPillX, catPillY + i * catStep, catPillW, catPillH)) {
			if ((moved || clicked) && (i != categoryIndex || focusMode != "strip")) {
				focusMode = "strip";
				setCategory(i, true);
			}
		}
	}

	for (i in 0...tiles.length) {
		if (inRect(mx, my, tileX(i), tileY(i), tileW, tileH)) {
			if (moved && focusMode != "adjust" && (focusMode != "panel" || tileIndex != i)) {
				focusMode = "panel";
				tileIndex = i;
				refreshSelection();
			}
			if (clicked && focusMode != "adjust") {
				focusMode = "panel";
				tileIndex = i;
				refreshSelection();
				activateTile(mx);
			}
		}
	}
}

function update(elapsed) {
	if (!canConfirm)
		return;

	if (focusMode == "capturing") {
		updateCapture();
		return;
	}

	updateMouse();

	if (focusMode == "strip")
		updateStrip();
	else if (focusMode == "adjust")
		updateAdjust();
	else
		updatePanel();
}

function updateStrip() {
	if (controls.UP_P)
		changeCategory(-1);
	else if (controls.DOWN_P)
		changeCategory(1);

	if (controls.RIGHT_P || controls.ACCEPT)
		enterPanel();

	if (controls.BACK)
		exitToMainMenu();
}

function updatePanel() {
	if (controls.UP_P)
		moveTile(0, -1);
	else if (controls.DOWN_P)
		moveTile(0, 1);
	else if (controls.LEFT_P)
		moveTile(-1, 0);
	else if (controls.RIGHT_P)
		moveTile(1, 0);

	if (controls.ACCEPT)
		activateTile(-1);

	if (controls.BACK)
		exitToStrip();
}

function updateAdjust() {
	var row = tiles[tileIndex].row;
	if (controls.LEFT_P || controls.RIGHT_P) {
		setSlider(row, sliderValue(row) + (controls.RIGHT_P ? 0.1 : -0.1));
		refreshTile(tileIndex);
	}

	if (controls.ACCEPT || controls.BACK)
		focusMode = "panel";
}

function destroy() {
	FlxG.mouse.visible = false;
}
