#pragma header

// Calm, TRANSPARENT water on the floor of the black stage of Limbo (BE-54), drawn in the same 3D space as Zyra's Blender camera. It has no body: where the
// water is flat nothing is drawn (the black shows through). What is drawn is, mostly, RINGS drawn like pencil lines (thin, pale grey, a little broken) that open on the
// floor: some come by themselves here and there, others leave Zyra's feet and the arrow that is hit. On top, a little glitter of the light on a few
// patches of ripples.
// For every pixel the shader rebuilds the ray of the Blender camera (camPos, camRight/camUp/camFwd, focal in pixels of the 1920x1080 render), meets it with
// the plane z = 0 and shades that point: slope of the ripples -> mirror reflection of the light (glitter) and of a dim sky (Fresnel).
//   layerMode  0 = the floor BEHIND Zyra (draw it before her), 1 = the floor in FRONT of her (draw it after her) + the line of water that covers her boots
//   rings      ring0..4 = (x, y, age, amp): where each ring was born on the floor (metres), seconds since, strength (0 = no ring). 0-3 are the arrows (coloured by
//              rc0..3), 4 is Zyra's own
//   sink       how deep her boots are in the water (metres); feetPx is where her feet are in the render
//   amount     0..1 reveal: the water comes out of the black like the rest of the scene
// Every strength is a live uniform. Only 0.0-style floats and no switch, as the engine's compatibility guide asks.
uniform float time;
uniform float layerMode;
uniform vec4 quadRect;
uniform vec2 anchorWorld;
uniform vec2 feetPx;
uniform float pxScale;
uniform vec3 camPos;
uniform vec3 camRight;
uniform vec3 camUp;
uniform vec3 camFwd;
uniform float focal;
uniform vec2 renderHalf;
uniform float depthZ;
uniform vec3 light3;
uniform vec3 lightColor;
uniform float amount;
uniform float sink;
uniform vec4 ring0;
uniform vec4 ring1;
uniform vec4 ring2;
uniform vec4 ring3;
uniform vec4 ring4;
uniform vec3 rc0;
uniform vec3 rc1;
uniform vec3 rc2;
uniform vec3 rc3;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vn(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i), hash2(i + vec2(1.0, 0.0)), f.x), mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), f.x), f.y);
}

// a ring that spreads out from where it was born: returns (slope x, slope y, brightness of the crest)
vec3 ringField(vec2 p, vec4 r) {
	if (r.w <= 0.001) return vec3(0.0, 0.0, 0.0);
	vec2 dd = p - r.xy;
	float d = length(dd) + 0.0001;
	float front = 0.8 * r.z;
	float w = 0.10 + 0.05 * r.z;
	float k = (d - front) / w;
	float env = exp(-k * k * 0.5) * r.w * exp(-r.z * 0.8) / (1.0 + 1.3 * front);
	float tilt = -sin(k * 2.2) * env * 0.12;
	return vec3(dd.x / d * tilt, dd.y / d * tilt, abs(tilt) * 0.9 + env * 0.15);
}

// the width of one screen pixel on the floor, measured across a line whose normal on the floor is g (the floor is seen very obliquely: a pixel covers
// much more floor in depth than across, so the lines are as thin as pencil lines everywhere)
float pxWidth(vec2 g, vec3 ud, float s) {
	float a = s / focal;
	float b = a / max(0.12, 0.0 - ud.z);
	vec2 h = normalize(ud.xy + vec2(0.00001, 0.0));
	vec2 r = vec2(0.0 - h.y, h.x);
	float gr = dot(g, r) / a;
	float gh = dot(g, h) / b;
	return 1.0 / sqrt(gr * gr + gh * gh + 0.000001);
}

// one thin, a little broken, circular line of radius R around c: 0..1 coverage
float ringLine(vec2 p, vec2 c, float R, vec3 ud, float s, float seed) {
	vec2 dd = p - c;
	float d = length(dd) + 0.0001;
	float w = pxWidth(dd / d, ud, s) * 2.0;
	float line = 1.0 - smoothstep(0.35 * w, 1.1 * w, abs(d - R));
	float ang = atan(dd.y, dd.x);
	float dash = smoothstep(0.15, 0.40, fract(ang * 1.1 + seed * 5.0) + 0.25 * sin(ang * 3.0 + seed * 9.0));
	return line * dash;
}

// the rings that come by themselves: every cell of the floor has (maybe) a ring that opens, fades and starts again
float ambientRings(vec2 p, vec3 ud, float s) {
	float total = 0.0;
	vec2 id = floor(p / 2.4);
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 cell = id + vec2(float(i), float(j));
			float h = hash2(cell);
			if (h > 0.15) {
				vec2 c = (cell + vec2(0.2 + 0.6 * hash2(cell + 1.3), 0.2 + 0.6 * hash2(cell + 7.7))) * 2.4;
				float T = 4.5 + 3.0 * hash2(cell + 4.1);
				float ph = fract(time / T + h * 7.0);
				float fade = pow(1.0 - ph, 1.6) * smoothstep(0.0, 0.06, ph);
				float R = ph * 1.4;
				float l1 = ringLine(p, c, R, ud, s, h);
				float l2 = ringLine(p, c, R * 0.62, ud, s, h + 0.4) * step(0.2, ph) * 0.6;
				total += (l1 + l2) * fade * 0.8;
			}
		}
	}
	return total;
}

// the rings of an event (Zyra's feet, an arrow that was hit): three lines that open together
float eventRings(vec2 p, vec4 r, vec3 ud, float s) {
	if (r.w <= 0.001) return 0.0;
	float front = 0.9 * r.z;
	float env = r.w * exp(-r.z * 0.7) * smoothstep(0.0, 0.05, r.z);
	float l = ringLine(p, r.xy, front, ud, s, 0.3) + 0.7 * ringLine(p, r.xy, front * 0.64, ud, s, 0.7) + 0.4 * ringLine(p, r.xy, front * 0.32, ud, s, 0.1);
	return l * env;
}

void main() {
	vec2 uv = openfl_TextureCoordv;
	vec2 wpx = quadRect.xy + uv * quadRect.zw;
	vec2 rpx = feetPx + (wpx - anchorWorld) / pxScale;
	vec3 ud = normalize(camFwd * focal + camRight * (rpx.x - renderHalf.x) + camUp * (renderHalf.y - rpx.y));

	vec3 col = vec3(0.0, 0.0, 0.0);
	float a = 0.0;

	// the floor: where the ray meets z = 0, behind or in front of Zyra's plane
	if (ud.z < -0.0001) {
		float s = (0.0 - camPos.z) / ud.z;
		float sz = depthZ / dot(ud, camFwd);
		float inLayer = (layerMode < 0.5) ? step(sz, s) : step(s, sz);
		vec2 p = camPos.xy + ud.xy * s;
		float farFade = 1.0 - smoothstep(14.0, 38.0, s);
		float nearFade = smoothstep(1.5, 5.0, s);
		float res = 1.0 / (1.0 + 0.08 * s);               // the small ripples are lost with distance (and do not shimmer into noise)

		// where the water is disturbed: a few patches of a few metres that drift slowly; the rest is flat and shows nothing
		float pat = smoothstep(0.50, 0.80, vn(p * 0.32 + vec2(time * 0.025, 3.0)) * 0.7 + vn(p * 0.9 + vec2(7.0, time * 0.04)) * 0.3);
		// the slope of the ripples: a few crossing waves, slow
		vec2 sl = vec2(0.0, 0.0);
		sl += vec2(0.6, 0.8) * (0.034 * cos(2.1 * (0.6 * p.x + 0.8 * p.y) - time * 0.9));
		sl += vec2(-0.8, 0.6) * (0.040 * cos(3.4 * (0.0 - 0.8 * p.x + 0.6 * p.y) - time * 1.3 + 1.7));
		sl += vec2(0.28, -0.96) * (0.050 * cos(5.6 * (0.28 * p.x - 0.96 * p.y) - time * 1.8 + 4.0)) * res;
		sl += vec2(0.96, 0.28) * (0.040 * cos(9.0 * (0.96 * p.x + 0.28 * p.y) - time * 2.4 + 2.0)) * res * res;
		// fine ripples on top: a thin grain that makes the glitter sharp (they fade out with distance, and so does the grain)
		sl += vec2(0.5, 0.87) * (0.035 * cos(15.0 * (0.5 * p.x + 0.87 * p.y) - time * 2.9 + 0.7)) * res * res;
		sl += vec2(-0.94, 0.34) * (0.030 * cos(26.0 * (0.0 - 0.94 * p.x + 0.34 * p.y) - time * 3.6 + 3.1)) * res * res * res;
		sl *= pat;

		// the rings: the arrows that were hit and Zyra's feet
		vec3 f0 = ringField(p, ring0);
		vec3 f1 = ringField(p, ring1);
		vec3 f2 = ringField(p, ring2);
		vec3 f3 = ringField(p, ring3);
		vec3 f4 = ringField(p, ring4);
		sl += (f0.xy + f1.xy + f2.xy + f3.xy + f4.xy) * res;

		vec3 n = normalize(vec3(-sl.x, -sl.y, 1.0));
		vec3 V = -ud;
		vec3 L = normalize(light3 - vec3(p, 0.0));
		vec3 H = normalize(L + V);
		float glit = pow(max(dot(n, H), 0.0), 240.0);
		float cosv = max(dot(n, V), 0.0);
		float F = 0.03 + 0.97 * pow(1.0 - cosv, 5.0);
		// the dim sky mirrored by the ripples: only where they are tilted, and brighter on their tilted sides
		float sky = F * min(1.0, length(sl) * 14.0);

		// the glitter twinkles (each patch of water on its own time, smoothly) and the sky haze is kept very low: what is seen are fine points and thin lines
		float twinkle = 0.55 + 0.45 * sin(time * 2.6 + vn(p * 2.5) * 14.0);
		col = lightColor * glit * 4.0 * twinkle + vec3(0.52, 0.54, 0.58) * sky * 0.4;
		// the pencil rings: the ones that come by themselves are dark grey; the ones of an arrow take its colour
		vec3 pale = vec3(0.66, 0.68, 0.72);
		vec3 lines = pale * ambientRings(p, ud, s) * 1.4 + pale * eventRings(p, ring4, ud, s) * 0.9;
		lines += rc0 * eventRings(p, ring0, ud, s) + rc1 * eventRings(p, ring1, ud, s) + rc2 * eventRings(p, ring2, ud, s) + rc3 * eventRings(p, ring3, ud, s);
		col += lines * (1.0 - 0.0);
		col *= inLayer * farFade * nearFade * amount;
	}

	// her boots are in the water: a band of dark water covers their bottom, with a thin line of light at the edge, a little uneven
	if (layerMode > 0.5) {
		float sinkPx = focal * sink / depthZ;
		float halfW = focal * 0.36 / depthZ;
		float dx = (rpx.x - feetPx.x) / halfW;
		float dy = (feetPx.y - rpx.y) / sinkPx;
		float wob = 0.10 * sin(rpx.x * 0.045 + time * 1.6) + 0.06 * sin(rpx.x * 0.13 - time * 2.3);
		float side = 1.0 - smoothstep(0.55, 1.0, abs(dx));
		float covered = smoothstep(1.0 + wob, 0.8 + wob, dy) * step(-0.3, dy) * side * amount;
		float line = exp(-pow((dy - 1.0 - wob) / 0.11, 2.0)) * side * amount;
		vec3 water = vec3(0.020, 0.021, 0.024);
		col = col + water * covered * 0.6 + vec3(0.45, 0.47, 0.50) * line * 0.18;
		a = max(a, covered * 0.62);
	}

	a = clamp(max(a, max(col.r, max(col.g, col.b))), 0.0, 1.0);
	gl_FragColor = vec4(min(col, vec3(a)), a);
}
