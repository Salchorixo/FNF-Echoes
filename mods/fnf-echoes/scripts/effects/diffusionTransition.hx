import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.backend.scripting.ModState;
import funkin.backend.scripting.Script;
import funkin.options.Options;

// The DIFFUSION transition between menu screens (BE-24, mockup AI_build_transition_diffusion_v5.py). It is the engine's own
// transition script (MusicBeatTransition.script, set by MainMenuState): the engine opens it twice, once in the screen that
// is left (newState != null) and once in the screen that arrives (newState == null), and in both the script draws everything.
// The idea: an AI that "imagines" the next screen. The old screen breaks into noise; a REAL CONSOLE (the console window of the
// current theme: Vista, XP, 98 or Mac) types the commands an image-diffusion model really runs (tokenize the prompt, encode it,
// start from noise with a seed, 20 UNET steps where the noise level SIGMA falls, decode); the new screen comes out of the noise
// in those 20 steps (blocks that get finer); the console switches off like a CRT and a white flash lands. The hint about Zyra:
// the command says --ATTEMPT=2, it prints "ATTEMPT 1 ... FAILED. RETRYING." and ends with "DONE. SECOND TRY, BETTER.".
// Text is always English (Zyra's call). The text of the prompt depends on where we are going (see destOf()).
//
// One timeline for both halves, counted in frames of 20 fps (the stepped look of the mockup): f 0-10 the old screen turns
// into noise, 3-8 the console arrives with a trail of copies (like the dragged windows), 4-11 the command is typed, 17-36 are the
// 20 steps, 36-38 decode and done, 42-45 the console switches off, 45-48 white flash, 49 the end. The LEAVING half plays frames
// 0-17 and then lets the engine switch the state (the noise covers the screen, so the loading is hidden); the ARRIVING half
// continues from frame 17 (the console is rebuilt to look as it was) and plays the rest. If the arriving half starts without a
// leaving half (e.g. after the title screen's normal transition) it starts at frame 3 with the console arriving.
// Art: images/menus/diffusion/ (AI_export_diffusion.py, private art folder): console_<theme>, console_scan, noise_<theme>_<c|m|f>_<n>.
// "Reduce flashes" (Options.flashingMenu off): no shake, no white flash, and the noise does not flicker.
// Screens that are not menus (the song itself) are not handled here: the engine's normal transition runs.

var fps:Float = 20;
var leaveEnd:Int = 17;
var lastFrame:Int = 49;

var active:Bool = false;
var leaving:Bool = false;
var theme:String = "vista";
var soft:Bool = false;
var dest:Dynamic = null;
var time:Float = 0;
var startFrame:Int = 0;
var shownFrame:Int = -1;
var ended:Bool = false;

var frameSpr:FlxSprite;
var scanSpr:FlxSprite;
var ghosts:Array<FlxSprite> = [];
var crtLine:FlxSprite;
var whiteSpr:FlxSprite;
var noiseSprites:Dynamic = {};
var activeNoise:FlxSprite = null;
var elems:Array<Dynamic> = [];
var cw:Float = 13.2;
var frameX:Float = 0;
var frameY:Float = 0;
var consoleW:Float = 1077;
var consoleH:Float = 372;
var baseTextX:Float = 15;

var cmdText:FlxText;
var dotsText:FlxText;
var stepText:FlxText;
var sigmaText:FlxText;
var pctText:FlxText;
var barFill:FlxSprite;
var cols:Array<Int> = [];
var errColor:Int = 0;

// Where are we going (or where did we arrive)? null = not a menu: the engine's own transition runs.
function destOf(state:Dynamic):Dynamic {
	if (Type.getClassName(Type.getClass(state)) != "funkin.backend.scripting.ModState")
		return null;
	var name = ModState.lastName;
	if (name == "EchoSelectState")
		return {name: "ECHO", prompt: "CHOOSE AN ECHO", tokens: 5};
	if (name == "StoryMapState")
		return {name: "SONGS", prompt: "PICK A SONG", tokens: 5};
	if (name == "MainMenuState")
		return {name: "MENU", prompt: "MAIN MENU", tokens: 4};
	if (name == "TitleState")
		return {name: "TITLE", prompt: "TITLE SCREEN", tokens: 4};
	return null;
}

function create(event) {
	leaving = event.newState != null;
	dest = destOf(leaving ? event.newState : FlxG.state);
	if (dest == null)
		return;
	active = true;
	event.cancel(); // we draw everything ourselves; the engine's black swipe does not run

	var themer = Script.create(Paths.script('scripts/ui/themeManager'));
	themer.load();
	theme = themer.call("current");
	soft = !Options.flashingMenu;

	var cameraW = transitionCamera.width;
	var cameraH = transitionCamera.height;
	frameX = Math.round((cameraW - consoleW) / 2);
	frameY = 324;
	baseTextX = (theme == "vista" || theme == "mac") ? 18 : 15;

	if (leaving) {
		startFrame = 0;
	} else {
		startFrame = FlxG.save.data.echoesDiffusion == true ? leaveEnd : 3; // came from the leaving half, or from nothing
		FlxG.save.data.echoesDiffusion = false;
	}

	buildNoise(cameraW, cameraH);
	buildConsole();
	whiteSpr = new FlxSprite();
	whiteSpr.makeGraphic(1, 1, FlxColor.WHITE);
	whiteSpr.setGraphicSize(cameraW, cameraH);
	whiteSpr.updateHitbox();
	whiteSpr.alpha = 0;
	add(whiteSpr);
}

function buildNoise(cameraW:Int, cameraH:Int) {
	for (size in ["c", "m", "f"]) {
		var list = [];
		for (k in 0...3) {
			var spr = new FlxSprite();
			spr.loadGraphic(Paths.image('menus/diffusion/noise_' + theme + '_' + size + '_' + k));
			spr.antialiasing = false;
			spr.setGraphicSize(cameraW, cameraH);
			spr.updateHitbox();
			spr.visible = false;
			add(spr);
			list.push(spr);
		}
		Reflect.setField(noiseSprites, size, list);
	}
}

// Text colours of each theme's console: [text, prompt/ok, number, function name].
function palette():Array<Int> {
	if (theme == "mac")
		return [FlxColor.fromRGB(230, 232, 240), FlxColor.fromRGB(120, 230, 140), FlxColor.fromRGB(255, 200, 100), FlxColor.fromRGB(120, 230, 140)];
	if (theme == "vista")
		return [FlxColor.fromRGB(210, 210, 210), FlxColor.fromRGB(90, 220, 120), FlxColor.fromRGB(240, 210, 90), FlxColor.fromRGB(110, 190, 255)];
	var gray = FlxColor.fromRGB(192, 192, 192);
	return [gray, gray, gray, gray];
}

// One piece of text of the console: row and column in characters, the colour index (0 text, 1 ok, 2 number, 3 function, 4 error)
// and the frame from which it exists. Monospaced font: the column decides the x.
function addText(str:String, row:Int, col:Int, colorIndex:Int, minFrame:Int):FlxText {
	var spr = new FlxText(0, 0, 0, str);
	spr.setFormat(Paths.font("vcr.ttf"), 22, colorIndex == 4 ? errColor : cols[colorIndex], "left");
	spr.antialiasing = false;
	spr.visible = false;
	add(spr);
	elems.push({spr: spr, ox: baseTextX + col * cw - 2, oy: 42 + row * 24 - 3, minF: minFrame});
	return spr;
}

function buildConsole() {
	cols = palette();
	errColor = FlxColor.fromRGB(240, 96, 84);
	var probe = new FlxText(0, 0, 0, "MMMMMMMMMM");
	probe.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, "left");
	cw = probe.textField.textWidth / 10;
	if (cw < 5)
		cw = 13.2;

	for (g in 0...3) {
		var ghost = new FlxSprite();
		ghost.loadGraphic(Paths.image('menus/diffusion/console_' + theme));
		ghost.antialiasing = false;
		ghost.visible = false;
		add(ghost);
		ghosts.push(ghost);
	}
	frameSpr = new FlxSprite();
	frameSpr.loadGraphic(Paths.image('menus/diffusion/console_' + theme));
	frameSpr.antialiasing = false;
	frameSpr.visible = false;
	add(frameSpr);

	var prompt = theme == "mac" ? "ZYRA@ECHO ~ % " : "C:\\ZYRA> ";
	var promptLen = prompt.length;
	addText(prompt, 0, 0, 1, 3);
	cmdText = addText("", 0, promptLen, 0, 3);
	addText("ATTEMPT 1 ... ", 1, 0, 0, 11);
	addText("FAILED", 1, 14, 4, 11);
	addText(". RETRYING.", 1, 20, 0, 11);
	addText("LOADING MODEL ZYRA-2 ", 2, 0, 0, 12);
	dotsText = addText("", 2, 21, 0, 12);
	addText(" [OK]", 2, 29, 1, 14);
	var quoted = '("' + dest.prompt + '") -> ';
	addText("TOKENIZE", 3, 0, 3, 14);
	addText(quoted, 3, 8, 0, 14);
	addText(dest.tokens + " TOKENS", 3, 8 + quoted.length, 2, 14);
	addText("ENCODE", 4, 0, 3, 15);
	addText("(TOKENS) -> ", 4, 6, 0, 15);
	addText("EMB[77,768]", 4, 18, 2, 15);
	addText("LATENT = NOISE", 5, 0, 3, 16);
	addText("(SEED=", 5, 14, 0, 16);
	addText("4821", 5, 20, 2, 16);
	addText(")", 5, 24, 0, 16);
	addText("UNET STEP ", 6, 0, 3, 17);
	stepText = addText("", 6, 10, 2, 17);
	addText(" SIGMA=", 6, 15, 0, 17);
	sigmaText = addText("", 6, 22, 2, 17);
	addText(" CFG=", 6, 27, 0, 17);
	addText("7.5", 6, 32, 2, 17);
	addText("[", 7, 0, 1, 17);
	addText("]", 7, 23, 1, 17);
	pctText = addText("", 7, 25, 2, 17);
	addText("VAE.DECODE", 8, 0, 3, 36);
	addText("(LATENT) -> ", 8, 10, 0, 36);
	addText("1280X720", 8, 22, 2, 36);
	addText("DONE. SECOND TRY, BETTER.", 9, 0, 1, 38);

	barFill = new FlxSprite();
	barFill.makeGraphic(1, 1, cols[1]);
	barFill.visible = false;
	add(barFill);

	scanSpr = new FlxSprite();
	scanSpr.loadGraphic(Paths.image('menus/diffusion/console_scan'));
	scanSpr.antialiasing = false;
	scanSpr.visible = false;
	add(scanSpr);

	crtLine = new FlxSprite();
	crtLine.makeGraphic(1, 1, FlxColor.WHITE);
	crtLine.visible = false;
	add(crtLine);
}

function ease(t:Float):Float {
	t = Math.max(0, Math.min(1, t));
	return t * t * (3 - 2 * t);
}

function twoDigits(n:Int):String {
	return n < 10 ? "0" + n : "" + n;
}

// SIGMA falls exponentially from 14.6 to 0.03 over the 20 steps, as in a real sampler; always 5 characters wide.
function sigmaString(step:Int):String {
	var sigma = 14.6 * Math.pow(0.03 / 14.6, step / 20);
	var hundredths = Math.round(sigma * 100);
	var s = "" + hundredths;
	while (s.length < 3)
		s = "0" + s;
	s = s.substr(0, s.length - 2) + "." + s.substr(s.length - 2);
	while (s.length < 5)
		s = " " + s;
	return s;
}

function consoleOffset(f:Int):Float {
	return f < 9 ? 390 * (1 - ease((f - 3) / 5)) : 0;
}

// Everything that depends on the frame number. Deterministic: it draws the same picture whichever half calls it.
function showFrame(f:Int) {
	var step = Math.max(0, Math.min(20, f - 16));
	var stepInt = Std.int(step);

	// noise: rises over the old screen (0-10), covers (10-16), then falls in 20 steps going from coarse blocks to fine grain
	var alpha = 0.0;
	if (f < 10)
		alpha = Math.min(1, (f + 1) / 10 * 1.1);
	else if (f <= 16)
		alpha = 1;
	else if (f < 37)
		alpha = Math.pow(Math.max(0, 1 - stepInt / 20), 1.6);
	var size = "f";
	if (f > 16 && f < 37)
		size = stepInt <= 6 ? "c" : (stepInt <= 13 ? "m" : "f");
	var variant = soft ? 0 : (f <= 16 ? f % 3 : Std.int(stepInt / 2) % 3);
	var wanted = Reflect.field(noiseSprites, size)[variant];
	if (activeNoise != wanted) {
		if (activeNoise != null)
			activeNoise.visible = false;
		activeNoise = wanted;
	}
	activeNoise.visible = alpha > 0.01;
	activeNoise.alpha = alpha;

	// the console
	var squash = f >= 42 ? (f - 42) / 3 : 0;
	var show = f >= 3 && f < 45;
	var y = frameY + consoleOffset(f);
	var consoleAlpha = stepInt < 10 ? 1.0 : Math.max(0.8, 1 - 0.02 * (stepInt - 10));
	frameSpr.visible = show;
	frameSpr.alpha = consoleAlpha;
	frameSpr.setPosition(frameX, y);
	if (squash > 0) {
		frameSpr.scale.set(1 + 0.06 * squash, Math.max(0.01, Math.pow(1 - ease(squash), 1.4)));
	} else {
		frameSpr.scale.set(1, 1);
	}
	for (g in 0...3) {
		var ff = f - (g + 1);
		var ghost = ghosts[g];
		ghost.visible = show && ff >= 3 && ff < 9 && !soft;
		if (ghost.visible) {
			ghost.setPosition(frameX, frameY + consoleOffset(ff));
			ghost.alpha = 0.16 * (3 - g);
		}
	}

	var typed = Std.int(cmdLength() * Math.min(1, Math.max(0, (f - 4) / 7)));
	cmdText.text = cmdString().substr(0, typed);
	var dots = Std.int(Math.min(8, Math.max(1, (f - 12) * 3)));
	dotsText.text = f >= 12 ? "........".substr(0, dots) : "";
	stepText.text = twoDigits(stepInt) + "/20";
	sigmaText.text = sigmaString(stepInt);
	pctText.text = Std.int(100 * stepInt / 20) + "%";

	var textsVisible = show && squash == 0;
	for (e in elems) {
		var spr = e.spr;
		spr.visible = textsVisible && f >= e.minF && !(e.spr == stepText && stepInt < 1) && !(e.spr == sigmaText && stepInt < 1) && !(e.spr == pctText && stepInt < 1);
		if (spr.visible) {
			spr.setPosition(frameX + e.ox, y + e.oy);
			spr.alpha = consoleAlpha;
		}
	}
	barFill.visible = textsVisible && stepInt >= 1;
	if (barFill.visible) {
		barFill.setGraphicSize(Math.max(1, cw * 22 * stepInt / 20), 14);
		barFill.updateHitbox();
		barFill.setPosition(frameX + baseTextX + cw - 2, y + 42 + 7 * 24 + 4);
		barFill.alpha = consoleAlpha;
	}
	scanSpr.visible = textsVisible;
	scanSpr.setPosition(frameX, y);
	scanSpr.alpha = consoleAlpha;

	// the CRT switches off: a bright line that fades
	crtLine.visible = show && squash > 0.55;
	if (crtLine.visible) {
		var lineW = consoleW * (1 + 0.06 * squash);
		crtLine.setGraphicSize(lineW, 3);
		crtLine.updateHitbox();
		crtLine.setPosition(frameX + consoleW / 2 - lineW / 2, frameY + consoleH / 2 - 1);
		crtLine.alpha = 1 - (squash - 0.55) / 0.45;
	}

	// the white flash when the new screen lands
	whiteSpr.alpha = (!soft && f >= 45 && f <= 48) ? 0.59 * (1 - (f - 45) / 4) : 0;
}

function cmdString():String {
	return "IMAGINE --DEST=" + dest.name + " --ATTEMPT=2";
}

function cmdLength():Int {
	return cmdString().length;
}

// Events that happen once, at a frame.
function frameEvent(f:Int) {
	if (soft)
		return;
	if (leaving && f == 8)
		shakeScreens(0.012, 0.2);
	if (!leaving && f == 45)
		shakeScreens(0.006, 0.12);
}

function shakeScreens(intensity:Float, duration:Float) {
	for (c in FlxG.cameras.list)
		if (c != transitionCamera)
			c.shake(intensity, duration);
}

function update(elapsed:Float) {
	if (!active || ended)
		return;
	time += elapsed;
	var f = startFrame + Std.int(time * fps);
	if (shownFrame < 0)
		shownFrame = startFrame - 1;
	while (shownFrame < f) {
		shownFrame++;
		frameEvent(shownFrame);
	}
	showFrame(shownFrame);

	if ((leaving && shownFrame >= leaveEnd) || (!leaving && shownFrame >= lastFrame)) {
		ended = true;
		finish();
	}
}

// The leaving half hands over to the arriving one (which continues the same console).
function onFinish(event) {
	if (active && leaving)
		FlxG.save.data.echoesDiffusion = true;
}
