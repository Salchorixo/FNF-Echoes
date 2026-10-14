import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.backend.scripting.ModState;
import funkin.backend.scripting.Script;

// Song selection (the screen after ECHO 1), from Zyra's vertical sketch, on a black background:
//   left   an XP window with the level's mechanic (placeholder content for now),
//   centre a vertical path, bottom to top, with one node per song (SOUL, TARO, KIYU) and Zyra's
//          icon to the right of the node he stands on (placeholder icon: Zyra draws the real one),
//   right  the level art, a flat rectangle for now (the nodeArtPanel script, full height, bleeding
//          to the edge); Zyra makes the real art.
// All pixel art comes from AI_build_song_select.py (private art folder) at native resolution,
// shown at 3x with no smoothing. The nodes are little spheres:
//   SOUL  black sphere with spikes, corrupted, with a calm pale-blue part;
//   TARO  white-cyan orb with a ring of NCS-style audio bars;
//   KIYU  a calm, tender pink orb, which becomes INFECTED (a black unstable mass taking it over)
//         once song 2 is completed.
//
// So that the nodes never look like a short repeating loop, three layers are combined:
//   1. each node has its own base loop length (64/48/80/56 frames), a random start frame and a
//      slightly different speed, so they never line up;
//   2. orbiting motes are runtime particles with random radius, speed, direction and life;
//   3. every 3-9 seconds a node plays a short overlay "event" (a pulse, a burst, a twinkle or a
//      glitch spasm) on top of its loop. Locked (dimmed) nodes stay dormant: no motes, no events.
//
// ACCEPT is a PROTOTYPE: no songs exist in the mod yet, so it just marks the selected song as
// completed and unlocks the next node (and infects Kiyu when Taro is completed). Real songs will go
// through LoadingState/PlayState and the progress will be saved (Receta E). Playing each node's
// instrumental when it is selected is pending: Zyra does not have all the insts yet.

var pixel:Float = 3;                 // native pixel -> screen pixel
var nodeCx:Float = 640;              // the path is centred on the screen
var nodeCell:Int = 48;               // native size of a node frame
var fxFrames:Int = 12;

// y is the node centre on screen. frames/sheet/fx are the calm art; Kiyu swaps to kiyuInfected.
var nodes:Array<Dynamic> = [
	{key: "soul", sheet: "node_soul", frames: 64, fx: "fx_soul", y: 570, unlocked: true, completed: false, infected: false},
	{key: "taro", sheet: "node_taro", frames: 48, fx: "fx_taro", y: 360, unlocked: false, completed: false, infected: false},
	{key: "kiyu", sheet: "node_kiyu", frames: 80, fx: "fx_kiyu", y: 156, unlocked: false, completed: false, infected: false}
];
var kiyuInfected:Dynamic = {sheet: "node_kiyu_infected", frames: 56, fx: "fx_infected"};

var nodeSprites:Array<FlxSprite> = [];
var fxSprites:Array<FlxSprite> = [];
var nameSprites:Array<FlxSprite> = [];
var nodeBaseX:Float = 0;
var nodeShake:Array<Float> = [0.0, 0.0, 0.0];
var eventTimers:Array<Float> = [3.0, 6.0, 9.0];
var bobPeriods:Array<Float> = [3.1, 4.3, 3.7];
var bobPhases:Array<Float> = [0.0, 2.1, 4.2];

var pathDashes:Array<FlxSprite> = [];
var pathDashNode:Array<Int> = [];

var mechWindow:FlxSprite;
var artPanel:Script;
var zyra:FlxSprite;
var pointer:FlxSprite;
var zyraAnchor:Dynamic = {y: 0.0};

var currentIndex:Int = 0;
var time:Float = 0;

// Orbiting motes (runtime particles). Each has a back twin (added behind the nodes, shown while
// the mote is on the far side of its orbit) and a front twin (added above them, near side).
var motesPerNode:Int = 6;
var motes:Array<Dynamic> = [];
var moteTimers:Array<Float> = [0.3, 0.6, 0.9];

// Guards against the key press that opened this state still being "justPressed" on this
// state's very first update().
var canConfirm:Bool = false;
var lastMouseX:Float = -1;
var lastMouseY:Float = -1;

function create() {
	FlxG.camera.scroll.set(0, 0); // every screen resets its own camera
	bgColor = FlxColor.BLACK;

	artPanel = Script.create(Paths.script('scripts/ui/nodeArtPanel'));
	artPanel.load();
	artPanel.call("create", [0.34]);
	artPanel.call("showArt", [0, nodes[0].unlocked]);

	buildWindow();
	buildPath();
	buildMotes();
	buildNodes();
	buildMotesFront();
	buildZyra();

	FlxG.mouse.visible = true;
	// Start from where the pointer already is, so a mouse resting on a node at entry does not
	// count as hover and override the keyboard selection on the first frame.
	lastMouseX = FlxG.mouse.screenX;
	lastMouseY = FlxG.mouse.screenY;
	new FlxTimer().start(0.2, (_) -> canConfirm = true);
}

// ---------------------------------------------------------------- building

function pixelSprite(sprite:FlxSprite) {
	sprite.antialiasing = false;
	sprite.scale.set(pixel, pixel);
	sprite.updateHitbox();
	return sprite;
}

function buildWindow() {
	mechWindow = new FlxSprite();
	mechWindow.loadGraphic(Paths.image('menus/songs/mech_window'));
	pixelSprite(mechWindow);
	mechWindow.setPosition(-460, 36);
	mechWindow.alpha = 0;
	add(mechWindow);
	FlxTween.tween(mechWindow, {x: 24}, 0.5, {ease: FlxEase.quadOut, startDelay: 0.1});
	FlxTween.tween(mechWindow, {alpha: 1}, 0.3, {startDelay: 0.1});
}

// Dashes between nodes: bright where the next node is unlocked, dim where it is not.
function buildPath() {
	for (i in 0...nodes.length - 1) {
		var yTop = nodes[i + 1].y + 26 * pixel;
		var yBottom = nodes[i].y - 25 * pixel;
		var y = yTop;
		while (y < yBottom - 9) {
			var dash = new FlxSprite(nodeCx - 3, y);
			dash.makeGraphic(6, 9, FlxColor.WHITE);
			dash.alpha = 0;
			add(dash);
			pathDashes.push(dash);
			pathDashNode.push(i);
			FlxTween.tween(dash, {alpha: 1}, 0.4, {startDelay: 0.7});
			y += 18;
		}
	}
	refreshPath();
}

function refreshPath() {
	for (k in 0...pathDashes.length)
		pathDashes[k].color = nodes[pathDashNode[k] + 1].unlocked ? 0xFFBEC4D6 : 0xFF424656;
}

// Each node: base sprite (its own loop), an overlay sprite for events and its name.
function buildNodes() {
	nodeBaseX = nodeCx - (nodeCell * pixel) / 2;

	for (i in 0...nodes.length) {
		var index = i;
		var node = nodes[i];

		var sprite = new FlxSprite();
		var fx = new FlxSprite();
		nodeSprites.push(sprite);
		fxSprites.push(fx);
		applyNodeArt(index);
		sprite.alpha = 0;
		add(sprite);
		add(fx);
		fx.animation.onFinish.add((_) -> fx.visible = false);

		var nameSprite = new FlxSprite();
		nameSprite.loadGraphic(Paths.image('menus/songs/names'), true, 32, 10);
		pixelSprite(nameSprite);
		nameSprite.setPosition(nodeCx - 28 * pixel - 32 * pixel, node.y - 5 * pixel);
		nameSprite.alpha = 0;
		add(nameSprite);
		nameSprites.push(nameSprite);

		// Appear one after another from the bottom, like the path being lit.
		var delay = 0.3 + 0.18 * (nodes.length - 1 - index);
		FlxTween.tween(sprite, {alpha: 1}, 0.45, {startDelay: delay});
		FlxTween.tween(nameSprite, {alpha: 1}, 0.45, {startDelay: delay});

		refreshNodeLook(index, false);
	}
}

// (Re)load a node's art: its loop with a random start frame and a slightly different speed, and its
// event overlay. Kiyu uses the infected art once infected.
function applyNodeArt(i:Int) {
	var node = nodes[i];
	var sheet = node.sheet;
	var frames = node.frames;
	var fxSheet = node.fx;
	if (node.infected) {
		sheet = kiyuInfected.sheet;
		frames = kiyuInfected.frames;
		fxSheet = kiyuInfected.fx;
	}

	var sprite = nodeSprites[i];
	sprite.loadGraphic(Paths.image('menus/songs/' + sheet), true, nodeCell, nodeCell);
	sprite.animation.add('loop', [for (f in 0...frames) f], 10 * FlxG.random.float(0.93, 1.07), true);
	sprite.animation.play('loop', true, false, FlxG.random.int(0, frames - 1));
	pixelSprite(sprite);
	sprite.setPosition(nodeBaseX, node.y - (nodeCell * pixel) / 2);

	var fx = fxSprites[i];
	fx.loadGraphic(Paths.image('menus/songs/' + fxSheet), true, nodeCell, nodeCell);
	fx.animation.add('fx', [for (f in 0...fxFrames) f], 20, false);
	pixelSprite(fx);
	fx.setPosition(sprite.x, sprite.y);
	fx.visible = false;
}

// Dimmed when locked; the name uses its dim frame too. animate=true tweens the change.
function refreshNodeLook(i:Int, animate:Bool) {
	var unlocked = nodes[i].unlocked;
	var sprite = nodeSprites[i];
	var target = unlocked ? 0xFFFFFFFF : 0xFF8C8C8C;
	if (animate)
		FlxTween.color(sprite, 0.5, sprite.color, target);
	else
		sprite.color = target;
	nameSprites[i].animation.frameIndex = i * 2 + (unlocked ? 0 : 1);
}

function moteColors(i:Int) {
	var key = nodes[i].key;
	if (key == "soul") return [0xFFC8CEEC, 0xFF605A8C];
	if (key == "taro") return [0xFFD2FCFF, 0xFF1E78AA];
	if (nodes[i].infected) return [0xFFB278D2, 0xFF3C1E5A];
	return [0xFFFFE8F0, 0xFFC8789F];
}

function buildMotes() {
	for (i in 0...nodes.length) {
		for (m in 0...motesPerNode) {
			var back = new FlxSprite();
			back.makeGraphic(3, 3, FlxColor.WHITE);
			back.visible = false;
			add(back);
			var front = new FlxSprite();
			front.makeGraphic(3, 3, FlxColor.WHITE);
			front.visible = false;
			motes.push({node: i, back: back, front: front, active: false, angle: 0.0, speed: 0.0, radius: 0.0, age: 0.0, life: 1.0, phase: 0.0});
		}
	}
}

function buildMotesFront() {
	for (mote in motes)
		add(mote.front);
}

function buildZyra() {
	zyra = new FlxSprite();
	zyra.loadGraphic(Paths.image('menus/songs/zyra_icon'));
	pixelSprite(zyra);
	zyra.alpha = 0;
	add(zyra);

	pointer = new FlxSprite();
	pointer.loadGraphic(Paths.image('menus/songs/pointer'));
	pixelSprite(pointer);
	pointer.alpha = 0;
	add(pointer);

	zyraAnchor.y = nodes[0].y - 9 * pixel;
	FlxTween.tween(zyra, {alpha: 1}, 0.4, {startDelay: 1.0});
	FlxTween.tween(pointer, {alpha: 1}, 0.4, {startDelay: 1.0});
}

// ---------------------------------------------------------------- selection

function moveTo(index:Int) {
	if (index < 0 || index >= nodes.length || index == currentIndex)
		return;

	currentIndex = index;
	artPanel.call("showArt", [currentIndex, nodes[currentIndex].unlocked]);

	// Zyra hops to the new node.
	var targetY = nodes[currentIndex].y - 9 * pixel;
	var midY = (zyraAnchor.y + targetY) / 2 - 40;
	FlxTween.cancelTweensOf(zyraAnchor);
	FlxTween.tween(zyraAnchor, {y: midY}, 0.1, {
		ease: FlxEase.quadOut,
		onComplete: (_) -> FlxTween.tween(zyraAnchor, {y: targetY}, 0.12, {ease: FlxEase.quadIn})
	});
}

// PROTOTYPE (see the header): completes the selected song and unlocks the next node.
function confirmSelection() {
	if (!canConfirm || !nodes[currentIndex].unlocked)
		return;

	nodes[currentIndex].completed = true;
	var next = currentIndex + 1;
	if (next < nodes.length && !nodes[next].unlocked)
		unlockNode(next);
}

function unlockNode(i:Int) {
	nodes[i].unlocked = true;
	// Kiyu is calm until song 2 is completed; unlocking her is exactly that moment.
	if (nodes[i].key == "kiyu") {
		nodes[i].infected = true;
		applyNodeArt(i);
	}

	refreshNodeLook(i, true);
	refreshPath();
	eventTimers[i] = 0.5; // plays an event right away
	artPanel.call("showArt", [currentIndex, nodes[currentIndex].unlocked]);
}

// Hover only counts while the mouse actually moves: a pointer resting on a node must not undo what
// the keyboard just selected.
function updateMouse() {
	var moved = FlxG.mouse.screenX != lastMouseX || FlxG.mouse.screenY != lastMouseY;
	lastMouseX = FlxG.mouse.screenX;
	lastMouseY = FlxG.mouse.screenY;

	if (moved) {
		for (i in 0...nodeSprites.length) {
			if (FlxG.mouse.overlaps(nodeSprites[i]))
				moveTo(i);
		}
	}

	if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(nodeSprites[currentIndex]))
		confirmSelection();
}

// ---------------------------------------------------------------- life

function playEvent(i:Int) {
	var fx = fxSprites[i];
	fx.visible = true;
	fx.animation.play('fx', true);
	// Soul and an infected Kiyu are nervous: the whole node jolts for a moment.
	if (nodes[i].key == "soul" || nodes[i].infected)
		nodeShake[i] = 0.35;
}

function spawnMote(i:Int) {
	for (mote in motes) {
		if (mote.node != i || mote.active)
			continue;

		var colors = moteColors(i);
		mote.front.color = colors[0];
		mote.back.color = colors[1];
		mote.angle = FlxG.random.float(0, 6.2832);
		mote.speed = FlxG.random.float(0.7, 1.8) * FlxG.random.sign();
		mote.radius = FlxG.random.float(14, 20) * pixel;
		mote.age = 0.0;
		mote.life = FlxG.random.float(3, 7);
		mote.phase = FlxG.random.float(0, 6.2832);
		mote.active = true;
		return;
	}
}

function updateNodes(elapsed:Float) {
	for (i in 0...nodes.length) {
		var bob = pixel * Math.round(1.2 * Math.sin(time * 6.2832 / bobPeriods[i] + bobPhases[i]));
		var baseY = nodes[i].y - (nodeCell * pixel) / 2;
		var shakeX = 0.0;
		if (nodeShake[i] > 0) {
			nodeShake[i] -= elapsed;
			shakeX = FlxG.random.int(-1, 1) * pixel;
		}
		nodeSprites[i].setPosition(nodeBaseX + shakeX, baseY + bob);
		fxSprites[i].setPosition(nodeBaseX + shakeX, baseY + bob);

		if (!nodes[i].unlocked)
			continue; // dormant

		eventTimers[i] -= elapsed;
		if (eventTimers[i] <= 0) {
			eventTimers[i] = FlxG.random.float(3, 9);
			playEvent(i);
		}

		moteTimers[i] -= elapsed;
		if (moteTimers[i] <= 0) {
			moteTimers[i] = FlxG.random.float(0.35, 1.1);
			spawnMote(i);
		}
	}

	for (mote in motes) {
		if (!mote.active) {
			mote.back.visible = false;
			mote.front.visible = false;
			continue;
		}

		mote.age += elapsed;
		var t = mote.age / mote.life;
		if (t >= 1) {
			mote.active = false;
			mote.back.visible = false;
			mote.front.visible = false;
			continue;
		}

		mote.angle += mote.speed * elapsed;
		var i = mote.node;
		var bob = pixel * Math.round(1.2 * Math.sin(time * 6.2832 / bobPeriods[i] + bobPhases[i]));
		var r = mote.radius + 2 * pixel * Math.sin(mote.age * 1.3 + mote.phase);
		var x = nodeCx + Math.cos(mote.angle) * r;
		var y = nodes[i].y + bob + Math.sin(mote.angle) * r * 0.45 - 2 * pixel;
		x = Math.round(x / pixel) * pixel - pixel / 2;
		y = Math.round(y / pixel) * pixel - pixel / 2;

		var fade = t < 0.12 ? t / 0.12 : (t > 0.75 ? (1 - t) / 0.25 : 1.0);
		var onNearSide = Math.sin(mote.angle) >= 0;
		mote.front.visible = onNearSide;
		mote.back.visible = !onNearSide;
		mote.front.alpha = fade;
		mote.back.alpha = fade;
		mote.front.setPosition(x, y);
		mote.back.setPosition(x, y);
	}
}

function update(elapsed) {
	time += elapsed;

	if (controls.UP_P)
		moveTo(currentIndex + 1);
	else if (controls.DOWN_P)
		moveTo(currentIndex - 1);

	updateMouse();
	updateNodes(elapsed);

	// Zyra's icon: whole-pixel bobbing on top of the hop.
	var bob = pixel * Math.round(1.2 * Math.sin(time * 6.2832 / 3.4));
	zyra.setPosition(nodeCx + 31 * pixel + 1 * pixel, zyraAnchor.y + bob);
	pointer.setPosition(nodeCx + 25 * pixel + 2, zyra.y + 18);

	if (controls.ACCEPT)
		confirmSelection();

	if (controls.BACK)
		FlxG.switchState(new ModState("EchoSelectState"));
}

function destroy() {
	FlxG.mouse.visible = false;
}
