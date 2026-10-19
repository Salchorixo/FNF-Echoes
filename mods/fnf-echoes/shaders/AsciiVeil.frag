#pragma header

// A veil of ASCII characters over a camera (BE-57/BE-58). The screen is cut in cells of `cell` pixels (always the same grid on every camera, counted from the corner
// of the SCREEN); each cell looks at the colour of the picture at its centre and, if that is bright enough, draws one of the glyphs of images/game/ascii/ramp.png
// (` .:-=+*#%@`, from dim to bright) in light over it. The picture underneath is NOT replaced: the shapes keep reading as they were, the characters only add a
// texture to what is lit. So it can be very light (strength 0.15 on the mist and on Zyra) or stronger (0.5 on the arrows) and nothing is lost for the game.
// It is meant to belong to the picture, not to sit over it:
//   - the characters are drawn with the colour of the picture itself (inkMix near 1), only a touch of inkColor, and they have soft edges;
//   - they are strongest where the picture is brightest and fade with it, pixel by pixel;
//   - they move, slowly: about a third of the cells swap to the next dimmer glyph and back at their own pace, a soft wave crosses the veil diagonally and the
//     whole veil breathes a little (time is a uniform the script advances).
//   glyphs      the alphabet (count glyphs side by side)      cell        size of a cell in pixels      minLuma   below this brightness nothing is drawn
//   gain        how bright the picture must be for the last glyph      inkColor   colour of the characters, mixed with the colour of the picture (inkMix)
//   quietY/quietH/quiet  a horizontal band of the screen (centre and half height, in pixels) where the veil is multiplied by `quiet`: the row of receptors is quieter
//              than the notes that pass over the rest of the screen (1 = no band)
//   camSize/camOffset  size of the camera and where its corner is on the screen (the arrows' camera is taller than the screen)
uniform sampler2D glyphs;
uniform vec2 camSize;
uniform vec2 camOffset;
uniform vec2 cell;
uniform float count;
uniform float strength;
uniform float minLuma;
uniform float gain;
uniform float inkMix;
uniform float time;
uniform float quietY;
uniform float quietH;
uniform float quiet;
uniform vec3 inkColor;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float glyphAt(float idx, vec2 local) {
	float du = 0.5 / (count * 8.0);
	float dv = 0.5 / 14.0;
	vec2 uv = vec2((idx + 0.06 + local.x * 0.88) / count, local.y);
	float c = texture2D(glyphs, uv).a;
	float l = texture2D(glyphs, uv - vec2(du, 0.0)).a;
	float r = texture2D(glyphs, uv + vec2(du, 0.0)).a;
	float u = texture2D(glyphs, uv - vec2(0.0, dv)).a;
	float d = texture2D(glyphs, uv + vec2(0.0, dv)).a;
	return 0.4 * c + 0.15 * (l + r + u + d);
}

void main() {
	vec2 q = getCamPos(openfl_TextureCoordv);
	vec4 base = textureCam(bitmap, q);
	vec2 spx = q * camSize + camOffset;
	vec2 cellId = floor(spx / cell);
	vec2 local = fract(spx / cell);
	vec2 cq = clamp(((cellId + 0.5) * cell - camOffset) / camSize, 0.0, 1.0);
	vec4 cc = textureCam(bitmap, cq);
	float luma = dot(cc.rgb, vec3(0.299, 0.587, 0.114));

	// each cell lives at its own pace: a third of them swap to the next dimmer glyph and back, slowly
	float h = hash(cellId);
	float pace = 0.25 + 0.35 * fract(h * 7.0);
	float swap = step(0.66, h) * step(0.5, fract(time * pace + h * 13.0));
	float idx = max(0.0, floor(clamp(luma * gain, 0.0, 0.999) * count) - swap);
	float g = glyphAt(idx, local);

	float vis = smoothstep(minLuma, minLuma + 0.06, luma);
	// a soft wave crosses the veil diagonally and the whole veil breathes a little
	float wave = 0.8 + 0.2 * sin(spx.x * 0.012 + spx.y * 0.018 - time * 0.9);
	float breathe = 0.93 + 0.07 * sin(time * 0.6);
	// strongest where the picture itself is brightest, pixel by pixel
	float pixelL = dot(base.rgb, vec3(0.299, 0.587, 0.114));
	float lit = 0.35 + 0.65 * clamp(pixelL * gain * 1.2, 0.0, 1.0);

	vec3 pic = cc.rgb / max(max(cc.r, max(cc.g, cc.b)), 0.001);
	vec3 ink = mix(inkColor, pic, inkMix);
	float inBand = 1.0 - smoothstep(quietH, quietH * 1.6, abs(spx.y - quietY));
	vec3 add = ink * (g * vis * strength * mix(1.0, quiet, inBand) * wave * breathe * lit);
	gl_FragColor = vec4(base.rgb + add, max(base.a, max(add.r, max(add.g, add.b))));
}
