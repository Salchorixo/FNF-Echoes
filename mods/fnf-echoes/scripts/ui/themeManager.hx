import funkin.options.Options;

// The theme system (BE-16): Zyra's desktop changes by itself between four retro operating systems. A THEME is
// a package of art: a wallpaper with its taskbar or menu bar, the buttons, the folder, the vinyl, a cursor and
// its own sounds (images/menus/themes/<theme>_*.png, sounds/themes/<theme>_*.ogg, made by
// AI_export_themes.py and AI_export_theme_sounds.py in the private art folder). What never changes is Zyra's
// animation and the pencil outlines. This script is shared through Script.create() by the screens that show
// a theme (MainMenuState today); it only holds the rules and the data, the drawing is done by the screens.
//
// WHEN does the theme change? With a purpose, not by chance: the menu takes the theme of the feeling of the
// song you last finished (themeBySong, a PROVISIONAL suggestion to be decided by Zyra: Soul tired = Windows 98,
// Taro bright = Vista, Kiyu tender = Mac). A screen that wants a change calls requestForSong(); the main menu
// reads pending() when it opens and plays the change. The preferences of the Settings screen are respected:
// "Background changes" off = it never changes; "Reduce flashes" on = the change is a soft fade, without
// tearing, snow, colour split or flashes.

var themes:Array<String> = ["vista", "xp", "win98", "mac"];
var themeBySong:Array<String> = ["win98", "vista", "mac"];

function current():String {
	var theme = FlxG.save.data.echoesTheme;
	return theme == null ? "vista" : theme;
}

function setCurrent(theme:String) {
	FlxG.save.data.echoesTheme = theme;
}

function next(theme:String):String {
	return themes[(themes.indexOf(theme) + 1) % themes.length];
}

// "Background changes" in Settings (on by default).
function changesEnabled():Bool {
	var value = FlxG.save.data.echoesBackgroundChanges;
	return value == null ? true : value;
}

// "Reduce flashes" in Settings is Options.flashingMenu inverted.
function reduceFlashes():Bool {
	return !Options.flashingMenu;
}

// The change a finished song asks for. If the song's own theme is already the current one the desktop would never move
// (only Soul is unlocked in a fresh session, and it maps to a single theme), so then it changes to another theme at random:
// finishing a song always changes the desktop (BE-25).
function requestForSong(songIndex:Int) {
	var wanted = themeBySong[songIndex];
	if (wanted == current()) {
		var others = [];
		for (t in themes)
			if (t != wanted)
				others.push(t);
		wanted = others[FlxG.random.int(0, others.length - 1)];
	}
	FlxG.save.data.echoesThemePending = wanted;
}

// The theme another screen asked for (or null). Reading it does not clear it: call clearPending().
function pending():String {
	return FlxG.save.data.echoesThemePending;
}

function clearPending() {
	FlxG.save.data.echoesThemePending = null;
}

// Art and sounds of a theme.
function image(theme:String, name:String):String {
	return Paths.image('menus/themes/' + theme + '_' + name);
}

function sound(theme:String, name:String):String {
	return Paths.sound('themes/' + theme + '_' + name);
}

function language():String {
	return Options.language == "es" ? "es" : "en";
}

// The colour of a button label and of its glow/shadow (0 = no shadow), from the design: Vista navy on white
// shadow, XP and 98 plain black, Mac dark (white when selected, with a navy glow).
function labelColor(theme:String, selected:Bool):Int {
	if (theme == "vista") return 0xFF183464;
	if (theme == "mac") return selected ? 0xFFFFFFFF : 0xFF14141C;
	return 0xFF000000;
}

function labelShadow(theme:String, selected:Bool):Int {
	if (theme == "vista") return 0xFFFFFFFF;
	if (theme == "mac") return selected ? 0xFF0A286E : 0xFFFFFFFF;
	return 0;
}

// How each wallpaper arrives (the revealMode of ChannelShader.frag).
function revealMode(theme:String):Float {
	if (theme == "vista") return 0;
	if (theme == "xp") return 1;
	if (theme == "win98") return 2;
	return 3;
}
