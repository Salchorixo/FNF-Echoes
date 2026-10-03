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
import funkin.menus.MainMenuState;
import funkin.options.Options;

// Custom Options screen (replaces the native OptionsMenu). A vertical
// category strip (Controls/Language/Gameplay) on the left, a detail panel
// for whichever category is open on the right, over a dim circular
// CRT-style glow. Only the category strip carousels (selected item stays
// vertically centered, the rest slide around it) — panel rows are a plain
// top-anchored list, deliberately not given the same treatment.
//
// Controls rows are data-driven on purpose: adding a future keybindable
// mechanic later is just appending to controlsRows, not touching the
// render/navigation logic. Gameplay rows aren't given the same treatment —
// only 3 known Options fields are exposed and no extensibility was asked
// for that category.
var controlsRows:Array<Dynamic> = [
	{label: "UP", kind: "keybind", controlName: "P1_UP"},
	{label: "DOWN", kind: "keybind", controlName: "P1_DOWN"},
	{label: "LEFT", kind: "keybind", controlName: "P1_LEFT"},
	{label: "RIGHT", kind: "keybind", controlName: "P1_RIGHT"}
];

var gameplayRows:Array<Dynamic> = [
	{label: "SCREEN QUALITY", kind: "quality"},
	{label: "DOWNSCROLL", kind: "bool", fieldName: "downscroll"},
	{label: "GHOST TAPPING", kind: "bool", fieldName: "ghostTapping"}
];

// Language names stay in their own language always (standard convention —
// "ENGLISH"/"ESPAÑOL" don't get translated relative to the current UI
// language). Everything else this screen shows goes through t(key) below,
// which is what makes picking a language actually change what's on screen,
// not just flip a saved setting nothing visibly reacts to.
var languageCodes:Array<String> = ["en", "es"];
var languageLabels:Array<String> = ["ENGLISH", "ESPAÑOL"];

var i18n:Script;

function t(key:String):String {
	return i18n.call("get", [key]);
}

var categoryLabels:Array<String> = ["CONTROLS", "LANGUAGE", "GAMEPLAY"];
var categoryTexts:Array<FlxText> = [];

// "strip" = browsing categories, "panel" = browsing the open category's
// rows, "capturing" = waiting for a new key to rebind a Controls row.
var focusMode:String = "strip";
var categoryIndex:Int = 0;
var rowIndex:Int = 0;

var panelRowLabels:Array<FlxText> = [];
var panelRowValues:Array<FlxText> = [];

var capturingStillPressed:Bool = false;

// Ignores the ACCEPT press that opened this state from MainMenuState's own
// "OPTIONS" card, same guard EchoSelectState.hx uses for the same reason.
var canConfirm:Bool = false;

// Strip + panel are treated as one content block and centered together on
// screen, instead of anchoring near the left edge — the category strip sits
// at the left edge of that centered block, panel content to its right. All
// of this is computed in create(), not here, since FlxG dimensions aren't
// reliably available at module-level var initialization.
var stripWidth:Float = 220;
var panelWidth:Float = 300;
var contentGap:Float = 80;
var stripX:Float = 0;
var panelX:Float = 0;
var carouselCenterY:Float = 0;
var stripRowHeight:Float = 70;
var panelRowHeight:Float = 50;
var panelTopY:Float = 120;

function create() {
	bgColor = FlxColor.BLACK;

	// The card menus pan the camera slightly on selection (see cardMenu.hx)
	// — reset here so this screen never inherits a leftover shift from them.
	FlxG.camera.scroll.set(0, 0);

	var contentX = (FlxG.width - (stripWidth + contentGap + panelWidth)) / 2;
	stripX = contentX;
	panelX = contentX + stripWidth + contentGap;
	carouselCenterY = FlxG.height / 2;

	var vhsFx = Script.create(Paths.script('scripts/effects/vhsShader'));
	vhsFx.load();
	vhsFx.call('attach');

	i18n = Script.create(Paths.script('scripts/ui/translate'));
	i18n.load();

	add(buildBackgroundGlow());
	buildCategoryStrip();
	refreshStripHighlight();

	new FlxTimer().start(0.2, (_) -> canConfirm = true);
}

function buildBackgroundGlow():FlxSprite {
	var size = 128;
	var glow = new FlxSprite();
	glow.makeGraphic(size, size, FlxColor.TRANSPARENT, true, "echoesOptionsGlow");

	var center = size / 2;

	for (y in 0...size) {
		for (x in 0...size) {
			var dx = x - center;
			var dy = y - center;
			var dist = Math.sqrt(dx * dx + dy * dy) / center;
			var falloff = 1 - Math.min(dist, 1);
			var alpha = Std.int(55 * falloff * falloff);
			glow.pixels.setPixel32(x, y, FlxColor.fromRGB(216, 199, 161, alpha));
		}
	}
	glow.dirty = true;

	glow.antialiasing = true;
	glow.scale.set((FlxG.width / size) * 1.4, (FlxG.height / size) * 1.4);
	glow.updateHitbox();
	glow.screenCenter();
	glow.scrollFactor.set();

	return glow;
}

// Carousel positioning — category strip only. The selected category stays
// vertically centered on screen; the others slide to their place around it.
function stripCarouselY(indexInList:Int):Float {
	return carouselCenterY + ((indexInList - categoryIndex) * stripRowHeight);
}

function buildCategoryStrip() {
	for (i in 0...categoryLabels.length) {
		var label = new FlxText(stripX, stripCarouselY(i) - 12, stripWidth, "");
		label.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, "left");
		add(label);
		categoryTexts.push(label);
	}
	refreshCategoryText();
}

function refreshCategoryText() {
	for (i in 0...categoryTexts.length)
		categoryTexts[i].text = t(categoryLabels[i]);
}

function refreshStripHighlight() {
	for (i in 0...categoryTexts.length) {
		var isSelected = i == categoryIndex;
		var color = 0xFF8A7A5C;
		if (isSelected)
			color = focusMode == "strip" ? 0xFFFFFFFF : 0xFFD8C7A1;
		categoryTexts[i].color = color;

		var targetScale = isSelected ? 1.15 : 1.0;
		FlxTween.cancelTweensOf(categoryTexts[i].scale);
		FlxTween.tween(categoryTexts[i].scale, {x: targetScale, y: targetScale}, 0.2);
	}
}

function repositionStrip() {
	for (i in 0...categoryTexts.length) {
		FlxTween.cancelTweensOf(categoryTexts[i]);
		FlxTween.tween(categoryTexts[i], {y: stripCarouselY(i) - 12}, 0.25, {ease: FlxEase.quadOut});
	}
}

function changeCategory(delta:Int) {
	var newIndex = categoryIndex + delta;
	if (newIndex < 0 || newIndex >= categoryLabels.length)
		return;

	categoryIndex = newIndex;
	repositionStrip();
	refreshStripHighlight();
}

function currentRows():Array<Dynamic> {
	return switch (categoryIndex) {
		case 0: controlsRows;
		case 2: gameplayRows;
		default: [];
	}
}

function enterPanel() {
	focusMode = "panel";
	rowIndex = 0;
	refreshStripHighlight();
	buildPanelRows();
}

function exitToStrip() {
	focusMode = "strip";
	clearPanelRows();
	refreshStripHighlight();
}

function buildPanelRows() {
	clearPanelRows();

	if (categoryIndex == 1) {
		addPanelRow(0, "LANGUAGE", languageLabels[languageCodes.indexOf(Options.language)]);
		refreshRowHighlight();
		return;
	}

	var rows = currentRows();
	for (i in 0...rows.length)
		addPanelRow(i, rows[i].label, rowValueText(rows[i]));

	refreshRowHighlight();
}

// Plain top-anchored list — no carousel here, unlike the category strip.
function addPanelRow(i:Int, labelKey:String, value:String) {
	var rowY = panelTopY + (i * panelRowHeight);

	var labelText = new FlxText(panelX, rowY, panelWidth, t(labelKey));
	labelText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, "left");
	add(labelText);
	panelRowLabels.push(labelText);

	var valueText = new FlxText(panelX, rowY + 24, panelWidth, value);
	valueText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, "left");
	add(valueText);
	panelRowValues.push(valueText);
}

function clearPanelRows() {
	for (label in panelRowLabels) {
		remove(label);
		label.destroy();
	}
	for (value in panelRowValues) {
		remove(value);
		value.destroy();
	}
	panelRowLabels = [];
	panelRowValues = [];
}

function refreshRowHighlight() {
	for (i in 0...panelRowLabels.length) {
		var color = i == rowIndex ? 0xFFFFFFFF : 0xFF8A7A5C;
		panelRowLabels[i].color = color;
		panelRowValues[i].color = color;
	}
}

function rowValueText(row:Dynamic):String {
	return switch (row.kind) {
		case "quality": t(Options.quality == 0 ? "PERFORMANCE" : "HIGH");
		case "bool": t(Reflect.field(Options, row.fieldName) ? "ON" : "OFF");
		case "keybind":
			var keys:Array<FlxKey> = Reflect.field(Options, row.controlName);
			CoolUtil.keyToString(keys[0]);
		default: "";
	}
}

function changeRow(delta:Int) {
	var count = categoryIndex == 1 ? 1 : currentRows().length;
	var newIndex = rowIndex + delta;
	if (newIndex < 0 || newIndex >= count)
		return;

	rowIndex = newIndex;
	refreshRowHighlight();
}

function adjustRow() {
	if (categoryIndex == 1) {
		cycleLanguage();
		return;
	}

	var row = currentRows()[rowIndex];
	// Controls rows don't respond to LEFT/RIGHT — rebinding needs the
	// distinct "start capture" gesture on ACCEPT instead.
	if (row.kind == "keybind")
		return;

	switch (row.kind) {
		case "quality":
			Options.quality = Options.quality == 0 ? 1 : 0;
			Options.applyQuality();
		case "bool":
			Reflect.setField(Options, row.fieldName, !Reflect.field(Options, row.fieldName));
	}

	panelRowValues[rowIndex].text = rowValueText(row);
}

function cycleLanguage() {
	var nextIndex = (languageCodes.indexOf(Options.language) + 1) % languageCodes.length;
	TranslationUtil.setLanguage(languageCodes[nextIndex]);

	// Re-render everything currently on screen in the new language — this
	// is what makes the toggle actually change what you see, not just the
	// saved setting.
	refreshCategoryText();
	buildPanelRows();
}

function confirmRow() {
	if (categoryIndex == 0) {
		beginCapture();
		return;
	}

	adjustRow();
}

function beginCapture() {
	focusMode = "capturing";
	capturingStillPressed = true;
	panelRowValues[rowIndex].text = t("PRESS A KEY...");
}

function updateCapture() {
	if (capturingStillPressed && controls.ACCEPT)
		return;
	capturingStillPressed = false;

	var key:FlxKey = FlxG.keys.firstJustPressed();
	if (cast(key, Int) <= 0)
		return;

	if (key == FlxKey.ESCAPE) {
		focusMode = "panel";
		panelRowValues[rowIndex].text = rowValueText(controlsRows[rowIndex]);
		return;
	}

	var row = controlsRows[rowIndex];
	Reflect.setField(Options, row.controlName, [key]);
	Options.applyKeybinds();

	focusMode = "panel";
	panelRowValues[rowIndex].text = rowValueText(row);
}

function exitToMainMenu() {
	Options.save();
	Options.applySettings();
	FlxG.switchState(new ModState("MainMenuState"));
}

function update(elapsed) {
	if (!canConfirm)
		return;

	switch (focusMode) {
		case "strip": updateStrip();
		case "panel": updatePanel();
		case "capturing": updateCapture();
	}
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
		changeRow(-1);
	else if (controls.DOWN_P)
		changeRow(1);
	else if (controls.LEFT_P || controls.RIGHT_P)
		adjustRow();

	if (controls.ACCEPT)
		confirmRow();

	if (controls.BACK)
		exitToStrip();
}
