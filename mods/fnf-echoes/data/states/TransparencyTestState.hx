import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.backend.scripting.ModState;
import funkin.backend.utils.NativeAPI;

// EXPERIMENT (BE-7, see ADR-0003): checks whether the desktop shows through the
// game window on macOS. Deliberately has no VHS shader (it forces alpha 1).
//
// Keys:  T = transparency   F = fullscreen on/off   ESC = back
//
// Not reachable from the UI: the temporary T shortcut on the title screen was removed so a
// player can never open a debug screen. To use it, add
//   FlxG.switchState(new ModState("TransparencyTestState"));
// to a state while testing (needs `import funkin.backend.scripting.ModState;`).
//
// On macOS native fullscreen is a separate Space that is always opaque, so it is
// disabled on every window and FlxG.fullscreen uses SDL's Space-less mode instead
// (a borderless desktop-sized window above the menu bar). The native patch also
// keeps the transparency applied across the window changes that mode causes.
//
// Transparency toggles two things together:
//  - FlxG.stage.color = null  -> OpenFL's OpenGLRenderer clears the framebuffer
//    to alpha 0 instead of opaque black (Stage.set_color / __clear).
//  - camera bgColor alpha 0   -> Flixel does not repaint a black background over it.
// plus NativeAPI.setWindowTransparent() for the OS window and its layers.
var transparent:Bool = false;
var nativeStatus:Int = -1;
var statusText:FlxText;

function create() {
	trace("[BE-7] TransparencyTestState.create, fullscreen = " + FlxG.fullscreen);
	FlxG.camera.scroll.set(0, 0);

	// Solid shapes so it is obvious what stays opaque while the rest turns see-through.
	var box = new FlxSprite(0, 0).makeGraphic(360, 220, FlxColor.fromRGB(230, 60, 60));
	box.screenCenter();
	add(box);

	var strip = new FlxSprite(0, 0).makeGraphic(FlxG.width, 40, FlxColor.fromRGB(60, 160, 230));
	strip.y = FlxG.height - 40;
	add(strip);

	statusText = new FlxText(0, 30, FlxG.width, "");
	statusText.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, "center");
	add(statusText);

	var help = new FlxText(0, 0, FlxG.width, "T: transparency    F: fullscreen    ESC: back");
	help.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, "center");
	help.y = FlxG.height - 34;
	add(help);

	NativeAPI.disableNativeFullscreen();
	setTransparent(false);
}

function setTransparent(on:Bool) {
	transparent = on;
	FlxG.stage.color = on ? null : 0x000000;
	FlxG.camera.useBgAlphaBlending = on;
	FlxG.camera.bgColor = on ? 0x00000000 : 0xFF000000;

	// macOS: make the OS window and its layers translucent. Bit mask: 1 = window updated,
	// 2 = GL surface translucent, 4 = native fullscreen (always opaque), 8 = framebuffer
	// has alpha, 16 = content view is layer-backed.
	nativeStatus = NativeAPI.setWindowTransparent(on);
	trace("[BE-7] transparent = " + on + " nativeStatus = " + nativeStatus);
	updateStatus();
}

function toggleFullscreen() {
	FlxG.fullscreen = !FlxG.fullscreen;
	trace("[BE-7] fullscreen = " + FlxG.fullscreen);
	// The window changes asynchronously; refresh the status text once it settled.
	new FlxTimer().start(0.8, (_) -> updateStatus());
	updateStatus();
}

function updateStatus() {
	var win = FlxG.stage.window;
	statusText.text = "TRANSPARENT: " + (transparent ? "ON" : "OFF")
		+ "    FULLSCREEN: " + (FlxG.fullscreen ? "ON" : "OFF")
		+ "\nwindow " + win.width + "x" + win.height + " @ " + win.x + "," + win.y
		+ "    native status " + nativeStatus;
}

function update(elapsed) {
	if (FlxG.keys.justPressed.T) {
		trace("[BE-7] key T");
		setTransparent(!transparent);
	}

	if (FlxG.keys.justPressed.F) {
		trace("[BE-7] key F");
		toggleFullscreen();
	}

	if (FlxG.keys.justPressed.ESCAPE) {
		trace("[BE-7] key ESC");
		setTransparent(false);
		if (FlxG.fullscreen) FlxG.fullscreen = false;
		FlxG.switchState(new ModState("MainMenuState"));
	}
}
