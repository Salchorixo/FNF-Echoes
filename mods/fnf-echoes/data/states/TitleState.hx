import flixel.FlxSprite;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import funkin.backend.scripting.Script;
import funkin.menus.MainMenuState;

// Placeholder for the real animated eye sprites (to be swapped in later).
// Two halves sharing one rectangle graphic, each showing only its own side via
// clipRect — this is what lets them visually "split" when pulled apart.
var eyeLeft:FlxSprite;
var eyeRight:FlxSprite;
var eyeWidth:Int = 220;
var eyeHeight:Int = 360;

// Two-stage split: a small crack first, then a wider pull-apart.
var fractureGap:Float = 14;
var separateDistance:Float = 90;

// Stand-in for real window transparency (see ADR-0003: not available yet on this
// engine build). Flashes behind the eye to sell the glitch without hiding it.
// Capped at glitchMaxDuration regardless of how long fracture/separate take.
//
// The eye always inverts against the flash — black eye on the white flash,
// white eye on the normal black background. Done here via a color tint
// (setGlitchFrame) since it's still a placeholder rectangle; the real
// version will swap between two separate animated sprite sequences (a
// black-eye take and a white-eye take) on every flash toggle instead —
// setGlitchFrame is the one place that decision plugs into later.
var glitchFlash:FlxSprite;
// Pairs are (black hold, white flash) — flashes stay short (1-3 frames) so
// the white never sits long enough to read as a held cut, only a flicker.
var glitchFrameCounts:Array<Int> = [10, 2, 4, 1, 16, 3, 6, 1, 20, 2, 8, 1, 5, 3];
var glitchStep:Int = 0;
var glitchFrameTimer:Int = 0;
var glitchActive:Bool = false;
var glitchMaxDuration:Float = 2.0;

var pressKeyText:FlxText;
var phase:String = "idle";

function create() {
	bgColor = FlxColor.BLACK;

	FlxG.fullscreen = true;

	var vhsFx = Script.create(Paths.script('scripts/effects/vhsShader'));
	vhsFx.load();
	vhsFx.call('attach');

	glitchFlash = new FlxSprite(0, 0);
	glitchFlash.makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
	glitchFlash.visible = false;
	add(glitchFlash);

	var halfWidth = Std.int(eyeWidth / 2);

	eyeLeft = new FlxSprite();
	eyeLeft.makeGraphic(eyeWidth, eyeHeight, FlxColor.WHITE, true, "echoesEyePlaceholder");
	eyeLeft.clipRect = new FlxRect(0, 0, halfWidth, eyeHeight);
	eyeLeft.screenCenter();
	eyeLeft.alpha = 0;

	eyeRight = new FlxSprite();
	eyeRight.makeGraphic(eyeWidth, eyeHeight, FlxColor.WHITE, true, "echoesEyePlaceholder");
	eyeRight.clipRect = new FlxRect(halfWidth, 0, halfWidth, eyeHeight);
	eyeRight.screenCenter();
	eyeRight.alpha = 0;

	add(eyeLeft);
	add(eyeRight);

	pressKeyText = new FlxText(0, 0, FlxG.width, "PRESS ANY KEY TO CONTINUE");
	pressKeyText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, "center");
	pressKeyText.y = FlxG.height * 0.8;
	pressKeyText.alpha = 0;
	add(pressKeyText);

	phase = "appearing";
	FlxTween.tween(eyeLeft, {alpha: 1}, 0.6);
	FlxTween.tween(eyeRight, {alpha: 1}, 0.6, {onComplete: (_) -> holdEye()});
}

function holdEye() {
	phase = "holding";
	new FlxTimer().start(2.0, (_) -> startFracture());
}

function startFracture() {
	phase = "fracturing";
	glitchActive = true;
	glitchStep = 0;
	glitchFrameTimer = 0;
	new FlxTimer().start(glitchMaxDuration, (_) -> stopGlitch());

	FlxTween.tween(eyeLeft, {x: eyeLeft.x - fractureGap}, 1.4, {ease: FlxEase.quadInOut});
	FlxTween.tween(eyeRight, {x: eyeRight.x + fractureGap}, 1.4, {ease: FlxEase.quadInOut, onComplete: (_) -> startSeparate()});
}

function stopGlitch() {
	glitchActive = false;
	setGlitchFrame(false);
}

function setGlitchFrame(flashVisible:Bool) {
	glitchFlash.visible = flashVisible;
	var eyeColor = flashVisible ? FlxColor.BLACK : FlxColor.WHITE;
	eyeLeft.color = eyeColor;
	eyeRight.color = eyeColor;
}

function startSeparate() {
	phase = "separating";
	FlxTween.tween(eyeLeft, {x: eyeLeft.x - separateDistance}, 1.4, {ease: FlxEase.quadIn});
	FlxTween.tween(eyeRight, {x: eyeRight.x + separateDistance}, 1.4, {ease: FlxEase.quadIn, onComplete: (_) -> startFadeOut()});
}

function startFadeOut() {
	phase = "fading";
	stopGlitch();

	FlxTween.tween(eyeLeft, {alpha: 0}, 1.2);
	FlxTween.tween(eyeRight, {alpha: 0}, 1.2, {onComplete: (_) -> new FlxTimer().start(2.0, (_) -> showPrompt())});
}

function showPrompt() {
	phase = "settled";
	FlxTween.tween(pressKeyText, {alpha: 1}, 0.6);
}

function update(elapsed) {
	if (glitchActive) {
		glitchFrameTimer++;
		if (glitchFrameTimer >= glitchFrameCounts[glitchStep % glitchFrameCounts.length]) {
			glitchFrameTimer = 0;
			glitchStep++;
			setGlitchFrame(!glitchFlash.visible);
		}
	}

	if (phase == "settled" && FlxG.keys.justPressed.ANY)
		FlxG.switchState(new MainMenuState());
}
