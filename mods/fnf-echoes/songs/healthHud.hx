import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxRect;

// Zyra's HUD (BE-51), for every song: the drawing images/game/hud/skin.png (600x600, transparent) is only a SKIN on top; under it there
// is a plain fill that does the work. Same canvas for all four images, so they are stacked at the same place:
//   fill_health.png  crimson/wine rectangle in the horizontal bar's groove (x 100..378, y 474..518 of the canvas: it starts under Zyra's head); it is clipped from the left (the head)
//                    to the right according to the health, with a smooth movement;
//   fill_trail.png   the same rectangle in a lighter rose, behind it: when the health drops it stays a moment and then drains away slowly (the
//                    "drain" that shows how much you just lost);
//   fill_sanity.png  the vertical frame's pocket, painted green from the bottom up. Nothing lowers it yet: other scripts change it with
//                    scripts.call("setSanity", [0..1]) when its mechanic exists.
// The engine's own health bar and icons are hidden. The HUD sits in the bottom-left corner of the HUD camera, BELOW the arrows.
// The layout numbers are variables to tune by eye.

var HUD_SCALE = 0.8;
var HUD_X = -4.0;          // the drawing starts 5 px inside its canvas (x 5 * scale): this leaves it flush with the screen's left edge
var HUD_Y = 245.0;         // the drawing ends at canvas y 584: 245 + 584 * 0.8 = 712 on a 720 px screen
// x0 = where the fill image starts (it goes under Zyra's head), vis = where the groove becomes visible, right after the head: 0 % is empty there.
var HEALTH_BOX = {x0: 100, vis: 152, x1: 378, y0: 474, y1: 518};
var SANITY_Y0 = 222;
var SANITY_Y1 = 447;
var DRAIN_HOLD = 0.35;     // seconds the trail waits before draining
var DRAIN_SPEED = 2.2;

var skin = null;
var fillHealth = null;
var trail = null;
var fillSanity = null;
var shown = 1.0;
var trailFrac = 1.0;
var lastTarget = 1.0;
var hold = 0.0;
var sanity = 1.0;
var sanityShown = 1.0;

function makeSprite(name) {
	var spr = new FlxSprite(HUD_X, HUD_Y);
	spr.loadGraphic(Paths.image('game/hud/' + name));
	spr.origin.set(0, 0);
	spr.scale.set(HUD_SCALE, HUD_SCALE);
	spr.antialiasing = true;
	spr.scrollFactor.set();
	spr.cameras = [camHUD];
	insert(members.indexOf(strumLines), spr); // below the arrows, above the stage
	return spr;
}

function postCreate() {
	healthBarBG.visible = false;
	healthBar.visible = false;
	iconP1.visible = false;
	iconP2.visible = false;
	trail = makeSprite('fill_trail');
	fillHealth = makeSprite('fill_health');
	fillSanity = makeSprite('fill_sanity');
	skin = makeSprite('skin');
	shown = trailFrac = lastTarget = FlxMath.bound(health / maxHealth, 0, 1);
}

// Other scripts set the sanity (0 to 1) with scripts.call("setSanity", [value]).
function setSanity(value) {
	sanity = FlxMath.bound(value, 0, 1);
}

function postUpdate(elapsed) {
	if (skin == null) return;
	var target = FlxMath.bound(health / maxHealth, 0, 1);
	if (target < lastTarget) hold = DRAIN_HOLD;
	lastTarget = target;
	shown += (target - shown) * Math.min(1, elapsed * 12);
	if (target >= trailFrac) {
		trailFrac = target;
	} else {
		hold -= elapsed;
		if (hold <= 0)
			trailFrac += (target - trailFrac) * Math.min(1, elapsed * DRAIN_SPEED);
	}
	var under = HEALTH_BOX.vis - HEALTH_BOX.x0;           // the part of the fill that stays hidden under the head
	var w = HEALTH_BOX.x1 - HEALTH_BOX.vis + 1;
	var h = HEALTH_BOX.y1 - HEALTH_BOX.y0 + 1;
	fillHealth.clipRect = new FlxRect(HEALTH_BOX.x0, HEALTH_BOX.y0, under + Math.max(1, w * shown), h);
	trail.clipRect = new FlxRect(HEALTH_BOX.x0, HEALTH_BOX.y0, under + Math.max(1, w * trailFrac), h);

	sanityShown += (sanity - sanityShown) * Math.min(1, elapsed * 8);
	var sh = SANITY_Y1 - SANITY_Y0 + 1;
	var top = SANITY_Y1 - sh * sanityShown;
	fillSanity.clipRect = new FlxRect(0, top, 600, Math.max(1, SANITY_Y1 - top + 1));
}
