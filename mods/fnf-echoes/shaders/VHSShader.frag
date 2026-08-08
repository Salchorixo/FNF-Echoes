#pragma header

// VHS/CRT look for the whole window (see docs/adr/, After Effects reference
// stack in production notes: Optics Compensation, Venetian Blinds, VR
// Chromatic Aberrations, Fast Box Blur, Add Grain, Glow, Brightness &
// Contrast). AE's own math for each of those doesn't translate 1:1 to
// GLSL, so every strength below is a uniform tuned to *look* like the
// reference rather than reproduce its formulas exactly.
uniform float lensDistortAmount;
uniform float chromaticAberrationAmount;
uniform float chromaticAberrationFalloff;
uniform float blurAmount;
uniform float grainIntensity;
uniform float time;
uniform float glowThreshold;
uniform float glowIntensity;
uniform float brightness;
uniform float contrast;
uniform float scanlineWidth;
uniform float scanlineOpacity;
uniform float vignetteRadius;
uniform float vignetteSoftness;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 lensDistort(vec2 uv, float amount) {
	vec2 centered = uv - 0.5;
	float r2 = dot(centered, centered);
	return centered * (1.0 + amount * r2) + 0.5;
}

void main() {
	vec2 uv = getCamPos(openfl_TextureCoordv);
	vec2 warpedUV = lensDistort(uv, lensDistortAmount);

	vec2 toCenter = warpedUV - 0.5;
	float edgeDistance = length(toCenter);
	float aberrationStrength = smoothstep(0.0, chromaticAberrationFalloff, edgeDistance) * chromaticAberrationAmount;
	vec2 aberrationDir = toCenter / max(edgeDistance, 0.0001);

	vec3 col;
	col.r = textureCam(bitmap, warpedUV - aberrationDir * aberrationStrength).r;
	col.g = textureCam(bitmap, warpedUV).g;
	col.b = textureCam(bitmap, warpedUV + aberrationDir * aberrationStrength).b;

	vec3 blurred = vec3(0.0);
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			vec2 offset = vec2(float(x), float(y)) * blurAmount;
			blurred += textureCam(bitmap, warpedUV + offset).rgb;
		}
	}
	blurred /= 9.0;
	col = mix(col, blurred, 0.35);

	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	float glowMask = smoothstep(glowThreshold, 1.0, luma);
	col += blurred * glowMask * glowIntensity;

	float scanline = step(scanlineWidth, mod(gl_FragCoord.y, scanlineWidth * 2.0));
	col *= mix(1.0, scanline, scanlineOpacity);

	float grain = (rand(uv * 1000.0 + time) - 0.5) * grainIntensity;
	col += grain;

	col = (col - 0.5) * contrast + 0.5 + brightness;

	vec2 fromCenterAbs = abs(uv - 0.5) * 2.0;
	vec2 corner = max(fromCenterAbs - vignetteRadius, 0.0);
	float vignette = 1.0 - smoothstep(0.0, vignetteSoftness, length(corner));
	col *= vignette;

	gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
