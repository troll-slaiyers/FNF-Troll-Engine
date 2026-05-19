package funkin.transitions;

import flixel.graphics.FlxGraphic;
import openfl.media.Sound;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;
import flixel.group.FlxGroup;

class StickerTransition extends Transition {
	var grpStickers:FlxTypedGroup<StickerSprite> = null;
	var stickerData:StickerPack = null;

	public function new(?stickerData:StickerPack) {
		this.stickerData = stickerData;
		super();
	}

	override function create() {
		super.create();

		stickerData ??= StickerPack.getDefault();

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

	override function destroy() {
		stickerData.destroy();
		super.destroy();
	}
}

class StickerSprite extends FlxSprite {
	public var timing:Float = 0;
}

private typedef StringOr<T> = haxe.extern.EitherType<String, T>;

class StickerPack {
	public var sounds:Array<Sound> = [];
	public var graphics:Array<FlxGraphic> = [];
	
	public function new(graphics:Array<StringOr<FlxGraphic>>, sounds:Array<StringOr<Sound>>) {
		for (ass in graphics) {
			var img:FlxGraphic = null;

			if (ass is String)
				img = Paths.image(cast ass);
			else if (ass is FlxGraphic)
				img = cast ass;

			if (img != null)
				this.graphics.push(img);
		}

		for (ass in sounds) {
			var snd:Sound = null;

			if (ass is String)
				snd = Paths.sound(cast ass);
			else if (ass is Sound)
				snd = cast ass;

			if (snd != null)
				this.sounds.push(snd);
		}

		lockAssets();
	}

	public function getSound() {
		return FlxG.random.getObject(sounds);
	}

	public function getRandomStickerAsset(isLast:Bool) {
		return FlxG.random.getObject(graphics);
	}

	public function destroy() {
		unlockAssets();
	}

	private inline function lockAssets() {
		for (graphic in graphics)
			Paths.graphicDumpExclusions.push(graphic);
		for (sound in sounds)
			Paths.soundDumpExclusions.push(sound);
	}
	
	private inline function unlockAssets() {
		for (graphic in graphics)
			Paths.graphicDumpExclusions.remove(graphic);
		for (sound in sounds)
			Paths.soundDumpExclusions.remove(sound);
	}

	public static function getDefault() {
		var graphics:Array<FlxGraphic> = [];
		graphics.push(Paths.image("trollface"));

		var sounds:Array<Sound> = [];
		for (i in 1...10) {
			var sound = Paths.sound('stickersounds/keys/keyClick$i');
			if (sound != null) sounds.push(sound);
		}

		return new StickerPack(graphics, sounds);
	}
}