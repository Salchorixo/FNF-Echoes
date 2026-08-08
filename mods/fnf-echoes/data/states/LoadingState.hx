import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.backend.scripting.ModState;
import funkin.backend.scripting.Script;

// Loading screen shown between selecting a song and starting to play it.
// Static eye placeholder (no animation yet — that's for the real animated
// sprites later) + "LOADING" text + a progress-bar placeholder (visual
// only, not tracking real asset progress).
//
// Which eye sprite sequence shows is content, not code: it comes in via
// data.eyeVariant from whatever confirmed the song (e.g. "zyraEye" for the
// default protagonist, "kiyuEye" for songs centered on her partner), same
// with the state to land on afterwards (data.nextState). Both default
// sensibly so this state also works if invoked without extra data.
var eyeWidth:Int = 180;
var eyeHeight:Int = 120;

var barWidth:Int = 300;
var barHeight:Int = 20;
var barFillRatio:Float = 0.45;

function create() {
	bgColor = FlxColor.BLACK;

	var vhsFx = Script.create(Paths.script('scripts/effects/vhsShader'));
	vhsFx.load();
	vhsFx.call('attach');

	var eyeVariant:String = (data != null && data.eyeVariant != null) ? data.eyeVariant : "zyraEye";
	var nextState:String = (data != null && data.nextState != null) ? data.nextState : "StoryMapState";

	var eye = new FlxSprite();
	eye.makeGraphic(eyeWidth, eyeHeight, FlxColor.WHITE, true, 'echoesLoadingEye_$eyeVariant');
	eye.screenCenter(FlxAxes.X);
	eye.y = FlxG.height * 0.3;
	add(eye);

	var loadingText = new FlxText(0, 0, FlxG.width, "LOADING");
	loadingText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, "center");
	loadingText.y = eye.y + eyeHeight + 30;
	add(loadingText);

	var barX = (FlxG.width - barWidth) / 2;
	var barY = loadingText.y + 50;
	var barBorder:Int = 2;

	var barOutline = new FlxSprite(barX, barY);
	barOutline.makeGraphic(barWidth, barHeight, FlxColor.WHITE);
	add(barOutline);

	var barBackground = new FlxSprite(barX + barBorder, barY + barBorder);
	barBackground.makeGraphic(barWidth - (barBorder * 2), barHeight - (barBorder * 2), FlxColor.BLACK);
	add(barBackground);

	var barFill = new FlxSprite(barX + barBorder, barY + barBorder);
	barFill.makeGraphic(Std.int((barWidth - (barBorder * 2)) * barFillRatio), barHeight - (barBorder * 2), FlxColor.WHITE);
	add(barFill);

	new FlxTimer().start(1.6, (_) -> FlxG.switchState(new ModState(nextState)));
}
