import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.backend.scripting.ModState;
import funkin.backend.scripting.Script;

// First map prototype (Fase 5): a fixed sequence of 4 nodes, unlocked one
// at a time as each is confirmed. You can browse every node with LEFT/RIGHT
// (clamped at both ends, no wrap-around), but only the unlocked ones do
// anything on ACCEPT. The map is centered on the whole screen and meant to
// overlap the art panel, not avoid it.
//
// Node data lives here as plain anonymous objects instead of a separate
// "MapNode" class or typedef: mod content can only be HScript, parsed one
// state at a time as a flat expression sequence — it can't declare its own
// top-level types (typedef included, same limitation as "class ... extends"
// per the engine's own scripting docs), and it can't import a custom class
// from another mod file either (only compose via Script.create(), see
// cardMenu.hx). A one-consumer data class here would just be dead weight
// anyway. The art panel IS split out that way, since its slide/fade
// behavior is substantial enough to be worth reusing later.
var nodes:Array<Dynamic> = [
	{x: 400, y: 500, unlocked: true},
	{x: 570, y: 300, unlocked: false},
	{x: 730, y: 480, unlocked: false},
	{x: 880, y: 260, unlocked: false}
];

var nodeBarsH:Array<FlxSprite> = [];
var nodeBarsV:Array<FlxSprite> = [];
var token:FlxSprite;
var artPanel:Script;

// The token always walks the trail one node at a time, even across several
// queued key presses — tokenAtIndex is where it currently sits, targetIndex
// is where navigation wants it to end up. Tweening straight from wherever
// the token happens to be to a non-adjacent targetIndex would cut across
// the trail instead of following it, so movement is chained hop-by-hop
// instead of a single direct tween.
var tokenAtIndex:Int = 0;
var targetIndex:Int = 0;
var isHopping:Bool = false;

function create() {
	bgColor = FlxColor.BLACK;

	artPanel = Script.create(Paths.script('scripts/ui/nodeArtPanel'));
	artPanel.load();
	artPanel.call("create", [0.4]);
	artPanel.call("showArt", [0, nodes[0].unlocked]);

	drawTrail();
	drawNodes();

	token = new FlxSprite();
	token.makeGraphic(20, 20, FlxColor.WHITE, true, "echoesMapToken");
	add(token);
	token.setPosition(nodes[0].x - 10, nodes[0].y - 10);
}

function drawTrail() {
	for (i in 0...nodes.length - 1) {
		var from = nodes[i];
		var to = nodes[i + 1];
		var dx = to.x - from.x;
		var dy = to.y - from.y;
		var length = Math.sqrt(dx * dx + dy * dy);
		var angle = Math.atan2(dy, dx) * 180 / Math.PI;

		var segment = new FlxSprite(from.x, from.y);
		segment.makeGraphic(Std.int(length), 3, 0xFF8A7A5C, true, "echoesMapTrail");
		segment.origin.set(0, 1.5);
		segment.angle = angle;
		add(segment);
	}
}

function drawNodes() {
	for (node in nodes) {
		var horizontal = new FlxSprite(node.x - 8, node.y - 2);
		horizontal.makeGraphic(16, 4, nodeColor(node), true, "echoesMapNodeH");
		add(horizontal);
		nodeBarsH.push(horizontal);

		var vertical = new FlxSprite(node.x - 2, node.y - 8);
		vertical.makeGraphic(4, 16, nodeColor(node), true, "echoesMapNodeV");
		add(vertical);
		nodeBarsV.push(vertical);
	}
}

function nodeColor(node:Dynamic):FlxColor {
	return node.unlocked ? 0xFFD8C7A1 : 0xFF4A4238;
}

function refreshNodeColors() {
	for (i in 0...nodes.length) {
		nodeBarsH[i].color = nodeColor(nodes[i]);
		nodeBarsV[i].color = nodeColor(nodes[i]);
	}
}

function changeSelection(delta:Int) {
	var newTarget = targetIndex + delta;
	if (newTarget < 0 || newTarget >= nodes.length)
		return;

	targetIndex = newTarget;
	artPanel.call("showArt", [targetIndex, nodes[targetIndex].unlocked]);

	if (!isHopping)
		hopTowardTarget();
}

function hopTowardTarget() {
	if (tokenAtIndex == targetIndex) {
		isHopping = false;
		return;
	}

	isHopping = true;
	var step = targetIndex > tokenAtIndex ? 1 : -1;
	var nextIndex = tokenAtIndex + step;
	var node = nodes[nextIndex];

	FlxTween.tween(token, {x: node.x - 10, y: node.y - 10}, 0.18, {
		ease: FlxEase.quadOut,
		onComplete: (_) -> {
			tokenAtIndex = nextIndex;
			hopTowardTarget();
		}
	});
}

function confirmSelection() {
	var node = nodes[targetIndex];
	if (!node.unlocked)
		return;

	if (targetIndex + 1 < nodes.length) {
		nodes[targetIndex + 1].unlocked = true;
		refreshNodeColors();
	}
}

function update(elapsed) {
	if (controls.LEFT_P)
		changeSelection(-1);
	else if (controls.RIGHT_P)
		changeSelection(1);

	if (controls.ACCEPT)
		confirmSelection();

	if (controls.BACK)
		FlxG.switchState(new ModState("EchoSelectState"));
}
