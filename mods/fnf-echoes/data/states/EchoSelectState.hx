import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.backend.scripting.ModState;
import funkin.backend.scripting.Script;
import funkin.menus.MainMenuState;

// Only Echo 1 is playable — Echo 2 and 3 are reserved for a future full
// version of the mod, shown here as locked placeholders.
var echoLabels:Array<String> = ["ECHO 1", "ECHO 2", "ECHO 3"];
var echoUnlocked:Array<Bool> = [true, false, false];
var cardMenu:Script;

// Guards against the key press that opened this state still being
// "justPressed" on this state's very first update() — without this, the
// same physical ACCEPT press that confirmed "ECHOES" on the previous menu
// would immediately confirm a card here too.
var canConfirm:Bool = false;

function create() {
	bgColor = FlxColor.BLACK;

	var vhsFx = Script.create(Paths.script('scripts/effects/vhsShader'));
	vhsFx.load();
	vhsFx.call('attach');

	cardMenu = Script.create(Paths.script('scripts/ui/cardMenu'));
	cardMenu.load();
	cardMenu.call("create", [echoLabels, echoUnlocked]);

	new FlxTimer().start(0.2, (_) -> canConfirm = true);
}

function confirmSelection() {
	if (!canConfirm || !cardMenu.call("isSelectedUnlocked"))
		return;

	FlxG.switchState(new ModState("StoryMapState"));
}

function update(elapsed) {
	if (controls.LEFT_P)
		cardMenu.call("changeSelection", [-1]);
	else if (controls.RIGHT_P)
		cardMenu.call("changeSelection", [1]);

	if (controls.ACCEPT)
		confirmSelection();

	if (controls.BACK)
		FlxG.switchState(new ModState("MainMenuState"));
}
