#pragma header

// Zyra's reflection as dark water with glitch (BE-54). It is applied to a vertically flipped copy of her sprite (frames shared with her), so
// the feet are at the top of this sprite (depth 0) and the reflection goes down. The sprite lives inside an atlas, so the script sends the
// rectangle of the current frame (frameRect = left, top, width, height in uv) and every sample stays inside it.
//   wave     ripple strength (in frame widths)      fadeLen  share of the frame height the reflection lasts
//   glitch   0..1: bands that jump sideways, colour split and scanlines, in short bursts   tint  colour of the water
// Every strength is a live uniform.
uniform float time;
uniform vec4 frameRect;
uniform float wave;
uniform float fadeLen;
uniform float glitch;
uniform vec3 tint;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 samp(vec2 l) {
	if (l.x < 0.0 || l.x > 1.0 || l.y < 0.0 || l.y > 1.0)
		return vec4(0.0, 0.0, 0.0, 0.0);
	return flixel_texture2D(bitmap, vec2(frameRect.x + l.x * frameRect.z, frameRect.y + l.y * frameRect.w));
}

void main() {
	vec2 l = vec2((openfl_TextureCoordv.x - frameRect.x) / frameRect.z, (openfl_TextureCoordv.y - frameRect.y) / frameRect.w);
	float depth = 1.0 - l.y;

	// water: ripples that widen with depth, a slow swell, and a small vertical wobble
	float ripple = sin(depth * 46.0 - time * 3.2) + 0.6 * sin(depth * 113.0 + time * 4.7) + 0.4 * sin(depth * 21.0 - time * 1.3);
	float off = ripple * wave * (0.15 + depth * 1.1);
	float wob = sin(l.x * 18.0 + time * 2.2) * 0.012 * (0.4 + depth);

	// glitch: bands that jump sideways, mostly in bursts (about one tick in five), with a colour split
	float tick = floor(time * 14.0);
	float band = floor(depth * 26.0);
	float burst = step(0.82, hash(vec2(tick, 3.0)));
	float jump = (hash(vec2(band, tick)) - 0.5) * step(0.7, hash(vec2(band + 9.0, tick)));
	off += jump * glitch * (0.12 + 0.35 * burst);
	float split = glitch * (0.012 + 0.035 * burst);

	vec2 s = vec2(l.x + off, l.y + wob);
	vec4 cr = samp(s + vec2(split, 0.0));
	vec4 cg = samp(s);
	vec4 cb = samp(s - vec2(split, 0.0));
	vec3 col = vec3(cr.r, cg.g, cb.b) * tint;
	float a = max(cr.a, max(cg.a, cb.a));

	float fade = pow(clamp(1.0 - depth / fadeLen, 0.0, 1.0), 1.4);
	float shimmer = 0.78 + 0.22 * sin(depth * 150.0 - time * 5.0 + sin(l.x * 9.0) * 2.0);
	float scan = 1.0 - glitch * 0.35 * step(0.5, fract(depth * 90.0 + time * 0.5));
	gl_FragColor = vec4(col, a) * (fade * shimmer * scan);
}
