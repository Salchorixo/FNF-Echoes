// The images of a song, loaded by PARTS (OPT-shader-ram, ADR-0008). Zyra's rule: nothing is ever loaded while the music plays, it stutters.
// Every song has two parts, with a cutscene at the start and one between the parts: those are the safe moments.
//   - At the start (while the song is created, before the music) everything of part 1 is loaded AND sent to the graphics card. Without
//     the second step the card receives a picture the first time it is drawn, which can be in the middle of a camera cut.
//   - An image that the song will not draw again is released at the time given in `release` (releasing is instant, it does not stutter).
//     Be sure: if something draws it after that, the game breaks. In Limbo the sets of Zyra's frames depend only on the song time
//     (songs/zyraPoses.hx), so after the pose change (12.4 s) the sheets of the sets 0-2 are never drawn again.
//   - The cutscene between the parts calls startPart(1): the images of part 0 that part 1 does not use are released and those of part 1
//     are loaded and sent to the card. From a cutscene script: PlayState.instance.scripts.call("startPart", [1]);
// A restart (REWIND) creates the song again, so everything is loaded again. A song not in PARTS loads as the engine does.
// The images of the menus are released by the engine itself when the song starts (FlxG.bitmap.clearCache on every state switch).
// Keys are the names given to Paths.image: "characters/zyra/1" is the sheet images/characters/zyra/1.png.

var PARTS = [
	{song: "limbo", parts: [
		{
			images: ["characters/zyra/1", "characters/zyra/2", "characters/zyra/3", "characters/zyra/4", "characters/zyra_arm/1", "characters/zyra_eyes/1"],
			// the pose change starts at 11.775 s and lasts 0.625 s; a little margin after it
			release: [{at: 13000.0, images: ["characters/zyra/1", "characters/zyra/2", "characters/zyra/3"]}]
		}
	]}
];

var parts = null;
var part = -1;
var pending = [];         // the releases of the current part still to come: {at, images}

function postCreate() {
	var name = PlayState.SONG.meta.name;
	if (name == null) return;
	for (p in PARTS) if (p.song == name.toLowerCase()) parts = p.parts;
	if (parts != null) startPart(0);
}

// Loads part n (and releases what the previous part used and part n does not). Call it only in a safe moment: a cutscene, the start.
function startPart(n) {
	if (parts == null || n < 0 || n >= parts.length) return;
	var next = parts[n];
	if (part >= 0) {
		var keep = next.images;
		for (key in parts[part].images) if (keep.indexOf(key) == -1) release(key);
	}
	part = n;
	for (key in next.images) warm(key);
	pending = [];
	if (next.release != null) for (r in next.release) pending.push(r);
}

// loads the picture (if it is not loaded yet) and sends it to the graphics card now, so that its first frame on screen costs nothing
function warm(key) {
	var graphic = FlxG.bitmap.add(Paths.image(key));
	if (graphic == null || graphic.bitmap == null) {
		trace("songParts: no image " + key);
		return;
	}
	if (FlxG.stage.context3D != null) graphic.bitmap.getTexture(FlxG.stage.context3D);
}

// frees the picture (its memory and its texture); a key that is not loaded is ignored
function release(key) {
	var graphic = FlxG.bitmap.get(Paths.image(key));
	if (graphic != null) FlxG.bitmap.remove(graphic);
}

function update(elapsed) {
	if (pending.length == 0) return;
	var t = Conductor.songPosition;
	var i = 0;
	while (i < pending.length) {
		if (t >= pending[i].at) {
			for (key in pending[i].images) release(key);
			pending.splice(i, 1);
		} else i++;
	}
}
