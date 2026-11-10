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
	{key: "FOLDER", en: "FOLDER", es: "CARPETA"},
	{key: "TAPE INDEX", en: "INDEX · TAPE 01", es: "ÍNDICE · CINTA 01"},
	{key: "YOU ARE IN", en: "YOU ARE IN", es: "ESTÁS EN"},
	{key: "PLACE hills2", en: "THE HILLS", es: "LAS COLINAS"},
	{key: "PLACE pool", en: "THE POOL", es: "LA PISCINA"},
	{key: "PLACE hall", en: "THE HALL", es: "EL PASILLO"},
	{key: "MENU MUSIC", en: "PLAYING: MENU", es: "SUENA: MENÚ"},
	{key: "NOT YET", en: "NOT YET", es: "AÚN NO"},
	{key: "TAPES FOUND", en: "TAPES FOUND", es: "CINTAS ENCONTRADAS"},
	{key: "LOCKED", en: "LOCKED", es: "CERRADA"},
	{key: "DAMAGED", en: "DAMAGED", es: "DAÑADA"},
	{key: "RECOVERED", en: "1 OF 3 RECOVERED", es: "1 DE 3 RECUPERADAS"},
	{key: "ESC BACK", en: "ESC  BACK", es: "ESC  VOLVER"},
	{key: "TRACKS", en: "ECHO 1 · TRACKS", es: "ECHO 1 · PISTAS"},
	{key: "SIDE A", en: "SIDE A", es: "CARA A"},
	{key: "NOT RECORDED", en: "NOT RECORDED", es: "SIN GRABAR"},
	{key: "ENTER PLAY", en: "ENTER  PLAY", es: "ENTER  REPRODUCIR"},
	{key: "CREDITS INDEX", en: "CREDITS · TAPE LABEL", es: "CRÉDITOS · ETIQUETA DE LA CINTA"},
	{key: "ROLE SALCHORIZO", en: "IDEA · STORY · ART · ANIMATION", es: "IDEA · HISTORIA · ARTE · ANIMACIÓN"},
	{key: "ROLE SUNO", en: "MUSIC, WITH SALCHORIZO", es: "MÚSICA, CON SALCHORIZO"},
	{key: "ROLE ENGINE", en: "GAME ENGINE", es: "MOTOR DEL JUEGO"},
	{key: "ROLE FONT", en: "TYPEFACE (SIL OPEN FONT LICENSE)", es: "TIPOGRAFÍA (SIL OPEN FONT LICENSE)"},
	{key: "SETTINGS INDEX", en: "SETTINGS · INDEX", es: "AJUSTES · ÍNDICE"},
	{key: "TAPE NOISE", en: "TAPE NOISE", es: "RUIDO DE LA CINTA"},
	{key: "DESC TAPE", en: "How much noise and glitch the tape has (0 = clean picture). Left/Right to change it.", es: "Cuánto ruido y glitch tiene la cinta (0 = imagen limpia). Izquierda/derecha para cambiarlo."},
	{key: "DESC SCREEN TAPE", en: "The tape, the flashes and the effects on your desktop.", es: "La cinta, los destellos y los efectos sobre tu escritorio."},
	{key: "TAPE SIDE", en: "TAPE 01 · SIDE A", es: "CINTA 01 · LADO A"},
	{key: "TRACK", en: "TRACK", es: "PISTA"},
	{key: "RECORDED BY", en: "RECORDED BY", es: "GRABADO POR"},
	{key: "MUSIC WITH", en: "MUSIC WITH", es: "MÚSICA CON"},
	{key: "PAUSED", en: "PAUSED", es: "EN PAUSA"},
	{key: "CONTINUE", en: "CONTINUE", es: "CONTINUAR"},
	{key: "REWIND", en: "REWIND (RESTART)", es: "REBOBINAR (REINICIAR)"},
	{key: "EJECT", en: "EJECT (EXIT)", es: "EXPULSAR (SALIR)"},
	{key: "TO EDITOR", en: "BACK TO THE EDITOR", es: "VOLVER AL EDITOR"},
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
	{key: "DESKTOP BACKGROUND", en: "DESKTOP BACKGROUND", es: "FONDO DEL ESCRITORIO"},
	{key: "AUTO", en: "AUTO", es: "AUTOMÁTICO"},
	{key: "BACKGROUND CHANGES", en: "BACKGROUND CHANGES", es: "CAMBIOS DE FONDO"},
	{key: "DESKTOP EFFECTS", en: "DESKTOP EFFECTS", es: "EFECTOS DE ESCRITORIO"},
	{key: "STATUS HINT", en: "ARROWS MOVE    ENTER SELECT    ESC BACK", es: "FLECHAS MOVER    ENTER ELEGIR    ESC VOLVER"},
	{key: "DESC AUDIO", en: "Adjust the overall volume, the music and the sound effects.", es: "Ajusta el volumen general, la música y los efectos."},
	{key: "DESC CONTROLS", en: "Change a key: press Enter on it and then the new key.", es: "Cambia una tecla: pulsa Enter sobre ella y luego la tecla nueva."},
	{key: "DESC GAMEPLAY", en: "Graphics quality and aids for the notes.", es: "Calidad gráfica y ayudas para las notas."},
	{key: "DESC SCREEN", en: "Pick your desktop background (or leave it on auto so it changes by itself), and reduce flashes.", es: "Elige el fondo de tu escritorio (o déjalo en automático para que cambie solo) y reduce los destellos."},
	{key: "DESC LANGUAGE", en: "Choose the language of the game.", es: "Elige el idioma del juego."}
];

function get(key:String):String {
	for (entry in uiStrings)
		if (entry.key == key)
			return Reflect.field(entry, Options.language);
	return key;
}
