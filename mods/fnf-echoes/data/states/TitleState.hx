import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.menus.MainMenuState;

var helloText:FlxText;

function create() {
	helloText = new FlxText(0, 0, FlxG.width, "FNF ECHOES\nmod loaded\n\npress any key");
	helloText.setFormat(null, 16, FlxColor.WHITE, "center");
	helloText.screenCenter();
	add(helloText);
}

function update(elapsed) {
	if (FlxG.keys.justPressed.ANY)
		FlxG.switchState(new MainMenuState());
}
