import funkin.backend.shaders.CustomShader;

// Attaches the VHS/CRT shader to the current camera. Meant to be called
// from every state's own create() via Script.create()+call("attach") —
// not hooked through the mod's global script (data/global/LIB_fnf-echoes),
// because that hook never actually fired in testing (postStateSwitch and
// even a plain per-frame update() both stayed silent despite the file
// being confirmed present on disk at the path the engine's own source says
// it reads from — root cause not found, worth revisiting later). Every
// state already runs its own create() reliably, so this composes the same
// way as cardMenu.hx/nodeArtPanel.hx instead of depending on that hook.
//
// Starting points inspired by the After Effects reference stack (lens
// distortion, RGB split, light blur, grain, glow, contrast, scanlines,
// rounded CRT vignette) — AE's own units don't map 1:1 to this shader's
// math, so these are tuned by eye, not converted. Every value is a live
// uniform, safe to retune without touching the .frag file.
function attach() {
	var shader = new CustomShader("VHSShader");

	shader.hset("lensDistortAmount", 0.4);
	shader.hset("chromaticAberrationAmount", 0.006);
	shader.hset("chromaticAberrationFalloff", 0.6);
	shader.hset("blurAmount", 0.0015);
	shader.hset("grainIntensity", 0.06);
	shader.hset("time", Math.random() * 1000);
	shader.hset("glowThreshold", 0.6);
	shader.hset("glowIntensity", 0.35);
	shader.hset("brightness", 0.0);
	shader.hset("contrast", 1.15);
	shader.hset("scanlineWidth", 2.0);
	shader.hset("scanlineOpacity", 0.12);
	shader.hset("vignetteRadius", 0.75);
	shader.hset("vignetteSoftness", 0.5);

	FlxG.camera.removeShader(shader);
	FlxG.camera.addShader(shader);
}
