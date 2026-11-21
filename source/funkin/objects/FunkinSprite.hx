package funkin.objects;

import flixel.graphics.frames.FlxAtlasFrames;
import animate.FlxAnimate;
import flixel.FlxSprite;

#if USING_FLXANIMATE
class FunkinSprite extends FlxAnimate
#else
class FunkinSprite extends FlxSprite
#end
{
	public function addSubAtlas(key:String) {
		if (!(frames is FlxAtlasFrames))
			return;

		var frames:FlxAtlasFrames = cast this.frames;
		var subAtlas:FlxAtlasFrames = Paths.atlasFrames(key);
		if (subAtlas != null && @:privateAccess !frames.usedGraphics.contains(subAtlas.parent))
			frames.addAtlas(subAtlas, true);
	}

	public function loadAtlas(key:String) {
		var imageKeys:Array<String> = key.split(',');

		if (Paths.getImageFileType(imageKeys[0]) == ANIMATE) {
			frames = Paths.animateAtlas(imageKeys[0]);
		} else {
			frames = Paths.atlasFrames(imageKeys[0]);
			for (i in 1...imageKeys.length)
				addSubAtlas(imageKeys[i]);
		}
	}
}