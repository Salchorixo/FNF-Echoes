#pragma header

// The "channel change" (see ChannelShader.frag) for TRANSPARENT cameras, like the Settings window's (BE-28): the same
// tearing, colour split, snow, scanlines and white flash, but the picture keeps its own alpha (ChannelShader always
// writes alpha 1, which would paint a solid box over a transparent camera). Driven by the main menu's live values.
uniform float time;
uniform float tear;
uniform float rgb;
uniform float snow;
uniform float scan;
uniform float whiteMix;
uniform float flash;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
	vec2 q = getCamPos(openfl_TextureCoordv);
	vec2 uv = q;

	float band = floor(uv.y * 30.0);
	float tick = floor(time * 18.0);
	float shift = hash(vec2(band, tick)) - 0.5;
	float active = step(0.55, hash(vec2(band * 1.7, tick + 3.0)));
	uv.x += shift * tear * 0.22 * active;

	float split = rgb * 0.03;
	vec4 r = textureCam(bitmap, vec2(uv.x + split, uv.y));
	vec4 g = textureCam(bitmap, uv);
	vec4 b = textureCam(bitmap, vec2(uv.x - split, uv.y));
	float a = max(g.a, max(r.a, b.a));
	vec3 col = vec3(r.r, g.g, b.b);

	float n = hash(q * vec2(640.0, 360.0) + time * 60.0);
	col = mix(col, vec3(n) * a, snow * 0.55);
	col *= 1.0 - scan * 0.12 * step(0.5, fract(q.y * 240.0));
	col = mix(col, vec3(a), clamp(whiteMix + flash, 0.0, 1.0));

	gl_FragColor = vec4(col, a);
}
