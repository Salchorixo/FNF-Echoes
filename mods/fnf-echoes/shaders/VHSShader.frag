#pragma header

// The whole game recorded on a 90s camcorder tape and played back on a worn VCR (BE-59; Zyra, 2026-11-08: "almost real"
// glitches, the analog fear of the backrooms). A real-time port of the approved mockup (production: 02_Scenes/menu (with the accent)/
// AI_build_menu_vhs_mockup_v06.py). scripts/effects/vhsShader.hx puts it ONCE over the whole game (wholeGame = 1); it works in
// "tape pixels": the picture is always treated as 1280x720 whatever the window size.
//
// What the tape always does
//   luma     soft across (about 400 lines), with the halo of the deck's sharpening beside the edges
//   chroma   very soft across (about 90 lines) and a few pixels late, a touch more saturated and warm
//   fringes  red a couple of pixels to the right and smeared, blue a pixel to the left (chfoo/blender-vhs-filter, CC BY 4.0)
//   tone     blacks lifted a little, highlights rolled off, a small glow on the lights
//   motion   every line wobbles a pixel, the top of the picture bends (flagging), the last lines tear (head switching)
//   noise    faint horizontal streaks and, now and then, a dropout (a short white streak where the oxide is missing)
// What the game triggers (uniforms driven by vhsShader.hx)
//   cutAge   seconds since a camcorder edit (-1: none): sync lost, a roll with the blanking bar, a strong hook, snow, colour gone and back
//   tracking bad tracking (0..1): noisy bands that drift up the picture, the lines inside out of place
//   pauseOn  the deck's pause (0/1): two static noise bars
//   roll     the vertical hold slipping (0..1 of a picture)
//   satDrop  extra loss of colour (0 = none, 1 = grey)
//   noise    how worn the tape is (the "RUIDO DE LA CINTA" setting): 0 = clean picture, 1 = the approved look
// It keeps the alpha of what it draws over (BE-8, trap 16): where the game is transparent, the window stays transparent.

uniform float time;
uniform float noise;
uniform float seed;
uniform float lens;
uniform float cutAge;
uniform float cutSeed;
uniform float tracking;
uniform float trackSeed;
uniform float pauseOn;
uniform float roll;
uniform float satDrop;
uniform float wholeGame;   // 1: a single pass over the whole game (FlxG.game's filter) instead of one per camera

const vec2 TAPE = vec2(1280.0, 720.0);
const float TONE_DEN = 0.738154; // 1.0 - exp(-1.34), precomputed

// a hash without sin() (Dave Hoskins): the usual fract(sin(...)) makes diagonal patterns on some GPUs
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// value noise along a line, in cells of `cell` tape pixels: the streaks of tape noise
float streak(float x, float line, float frame, float cell) {
	float cx = x / cell;
	float i = floor(cx);
	float f = fract(cx);
	f = f * f * (3.0 - 2.0 * f);
	return mix(hash(vec2(i, line + frame * 0.731)), hash(vec2(i + 1.0, line + frame * 0.731)), f);
}

// the camcorder's wide lens: a slight barrel, scaled so the corners stay inside the picture
vec2 barrel(vec2 uv) {
	vec2 c = uv - 0.5;
	vec2 n = c * vec2(1.0, 720.0 / 1280.0) / 0.5735;
	return 0.5 + c * (1.0 + lens * dot(n, n)) / (1.0 + lens);
}

// the camera's picture at a point in tape pixels (textureCam: the camera's texture can be larger than what it shows)
vec4 tap(vec2 p) {
	vec2 c = clamp(p / TAPE, vec2(0.0), vec2(1.0));
	return wholeGame > 0.5 ? texture2D(bitmap, c) : textureCam(bitmap, c);
}

vec3 toYIQ(vec3 c) {
	return vec3(dot(c, vec3(0.299, 0.587, 0.114)), dot(c, vec3(0.596, -0.274, -0.322)), dot(c, vec3(0.211, -0.523, 0.312)));
}
vec3 fromYIQ(vec3 c) {
	return vec3(c.x + 0.956 * c.y + 0.621 * c.z, c.x - 0.272 * c.y - 0.647 * c.z, c.x - 1.106 * c.y + 1.703 * c.z);
}

// a band of bad tracking: how deep this line is inside it (1 in the middle, 0 at the edges, -1 outside)
float band(float line, float top, float height) {
	float d = (line - top) / height;
	return (d >= 0.0 && d <= 1.0) ? 1.0 - abs(d * 2.0 - 1.0) : -1.0;
}

void main() {
	float frame = mod(floor(time * 30.0), 4096.0);             // the tape runs at 30 pictures a second (kept small for float precision)
	vec2 uv = barrel(wholeGame > 0.5 ? openfl_TextureCoordv : getCamPos(openfl_TextureCoordv));
	vec2 p = uv * TAPE;

	// ---- the edit: how strong each part of it is right now
	float edit = cutAge >= 0.0 ? cutAge : 99.0;
	float editFrame = floor(edit * 30.0);
	float sync = edit < 0.12 ? 1.0 - edit / 0.12 : 0.0;       // sync lost: the first frames
	float editRoll = 0.0;
	if (edit < 0.1) {
		if (editFrame < 1.0) editRoll = mix(90.0, 330.0, hash(vec2(cutSeed, 1.0)));
		else if (editFrame < 2.0) editRoll = mix(20.0, 90.0, hash(vec2(cutSeed, 2.0)));
		else editRoll = mix(0.0, 12.0, hash(vec2(cutSeed, 3.0)));
	}
	float editSkew = edit < 0.07 ? (hash(vec2(cutSeed, 4.0)) - 0.5) * 0.3 * (1.0 - edit / 0.07) : 0.0;
	float editSnow = edit < 0.1 ? 0.45 * (1.0 - edit / 0.1) : 0.0;
	float editColour = clamp((edit - 0.12) / 0.26, 0.0, 1.0); // colour gone, then back

	// ---- vertical: the roll of an edit or of the vertical hold
	float rollPx = editRoll + roll * TAPE.y;
	float y = mod(p.y + rollPx, TAPE.y);
	float line = floor(y);
	float seam = mod(TAPE.y - rollPx, TAPE.y);                 // where the bottom of one picture meets the top of the next
	bool blanking = rollPx > 0.5 && abs(p.y - seam) < 13.0;

	// ---- horizontal: every line slides on its own
	float wobble = 0.6 * noise * sin(line * 0.045 + time * 3.1 + seed);
	float hook = ((4.0 + 2.0 * sin(time * 1.7)) * noise + 150.0 * sync * mix(0.7, 1.2, hash(vec2(cutSeed, 5.0)))) * exp(-y / 38.0);
	float dx = wobble + hook + editSkew * (y - TAPE.y * 0.5);

	// bad tracking: one or two bands drift up through the picture
	float inBand = -1.0;
	float trk = 0.0;
	if (tracking > 0.001) {
		float speed = mix(0.3, 0.9, hash(vec2(trackSeed, 1.0)));
		float top1 = mod(hash(vec2(trackSeed, 2.0)) * TAPE.y - time * speed * 160.0, TAPE.y);
		float h1 = mix(18.0, 70.0, hash(vec2(trackSeed, 3.0)));
		inBand = band(line, top1, h1);
		if (hash(vec2(trackSeed, 4.0)) > 0.6) inBand = max(inBand, band(line, mod(top1 + 230.0, TAPE.y), h1 * 0.7));
		trk = tracking * (0.4 + 0.6 * tracking);
	}
	// the pause: two bars that do not move (they jitter a few lines)
	float inPause = -1.0;
	if (pauseOn > 0.5) {
		float j = floor(hash(vec2(frame, 7.0)) * 6.0) - 3.0;
		inPause = max(band(line, TAPE.y * 0.28 + j, 22.0), band(line, TAPE.y * 0.71 - j, 22.0));
	}
	float bad = max(inBand >= 0.0 ? trk : 0.0, inPause >= 0.0 ? 1.0 : 0.0);
	if (bad > 0.0) dx += (hash(vec2(floor(line / 2.0), frame)) - 0.5) * 52.0 * bad;
	// head switching: the last lines torn sideways
	if (line > TAPE.y - 10.0) dx += (18.0 + hash(vec2(frame, 3.0)) * 10.0) * noise;

	vec2 q = vec2(p.x - dx, y);

	// ---- luma: soft across with the sharpening halo; chroma: softer and late
	vec4 c0 = tap(q);
	// nothing drawn here and no event that paints the empty (bad bands, snow, blanking): the result is transparent anyway (the colour is
	// multiplied by the alpha at the end), so the other ten reads are skipped. Most of the cameras over the game are empty almost everywhere.
	if (c0.a <= 0.0 && bad <= 0.0 && editSnow <= 0.0 && !blanking) {
		gl_FragColor = vec4(0.0);
		return;
	}
	vec3 l1 = tap(q + vec2(-2.0, 0.0)).rgb;
	vec3 r1 = tap(q + vec2(2.0, 0.0)).rgb;
	vec3 l2 = tap(q + vec2(-5.0, 0.0)).rgb;
	vec3 r2 = tap(q + vec2(5.0, 0.0)).rgb;
	float yNarrow = toYIQ(c0.rgb * 0.4 + (l1 + r1) * 0.3).x;
	float yWide = toYIQ((c0.rgb + l1 + r1 + l2 + r2) * 0.2).x;
	float luma = yNarrow + 0.6 * (yNarrow - yWide);
	vec2 chroma = vec2(0.0);
	for (int k = -2; k <= 2; k++) chroma += toYIQ(tap(q + vec2(-4.0 + float(k) * 6.0, 0.0)).rgb).yz;
	chroma *= 0.2;

	// premultiplied alpha: the colours are worked out on their own and multiplied back at the end
	float a = c0.a;
	float inv = a > 0.001 ? 1.0 / a : 0.0;
	luma *= inv;
	chroma *= inv;
	float glow = max(yWide * inv - 0.8, 0.0) * 0.7;

	// ---- tone: blacks lifted, highlights rolled off
	luma = 0.04 + 0.93 * (1.0 - exp(-luma * 1.34)) / TONE_DEN + glow;

	// ---- noise: streaks on the luma, a touch on the chroma
	luma += (streak(q.x, line, frame, 16.0) - 0.5) * 0.018 * noise;
	chroma.x += (streak(q.x, line + 3.0, frame, 40.0) - 0.5) * 0.01 * noise;

	// ---- colour: tape saturation and warmth, and its losses
	float sat = 1.1 * editColour * (1.0 - satDrop);
	if (hash(vec2(floor(frame / 3.0), 9.0)) < 0.04 * noise) sat *= 0.45;   // the colour flutters now and then
	chroma *= sat;
	chroma += vec2(0.008, 0.0) * sat;
	vec3 col = fromYIQ(vec3(luma, chroma));

	// the colour fringes, added as differences so they do not undo the tone above
	float fringe = 0.5 * min(sat, 1.0);
	float rShift = max(l1.r, l2.r * 0.6);
	col.r += max(rShift - c0.r, 0.0) * inv * fringe;
	col.b += (tap(q + vec2(1.0, 0.0)).b - c0.b) * inv * fringe;

	// ---- the bad bands: lighter, streaky, with bright edges where the head finds and loses the track
	if (bad > 0.0) {
		float s = streak(q.x, line, frame, 6.0);
		col = mix(col, vec3(min(1.0, s + 0.2)), 0.35 * bad);
		float edge = inPause >= 0.0 ? inPause : inBand;
		if (edge < 0.15 && hash(vec2(floor(q.x / 90.0), line + frame)) > 0.6) col = vec3(0.92);
		a = max(a, bad);
	}
	if (line > TAPE.y - 10.0) col = mix(col, vec3(streak(q.x, line, frame, 8.0)), 0.35 * noise);

	// ---- dropouts: a few short white streaks a picture, more during an edit
	float dropRate = 0.0015 * noise + (edit < 0.1 ? 0.02 : 0.0) + 0.01 * bad;
	if (hash(vec2(line * 1.37, frame + 0.5)) < dropRate) {
		float x0 = hash(vec2(line, frame + 1.7)) * TAPE.x;
		float len = mix(8.0, 140.0, hash(vec2(line, frame + 4.2)));
		if (p.x > x0 && p.x < x0 + len) col = vec3(mix(0.7, 1.0, hash(vec2(line, frame + 9.0))));
	}

	// ---- snow of an edit
	if (editSnow > 0.0) {
		col = mix(col, vec3(hash(vec2(floor(p.x / 3.0) + frame * 0.37, floor(p.y / 2.0)))), editSnow);
		a = max(a, editSnow);
	}

	// ---- the blanking bar of a roll: black with the grey sync pulse
	if (blanking) {
		col = abs(p.y - seam) < 3.0 ? vec3(0.27) : vec3(0.025);
		a = 1.0;
	}

	gl_FragColor = vec4(clamp(col, 0.0, 1.0) * a, a);
}
