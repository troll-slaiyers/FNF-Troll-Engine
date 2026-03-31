package funkin.transitions;

import flixel.graphics.FlxGraphic;
import openfl.media.Sound;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;
import flixel.group.FlxGroup;

// NOTE: only added this as a test, i'll finish the sticker pack shit later maybe... i don't fucking care honestly

class StickerPack {
	var sounds:Array<Sound> = [];
	var graphics:Array<FlxGraphic> = [];

	var test:FlxGraphic;
	
	public function new() {
		for (i in 1...10) {
			var sound = Paths.sound('stickersounds/keys/keyClick$i');
			if (sound != null) sounds.push(sound);
		}

		test = Paths.image("trollface");
		graphics.push(test);

		////
		for (graphic in graphics) {
			//Paths.sound
		}

		for (graphic in graphics) {
			Paths.graphicDumpExclusions.push(graphic);
		}
	}

	public function getSound() {
		return FlxG.random.getObject(sounds);
	}

	public function getRandomStickerAsset(isLast:Bool) {
		return test;
	}

	public function destroy() {

		for (graphic in graphics) {
			Paths.graphicDumpExclusions.remove(graphic);
		}
	}
}

class StickerTransition extends Transition {
	var grpStickers:FlxTypedGroup<StickerSprite>;
	var stickerData:StickerPack;

	override function create() {
		super.create();

		stickerData = new StickerPack();

		grpStickers = new FlxTypedGroup<StickerSprite>();
		add(grpStickers);
		regenStickers();
	}

	function regenStickers():Void
	{
		if (grpStickers.members.length > 0) grpStickers.clear();

		// Initialize stickers at each point on the screen, then shuffle up the order they will get placed.
		// This ensures stickers consistently cover the screen.
		var xPos:Float = -100;
		var yPos:Float = -100;
		while (xPos <= FlxG.width)
		{
			var sticky:StickerSprite = new StickerSprite(0, 0, stickerData.getRandomStickerAsset(false));
			sticky.visible = false;
			sticky.x = xPos;
			sticky.y = yPos;
			xPos += sticky.frameWidth * 0.5;
			if (xPos >= FlxG.width)
			{
				if (yPos <= FlxG.height)
				{
					xPos = -100;
					yPos += FlxG.random.float(70, 120);
				}
			}
			sticky.angle = FlxG.random.int(-60, 70);
			grpStickers.add(sticky);
		}
		FlxG.random.shuffle(grpStickers.members);
		// Creates a new sticker for the very center.
		var lastSticker:StickerSprite = new StickerSprite(0, 0, stickerData.getRandomStickerAsset(true));
		lastSticker.visible = false;
		lastSticker.updateHitbox();
		lastSticker.angle = 0;
		lastSticker.screenCenter();
		grpStickers.add(lastSticker);		
	}

	override function start(status:TransitionStatus) {
		switch(status){
			case OUT:
				for (ind => sticker in grpStickers.members)
				{
					sticker.timing = FlxMath.remapToRange(ind, 0, grpStickers.members.length, 0, 0.9);
					new FlxTimer().start(sticker.timing, _ ->
					{
						if (grpStickers == null) return;
						sticker.visible = true;

						FlxG.sound.play(stickerData.getSound());

						var frameTimer:Int = FlxG.random.int(0, 2);
						// always make the last one POP
						if (ind == grpStickers.members.length - 1) frameTimer = 2;
						new FlxTimer().start((1 / 24) * frameTimer, _ ->
						{
							if (sticker == null) return;
							sticker.scale.x = sticker.scale.y = FlxG.random.float(0.97, 1.02);
							if (ind == grpStickers.members.length - 1)
							{
								finish();
							}
						});
					});
				}
				grpStickers.sort((ord, a, b) ->
				{
					return FlxSort.byValues(ord, a.timing, b.timing);
				}); 
			case IN:
				for (ind => sticker in grpStickers.members)
				{
					new FlxTimer().start(sticker.timing, _ ->
					{
						sticker.visible = false;

						FlxG.sound.play(stickerData.getSound());
						
						if (grpStickers == null || ind == grpStickers.members.length - 1)
						{
							finish();
						}
					});
				}

			default:
		}	
	}
}

class StickerSprite extends FlxSprite {
	public var timing:Float = 0;
}