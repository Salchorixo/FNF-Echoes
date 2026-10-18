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
//   fade       the notes fade in between fadeStart and fadeEnd (share of the screen height away from the receptors) so they do not pop in half way
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
uniform float flatMode;
uniform float flatScale;
uniform float flatShiftY;

void main() {
	vec2 q = getCamPos(openfl_TextureCoordv);
	vec2 scr = q * camSize + camOffset;
	scr = (scr - hudSize * 0.5) / hudZoom + hudSize * 0.5;
	vec2 rp = scr / hudPerRender;
	vec3 d = camFwd * focal + camRight * (rp.x - 960.0) + camUp * (540.0 - rp.y);

	if (flatMode > 0.5) {
		vec2 pivot = vec2(flatCentre.x, flatCentre.y + flatShiftY);
		vec2 fsrc = flatCentre + (scr - pivot) / flatScale;
		vec2 fq = (fsrc - camOffset) / camSize;
		if (fq.x < 0.0 || fq.x > 1.0 || fq.y < 0.0 || fq.y > 1.0) {
			gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
			return;
		}
		float fdist = abs(fsrc.y - flatCentre.y) / hudSize.y;
		gl_FragColor = textureCam(bitmap, fq) * (1.0 - smoothstep(fadeStart, fadeEnd, fdist));
		return;
	}

	vec3 n = cross(planeR, planeU);
	float den = dot(n, d);
	if (abs(den) < 0.000001) {
		gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
		return;
	}
	float t = dot(n, planeO - camPos) / den;
	if (t <= 0.0) {
		gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
		return;
	}
	vec3 p = camPos + d * t - planeO;
	vec2 src = vec2(flatCentre.x + dot(p, planeR) / mpp, flatCentre.y - dot(p, planeU) / mpp);
	vec2 sq = (src - camOffset) / camSize;
	if (sq.x < 0.0 || sq.x > 1.0 || sq.y < 0.0 || sq.y > 1.0) {
		gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
		return;
	}
	float dist = abs(src.y - flatCentre.y) / hudSize.y;
	float fade = 1.0 - smoothstep(fadeStart, fadeEnd, dist);
	gl_FragColor = textureCam(bitmap, sq) * fade;
}
