#pragma header

// Puts the whole flat picture of a camera (Zyra's row of arrows, drawn by the engine as usual) onto a PLANE of the 3D scene, as seen by Zyra's real Blender camera
// (BE-57). For every pixel of the screen the shader rebuilds the ray that camera would shoot through it (camPos, camRight/camUp/camFwd, focal in pixels of the
// 1920x1080 render; hudPerRender turns render pixels into the 1280x720 pixels of the game), finds where the ray hits the plane and reads the flat picture at that
// point. So the arrows are really foreshortened, the lanes converge to a vanishing point and a long note leans with them: it is a true perspective warp,
// not sprites moved and scaled one by one.
//   plane      planeO = where the middle of the row of receptors is in the scene (metres), planeR = the direction of the row, planeU = the direction the notes
//              travel on the plane (both unit vectors, planeU already leaned by the tilt)
//   flat       flatCentre = the middle of the receptors in the flat picture (pixels of the 1280x720 HUD, after the downscroll flip) and mpp = metres per pixel there
//   camSize/camOffset  the camera of the arrows is TALLER than the screen (it also covers the stretch where the notes appear, above the top of the screen in downscroll)
//              and sits partly off it: camOffset is where its corner is on the screen. Everything the shader computes in screen pixels is turned back to the
//              camera's own picture at the end
//   hudZoom    the zoom the HUD camera has (the beat bounce): the whole projected plane grows around the centre of the screen
//   flatMode   for the shots where the row is NOT on a plane: the flat picture is only made smaller (flatScale, around the middle of the receptors) and moved
//              down (flatShiftY pixels); the notes fade in at the top in the same way
//   rollRad/shiftPx  the camera LEANS with the notes (songs/limboScene.hx): the world cameras roll and move, and so must the arrows that live in the scene, so the
//              plane is seen through the same roll (radians, clockwise) and shift (screen pixels) as they are
//   desat/tint a COMMON PALETTE for the arrows: their colours are pulled a little towards grey (desat, 0..1) and towards the cool tone of the scene (tint)
//   mirror*    the arrows are REFLECTED in the floor (the same floor where Zyra's reflection is): the plane is mirrored about z = 0 and seen through the floor,
//              dimmer (mirrorAlpha), fading with depth below the floor (mirrorFade metres), with ripples (mirrorWave metres) and short sideways jumps of bands
//              (mirrorGlitch), tinted like water (mirrorTint)
//   fade       the notes fade in between fadeStart and fadeEnd (share of the screen height away from the receptors) so they do not pop in half way
//   haze*      BE-58, the places: the farther along the plane a note is (metres from the receptors, between hazeStart and hazeEnd), the more it takes the
//              colour of the place's air (hazeColor), up to hazeAmount
//   glitch*    BE-58: the arrows glitch with the scenes (0 = clean, 1 = strong): the colours split sideways (glitchSplit pixels at 1), bands of the
//              screen jump sideways (24 times a second), now and then a band drops out; glitchRed pulls them towards red (the second pass)
// Every strength is a live uniform. Only 0.0-style floats and no switch, as the engine's compatibility guide asks.
uniform vec3 camPos;
uniform vec3 camRight;
uniform vec3 camUp;
uniform vec3 camFwd;
uniform float focal;
uniform float hudPerRender;
uniform vec3 planeO;
uniform vec3 planeR;
uniform vec3 planeU;
uniform vec2 flatCentre;
uniform float mpp;
uniform vec2 hudSize;
uniform vec2 camSize;
uniform vec2 camOffset;
uniform float hudZoom;
uniform float fadeStart;
uniform float fadeEnd;
uniform float rollRad;
uniform vec2 shiftPx;
uniform float desat;
uniform vec3 tint;
uniform float time;
uniform float mirrorAlpha;
uniform float mirrorFade;
uniform float mirrorWave;
uniform float mirrorGlitch;
uniform vec3 mirrorTint;
uniform float flatMode;
uniform float flatScale;
uniform float flatShiftY;
uniform vec3 hazeColor;
uniform float hazeAmount;
uniform float hazeStart;
uniform float hazeEnd;
uniform float glitch;
uniform float glitchSplit;
uniform float glitchRed;

vec4 grade(vec4 c) {
	if (c.a <= 0.001) return c;
	vec3 rgb = c.rgb / c.a;
	float l = dot(rgb, vec3(0.299, 0.587, 0.114));
	rgb = mix(rgb, vec3(l) * tint, desat);
	return vec4(rgb * c.a, c.a);
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float gZ = 1.0;     // height of the point the last onPlane() call hit

// what the flat picture shows where the ray `d` meets the plane (O, R, U); transparent when it misses
vec4 onPlane(vec3 O, vec3 R, vec3 U, vec3 d, float ripple, float jump) {
	vec3 n = cross(R, U);
	float den = dot(n, d);
	gZ = 1.0;
	if (abs(den) < 0.000001) return vec4(0.0, 0.0, 0.0, 0.0);
	float t = dot(n, O - camPos) / den;
	if (t <= 0.0) return vec4(0.0, 0.0, 0.0, 0.0);
	vec3 p3 = camPos + d * t;
	gZ = p3.z;
	vec3 p = p3 - O;
	float u = dot(p, R);
	float v = dot(p, U);
	if (ripple > 0.0 || jump > 0.0) {
		float band = floor(abs(v) * 8.0);
		float tick = floor(time * 14.0);
		u += ripple * sin(v * 9.0 - time * 3.2) + (hash2(vec2(band, tick)) - 0.5) * step(0.75, hash2(vec2(band + 9.0, tick))) * jump;
	}
	vec2 src = vec2(flatCentre.x + u / mpp, flatCentre.y - v / mpp);
	vec2 sq = (src - camOffset) / camSize;
	if (sq.x < 0.0 || sq.x > 1.0 || sq.y < 0.0 || sq.y > 1.0) return vec4(0.0, 0.0, 0.0, 0.0);
	float dist = abs(src.y - flatCentre.y) / hudSize.y;
	float fade = 1.0 - smoothstep(fadeStart, fadeEnd, dist);
	vec4 c = grade(textureCam(bitmap, sq)) * fade;
	if (hazeAmount > 0.001) {
		float h = smoothstep(hazeStart, hazeEnd, abs(v)) * hazeAmount;
		c = vec4(mix(c.rgb, hazeColor * c.a, h), c.a);
	}
	return c;
}

// what the arrows' picture shows at this point of the screen (screen pixels of the 1280x720 HUD, before the camera's own zoom)
vec4 arrowsAt(vec2 scr) {
	scr = (scr - hudSize * 0.5) / hudZoom + hudSize * 0.5;
	if (flatMode < 0.5) {
		vec2 dd = scr - hudSize * 0.5 - shiftPx;
		scr = vec2(cos(rollRad) * dd.x + sin(rollRad) * dd.y, 0.0 - sin(rollRad) * dd.x + cos(rollRad) * dd.y) + hudSize * 0.5;
	}
	vec2 rp = scr / hudPerRender;
	vec3 d = camFwd * focal + camRight * (rp.x - 960.0) + camUp * (540.0 - rp.y);

	if (flatMode > 0.5) {
		vec2 pivot = vec2(flatCentre.x, flatCentre.y + flatShiftY);
		vec2 fsrc = flatCentre + (scr - pivot) / flatScale;
		vec2 fq = (fsrc - camOffset) / camSize;
		if (fq.x < 0.0 || fq.x > 1.0 || fq.y < 0.0 || fq.y > 1.0) return vec4(0.0, 0.0, 0.0, 0.0);
		float fdist = abs(fsrc.y - flatCentre.y) / hudSize.y;
		return grade(textureCam(bitmap, fq)) * (1.0 - smoothstep(fadeStart, fadeEnd, fdist));
	}

	vec4 real = onPlane(planeO, planeR, planeU, d, 0.0, 0.0);
	vec4 refl = vec4(0.0, 0.0, 0.0, 0.0);
	if (mirrorAlpha > 0.001) {
		// the reflection: the mirrored plane, seen where the ray has already gone through the floor
		vec3 om = vec3(planeO.x, planeO.y, 0.0 - planeO.z);
		vec3 um = vec3(planeU.x, planeU.y, 0.0 - planeU.z);
		vec4 r = onPlane(om, planeR, um, d, mirrorWave, mirrorGlitch * 0.25);
		if (gZ < 0.0)
			refl = vec4(r.rgb * mirrorTint, r.a) * (mirrorAlpha * (1.0 - smoothstep(0.0, mirrorFade, 0.0 - gZ)));
	}
	return real + refl * (1.0 - real.a);
}

void main() {
	vec2 q = getCamPos(openfl_TextureCoordv);
	vec2 scr = q * camSize + camOffset;
	// this camera is taller than the screen (the notes must exist before they come in): the part of it that falls outside the screen is
	// never seen, so nothing is worked out there. It is still READ below (the plane brings the far notes in), only not drawn (OPT-shader-ram).
	if (scr.y < -2.0 || scr.y > hudSize.y + 2.0) {
		gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
		return;
	}
	if (glitch <= 0.001) {
		gl_FragColor = arrowsAt(scr);
		return;
	}
	// the glitch: a band of the screen jumps sideways, now and then one drops out, and the colours split
	float tick = floor(time * 24.0);
	float band = floor(scr.y / 9.0);
	float hb = hash2(vec2(band, tick));
	if (hb < glitch * 0.35) scr.x += (hash2(vec2(band + 31.0, tick)) - 0.5) * glitch * 90.0;
	if (hash2(vec2(band + 77.0, tick)) < glitch * 0.06) {
		gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
		return;
	}
	float sp = glitchSplit * glitch;
	vec4 l = arrowsAt(scr - vec2(sp, 0.0));
	vec4 m = arrowsAt(scr);
	vec4 r = arrowsAt(scr + vec2(sp, 0.0));
	float a = max(m.a, max(l.a, r.a));
	vec3 rgb = vec3(r.r, m.g, l.b);
	rgb = mix(rgb, vec3(dot(rgb, vec3(0.299, 0.587, 0.114)) * 1.3, rgb.g * 0.25, rgb.b * 0.25), glitchRed);
	gl_FragColor = vec4(rgb, a);
}
