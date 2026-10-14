#pragma header

// The "channel change" of the theme system (BE-16): an old TV losing the signal and tuning a new one. It is
// added to the camera that draws the wallpaper and the UI (Zyra and the pencil are on another camera, so they
// are never touched) only while a theme change lasts. Every strength is a live uniform.
//   tear     horizontal bands that slide sideways          rgb    colour-channel split
//   snow     TV noise                                       roll   vertical roll (0..1)
//   scan     scanlines                                      whiteMix  fade to Zyra's real white background
//   reveal   0..1: how much of the new wallpaper has arrived (white where it has not), with the signature
//   revealMode  0 Vista (a bloom from the centre with a light streak), 1 XP (repainted from the top, few
//               colours first), 2 Windows 98 (a mosaic of tiles, 16-colour look), 3 Mac (a ripple from the
//               centre), 4 none (the whole picture is shown)
uniform float time;
uniform float tear;
uniform float rgb;
uniform float snow;
uniform float roll;
uniform float scan;
uniform float whiteMix;
uniform float reveal;
uniform float revealMode;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
	vec2 q = getCamPos(openfl_TextureCoordv);
	vec2 uv = q;

	uv.y = fract(uv.y + roll);

	float band = floor(uv.y * 30.0);
	float tick = floor(time * 18.0);
	float shift = hash(vec2(band, tick)) - 0.5;
	float active = step(0.55, hash(vec2(band * 1.7, tick + 3.0)));
	uv.x += shift * tear * 0.22 * active;

	if (revealMode > 2.5 && revealMode < 3.5) {
		vec2 dir = q - vec2(0.5, 0.5);
		float d = length(dir * vec2(1.78, 1.0));
		float w = sin(d * 42.0 - reveal * 24.0) * 0.012 * (1.0 - reveal);
		uv += normalize(dir + vec2(0.0001, 0.0)) * w;
	}

	float split = rgb * 0.03;
	vec3 col;
	col.r = textureCam(bitmap, vec2(uv.x + split, uv.y)).r;
	col.g = textureCam(bitmap, uv).g;
	col.b = textureCam(bitmap, vec2(uv.x - split, uv.y)).b;

	if (revealMode < 2.5) {
		float m = 1.0;
		if (revealMode < 0.5) {
			float d = length((q - 0.5) * vec2(1.78, 1.0));
			float edge = reveal * 1.35;
			m = 1.0 - smoothstep(edge - 0.3, edge, d);
			col += vec3(0.35) * exp(-pow((d - (edge - 0.1)) * 7.0, 2.0)) * step(0.001, reveal) * (1.0 - reveal * 0.5);
		} else if (revealMode < 1.5) {
			float edge = reveal * 1.15;
			m = 1.0 - smoothstep(edge - 0.12, edge, q.y);
			float levels = mix(4.0, 48.0, reveal);
			col = floor(col * levels + 0.5) / levels;
		} else {
			float cell = hash(floor(q * vec2(32.0, 18.0)));
			m = step(cell, reveal * 1.05);
			float levels = mix(3.0, 12.0, reveal);
			col = floor(col * levels + 0.5) / levels;
		}
		col = mix(vec3(1.0), col, m);
	} else if (revealMode < 3.5) {
		float d = length((q - 0.5) * vec2(1.78, 1.0));
		float edge = reveal * 1.5;
		col = mix(vec3(1.0), col, 1.0 - smoothstep(edge - 0.25, edge, d));
	}

	float n = hash(q * vec2(640.0, 360.0) + time * 60.0);
	col = mix(col, vec3(n), snow * 0.55);
	col *= 1.0 - scan * 0.12 * step(0.5, fract(q.y * 240.0));
	col = mix(col, vec3(1.0), whiteMix);

	gl_FragColor = vec4(col, 1.0);
}
