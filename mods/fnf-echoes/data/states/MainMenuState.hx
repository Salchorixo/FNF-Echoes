import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import funkin.backend.scripting.ModState;
import funkin.menus.TitleState;
import funkin.menus.credits.CreditsMain;
import funkin.options.OptionsMenu;

// Placeholder kraft-paper cards (real card art comes later). Options and
// Credits reuse the engine's native screens — they're utility screens, not
// narrative content, so there's no need to rebuild them yet.
var cardLabels:Array<String> = ["ECHOES", "OPTIONS", "CREDITS"];
var cards:Array<FlxSprite> = [];
var labels:Array<FlxText> = [];
var selectedIndex:Int = 0;

var cardWidth:Int = 260;
var cardHeight:Int = 380;
var cardGap:Int = 40;

function create() {
	bgColor = FlxColor.BLACK;

	var totalWidth = (cardWidth * cardLabels.length) + (cardGap * (cardLabels.length - 1));
	var startX = (FlxG.width - totalWidth) / 2;
	var cardY = (FlxG.height - cardHeight) / 2;

	for (i in 0...cardLabels.length) {
		var card = new FlxSprite(startX + (i * (cardWidth + cardGap)), cardY);
		card.makeGraphic(cardWidth, cardHeight, 0xFFD8C7A1, true, "echoesMenuCardPlaceholder");
		add(card);
		cards.push(card);

		var label = new FlxText(card.x, card.y + (cardHeight / 2) - 12, cardWidth, cardLabels[i]);
		label.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.BLACK, "center");
		add(label);
		labels.push(label);
	}

	updateSelection();
}

function updateSelection() {
	for (i in 0...cards.length) {
		var card = cards[i];
		var isSelected = i == selectedIndex;

		card.color = isSelected ? 0xFFFFFFFF : 0xFF8A7A5C;
		FlxTween.cancelTweensOf(card.scale);
		FlxTween.tween(card.scale, {x: isSelected ? 1.08 : 1, y: isSelected ? 1.08 : 1}, 0.15);
	}
}

function changeSelection(delta:Int) {
	selectedIndex = (selectedIndex + delta + cardLabels.length) % cardLabels.length;
	updateSelection();
}

function confirmSelection() {
	switch (cardLabels[selectedIndex]) {
		case "ECHOES": FlxG.switchState(new ModState("EchoSelectState"));
		case "OPTIONS": FlxG.switchState(new OptionsMenu());
		case "CREDITS": FlxG.switchState(new CreditsMain());
	}
}

function update(elapsed) {
	if (controls.LEFT_P)
		changeSelection(-1);
	else if (controls.RIGHT_P)
		changeSelection(1);

	if (controls.ACCEPT)
		confirmSelection();

	if (controls.BACK)
		FlxG.switchState(new TitleState());
}
