import flixel.tweens.FlxEase;
import funkin.backend.utils.NativeAPI;
import lime.system.System;

// Moves the game window on its own. Story: Zyra is inside the window like in a cell; when he
// hits its inner left (or right) wall, that hit launches the window the other way across the
// desktop until it slams into the edge of the screen. Shared via Script.create() + call(),
// like vhsShader.hx. The state that uses it must call update(elapsed) every frame (shared
// scripts are not updated by the engine) and restore() when it is destroyed.
//
// The state decides WHEN Zyra hits the wall (that is his animation, inside the game); this
// script does what the window does about it:
//   begin()                 fullscreen -> windowed, sized and centred            -> phase "ready"
//   launch(side, ...)       "hitstop" (a frozen beat, tiny jitter) -> "flying" (explosive
//                           ease-out) -> "impact" (shake, inwards) -> "settling" -> "recentering"
//                           (the window drifts back to the middle of the screen) -> "ready"
//   finish()                back to fullscreen                                   -> phase "done"
// Phases: idle | leaving | sizing | ready | hitstop | flying | impact | settling | recentering | returning | done
//
// Nothing assumes a resolution or aspect ratio. Everything is read at run time:
//  - the screen is window.display.bounds (the monitor the window is on, in the same units as
//    window.x / window.y: points on macOS, pixels on Windows);
//  - the window gets the game's aspect ratio and a fraction of that screen, so there is room;
//  - the shake size scales with the screen width.
//
// Why "overshoot": an ease-out curve ends at speed 0, but a window that hits a wall should hit
// it FAST. The flight aims at a virtual target past the edge (edge distance * (1 + overshoot));
// the screen edge stops it early, still moving. overshoot 0 = it just reaches the edge, slowly.
//
// Polled, not callback-driven: popHits() hands out one record per wall hit,
// [side, gap, hitNumber, impactSpeed]. gap is how far the window really stopped from the edge
// in pixels (0 = touching), read from the OS's own WINDOW_MOVE event a moment after the shake;
// impactSpeed is in px/s at the moment of impact.
//
// Every mode change is asynchronous, so each step waits for it to settle instead of reading
// window.* right after changing it (see docs/agents/04_TRAMPAS_CONOCIDAS.md nº 14).

var phase:String = "idle";
var phaseTime:Float = 0;
var transparent:Bool = false;

// Optional fake screen [width, height], centred inside the real monitor. Only tests the maths.
var virtualSize:Array<Float> = null;

var scrX:Float = 0;
var scrY:Float = 0;
var scrW:Float = 0;
var scrH:Float = 0;

var winY:Int = 0;
var minX:Float = 0;
var maxX:Float = 0;
var posX:Float = 0;

var launchSide:String = "";
var launchDir:Int = 1;
var launchFrom:Float = 0;
var launchTarget:Float = 0;
var launchEdge:Float = 0;
var launchSeconds:Float = 1;
var launchEaseFn:Dynamic = null;
var hitstopSeconds:Float = 0.09;
var prevX:Float = 0;
var impactSpeed:Float = 0;
var shakeAmp:Float = 0;
var shakeSeconds:Float = 0.4;

var hitsDone:Int = 0;
var observedMinX:Float = 0;
var observedMaxX:Float = 0;
var maxLag:Float = 0;

var pendingHits:Array<Dynamic> = [];
var logLines:Array<String> = [];

var settleLeave:Float = 0.9;
var settleResize:Float = 0.5;
var settleEnter:Float = 1.0;
var settleMeasure:Float = 0.12;

var recenterSeconds:Float = 0.8;
var recenterEaseFn:Dynamic = null;
var recenterFrom:Float = 0;
var centreX:Float = 0;

function say(msg:String) {
	trace("[WindowFx] " + msg);
	logLines.push(msg);
	while (logLines.length > 12) logLines.shift();
}

function setTransparent(value:Bool) {
	transparent = value;
}

// How the window comes back to the middle after an impact (default: 0.8 s, cubeInOut).
function setRecenter(seconds:Float, easeName:String) {
	recenterSeconds = Math.max(0.05, seconds);
	recenterEaseFn = easeFn(easeName);
}

function setVirtualScreen(w:Float, h:Float) {
	virtualSize = (w <= 0 || h <= 0) ? null : [w, h];
}

function getPhase() return phase;
function getLog() return logLines;
function getScreen() return [scrX, scrY, scrW, scrH];
function getStats() return [observedMinX, observedMaxX, maxLag, minX, maxX];

function popHits() {
	var out = pendingHits;
	pendingHits = [];
	return out;
}

// Names the state may use for the launch curve. "...Out" curves start at full speed (explosive).
function easeFn(name:String) {
	switch (name) {
		case "linear": return FlxEase.linear;
		case "sineOut": return FlxEase.sineOut;
		case "quadOut": return FlxEase.quadOut;
		case "cubeOut": return FlxEase.cubeOut;
		case "quartOut": return FlxEase.quartOut;
		case "quintOut": return FlxEase.quintOut;
		case "expoOut": return FlxEase.expoOut;
		case "circOut": return FlxEase.circOut;
		case "quadIn": return FlxEase.quadIn;
		case "cubeIn": return FlxEase.cubeIn;
		case "expoIn": return FlxEase.expoIn;
		case "sineInOut": return FlxEase.sineInOut;
		case "quadInOut": return FlxEase.quadInOut;
		case "cubeInOut": return FlxEase.cubeInOut;
		case "quartInOut": return FlxEase.quartInOut;
		case "backInOut": return FlxEase.backInOut;
		default:
			say("unknown ease '" + name + "', using cubeOut");
			return FlxEase.cubeOut;
	}
}

function setPhase(name:String) {
	phase = name;
	phaseTime = 0;
}

function reapplyTransparency() {
	// macOS re-applies it by itself after window changes; Windows does not.
	if (transparent) NativeAPI.setWindowTransparent(true);
}

function readScreen() {
	var win = FlxG.stage.window;
	var b = win.display.bounds;

	if (virtualSize == null) {
		scrX = b.x;
		scrY = b.y;
		scrW = b.width;
		scrH = b.height;
	} else {
		scrW = Math.min(virtualSize[0], b.width);
		scrH = Math.min(virtualSize[1], b.height);
		scrX = b.x + (b.width - scrW) / 2;
		scrY = b.y + (b.height - scrH) / 2;
	}

	say("os " + System.platformName + "  screen " + scrW + "x" + scrH + " @ " + scrX + "," + scrY
		+ (virtualSize == null ? "" : " (virtual)")
		+ "  dpi " + win.display.dpi + "  scale " + win.scale);
}

// Leaves fullscreen and gets the window ready (sized, centred). Ends in phase "ready".
function begin() {
	if (phase != "idle" && phase != "done") return;

	hitsDone = 0;
	pendingHits = [];
	maxLag = 0;

	if (FlxG.fullscreen) {
		say("leaving fullscreen");
		FlxG.fullscreen = false;
		setPhase("leaving");
	} else {
		sizeWindow();
	}
}

// Window with the game's aspect ratio, at most half the screen wide and 70% of its height.
function sizeWindow() {
	readScreen();

	var aspect = FlxG.width / FlxG.height;
	var w = Math.min(scrW * 0.5, scrH * 0.7 * aspect);
	w = Math.max(w, 320);
	var h = Math.round(w / aspect);

	FlxG.stage.window.resize(Std.int(Math.round(w)), Std.int(h));
	setPhase("sizing");
	say("resize to " + Std.int(Math.round(w)) + "x" + h);
}

function centreWindow() {
	var win = FlxG.stage.window;

	winY = Std.int(Math.round(scrY + (scrH - win.height) / 2));
	minX = scrX;
	maxX = scrX + scrW - win.width;

	if (maxX <= minX) {
		say("ERROR: window " + win.width + " px is not narrower than the screen " + scrW + " px, nothing to move");
		finish();
		return;
	}

	centreX = scrX + (scrW - win.width) / 2;
	posX = centreX;
	observedMinX = posX;
	observedMaxX = posX;

	win.move(Std.int(Math.round(posX)), winY);
	reapplyTransparency();
	say("window " + win.width + "x" + win.height + "  travel " + minX + " .. " + maxX);
	setPhase("ready");
}

// Zyra hit the inner wall on `side` ("left" | "right"): the window is thrown to that side.
// seconds = the whole curve (the flight ends earlier when overshoot > 0), easeName = see easeFn,
// overshoot = how far past the edge the curve aims (fraction of the edge distance, e.g. 0.5),
// hitstop = the frozen beat between the hit and the launch. Returns false if it cannot launch.
function launch(side:String, seconds:Float, easeName:String, overshoot:Float, hitstop:Float) {
	if (phase != "ready") return false;

	if (recenterEaseFn == null) recenterEaseFn = easeFn("cubeInOut");

	launchSide = side;
	launchDir = side == "left" ? -1 : 1;
	launchEdge = side == "left" ? minX : maxX;
	launchFrom = posX;

	var dist = Math.abs(launchEdge - launchFrom);
	if (dist < 2) {
		say("launch " + side + ": already at that edge");
		return false;
	}

	launchTarget = launchFrom + launchDir * dist * (1 + Math.max(0, overshoot));
	launchSeconds = Math.max(0.05, seconds);
	launchEaseFn = easeFn(easeName);
	hitstopSeconds = Math.max(0, hitstop);

	say("launch " + side + "  ease " + easeName + "  " + launchSeconds + " s  overshoot " + overshoot + "  hitstop " + hitstopSeconds + " s");
	setPhase("hitstop");
	return true;
}

function finish() {
	if (phase == "idle" || phase == "done" || phase == "returning") return;

	say("entering fullscreen");
	FlxG.fullscreen = true;
	setPhase("returning");
}

function moveWindow(x:Float, y:Float) {
	FlxG.stage.window.move(Std.int(Math.round(x)), Std.int(Math.round(y)));
}

function update(elapsed:Float) {
	if (phase == "idle" || phase == "done") return;

	phaseTime += elapsed;
	var win = FlxG.stage.window;
	var dt = Math.min(elapsed, 0.05);

	switch (phase) {
		case "leaving":
			if (phaseTime >= settleLeave) {
				reapplyTransparency();
				sizeWindow();
			}

		case "sizing":
			if (phaseTime >= settleResize) centreWindow();

		case "hitstop":
			// The wall took the hit: the window holds still and only trembles a little.
			var jitter = Math.max(2, scrW * 0.0015);
			// The window may be sitting at an edge: never let the jitter push it off the screen.
			moveWindow(Math.max(minX, Math.min(maxX, posX + (Math.random() * 2 - 1) * jitter)), winY + (Math.random() * 2 - 1) * jitter);

			if (phaseTime >= hitstopSeconds) {
				moveWindow(posX, winY);
				prevX = posX;
				setPhase("flying");
			}

		case "flying":
			var t = Math.min(1, phaseTime / launchSeconds);
			var x = launchFrom + (launchTarget - launchFrom) * launchEaseFn(t);
			var reached = launchDir * (x - launchEdge) >= 0 || t >= 1;

			// Speed is measured before the edge clips the last step, or the impact would read slow.
			impactSpeed = dt > 0 ? Math.abs(x - prevX) / dt : 0;

			if (reached) x = launchEdge;

			prevX = x;
			posX = x;
			moveWindow(posX, winY);

			// win.x comes back from the OS event, so it trails what we asked by a frame or two.
			maxLag = Math.max(maxLag, Math.abs(win.x - posX));
			observedMinX = Math.min(observedMinX, win.x);
			observedMaxX = Math.max(observedMaxX, win.x);

			if (reached) {
				// Stronger hits shake more; the size follows the screen so it reads the same everywhere.
				shakeAmp = Math.min(scrW * 0.012, Math.max(scrW * 0.003, impactSpeed * 0.012));
				say("IMPACT " + launchSide + "  speed " + Math.round(impactSpeed) + " px/s  ("
					+ Math.round(impactSpeed / scrW * 100) / 100 + " screens/s)  shake " + Math.round(shakeAmp) + " px");
				setPhase("impact");
			}

		case "impact":
			// Shake only inwards on X (the edge is a wall) and both ways on Y; it dies out fast.
			var k = Math.min(1, phaseTime / shakeSeconds);
			var amp = shakeAmp * (1 - k) * (1 - k);
			moveWindow(launchEdge - launchDir * Math.abs(Math.random()) * amp, winY + (Math.random() * 2 - 1) * amp * 0.6);

			if (k >= 1) {
				moveWindow(launchEdge, winY);
				setPhase("settling");
			}

		case "settling":
			if (phaseTime >= settleMeasure) {
				hitsDone++;
				var gap = launchSide == "left" ? win.x - minX : maxX - win.x;
				pendingHits.push([launchSide, gap, hitsDone, impactSpeed]);
				say("hit " + hitsDone + " " + launchSide + "  gap " + gap + " px  (y drift " + (win.y - winY) + ")");
				recenterFrom = posX;
				setPhase("recentering");
			}

		case "recentering":
			var k = Math.min(1, phaseTime / recenterSeconds);
			posX = recenterFrom + (centreX - recenterFrom) * recenterEaseFn(k);
			moveWindow(posX, winY);

			if (k >= 1) {
				posX = centreX;
				moveWindow(posX, winY);
				setPhase("ready");
			}

		case "returning":
			if (phaseTime >= settleEnter) {
				reapplyTransparency();
				say("done, fullscreen = " + FlxG.fullscreen);
				setPhase("done");
			}
	}
}

// Safety net for ESC and destroy(): stops everything and leaves the game in fullscreen.
function restore() {
	if (phase != "idle" && phase != "done") {
		say("restore: interrupted in phase " + phase);
		FlxG.fullscreen = true;
		reapplyTransparency();
	}
	phase = "idle";
	pendingHits = [];
}
