import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxGradient;
import funkin.backend.scripting.ModState;
import funkin.backend.scripting.Script;
import funkin.backend.utils.FunkinParentDisabler;
import funkin.editors.charter.Charter;
import funkin.game.PlayState;

// The pause of a song (BE-62, canvas "Pausa · E", Zyra: transparent): the song stays frozen behind, in full colour, with the
// deck's two noise bars (songs/tapeSong.hx opens this and asks the tape for them); only the index of the pause is drawn, with a
// soft shade on its side so it reads. CONTINUE, REWIND (restart), BACK TO THE EDITOR (only when playtesting from the chart
// editor) and EJECT (exit to the songs). The bar is where the song was paused.

var FONT = "IBMPlexMono-Regular.ttf";
var FONT_BOLD = "IBMPlexMono-SemiBold.ttf";
var WHITE = 0xFFF2F2EE;
var X = 72;
var Y = 180;
var W = 500;
var ROW_H = 50;

var i18n;
var cam;
var disabler;
var options = [];
var rows = [];
var selected = 0;
var lastMouseX = 0;
var lastMouseY = 0;

function create() {
	i18n = Script.create(Paths.script('scripts/ui/translate'));
	i18n.load();
	add(disabler = new FunkinParentDisabler());
	cam = new FlxCamera();
	cam.bgColor = 0x00000000;
	FlxG.cameras.add(cam, false);

	options = ["CONTINUE", "REWIND"];
	if (PlayState.chartingMode) options.push("TO EDITOR");
	options.push("EJECT");

	put(FlxGradient.createGradientFlxSprite(Std.int(FlxG.width * 0.5), FlxG.height, [0x73000000, 0x00000000], 1, 0));
	var song = PlayState.SONG.meta.displayName != null ? PlayState.SONG.meta.displayName : PlayState.SONG.meta.name;
	text(X, Y - 4, W, 16, false, "left", "01 · " + song.toUpperCase(), 0.85);
	text(X, Y - 4, W, 16, false, "right", i18n.call("get", ["PAUSED"]), 0.85);
	put(new FlxSprite(X, Y + 26).makeGraphic(W, 1, 0x66F2F2EE));
	for (i in 0...options.length) {
		var y = Y + 40 + i * ROW_H;
		var label = i18n.call("get", [options[i]]);
		rows.push({
			number: text(X, y + 8, 52, 17, false, "left", "0" + (i + 1), 1),
			label: text(X + 52, y + 2, W - 52, 22, false, "left", label, 1),
			labelBold: text(X + 52, y, W - 52, 26, true, "left", label, 1),
			y: y
		});
	}
	var barY = Y + 40 + options.length * ROW_H + 14;
	var length = FlxG.sound.music.length / 1000;
	var at = Math.max(0, Conductor.songPosition / 1000);
	put(new FlxSprite(X, barY).makeGraphic(W, 4, 0x40F2F2EE));
	put(new FlxSprite(X, barY).makeGraphic(Std.int(Math.max(1, W * Math.min(1, at / length))), 4, WHITE));
	text(X, barY + 10, W, 16, false, "left", clock(at), 0.85);
	text(X, barY + 10, W, 16, false, "right", clock(length), 0.85);
	select(0);
}

function put(obj) {
	obj.cameras = [cam];
	add(obj);
	return obj;
}

function text(x, y, w, size, bold, align, value, alpha) {
	var t = new FlxText(x, y, w, value);
	t.setFormat(Paths.font(bold ? FONT_BOLD : FONT), size, WHITE, align);
	t.antialiasing = true;
	t.alpha = alpha;
	// a little shadow: the song behind can be bright
	t.borderColor = 0xCC000000;
	t.borderSize = 2;
	t.borderQuality = 1;
	return put(t);
}

function clock(seconds) {
	var s = Std.int(seconds);
	return Std.int(s / 60) + ":" + (s % 60 < 10 ? "0" : "") + (s % 60);
}

function select(i) {
	selected = i;
	for (k in 0...rows.length) {
		var on = k == selected;
		rows[k].labelBold.visible = on;
		rows[k].label.visible = !on;
		rows[k].number.alpha = rows[k].label.alpha = on ? 1.0 : 0.75;
	}
}

function choose() {
	switch (options[selected]) {
		case "CONTINUE":
			close();
		case "REWIND":
			disabler.reset();
			PlayState.instance.registerSmoothTransition();
			FlxG.resetState();
		case "TO EDITOR":
			FlxG.switchState(new Charter(PlayState.SONG.meta.name, PlayState.difficulty, PlayState.variation, false));
		case "EJECT":
			if (PlayState.chartingMode && Charter.undos.unsaved) PlayState.instance.saveWarn(false);
			else FlxG.switchState(new ModState("StoryMapState"));
	}
}

function update(elapsed) {
	var mx = FlxG.mouse.screenX;
	var my = FlxG.mouse.screenY;
	var moved = mx != lastMouseX || my != lastMouseY;
	lastMouseX = mx;
	lastMouseY = my;
	var over = -1;
	if (mx >= X && mx < X + W) for (k in 0...rows.length) if (my >= rows[k].y && my < rows[k].y + ROW_H) over = k;
	if (moved && over != -1 && over != selected) select(over);
	if (controls.UP_P || controls.DOWN_P) {
		FlxG.sound.play(Paths.sound("menu/scroll"), 0.5);
		select((selected + (controls.UP_P ? rows.length - 1 : 1)) % rows.length);
	}
	if (controls.ACCEPT || (FlxG.mouse.justPressed && over != -1)) choose();
	else if (controls.BACK) close();
}

function destroy() {
	FlxG.cameras.remove(cam);
}
