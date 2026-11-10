#pragma header

// The tape's transitions between screens (BE-63; Zyra, 2026-11-10). scripts/effects/tapeTransition.hx puts it, for a moment,
// on every camera that the tape (VHSShader) covers, after the tape, and drives these uniforms. It works in "tape pixels":
// the picture is always treated as 1280x720 whatever the window size. ASCII only: the Mac driver rejects anything else (trap 30).
//
// The edit point (pausing the camcorder and recording again): jump, sat, rainbow, drops.
//   jump     tape pixels the picture is moved down (negative: up); the gap it opens is the black of the blanking
//   sat      colour, 1 = normal, 0 = grey (the colour takes a moment to lock after an edit)
//   rainbow  the band of chroma stripes a camcorder leaves at the bottom of an edit (0..1), at rainbowTop, rainbowH tall,
//            moved sideways by rainbowShift
//   drops    dropouts: short white streaks where the oxide is missing (0..1, how many)
// The chewed tape (entering or leaving a song): warp, tear, stretch, mono, bright.
//   warp     every line pushed sideways by a wave and by noise (0..1)
//   tear     three bands of the picture torn sideways (0..1)
//   stretch  vertical scale about the middle: above 1 stretched, below 1 squashed into a line (outside it is black)
//   mono     grey with a hard contrast (0..1)
//   bright   a multiplier of the light
// It keeps the alpha of what it draws over (trap 16), except where it draws black or a streak of its own.

uniform float time;
uniform float seed;
uniform float jump;
uniform float sat;
uniform float rainbow;
uniform float rainbowTop;
uniform float rainbowH;
uniform float rainbowShift;
uniform float drops;
uniform float warp;
uniform float tear;
uniform float stretch;
uniform float mono;
uniform float bright;

const vec2 TAPE = vec2(1280.0, 720.0);

// a hash without sin() (Dave Hoskins), the same as the tape's
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void main() {
	vec2 p = getCamPos(openfl_TextureCoordv) * TAPE;
	float frame = floor(time * 15.0);
	float line = floor(p.y);

	// squashed into a line or stretched, about the middle of the picture
	float s = max(stretch, 0.001);
	float halfH = TAPE.y * 0.5;
	if (abs(p.y - halfH) > halfH * s) {
		gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
		return;
	}
	vec2 q = vec2(p.x, halfH + (p.y - halfH) / s - jump);

	if (warp > 0.0) {
		float wave = sin(q.y * 0.045 + time * 9.0 + seed * 6.0) * 0.6;
		float jitter = hash(vec2(floor(q.y / 3.0), frame + seed)) - 0.5;
		q.x += (wave + jitter * 0.8) * 90.0 * warp;
	}
	if (tear > 0.0) {
		for (int i = 0; i < 3; i++) {
			float fi = float(i);
			float top = hash(vec2(fi, seed + floor(frame / 2.0))) * TAPE.y;
			float h = mix(20.0, 120.0, hash(vec2(fi + 7.0, seed + floor(frame / 2.0))));
			if (q.y > top && q.y < top + h) q.x += (hash(vec2(fi + 3.0, frame + seed)) - 0.5) * 400.0 * tear;
		}
	}

	vec3 col = vec3(0.0);
	float a = 1.0;
	if (q.y >= 0.0 && q.y <= TAPE.y) {
		vec4 c = textureCam(bitmap, clamp(q / TAPE, vec2(0.0), vec2(1.0)));
		a = c.a;
		col = a > 0.0 ? c.rgb / a : vec3(0.0);
	}

	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l), col, clamp(sat, 0.0, 1.0));
	if (mono > 0.0) col = mix(col, vec3(clamp((l - 0.5) * (1.0 + 0.9 * mono) + 0.5, 0.0, 1.0)), mono);
	col *= bright;

	if (rainbow > 0.0 && p.y > rainbowTop && p.y < rainbowTop + rainbowH) {
		float x = mod(p.x + rainbowShift + 2900.0, 29.0);
		vec3 stripe = x < 9.0 ? vec3(1.0, 0.16, 0.47) : (x < 17.0 ? vec3(0.16, 1.0, 0.78) : (x < 26.0 ? vec3(0.35, 0.35, 1.0) : vec3(1.0)));
		col += stripe * 0.55 * rainbow;
		a = max(a, 0.6 * rainbow);
	}

	if (drops > 0.0 && hash(vec2(floor(line / 2.0) * 1.37, frame + seed)) < 0.03 * drops) {
		float x0 = hash(vec2(floor(line / 2.0), frame + 1.7)) * TAPE.x;
		float len = mix(20.0, 220.0, hash(vec2(floor(line / 2.0), frame + 4.2)));
		if (p.x > x0 && p.x < x0 + len) {
			col = vec3(0.95);
			a = 1.0;
		}
	}

	gl_FragColor = vec4(clamp(col, 0.0, 1.0) * a, a);
}
