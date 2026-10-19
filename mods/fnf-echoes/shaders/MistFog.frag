#pragma header

// Floor mist for the black stage of Limbo (BE-54), drawn in the SAME 3D space as Zyra's Blender camera. The quad covers the screen; for every
// pixel the shader rebuilds the ray the Blender camera would shoot through it (camPos, camRight/camUp/camFwd, focal in pixels of the 1920x1080
// render) and marches it through a layer of fog lying on the floor. Every step absorbs the light behind it and adds its own colour, lit by a 3D
// light: the glow lives INSIDE the fog, it is not a layer painted over it. It is alive: the wind comes in gusts (flowX is integrated by the script),
// the upper wisps move faster than the ground (wind shear), the clouds boil upwards, slow surges roll towards the camera, and a faint wake turns
// around Zyra's feet all the time.
//   layerMode 0 = the part of the ray BEHIND Zyra (draw it before her), 1 = the part in FRONT of her (draw it after her). Both are the same
//             volume, so the join is seamless. depthZ is Zyra's distance from the camera along its forward axis.
//   world <-> render: the quad is placed in game pixels (quadRect); the point anchorWorld of the game is where Zyra's feet are, and feetPx is
//             where the Blender render has them; pxScale = game pixels per render pixel (her sprite scale).
//   fogTop  height where the layer ends (metres); groundH  how fast the mist thins with height
//   flowX   how far the wind has carried the clouds along x (metres): the script integrates it so gusts do not make the clouds jump
//   clearR  radius (metres) of the clear air around Zyra: no mist touches her, so the depth of the mist reads in front of her and behind her.
//           Her push opens that clearing wider for a moment (pushAmt)
//   quality  how many steps each ray takes (3..8): the knob between looks and speed
//   light model: the light scatters forward (the fog glows when you look towards it), and Zyra casts a real volumetric shadow through the lit
//           fog (a dark shaft behind her, found analytically, no extra steps)
//   aPos0..3/aCol0..3/aR  the four ARROWS are lights too: each one lights the mist around it (position in metres, colour already multiplied by its intensity,
//           radius aR in metres), so the arrows seem to give off light into the air instead of lying over it
//   pushPos/pushAmt/pushR/pushMeters  Zyra opens the mist: around pushPos (metres) the air is thrown outwards and thinned (pushAmt 0..1)
//   light3/lightR  a light in the world (metres, radius in metres): the fog near it glows and takes its colour; flash is a short pulse; tintMix =
//           how much of the light's colour reaches the mist (the mist is dark grey, so it is small); breath (0..1) lifts density and glow for a moment
// Every strength is a live uniform. Only 0.0-style floats, no switch, no arrays, as the engine's compatibility guide asks.
uniform float time;
uniform float seed;
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
uniform float fogTop;
uniform float groundH;
uniform float flowX;
uniform float density;
uniform vec3 pushPos;
uniform float pushAmt;
uniform float pushR;
uniform float pushMeters;
uniform float quality;
uniform float clearR;
uniform vec3 light3;
uniform float lightR;
uniform float lightLevel;
uniform float flash;
uniform float breath;
uniform vec3 lightColor;
uniform float tintMix;
uniform vec3 aPos0;
uniform vec3 aPos1;
uniform vec3 aPos2;
uniform vec3 aPos3;
uniform vec3 aCol0;
uniform vec3 aCol1;
uniform vec3 aCol2;
uniform vec3 aCol3;
uniform float aR;
uniform vec3 baseColor;

float hash3(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.1, 0.1));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float vnoise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(hash3(i), hash3(i + vec3(1.0, 0.0, 0.0)), f.x);
	float b = mix(hash3(i + vec3(0.0, 1.0, 0.0)), hash3(i + vec3(1.0, 1.0, 0.0)), f.x);
	float c = mix(hash3(i + vec3(0.0, 0.0, 1.0)), hash3(i + vec3(1.0, 0.0, 1.0)), f.x);
	float d = mix(hash3(i + vec3(0.0, 1.0, 1.0)), hash3(i + vec3(1.0, 1.0, 1.0)), f.x);
	return mix(mix(a, b, f.y), mix(c, d, f.y), f.z);
}

float fbm3(vec3 p) {
	float v = 0.5 * vnoise3(p);
	p = p * 2.03 + vec3(17.1, 9.2, 5.7);
	v += 0.3 * vnoise3(p);
	p = p * 2.03 + vec3(3.3, 7.4, 1.9);
	v += 0.2 * vnoise3(p);
	p = p * 2.03 + vec3(11.5, 2.6, 8.8);
	v += 0.07 * vnoise3(p);
	return v / 1.07;
}

// interleaved gradient noise: a cleaner dither than a sine hash, so the few steps do not show as grain
float ign(vec2 p) {
	return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715))));
}

// Henyey-Greenstein: the fog scatters most of the light forward, towards the eye when you look at the light
float hgPhase(float c, float g) {
	float g2 = g * g;
	return (1.0 - g2) / (12.566 * pow(1.0 + g2 - 2.0 * g * c, 1.5));
}

// how much of the light reaches a point of the fog: Zyra (a vertical capsule at pushPos) blocks the way to the light
float zyraShadow(vec3 p, vec3 toLight, float dl) {
	vec2 c = pushPos.xy - p.xy;
	float lxy2 = dot(toLight.xy, toLight.xy) + 0.0001;
	float t = dot(c, toLight.xy) / lxy2;
	if (t < 0.0 || t > dl) return 1.0;
	float zAt = p.z + toLight.z * t;
	float dxy = length(p.xy + toLight.xy * t - pushPos.xy);
	float inH = smoothstep(-0.1, 0.2, zAt) * (1.0 - smoothstep(1.5, 1.9, zAt));
	return 1.0 - 0.85 * (1.0 - smoothstep(0.22, 0.6, dxy)) * inH;
}

float gCloud = 0.0;     // the cloud value of the last fogDensity() call, used to shade the texture

// density of the mist at a point of the world (metres)
float fogDensity(vec3 p) {
	// Zyra opens the mist: the noise is sampled from nearer her, so what is there looks pushed outwards, with a slight curl
	vec3 dd = p - pushPos;
	float dist = length(dd * vec3(1.0, 1.0, 1.6));
	float fall = exp(-(dist * dist) / (pushR * pushR));
	vec2 dir = dd.xy / (dist + 0.001);
	vec3 q = p;
	q.xy -= dir * (pushAmt * fall * pushMeters);
	q.xy += vec2(-dd.y, dd.x) * (pushAmt * fall * 0.25);
	q.xy += vec2(-dd.y, dd.x) * (0.06 * fall * sin(time * 0.6));       // a faint wake that turns around her all the time

	// big slow clouds, stretched along the wind (x), warped. Wind shear: the higher a wisp is, the faster the wind carries it; and the clouds boil upwards
	float shear = flowX * (0.6 + 0.7 * clamp(p.z, 0.0, 2.0));
	vec3 w = q * vec3(0.17, 0.38, 0.9) + vec3(shear, time * 0.015, 0.0 - time * 0.05) + vec3(seed, seed * 0.7, seed * 1.3);
	vec3 warp = vec3(vnoise3(w * 0.7 + vec3(3.1, 0.0, 0.0)), vnoise3(w * 0.7 + vec3(0.0, 9.7, 0.0)), 0.0) * 1.7;
	float n = fbm3(w + warp);
	float cloud = smoothstep(0.42, 0.74, n);
	gCloud = n;

	// the floor mist, with slow surges that roll towards the camera
	float blotch = 0.5 + 0.9 * vnoise3(p * 0.09 + vec3(seed, 0.0, 0.0));
	float surge = 0.8 + 0.4 * sin(p.y * 0.45 - time * 0.5 + 3.0 * vnoise3(p * 0.2 + vec3(seed, 0.0, 0.0)));
	// a vast, empty place: most of the floor is bare, and the mist gathers in a few big banks that drift slowly (features of 15-20 metres)
	float vast = smoothstep(0.30, 0.72, vnoise3(p * vec3(0.045, 0.06, 0.0) + vec3(seed * 3.0, time * 0.004, 0.0)));
	float ground = cloud * exp(-p.z / groundH) * blotch * surge * (0.22 + 1.05 * vast);

	// clear air around Zyra: the mist keeps its distance, and her push widens the clearing
	float cd = length((p - pushPos) * vec3(1.0, 1.0, 0.6));
	float openR = clearR + pushAmt * pushMeters;
	ground *= smoothstep(openR, openR + 3.0, cd);
	float top = 1.0 - smoothstep(fogTop * 0.6, fogTop, p.z);
	return ground * top * (1.0 - pushAmt * fall * 0.95);
}

void main() {
	vec2 uv = openfl_TextureCoordv;
	vec2 wpx = quadRect.xy + uv * quadRect.zw;
	vec2 rpx = feetPx + (wpx - anchorWorld) / pxScale;
	vec3 ud = normalize(camFwd * focal + camRight * (rpx.x - renderHalf.x) + camUp * (renderHalf.y - rpx.y));

	// the part of the ray that lies inside the fog layer (metres along the ray from the camera)
	float sFar = 60.0;
	float sA = 0.0;
	float sB = sFar;
	float zc = camPos.z;
	if (ud.z < -0.0001) {
		sB = min(sFar, (0.0 - zc) / ud.z);
		if (zc > fogTop) sA = (fogTop - zc) / ud.z;
	} else {
		if (zc >= fogTop) {
			gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
			return;
		}
		if (ud.z > 0.0001) sB = min(sFar, (fogTop - zc) / ud.z);
	}

	// behind or in front of Zyra (her plane is perpendicular to the camera's forward axis)
	float sz = depthZ / dot(ud, camFwd);
	if (layerMode < 0.5) sA = max(sA, sz);
	else sB = min(sB, sz);
	if (sB <= sA) {
		gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
		return;
	}

	// march the ray: absorb what is behind, add the lit colour of each step (T = how much of the background still shows)
	float len = sB - sA;
	float steps = clamp(quality, 3.0, 8.0);
	float ds = len / steps;
	float jitter = ign(gl_FragCoord.xy);
	float T = 1.0;
	vec3 C = vec3(0.0, 0.0, 0.0);
	for (int i = 0; i < 8; i++) {
		if (float(i) >= steps) break;
		float s = sA + (float(i) + jitter) * ds;
		vec3 p = camPos + ud * s;
		// clear air close to the camera, and far away the mist fades into the dark instead of ending on a hard line
		float dens = fogDensity(p) * density * (1.0 + 0.35 * breath) * smoothstep(1.5, 9.0, s) * (1.0 - smoothstep(0.4 * sFar, sFar, s));
		float ai = 1.0 - exp(-dens * ds);

		// light: distance falloff, forward scattering towards the eye, and Zyra's shadow
		vec3 toL = light3 - p;
		float dl = length(toL);
		toL /= dl;
		float g = exp(-(dl * dl) / (lightR * lightR));
		float phase = 0.3 + 3.0 * hgPhase(dot(ud, toL), 0.5);
		float shadow = zyraShadow(p, toL, dl);
		float lit = clamp(lightLevel * (0.2 + 0.8 * g * phase * shadow) + (flash * 1.2 + breath * 0.3) * g * shadow, 0.0, 1.6);
		vec3 col = mix(baseColor, lightColor, clamp(lit, 0.0, 1.0) * tintMix) * (0.25 + 0.8 * lit);
		// body and texture: the cores of the clouds are brighter, the tops catch more light and the thick parts shade themselves
		col *= (0.7 + 0.6 * gCloud) * (0.8 + 0.4 * clamp(p.z / 1.2, 0.0, 1.0)) * (1.0 - 0.45 * ai);
		// the light of the arrows: it takes the mist's own shape (it is added before the mist is mixed into the picture) and keeps each arrow's colour
		vec3 q0 = p - aPos0;
		vec3 q1 = p - aPos1;
		vec3 q2 = p - aPos2;
		vec3 q3 = p - aPos3;
		float rr = aR * aR;
		col += aCol0 * exp(-dot(q0, q0) / rr) + aCol1 * exp(-dot(q1, q1) / rr) + aCol2 * exp(-dot(q2, q2) / rr) + aCol3 * exp(-dot(q3, q3) / rr);
		C += T * ai * col;
		T *= 1.0 - ai;
	}

	float a = 1.0 - T;
	float k = mix(1.0, 0.85, layerMode);
	gl_FragColor = vec4(C * k, a * k);
}
