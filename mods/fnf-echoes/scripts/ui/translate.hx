import funkin.options.Options;

// Shared UI-string lookup, driven via Script.create() by any state that
// shows translatable chrome text (MainMenuState, OptionsState, ...).
// Extracted here once a second real consumer needed the same strings
// (MainMenuState's OPTIONS/CREDITS cards, OptionsState's own labels) —
// before that it lived inline in OptionsState.hx alone.
//
// Keys double as their own English fallback, so there's no separate id
// scheme to maintain for a 2-language mod. "ECHOES"/"ECHO" are deliberately
// NOT in this table — those names stay in English always, per project rule,
// so callers should never route them through get().
var uiStrings:Array<Dynamic> = [
	{key: "PLAY", en: "PLAY", es: "JUGAR"},
	{key: "SETTINGS", en: "SETTINGS", es: "AJUSTES"},
	{key: "OPTIONS", en: "OPTIONS", es: "OPCIONES"},
	{key: "CREDITS", en: "CREDITS", es: "CRÉDITOS"},
	{key: "CONTROLS", en: "CONTROLS", es: "CONTROLES"},
	{key: "LANGUAGE", en: "LANGUAGE", es: "IDIOMA"},
	{key: "GAMEPLAY", en: "GAMEPLAY", es: "JUGABILIDAD"},
	{key: "UP", en: "UP", es: "ARRIBA"},
	{key: "DOWN", en: "DOWN", es: "ABAJO"},
	{key: "LEFT", en: "LEFT", es: "IZQUIERDA"},
	{key: "RIGHT", en: "RIGHT", es: "DERECHA"},
	{key: "SCREEN QUALITY", en: "SCREEN QUALITY", es: "CALIDAD DE PANTALLA"},
	{key: "DOWNSCROLL", en: "DOWNSCROLL", es: "SCROLL INVERTIDO"},
	{key: "GHOST TAPPING", en: "GHOST TAPPING", es: "TOQUE FANTASMA"},
	{key: "ON", en: "ON", es: "SÍ"},
	{key: "OFF", en: "OFF", es: "NO"},
	{key: "HIGH", en: "HIGH", es: "ALTA"},
	{key: "PERFORMANCE", en: "PERFORMANCE", es: "RENDIMIENTO"},
	{key: "PRESS A KEY...", en: "PRESS A KEY...", es: "PRESIONA UNA TECLA..."},
	{key: "AUDIO", en: "AUDIO", es: "AUDIO"},
	{key: "SCREEN", en: "SCREEN", es: "PANTALLA"},
	{key: "VOLUME", en: "VOLUME", es: "VOLUMEN"},
	{key: "MUSIC", en: "MUSIC", es: "MÚSICA"},
	{key: "SOUND EFFECTS", en: "SOUND EFFECTS", es: "EFECTOS"},
	{key: "REDUCE FLASHES", en: "REDUCE FLASHES", es: "REDUCIR DESTELLOS"},
	{key: "BACKGROUND CHANGES", en: "BACKGROUND CHANGES", es: "CAMBIOS DE FONDO"},
	{key: "DESKTOP EFFECTS", en: "DESKTOP EFFECTS", es: "EFECTOS DE ESCRITORIO"},
	{key: "STATUS HINT", en: "ARROWS MOVE    ENTER SELECT    ESC BACK", es: "FLECHAS MOVER    ENTER ELEGIR    ESC VOLVER"},
	{key: "DESC AUDIO", en: "Adjust the overall volume, the music and the sound effects.", es: "Ajusta el volumen general, la música y los efectos."},
	{key: "DESC CONTROLS", en: "Change a key: press Enter on it and then the new key.", es: "Cambia una tecla: pulsa Enter sobre ella y luego la tecla nueva."},
	{key: "DESC GAMEPLAY", en: "Graphics quality and aids for the notes.", es: "Calidad gráfica y ayudas para las notas."},
	{key: "DESC SCREEN", en: "Reduce flashes, and choose if the background and the desktop change by themselves.", es: "Reduce los destellos y decide si el fondo y el escritorio cambian solos."},
	{key: "DESC LANGUAGE", en: "Choose the language of the game.", es: "Elige el idioma del juego."}
];

function get(key:String):String {
	for (entry in uiStrings)
		if (entry.key == key)
			return Reflect.field(entry, Options.language);
	return key;
}
