import flixel.FlxSprite;

// Zyra's ALTERNATIVE EYES (DS-2), shared script: while an "alt" note is sung her body is swapped for another render of the same frame, with the eye(s) that change
// switched off in Blender and Zyra's hand-drawn strokes on top (no patch, so no edge). The frames are images/characters/zyra_eyes (private tools:
// AI_build_zyra_eyes.py), one per frame of her pose, so it only has to follow the body (the normal body is hidden while it shows):
//   pose 3 (set c, Camera.002)    singDOWN "_ _"   singUP "> <"   singLEFT "0 <"   singRIGHT "> 0"      (0 = the real eye, which the body keeps)
//   pose 4 (set d, raised arm)    singDOWN angry triangles   singLEFT "0 -"
// The animation names are the names of the body's animations (singUP_c, singLEFT_d...), after the left/right swap of data/characters/zyra.hx, so the layer
// always matches the render that is showing. Any other animation, or an alt note in a pose without alternative, shows the normal eyes.
// Called from outside: attach(char), setAlt(bool), update().  The song script is songs/zyraEyes.hx; the playground (AnimTestState) toggles it with the A key.
var ANIMS = [["c", "singUP"], ["c", "singDOWN"], ["c", "singLEFT"], ["c", "singRIGHT"], ["d", "singDOWN"], ["d", "singLEFT"], ["d", "singUP"], ["d", "singRIGHT"]];

var eyes = null;
var char = null;
var alt = false;

// the layer goes right after her in the draw order (so it is under whatever is drawn after her, like the arm of pose 3 and the mist in front)
function attach(z) {
	char = z;
	eyes = new FlxSprite();
	eyes.frames = Paths.getFrames("characters/zyra_eyes");
	for (a in ANIMS)
		eyes.animation.addByPrefix(a[1] + "_" + a[0], a[0] + "_" + a[1], 24, false);
	eyes.antialiasing = true;
	eyes.visible = false;
	state.insert(state.members.indexOf(z) + 1, eyes);
}

function setAlt(b) {
	alt = b;
}

function isAlt() {
	return alt;
}

// every frame: the same animation and frame as the body, at the same place and size
function update() {
	if (eyes == null || char == null) return;
	var cur = char.animation.curAnim;
	if (alt && cur != null && eyes.animation.getByName(cur.name) != null) {
		if (eyes.animation.name != cur.name) eyes.animation.play(cur.name, true);
		eyes.animation.curAnim.paused = true;
		eyes.animation.curAnim.curFrame = Std.int(Math.min(cur.curFrame, eyes.animation.curAnim.numFrames - 1));
		eyes.scale.set(char.scale.x, char.scale.y);
		eyes.x = char.x;
		eyes.y = char.y;
		eyes.offset.set(char.offset.x, char.offset.y);
		eyes.flipX = char.flipX;
		eyes.alpha = char.alpha;
		eyes.cameras = char.cameras;
		eyes.visible = true;
		char.visible = false;
	} else {
		eyes.visible = false;
		char.visible = true;
	}
}
