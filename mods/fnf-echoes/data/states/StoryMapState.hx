import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.backend.scripting.ModState;
import funkin.backend.scripting.Script;

// Song selection (the screen after ECHO 1), from Zyra's vertical sketch:
//   left   a glass window with the level's mechanic (placeholder content for now),
//   centre a vertical path, bottom to top, with one node per song (SOUL, TARO, KIYU) and Zyra's
//          icon to the right of the node he stands on,
//   right  the level art, a flat rectangle for now (the nodeArtPanel script, full height, bleeding
//          to the edge); Zyra makes the real art.
// Every node has its own MOOD (soul, taro, kiyu, kiyu_inf = the infected Kiyu): an abstract animated
// background, a mechanic window that takes its ambience, name/path/pointer colours and a pencil outline
// (BE-11). Moods are 64-frame loops played at 10 fps, all in sync (one frame counter for every sheet).
// Changing node crossfades the mood with a short glitch. A locked node shows its mood dimmed.
// Zyra's icon is animated at runtime (breathing, irregular blinking, looking towards the node you move
// to) from two small sheets of poses; when he is on the LAST song with the last song unlocked it
// changes to the predator face (slow lids, a contracting pupil, a glitch tic now and then).
// All pixel art comes from AI_export_song_mood.py and AI_build_song_select.py (private art folder) at
// native resolution, shown at 3x with no smoothing. The nodes are little spheres:
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

// Moods (BE-11). One background sprite and one window sprite per mood, all kept loaded so that
// changing node never has to decode a sheet.
var moodKeys:Array<String> = ["soul", "taro", "kiyu", "kiyu_inf"];
var loopFrames:Int = 64;
var loopFps:Float = 10;
var bgSprites:Array<FlxSprite> = [];
var winSprites:Array<FlxSprite> = [];
var pencilLight:FlxSprite;
var pencilDark:FlxSprite;
var haloSprites:Array<FlxSprite> = [];
var haloStrength:Array<Float> = [0.30, 0.28, 0.40]; // from the design; x1.5 selected, x0.8 otherwise
var haloColors:Array<Int> = [0xFF50AADC, 0xFF96F0FF, 0xFF5A3296];
var mood:String = "";
var moodFade:Float = 0; // while > 0 the previous mood is still fading out
var moodPrev:String = "";
var glitchLeft:Float = 0;
var windowX:Float = 6;

var artPanel:Script;
var zyraAlert:FlxSprite;
var zyraDown:FlxSprite;
var pointer:FlxSprite;
var zyraAnchor:Dynamic = {y: 0.0};

// Zyra's icon animation: logic ticks at 12 per second; breathing is read from the clock.
var zyraClock:Float = 0;
var zyraBlinkIn:Int = 30;
var zyraDouble:Int = 0;
var zyraGlanceIn:Int = 70;
var zyraGlanceLeft:Int = 0;
var zyraLookLeft:Int = 0;
var zyraLookUp:Bool = false;
var zyraGlitchIn:Int = 80;
var zyraGlitchLeft:Int = 0;
var zyraFocus:Int = 0;
var zyraStep:Int = -1;
var zyraShut:Bool = false;
// the predator's blink: lid level 0..3 while closing, then 100/101 = the two re-opening poses
var downBlink:Array<Int> = [0, 1, 2, 2, 3, 3, 3, 3, 100, 101];

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

	buildBackground();
	buildHalos();

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
	buildPencil();
	setMood(moodOf(currentIndex), false);

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

// The mood of a node: its own, except that Kiyu uses the infected one once infected.
function moodOf(i:Int) {
	if (nodes[i].key == "kiyu" && nodes[i].infected)
		return "kiyu_inf";
	return nodes[i].key;
}

// One background per mood (427x240 native, 64 frames in 4 columns). All stay loaded; only the active
// one (and the one fading out) is visible.
function buildBackground() {
	for (key in moodKeys) {
		var bg = new FlxSprite();
		bg.loadGraphic(Paths.image('menus/songs/bg_' + key), true, 427, 240);
		pixelSprite(bg);
		bg.setPosition(0, 0);
		bg.visible = false;
		add(bg);
		bgSprites.push(bg);
	}
}

// A soft glow under each node: a white radial texture that is tinted and faded per node.
function buildHalos() {
	for (i in 0...nodes.length) {
		var halo = new FlxSprite();
		halo.loadGraphic(Paths.image('menus/songs/halo'));
		halo.antialiasing = false;
		halo.color = haloColors[i];
		halo.alpha = 0;
		halo.setPosition(nodeCx - 120, nodes[i].y - 120);
		add(halo);
		haloSprites.push(halo);
	}
}

// One mechanic window per mood (132x228 native: the 120x216 glass plus a margin for the outline).
function buildWindow() {
	for (key in moodKeys) {
		var win = new FlxSprite();
		win.loadGraphic(Paths.image('menus/songs/mood_' + key), true, 132, 228);
		pixelSprite(win);
		win.setPosition(-480, 18);
		win.alpha = 0;
		win.visible = false;
		add(win);
		winSprites.push(win);
		FlxTween.tween(win, {x: windowX}, 0.5, {ease: FlxEase.quadOut, startDelay: 0.1});
	}
}

// Loose pencil rectangles around the window and the art panel, on top of everything: pale on the
// dark moods (soul, taro), graphite on the light one (kiyu).
function buildPencil() {
	pencilLight = new FlxSprite();
	pencilLight.loadGraphic(Paths.image('menus/songs/pencil_light'));
	pencilDark = new FlxSprite();
	pencilDark.loadGraphic(Paths.image('menus/songs/pencil_dark'));
	for (p in [pencilLight, pencilDark]) {
		p.antialiasing = false;
		p.alpha = 0;
		p.visible = false;
		add(p);
	}
}

// Colours that depend on the mood: soul and taro are dark (pale lines), kiyu is light (violet lines).
function moodLight(key:String) {
	return key == "soul" || key == "taro";
}

function moodLine(key:String, lit:Bool) {
	if (key == "soul") return lit ? 0xFFE8F4FF : 0xFF6A7396;
	if (key == "taro") return lit ? 0xFFE8F4FF : 0xFF3A6A9A;
	return lit ? 0xFF3C286E : 0xFFB9A3D6;
}

function moodNames(key:String) {
	if (key == "soul") return "names_soul";
	if (key == "taro") return "names_taro";
	return "names_kiyu";
}

// Switch the mood. animate=true crossfades from the previous one with a short glitch (the CRT-like
// jolt of the design); false shows it at once (first frame).
function setMood(key:String, animate:Bool) {
	if (key == mood)
		return;

	moodPrev = mood;
	mood = key;

	for (k in 0...moodKeys.length) {
		var isNew = moodKeys[k] == key;
		var isOld = animate && moodKeys[k] == moodPrev && moodPrev != "";
		var bg = bgSprites[k];
		var win = winSprites[k];
		FlxTween.cancelTweensOf(bg, ["alpha"]);
		FlxTween.cancelTweensOf(win, ["alpha"]);
		if (isNew) {
			bg.visible = true;
			win.visible = true;
			if (animate) {
				bg.alpha = 0;
				FlxTween.tween(bg, {alpha: 1}, 0.28);
				win.alpha = 0;
				FlxTween.tween(win, {alpha: 1}, 0.28);
			} else {
				bg.alpha = 0;
				win.alpha = 0;
				FlxTween.tween(bg, {alpha: 1}, 0.45);
				FlxTween.tween(win, {alpha: 1}, 0.3, {startDelay: 0.1});
			}
		} else if (isOld) {
			var oldBg = bg;
			var oldWin = win;
			FlxTween.tween(oldBg, {alpha: 0}, 0.28, {onComplete: (_) -> oldBg.visible = false});
			FlxTween.tween(oldWin, {alpha: 0}, 0.28, {onComplete: (_) -> oldWin.visible = false});
		} else {
			bg.visible = false;
			win.visible = false;
		}
	}
	if (animate)
		glitchLeft = 0.3;

	// the pencil, the names and the path/pointer colours change at once
	var light = moodLight(key);
	pencilLight.visible = light;
	pencilDark.visible = !light;
	pencilLight.alpha = light ? 1 : 0;
	pencilDark.alpha = light ? 0 : 1;
	for (i in 0...nameSprites.length) {
		var name = nameSprites[i];
		name.loadGraphic(Paths.image('menus/songs/' + moodNames(key)), true, 34, 12);
		pixelSprite(name);
		name.setPosition(nodeCx - 59 * pixel, nodes[i].y - 6 * pixel);
		name.animation.frameIndex = i * 2 + (nodes[i].unlocked ? 0 : 1);
	}
	pointer.color = moodLine(key, true);
	refreshPath();
	refreshDim();
}

// A locked node shows its mood dimmed.
function refreshDim() {
	var unlocked = nodes[currentIndex].unlocked;
	for (k in 0...moodKeys.length) {
		bgSprites[k].color = unlocked ? 0xFFFFFFFF : 0xFF8C8C8C;
		winSprites[k].color = unlocked ? 0xFFFFFFFF : 0xFFB4B4B4;
	}
}

// The loop counter is shared by every sheet so the background, the window and the beat stay in sync.
function updateMood(elapsed:Float) {
	var frame = Std.int(time * loopFps) % loopFrames;
	for (k in 0...moodKeys.length) {
		if (bgSprites[k].visible) {
			bgSprites[k].animation.frameIndex = frame;
			winSprites[k].animation.frameIndex = frame;
		}
	}

	// the glitch of a mood change: the backgrounds jolt sideways for a moment
	var jolt = 0.0;
	if (glitchLeft > 0) {
		glitchLeft -= elapsed;
		if (glitchLeft > 0)
			jolt = FlxG.random.int(-6, 6) * pixel;
	}
	for (bg in bgSprites)
		bg.x = jolt;

	for (i in 0...haloSprites.length) {
		var target = haloStrength[i] * (i == currentIndex ? 1.5 : 0.8);
		haloSprites[i].alpha += (target - haloSprites[i].alpha) * Math.min(1, elapsed * 8);
	}
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
		pathDashes[k].color = moodLine(mood == "" ? "soul" : mood, nodes[pathDashNode[k] + 1].unlocked);
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
		nameSprite.loadGraphic(Paths.image('menus/songs/' + moodNames("soul")), true, 34, 12); // setMood swaps the sheet
		pixelSprite(nameSprite);
		nameSprite.setPosition(nodeCx - 59 * pixel, node.y - 6 * pixel);
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
	zyraAlert = new FlxSprite();
	zyraAlert.loadGraphic(Paths.image('menus/songs/zyra_alert'), true, 28, 28);
	zyraDown = new FlxSprite();
	zyraDown.loadGraphic(Paths.image('menus/songs/zyra_down'), true, 28, 28);
	for (z in [zyraAlert, zyraDown]) {
		pixelSprite(z);
		z.alpha = 0;
		add(z);
	}
	zyraDown.visible = false;

	pointer = new FlxSprite();
	pointer.loadGraphic(Paths.image('menus/songs/pointer'));
	pixelSprite(pointer);
	pointer.alpha = 0;
	add(pointer);

	zyraAnchor.y = nodes[0].y - 14 * pixel;
	FlxTween.tween(zyraAlert, {alpha: 1}, 0.4, {startDelay: 1.0});
	FlxTween.tween(zyraDown, {alpha: 1}, 0.4, {startDelay: 1.0});
	FlxTween.tween(pointer, {alpha: 1}, 0.4, {startDelay: 1.0});
}

// ---------------------------------------------------------------- Zyra's icon

// The predator face is for the LAST song, once it is unlocked.
function useDown() {
	return currentIndex == nodes.length - 1 && nodes[currentIndex].unlocked;
}

// One logic step (12 per second). Poses (sheets from AI_export_song_mood.py):
//   zyra_alert: 0 ahead, 1 at the path, 2 up, 3 down, 4 the > < blink
//   zyra_down:  0-11 look (left, ahead, right) x lid (open ... shut), 12-14 pupil contracted,
//               15-16 re-opening, 17-18 glitch tic
function zyraTick() {
	if (!useDown()) {
		var frame = 0;
		zyraShut = false;
		zyraBlinkIn--;
		if (zyraBlinkIn <= 0) {
			frame = 4;
			zyraBlinkIn = FlxG.random.int(36, 84);
			zyraDouble = FlxG.random.float() < 0.25 ? 5 : 0; // now and then a double blink
		} else if (zyraDouble > 0) {
			zyraDouble--;
			if (zyraDouble == 0)
				frame = 4;
		}
		if (frame == 0) {
			if (zyraLookLeft > 0) {
				zyraLookLeft--;
				frame = zyraLookUp ? 2 : 3; // towards the node he is moving to
			} else if (zyraGlanceLeft > 0) {
				zyraGlanceLeft--;
				frame = 1;
			} else {
				zyraGlanceIn--;
				if (zyraGlanceIn <= 0) {
					zyraGlanceLeft = 18; // an idle glance at the path
					zyraGlanceIn = FlxG.random.int(60, 108);
				}
			}
		}
		zyraAlert.animation.frameIndex = frame;
		return;
	}

	// the predator: slow, heavy tracking, rare slow blinks, a contracted pupil on re-opening, a tic
	var lx = 0.6 * Math.sin(time * 6.2832 / 8) - (zyraLookLeft > 0 ? 1 : 0);
	var look = lx < -0.5 ? 0 : (lx > 0.3 ? 2 : 1);
	if (zyraLookLeft > 0)
		zyraLookLeft--;
	var frame = look * 4;
	zyraShut = false;
	if (zyraStep >= 0) {
		var code = downBlink[zyraStep];
		zyraStep++;
		if (code >= 100) {
			frame = 15 + (code - 100);
		} else {
			frame = look * 4 + code;
			zyraShut = code >= 2; // the head sinks while the eyes are shut
		}
		if (zyraStep >= downBlink.length) {
			zyraStep = -1;
			zyraFocus = 4;
		}
	} else {
		zyraBlinkIn--;
		if (zyraBlinkIn <= 0) {
			zyraStep = 0;
			zyraBlinkIn = FlxG.random.int(84, 130);
		}
		if (zyraFocus > 0) {
			frame = 12 + look;
			zyraFocus--;
		}
	}
	if (zyraGlitchLeft > 0) {
		frame = 17 + (2 - zyraGlitchLeft);
		zyraGlitchLeft--;
	} else {
		zyraGlitchIn--;
		if (zyraGlitchIn <= 0) {
			zyraGlitchLeft = 2;
			zyraGlitchIn = FlxG.random.int(72, 132);
		}
	}
	zyraDown.animation.frameIndex = frame;
}

// Breathing: the head sinks one pixel half of the time (1.5 s the tender face, 2.5 s the predator, which
// also sinks while its eyes are shut). The sheets are drawn so that the predator is one pixel higher.
function updateZyra(elapsed:Float) {
	zyraClock += elapsed;
	while (zyraClock >= 1 / 12) {
		zyraClock -= 1 / 12;
		zyraTick();
	}

	var down = useDown();
	zyraAlert.visible = !down;
	zyraDown.visible = down;
	var x = nodeCx + 30 * pixel;
	var alertDy = Math.sin(time * 6.2832 / 1.5) > 0 ? 1 : 0;
	var downDy = (Math.sin(time * 6.2832 / 2.5) > 0 ? 1 : 0) + (zyraShut ? 1 : 0);
	zyraAlert.setPosition(x, zyraAnchor.y + alertDy * pixel);
	zyraDown.setPosition(x, zyraAnchor.y + (downDy - 1) * pixel);
	pointer.setPosition(nodeCx + 25 * pixel + 2, zyraAnchor.y + 11 * pixel);
}

// ---------------------------------------------------------------- selection

function moveTo(index:Int) {
	if (index < 0 || index >= nodes.length || index == currentIndex)
		return;

	zyraLookUp = index > currentIndex; // higher nodes are higher on the screen
	zyraLookLeft = 14;
	currentIndex = index;
	artPanel.call("showArt", [currentIndex, nodes[currentIndex].unlocked]);
	setMood(moodOf(currentIndex), true);
	refreshDim();

	// Zyra travels to the new node in ONE smooth trip: it starts fast and only slows down on arrival
	// (cubeOut), so it never stops half way, even when the key is pressed again during the trip.
	var targetY = nodes[currentIndex].y - 14 * pixel;
	FlxTween.cancelTweensOf(zyraAnchor);
	FlxTween.tween(zyraAnchor, {y: targetY}, 0.38, {ease: FlxEase.cubeOut});
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
	refreshDim();
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

	updateMood(elapsed);
	updateZyra(elapsed);

	if (controls.ACCEPT)
		confirmSelection();

	if (controls.BACK)
		FlxG.switchState(new ModState("EchoSelectState"));
}

function destroy() {
	FlxG.mouse.visible = false;
}
