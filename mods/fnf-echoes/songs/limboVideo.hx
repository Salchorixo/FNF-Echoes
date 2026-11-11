import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import hxvlc.flixel.FlxVideoSprite;

// Limbo's scene section (BE-58): a pre-rendered video of the scenes that has to stay locked to the song.
// It has its own camera, right above the world of Limbo (Zyra, the mist, her eyes) and below the arrows and the HUD: while a scene is on, Limbo's own
// Zyra is not seen (Zyra lives inside the scenes); in the bridge between the two passes and after them, Limbo is back. The arm of pose 3 sits on a
// camera above the arrows, so limboScene.hx hides it while FlxG.save.data.echoesSceneVideo is on.
// Zyra is her own layer on top of the video (on another camera, still below the arrows): one sprite per scene set (s1 Blender's viewport, s2 the TV's
// channel, s3_* each place, and their "_dark" versions for the second pass), all in the video's 1280x720 space. The track (data/limboScenes/
// zyraTrack.json, written with the video by AI_build_scene_video.py) says for every video frame which set is on screen and where (the video's camera
// moves, also through the transitions: Zyra always reacts to the notes, Zyra's call). What must cover her (the TV's parts that are built around her,
// Blender's Add menu, the mouse) is a front layer on a camera of its own, one picture per video frame (images/game/limboScenes/front). The playable Zyra of Limbo keeps getting the notes, hidden
// behind the video, and the scene's Zyra copies her animation and frame every frame, so she reacts to the arrows exactly like her.
// Sync: the video's clock (VLC reports it in steps, so it is interpolated between reports) is compared with the song's every frame. Small drifts are
// absorbed by nudging the video's speed; a big one that lasts (a hitch, the pause menu) by seeking. SHOW_SYNC puts the numbers on screen, and a
// summary goes to the log when the section ends.

var VIDEO_KEY = "limboScenes";              // mods/fnf-echoes/videos/limboScenes.mp4 (no sound: the song plays the music)
var VIDEO_START = 24500.0;                  // the song time (ms) of the video's first frame
var SCENES = [[25475.0, 31475.0], [31875.0, 37875.0]];   // the two passes of the four scenes (song ms); between and after them, Limbo
var SHOW_TO = 37875.0;                      // the video stops after the second pass
var SEEK_MS = 150.0;                        // a drift bigger than this, lasting SEEK_FRAMES frames, jumps straight to the right time
var SEEK_FRAMES = 3;
var SEEK_COOLDOWN = 300.0;                  // after a jump, the clock settles for this long (ms) before it is judged again
var NUDGE_MS = 15.0;                        // between this and SEEK_MS the speed is nudged until the drift is gone
var NUDGE_RATE = 0.04;                      // how much faster or slower (4 %)
var SHOW_SYNC = true;                       // the sync readout on screen (test only)
var TRACK_KEY = "limboScenes/zyraTrack";    // data/limboScenes/zyraTrack.json
var ZYRA_SETS = ["s1", "s1n", "s2", "s3_hills2", "s3_pool", "s3_hall", "s1_dark", "s1n_dark", "s2_dark", "s3_hills2_dark", "s3_pool_dark", "s3_hall_dark",
	"s1_alt", "s1n_alt", "s2_alt", "s1_alt_dark", "s1n_alt_dark", "s2_alt_dark"];
var ALT_NOTE_TYPE = "Alt Eyes";              // the alternative eyes (scenes 1 and 2): notes of this type, or the chart's Alt Animation Toggle ("-alt")
var ZYRA_ANIMS = ["idle", "singLEFT", "singDOWN", "singUP", "singRIGHT"];
// The places (sets s3_*): the arrows stand in the scene in front of Zyra (songs/limboScene.hx, Camera.007), so Zyra and the front layer go on cameras
// ABOVE the arrows' one there, and the scene camera's hit (read from Zyra's layer: zoom, x, y) and the place's air go to limboScene.hx through
// FlxG.save.data.echoesSceneCam.
var PLACE_SETS = ["s3_hills2", "s3_pool", "s3_hall"];
var PLACE_HAZE = [[0.16, 0.17, 0.18], [0.3, 0.41, 0.45], [0.08, 0.09, 0.1]];   // the colour of each place's air (the average of its picture)
// The arrows glitch with the scenes (mockup v12, explosive): a burst on every hit of the transitions (pass times; the second pass is PASS2_OFF later),
// flickers on the eighth notes of the infection (scene 4), and in the second pass a constant low glitch, stronger bursts and red.
var GLITCH_HITS = [25.475, 26.975, 27.475, 28.075, 28.275, 28.475, 28.85, 29.225, 29.6, 29.975, 30.675, 31.075];
var GLITCH_BURST = 0.85;                     // strength of a burst (0..1) ...
var GLITCH_BURST_S = 0.28;                   // ... and how long it dies out (seconds)
var GLITCH_INFECTION = 0.3;                  // the eighth-note flickers of scene 4 at their strongest
var GLITCH_PASS2_BASE = 0.15;                // the second pass: always a little ...
var GLITCH_PASS2_RED = 0.6;                  // ... and pulled towards red
var PASS2_OFF = 6.4;

var isLimbo = false;
var video:FlxVideoSprite = null;
var videoCam:FlxCamera = null;
var lastRaw = -1.0;                         // the last clock value VLC reported
var clock = 0.0;                            // the video's clock, interpolated between reports (ms)
var bigFrames = 0;
var cooldownUntil = 0.0;
var ready = false;
var started = false;
var rate = 1.0;
var zyraCam:FlxCamera = null;
var zyraSprites = [];                       // one per set, in ZYRA_SETS order
var frontCam:FlxCamera = null;
var frontSpr:FlxSprite = null;
var zyraTopCam:FlxCamera = null;            // above the arrows: Zyra and the front layer in the places
var frontTopCam:FlxCamera = null;
var track = null;                           // {start, fps, frames: [[set, scale, x, y] or null, ...]}
var shownSets = [];                         // the sprites drawn this frame
var altEyes = false;
var syncText:FlxText = null;
var syncBack:FlxSprite = null;
var stats = {frames: 0, sumAbs: 0.0, maxAbs: 0.0, seeks: 0, nudged: 0};

function postCreate() {
	var name = PlayState.SONG.meta.name;
	isLimbo = (name != null && name.toLowerCase() == "limbo");
	if (!isLimbo) return;
	var path = Paths.video(VIDEO_KEY);
	if (!Assets.exists(path)) {
		trace("limboVideo: no video at " + path + " (the section plays without it)");
		isLimbo = false;
		return;
	}
	video = new FlxVideoSprite(0, 0);
	video.antialiasing = true;
	video.autoPause = false;                  // the song decides when the video runs, not the window's focus
	// its own camera, right above the game's (the world of Limbo) and below everything else
	videoCam = new FlxCamera();
	videoCam.bgColor = 0x00000000;
	videoCam.visible = false;
	FlxG.cameras.insert(videoCam, FlxG.cameras.list.indexOf(camGame) + 1, false);
	video.cameras = [videoCam];
	video.scrollFactor.set(0, 0);
	video.bitmap.onFormatSetup.add(function() {
		video.setGraphicSize(FlxG.width, FlxG.height);
		video.updateHitbox();
		video.screenCenter();
	});
	add(video);
	FlxG.save.data.echoesSceneVideo = false;
	FlxG.save.data.echoesSceneCam = null;
	FlxG.save.data.echoesArrowGlitch = null;
	makeZyraLayers();
	if (video.load(Assets.getPath(path), [":no-audio"])) {
		ready = true;
	} else {
		trace("limboVideo: the video did not load");
	}
	if (SHOW_SYNC) {
		syncBack = new FlxSprite(8, 8).makeGraphic(900, 52, 0xAA000000);
		syncBack.cameras = [camHUD];
		syncBack.scrollFactor.set();
		add(syncBack);
		syncText = new FlxText(16, 12, 890, "");
		syncText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, "left");
		syncText.cameras = [camHUD];
		syncText.scrollFactor.set();
		add(syncText);
	}
}

// Zyra's layers: their camera (right above the video's), one sprite per set, and the track that places them
function makeZyraLayers() {
	var tpath = Paths.json(TRACK_KEY);
	if (!Assets.exists(tpath)) {
		trace("limboVideo: no track at " + tpath + " (Zyra stays baked in the video)");
		return;
	}
	track = Json.parse(Assets.getText(tpath));
	zyraCam = new FlxCamera();
	zyraCam.bgColor = 0x00000000;
	zyraCam.visible = false;
	FlxG.cameras.insert(zyraCam, FlxG.cameras.list.indexOf(videoCam) + 1, false);
	for (set in ZYRA_SETS) {
		if (!Paths.framesExists("game/limboScenes/zyra_" + set)) {      // a set that is not there yet (the alternative eyes): skipped
			zyraSprites.push(null);
			continue;
		}
		var spr = new FlxSprite(0, 0);
		spr.frames = Paths.getFrames("game/limboScenes/zyra_" + set);
		for (a in ZYRA_ANIMS) if (!(set.indexOf("_alt") >= 0 && a == "idle")) spr.animation.addByPrefix(a, a, 24, false);
		spr.animation.play(set.indexOf("_alt") >= 0 ? "singDOWN" : "idle");
		spr.animation.curAnim.paused = true;
		spr.antialiasing = true;
		spr.origin.set(0, 0);
		spr.offset.set(0, 0);
		spr.scrollFactor.set(0, 0);
		spr.cameras = [zyraCam];
		spr.visible = false;
		add(spr);
		zyraSprites.push(spr);
	}
	// the front layer: above Zyra, still below the arrows
	frontCam = new FlxCamera();
	frontCam.bgColor = 0x00000000;
	frontCam.visible = false;
	FlxG.cameras.insert(frontCam, FlxG.cameras.list.indexOf(zyraCam) + 1, false);
	frontSpr = new FlxSprite(0, 0);
	frontSpr.frames = Paths.getFrames("game/limboScenes/front");
	frontSpr.antialiasing = true;
	frontSpr.scrollFactor.set(0, 0);
	frontSpr.cameras = [frontCam];
	add(frontSpr);
}

// the cameras above the arrows: made the first time a place is on screen, when every script has already added its cameras (the arrows' one too)
function makeTopCams() {
	zyraTopCam = new FlxCamera();
	zyraTopCam.bgColor = 0x00000000;
	FlxG.cameras.add(zyraTopCam, false);
	frontTopCam = new FlxCamera();
	frontTopCam.bgColor = 0x00000000;
	frontTopCam.visible = false;
	FlxG.cameras.add(frontTopCam, false);
}

// [zoom, x, y, haze r, g, b]: Zyra's layer of a place is the scene camera itself (her base frame is the whole 1280x720 picture at scale 1)
function placeCam(l) {
	var base = StringTools.replace(l[0], "_dark", "");
	var k = PLACE_SETS.indexOf(base);
	var hz = k >= 0 ? PLACE_HAZE[k] : [0.15, 0.16, 0.17];
	return [l[1], l[2], l[3], hz[0], hz[1], hz[2]];
}

// how much the arrows glitch now: [strength, red]
function arrowGlitch(song) {
	var t = song / 1000.0;
	var pass2 = t >= SCENES[1][0] / 1000.0;
	if (pass2) t -= PASS2_OFF;
	var g = pass2 ? GLITCH_PASS2_BASE : 0.0;
	for (h in GLITCH_HITS) {
		var d = t - h;
		if (d >= 0 && d < GLITCH_BURST_S) {
			var k = 1.0 - d / GLITCH_BURST_S;
			g = Math.max(g, GLITCH_BURST * k * k * (pass2 ? 1.2 : 1.0));
		}
	}
	if (t >= 29.975 && t < 31.475) {
		var e = (t - 29.975) / 0.2;
		if (e - Math.floor(e) < 0.3) g = Math.max(g, GLITCH_INFECTION * Math.min(1.0, (t - 29.975) / 1.1 + 0.3));
	}
	return [Math.min(1.0, g), pass2 ? GLITCH_PASS2_RED : 0.0];
}

// "singUP_d" -> "singUP" (the playable Zyra's animations carry the suffix of her camera set)
function baseName(name) {
	if (name == null) return "idle";
	var n = name.length;
	if (n > 2 && name.charAt(n - 2) == "_") return name.substr(0, n - 2);
	return name;
}

function updateZyra(song, on) {
	if (track == null) return;
	var i = Std.int((song / 1000.0 - track.start) * track.fps);
	var layers = (on && i >= 0 && i < track.frames.length) ? track.frames[i] : null;
	// the front layer's picture for this video frame, if there is one
	var fname = (i >= 0 && on) ? "f" + StringTools.lpad(Std.string(i), "0", 4) : null;
	var ff = fname == null ? null : frontSpr.frames.getByName(fname);
	// a place on screen: Zyra and the front layer above the arrows, and the scene camera's hit for the arrows
	var place = layers != null && layers.length > 0 && StringTools.startsWith(layers[0][0], "s3_");
	if (place && zyraTopCam == null) makeTopCams();
	FlxG.save.data.echoesSceneCam = place ? placeCam(layers[0]) : null;
	frontCam.visible = ff != null && !place;
	if (frontTopCam != null) frontTopCam.visible = ff != null && place;
	frontSpr.cameras = [place ? frontTopCam : frontCam];
	if (ff != null) frontSpr.frame = ff;
	for (k in shownSets) zyraSprites[k].visible = false;
	shownSets = [];
	zyraCam.visible = layers != null && layers.length > 0;
	if (!zyraCam.visible) return;
	// the playable Zyra's animation and frame (her pose's key frame, the hold of a long note and the return to idle all come with it)
	var z = strumLines.members[1].characters[0];
	var cur = z.animation.curAnim;
	var base = cur == null ? "idle" : baseName(cur.name);
	if (ZYRA_ANIMS.indexOf(base) < 0) base = "idle";
	var f = cur == null ? 0 : cur.curFrame;
	for (l in layers) {
		// one layer: [set, scale, x, y, vertical scale, brightness, alpha] (the old tracks only had the first four)
		var set = l[0];
		if (altEyes && base != "idle") {                     // an Alt Eyes note: her alternative eyes, where the scene has them
			var alt = set.indexOf("_dark") >= 0 ? StringTools.replace(set, "_dark", "_alt_dark") : set + "_alt";
			var ai = ZYRA_SETS.indexOf(alt);
			if (ai >= 0 && zyraSprites[ai] != null) set = alt;
		}
		var idx = ZYRA_SETS.indexOf(set);
		if (idx < 0 || zyraSprites[idx] == null) continue;
		var spr = zyraSprites[idx];
		spr.visible = true;
		spr.cameras = [place ? zyraTopCam : zyraCam];
		shownSets.push(idx);
		var sy = l.length > 4 && l[4] != null ? l[4] : l[1];
		spr.scale.set(l[1], sy);
		spr.x = l[2];
		spr.y = l[3];
		var br = l.length > 5 && l[5] != null ? l[5] : 1.0;
		var al = l.length > 6 && l[6] != null ? l[6] : 1.0;
		spr.setColorTransform(br, br, br, al);
		if (spr.animation.name != base) spr.animation.play(base, true);
		spr.animation.curAnim.paused = true;
		spr.animation.curAnim.curFrame = Std.int(Math.min(f, spr.animation.curAnim.numFrames - 1));
	}
}

// the alternative eyes follow the notes like songs/zyraEyes.hx: a note decides, the pieces of a long note keep it, a miss clears it
function onPlayerHit(event) {
	if (!isLimbo) return;
	if (event.note != null && event.note.isSustainNote) return;
	altEyes = (event.noteType == ALT_NOTE_TYPE || event.animSuffix == "-alt");
}

function onPlayerMiss(event) {
	altEyes = false;
}

// the video's own clock, in ms (hxvlc gives an Int64; it is read through its text so HScript can use it as a number)
function videoTime() {
	return Std.parseFloat(Std.string(video.bitmap.time));
}

function inScene(t) {
	for (w in SCENES) if (t >= w[0] && t < w[1]) return true;
	return false;
}

function update(elapsed) {
	if (!isLimbo || !ready) return;
	var song = Conductor.songPosition;
	if (!started) {
		if (song < VIDEO_START) return;
		video.play();
		video.bitmap.time = Std.int(song - VIDEO_START);
		clock = song - VIDEO_START;
		cooldownUntil = song + SEEK_COOLDOWN;
		started = true;
		return;
	}
	var on = inScene(song);
	videoCam.visible = on;
	FlxG.save.data.echoesSceneVideo = on;
	FlxG.save.data.echoesArrowGlitch = on ? arrowGlitch(song) : null;
	updateZyra(song, on);
	if (song >= SHOW_TO) {
		if (video.bitmap.isPlaying) {
			video.pause();
			report();
		}
		return;
	}
	if (!video.bitmap.isPlaying) return;      // still opening
	// the video's clock: VLC's own report when it changes, and in between it runs on with the frame time
	var raw = videoTime();
	if (raw != lastRaw) {
		lastRaw = raw;
		clock = raw;
	} else {
		clock += elapsed * 1000.0 * rate;
	}
	var expected = song - VIDEO_START;
	var drift = clock - expected;             // positive: the video is ahead of the song
	var abs = Math.abs(drift);
	if (song < cooldownUntil) {
		bigFrames = 0;
	} else if (abs > SEEK_MS) {
		bigFrames++;
		if (bigFrames >= SEEK_FRAMES) {
			video.bitmap.time = Std.int(expected);
			clock = expected;
			stats.seeks++;
			bigFrames = 0;
			cooldownUntil = song + SEEK_COOLDOWN;
			setRate(1.0);
		}
	} else {
		bigFrames = 0;
		if (abs > NUDGE_MS) {
			setRate(drift > 0 ? 1.0 - NUDGE_RATE : 1.0 + NUDGE_RATE);
			stats.nudged++;
		} else {
			setRate(1.0);
		}
	}
	if (on) {
		stats.frames++;
		stats.sumAbs += abs;
		if (abs > stats.maxAbs) stats.maxAbs = abs;
	}
	if (syncText != null) {
		syncText.visible = on;
		syncBack.visible = on;
		syncText.text = "canción " + Std.int(song) + " ms   video " + Std.int(clock + VIDEO_START) + " ms   desfase " + (drift >= 0 ? "+" : "") + Std.int(drift)
			+ " ms\nvelocidad " + rate + "   saltos " + stats.seeks + "   media " + (stats.frames > 0 ? Std.int(stats.sumAbs / stats.frames) : 0) + " ms   máx " + Std.int(stats.maxAbs) + " ms";
	}
}

function setRate(r) {
	if (r == rate) return;
	rate = r;
	video.bitmap.rate = r;
}

function report() {
	var mean = stats.frames > 0 ? stats.sumAbs / stats.frames : 0;
	trace("limboVideo sync: frames " + stats.frames + ", mean |drift| " + Std.int(mean) + " ms, max " + Std.int(stats.maxAbs) + " ms, seeks " + stats.seeks + ", nudged frames " + stats.nudged);
}

function onGamePause() {
	if (video != null && started) video.pause();
}

function onSubstateClose() {
	// back from the pause menu: the next update seeks to the right time if needed
	if (video != null && started && Conductor.songPosition < SHOW_TO) video.resume();
}

function destroy() {
	FlxG.save.data.echoesSceneVideo = null;
	FlxG.save.data.echoesSceneCam = null;
	FlxG.save.data.echoesArrowGlitch = null;
	if (video != null) video.stop();
	if (videoCam != null && FlxG.cameras.list.contains(videoCam)) FlxG.cameras.remove(videoCam);
	if (zyraCam != null && FlxG.cameras.list.contains(zyraCam)) FlxG.cameras.remove(zyraCam);
	if (frontCam != null && FlxG.cameras.list.contains(frontCam)) FlxG.cameras.remove(frontCam);
	if (zyraTopCam != null && FlxG.cameras.list.contains(zyraTopCam)) FlxG.cameras.remove(zyraTopCam);
	if (frontTopCam != null && FlxG.cameras.list.contains(frontTopCam)) FlxG.cameras.remove(frontTopCam);
}
