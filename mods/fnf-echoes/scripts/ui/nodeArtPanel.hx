import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

// Right-side art preview panel, shared via Script.create() by any map/select
// screen that needs it. First reveal (create) slides in from fully
// off-screen; later changes (showArt) crossfade the incoming art in over
// the outgoing one instead of cutting to blank first. A dim overlay darkens
// the art whenever the node it represents isn't unlocked yet.
//
// Real art will eventually be an animated sprite sequence per node —
// buildLayerGraphic() is the one place that builds a layer's sprite, so
// swapping this placeholder color fill for a real loadGraphic() +
// animation later is a one-function change, not a rewrite of the
// slide/crossfade/dim behavior around it.
var backLayer:FlxSprite;
var frontLayer:FlxSprite;
var dimOverlay:FlxSprite;
var panelWidth:Float;
var restingX:Float;
var currentIndex:Int = -1;
var currentUnlocked:Bool = true;

var placeholderColors:Array<FlxColor> = [0xFF8A7A5C, 0xFFB09A72, 0xFF5C5044, 0xFFD8C7A1];

function create(widthRatio:Float = 0.4) {
	panelWidth = FlxG.width * widthRatio;
	restingX = FlxG.width - panelWidth;

	backLayer = new FlxSprite(FlxG.width, 0);
	state.add(backLayer);

	frontLayer = new FlxSprite(FlxG.width, 0);
	frontLayer.alpha = 0;
	state.add(frontLayer);

	dimOverlay = new FlxSprite(FlxG.width, 0);
	dimOverlay.makeGraphic(Std.int(panelWidth), FlxG.height, FlxColor.BLACK, true, "echoesMapArtDim");
	dimOverlay.alpha = 0;
	state.add(dimOverlay);

	buildLayerGraphic(backLayer, 0);
	buildLayerGraphic(frontLayer, 0);
	currentIndex = 0;

	new FlxTimer().start(0.5, (_) -> {
		for (layer in [backLayer, frontLayer, dimOverlay])
			FlxTween.tween(layer, {x: restingX}, 0.6, {ease: FlxEase.quadOut});
	});
}

function buildLayerGraphic(layer:FlxSprite, index:Int) {
	// No cache key: these are cheap synthetic fills, not real loaded assets,
	// and backLayer/frontLayer starting on the same index would otherwise
	// request the same cached graphic and end up sharing it under the hood.
	var color = placeholderColors[index % placeholderColors.length];
	layer.makeGraphic(Std.int(panelWidth), FlxG.height, color);
}

function showArt(index:Int, unlocked:Bool = true) {
	// Dim only animates when the lock state actually flips between the
	// previous node and this one — unlocked-to-unlocked does nothing (both
	// already at no dim), locked-to-locked does nothing either (already
	// dimmed, no need to replay it).
	var lockStateChanged = unlocked != currentUnlocked;
	currentUnlocked = unlocked;
	if (lockStateChanged)
		applyDim(unlocked);

	if (index == currentIndex)
		return;

	currentIndex = index;
	buildLayerGraphic(frontLayer, index);
	frontLayer.alpha = 0;

	// Copied to a local var: HScript closures don't reliably capture
	// function *parameters* (confirmed error — "Unknown variable: index"
	// inside this same onComplete closure when referencing the parameter
	// directly), only locals declared with var.
	var settledIndex = index;

	FlxTween.cancelTweensOf(frontLayer);
	FlxTween.tween(frontLayer, {alpha: 1}, 0.35, {
		onComplete: (_) -> {
			buildLayerGraphic(backLayer, settledIndex);
			frontLayer.alpha = 0;
		}
	});
}

// Runs alongside the art crossfade (same duration), not after it — dimming
// in or out is meant to read as part of the same motion as the art change.
function applyDim(unlocked:Bool) {
	FlxTween.cancelTweensOf(dimOverlay);
	FlxTween.tween(dimOverlay, {alpha: unlocked ? 0 : 0.55}, 0.35);
}
