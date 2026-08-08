import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;

// Shared horizontal card-grid selector, driven via Script.create() by any
// state that needs it (MainMenuState, EchoSelectState, ...) — avoids
// duplicating the same "row of cards + arrow-key highlight" logic per state.
// Placeholder look (flat kraft-tone rectangles) until real card art exists.
var cards:Array<FlxSprite> = [];
var cardLabelsList:Array<String> = [];
var unlockedFlags:Array<Bool> = [];
var selectedIndex:Int = 0;

var cardWidth:Int = 180;
var cardHeight:Int = 260;
var cardGap:Int = 60;

function create(labelsIn:Array<String>, ?unlockedIn:Array<Bool>) {
	cardLabelsList = labelsIn;
	unlockedFlags = unlockedIn != null ? unlockedIn : [for (l in labelsIn) true];

	var totalWidth = (cardWidth * cardLabelsList.length) + (cardGap * (cardLabelsList.length - 1));
	var startX = (FlxG.width - totalWidth) / 2;
	var cardY = (FlxG.height - cardHeight) / 2;

	for (i in 0...cardLabelsList.length) {
		var card = new FlxSprite(startX + (i * (cardWidth + cardGap)), cardY);
		card.makeGraphic(cardWidth, cardHeight, 0xFFD8C7A1, true, "echoesCardMenuPlaceholder");
		state.add(card);
		cards.push(card);

		var label = new FlxText(card.x, card.y + (cardHeight / 2) - 12, cardWidth, cardLabelsList[i]);
		label.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.BLACK, "center");
		state.add(label);

		var lockLabel = new FlxText(card.x, card.y + (cardHeight / 2) + 16, cardWidth, unlockedFlags[i] ? "" : "LOCKED");
		lockLabel.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.BLACK, "center");
		state.add(lockLabel);
	}

	updateHighlight();
}

function updateHighlight() {
	for (i in 0...cards.length) {
		var card = cards[i];
		var isSelected = i == selectedIndex;
		var unlocked = unlockedFlags[i];

		card.color = !unlocked ? 0xFF4A4238 : (isSelected ? 0xFFFFFFFF : 0xFF8A7A5C);

		FlxTween.cancelTweensOf(card.scale);
		FlxTween.tween(card.scale, {x: isSelected ? 1.08 : 1, y: isSelected ? 1.08 : 1}, 0.15);
	}
}

function changeSelection(delta:Int) {
	selectedIndex = (selectedIndex + delta + cardLabelsList.length) % cardLabelsList.length;
	updateHighlight();
}

function getSelectedIndex() return selectedIndex;
function isSelectedUnlocked() return unlockedFlags[selectedIndex];
