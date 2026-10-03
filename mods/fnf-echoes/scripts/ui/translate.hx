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
	{key: "PRESS A KEY...", en: "PRESS A KEY...", es: "PRESIONA UNA TECLA..."}
];

function get(key:String):String {
	for (entry in uiStrings)
		if (entry.key == key)
			return Reflect.field(entry, Options.language);
	return key;
}
