import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import funkin.backend.scripting.ModState;
import funkin.backend.scripting.Script;
import funkin.backend.utils.NativeAPI;

// EXPERIMENT: Zyra is inside the window like in a cell. He runs at the inner left (or right)
// wall, hits it, and that hit throws the window across the desktop until it slams into the
// screen edge, drifts back to the middle of the screen, and then he runs to the other wall. The window part lives in
// scripts/effects/windowFx.hx; this state is Zyra's side (a placeholder square until there is
// art) and the readout. It checks that the window really reaches both screen edges on any
// resolution / aspect ratio, on macOS and Windows.
//
// Keys:  SPACE = fullscreen -> window -> Zyra hits the walls -> fullscreen
//        E = next launch curve    T = transparency    R = fake screen sizes (maths only)
//        ESC = back
//
// Not reachable from the UI, like TransparencyTestState. To use it, add
//   FlxG.switchState(new ModState("WindowChoreographyTestState"));
// to a state while testing (needs `import funkin.backend.scripting.ModState;`).
//
// Read the numbers, do not trust the eye alone: every wall hit prints "gap N px", the
// distance between the window and the edge after the OS has moved it (0 = touching), and
// the impact speed. The same lines go to the log with the prefix [WindowFx], so they can be
// pasted from Windows.
var fx:Script;
var panel:FlxText;
var flash:FlxSprite;
var zyra:FlxSprite;
var room:FlxSprite;
var transparent:Bool = false;
var hitsPerRun:Int = 4;
var running:Bool = false;
var hitsSeen:Int = 0;

// Zyra's side. zState: off | beat | windup | dash | stuck
var zState:String = "off";
var zTime:Float = 0;
var zFrom:Float = 0;
var zTo:Float = 0;
var zSide:String = "left";
var zSize:Int = 90;
var wallThickness:Int = 10;

// [name, ease, seconds, overshoot, hitstop]. Every curve starts at full speed (explosive).
var curves:Array<Array<Dynamic>> = [
	["expoOut  (very explosive)", "expoOut", 1.1, 0.35, 0.09],
	["cubeOut  (strong)", "cubeOut", 0.9, 0.5, 0.09],
	["quartOut (strong, long tail)", "quartOut", 1.2, 0.4, 0.09],
	["quadOut  (soft)", "quadOut", 0.8, 0.5, 0.07],
	["linear   (reference)", "linear", 0.6, 0.0, 0.05]
];
var curveIndex:Int = 0;

// [width, height] of the fake screen; [0, 0] = the real monitor.
var screenPresets:Array<Array<Float>> = [[0, 0], [1024, 768], [1280, 800], [1366, 768], [2560, 1080], [800, 600]];
var presetIndex:Int = 0;

function create() {
	FlxG.camera.scroll.set(0, 0);

	fx = Script.create(Paths.script('scripts/effects/windowFx'));
	fx.load();

	// The cell: a dark room with two white inner walls (the window's own edges, seen from inside).
	room = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(34, 34, 40));
	add(room);

	var wallL = new FlxSprite(0, 0).makeGraphic(wallThickness, FlxG.height, FlxColor.WHITE);
	add(wallL);
	var wallR = new FlxSprite(FlxG.width - wallThickness, 0).makeGraphic(wallThickness, FlxG.height, FlxColor.WHITE);
	add(wallR);

	// Placeholder for Zyra (the black cat). Replace with the real sprite when it exists.
	zyra = new FlxSprite(0, 0).makeGraphic(zSize, zSize, FlxColor.fromRGB(12, 12, 14));
	zyra.y = FlxG.height - zSize - 60;
	zyra.x = (FlxG.width - zSize) / 2;
	add(zyra);

	flash = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
	flash.alpha = 0;
	add(flash);

	var panelBack = new FlxSprite(0, 0).makeGraphic(FlxG.width, 330, FlxColor.fromRGB(0, 0, 0));
	panelBack.alpha = 0.6;
	add(panelBack);

	panel = new FlxText(wallThickness + 8, 12, FlxG.width - 2 * wallThickness - 16, "");
	panel.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, "left");
	add(panel);

	var help = new FlxText(0, FlxG.height - 34, FlxG.width, "SPACE: run   E: curve   T: transparency   R: fake screen   ESC: back");
	help.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, "center");
	add(help);

	NativeAPI.disableNativeFullscreen();
	setTransparent(false);
}

function setTransparent(on:Bool) {
	transparent = on;
	FlxG.stage.color = on ? null : 0x000000;
	FlxG.camera.useBgAlphaBlending = on;
	FlxG.camera.bgColor = on ? 0x00000000 : 0xFF000000;
	// The opaque room would hide the desktop, so it goes away while the window is see-through
	// (the white walls stay, to show where the window edges are).
	room.visible = !on;
	var nativeStatus = NativeAPI.setWindowTransparent(on);
	trace("[WindowFx] transparent = " + on + "  nativeStatus = " + nativeStatus);
	fx.call("setTransparent", [on]);
}

function wallX(side:String):Float {
	return side == "left" ? wallThickness : FlxG.width - wallThickness - zSize;
}

// Zyra heads for the wall on `side`: a short beat, a wind-up away from it, then a dash.
function sendZyra(side:String, firstRun:Bool) {
	zSide = side;
	zFrom = zyra.x;
	zTo = wallX(side);
	zTime = 0;
	zState = "beat";
}

function updateZyra(elapsed:Float) {
	zTime += elapsed;
	var dir = zSide == "left" ? -1 : 1;

	switch (zState) {
		case "beat":
			if (zTime >= 0.35) {
				zFrom = zyra.x;
				zTime = 0;
				zState = "windup";
			}

		case "windup":
			// Pulls back (away from the wall) before the dash: reads as effort.
			var k = Math.min(1, zTime / 0.28);
			zyra.x = zFrom - dir * 50 * FlxEase.quadOut(k);

			if (k >= 1) {
				zFrom = zyra.x;
				zTime = 0;
				zState = "dash";
			}

		case "dash":
			// Distance-aware: the same speed across a 1280-wide cell, quicker for short runs.
			var dur = Math.max(0.16, Math.abs(zTo - zFrom) / 2400);
			var k = Math.min(1, zTime / dur);
			zyra.x = zFrom + (zTo - zFrom) * FlxEase.quadIn(k);

			if (k >= 1) {
				// Contact. The window takes the hit.
				zyra.x = zTo;
				zState = "stuck";
				var c = curves[curveIndex];
				fx.call("launch", [zSide, c[2], c[1], c[3], c[4]]);
			}
	}
}

function updatePanel() {
	var preset = screenPresets[presetIndex];
	var lines = fx.call("getLog");
	var stats = fx.call("getStats");

	panel.text = "PHASE: " + fx.call("getPhase")
		+ "   TRANSPARENT: " + (transparent ? "ON" : "OFF")
		+ "   FULLSCREEN: " + (FlxG.fullscreen ? "ON" : "OFF")
		+ "\nSCREEN: " + (preset[0] == 0 ? "real monitor" : "fake " + preset[0] + "x" + preset[1])
		+ "   CURVE: " + curves[curveIndex][0]
		+ "\nx seen " + Math.round(stats[0]) + " .. " + Math.round(stats[1])
		+ "   travel " + Math.round(stats[3]) + " .. " + Math.round(stats[4])
		+ "   max lag " + Math.round(stats[2]) + " px\n"
		+ lines.join("\n");
}

function update(elapsed) {
	fx.call("update", [elapsed]);

	var phase = fx.call("getPhase");

	for (hit in fx.call("popHits")) {
		trace("[WindowFx] hit record " + hit);
		hitsSeen++;
		flash.alpha = 0.8;
	}

	flash.alpha = Math.max(0, flash.alpha - elapsed * 4);

	// The run: wait for the window, send Zyra at one wall after another, then go back to fullscreen.
	if (running) {
		if (zState == "off" && phase == "ready") {
			zyra.x = (FlxG.width - zSize) / 2;
			sendZyra("left", true);
		}

		if (zState == "stuck" && phase == "ready") {
			if (hitsSeen >= hitsPerRun) {
				running = false;
				zState = "off";
				fx.call("finish");
			} else {
				sendZyra(zSide == "left" ? "right" : "left", false);
			}
		}

		if (zState == "beat" || zState == "windup" || zState == "dash")
			updateZyra(elapsed);
	}

	var idle = phase == "idle" || phase == "done";

	if (idle && FlxG.keys.justPressed.SPACE) {
		running = true;
		zState = "off";
		hitsSeen = 0;
		fx.call("begin");
	}

	if (idle && FlxG.keys.justPressed.R) {
		presetIndex = (presetIndex + 1) % screenPresets.length;
		fx.call("setVirtualScreen", [screenPresets[presetIndex][0], screenPresets[presetIndex][1]]);
	}

	if (FlxG.keys.justPressed.E)
		curveIndex = (curveIndex + 1) % curves.length;

	if (FlxG.keys.justPressed.T)
		setTransparent(!transparent);

	if (FlxG.keys.justPressed.ESCAPE) {
		running = false;
		fx.call("restore");
		setTransparent(false);
		FlxG.switchState(new ModState("MainMenuState"));
	}

	updatePanel();
}

function destroy() {
	fx.call("restore");
}
