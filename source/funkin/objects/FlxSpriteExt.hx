package funkin.objects;

import flixel.graphics.frames.FlxAtlasFrames;
#if USING_FLXANIMATE
import animate.FlxAnimate;
import animate.FlxAnimateController;
import animate.FlxAnimateFrames;
#end

/**
	FlxSprite but with more support for multiple sprite atlas formats
**/
#if USING_FLXANIMATE
class FlxSpriteExt extends FlxAnimate
#else
class FlxSpriteExt extends FlxSprite
#end
{
	public var isAnimateAtlas:Bool = false;
	public function loadFrames(type:String, image:String, images:Array<String> = null) {
		var atlases:Array<String> = [image];

		switch (type) {
			#if USING_FLXANIMATE
			case "texture":
				frames = Paths.animateAtlas(image);
				isAnimateAtlas = true;
			#end
			case "packer":
				frames = Paths.packerAtlas(image);
			case "sparrow":
				var frames:FlxAtlasFrames = Paths.sparrowAtlas(image);
				if (images != null && images.length > 0) {
					for (i in images) {
						if (!atlases.contains(i)) {
							atlases.push(i);
							var subAtlas:FlxAtlasFrames = Paths.sparrowAtlas(i);
							if (subAtlas == null)
								continue;
							@:privateAccess
							if (!frames.usedGraphics.contains(subAtlas.parent))
								frames.addAtlas(subAtlas, true);
						}
					}
				}
				this.frames = frames;
		}
	}
	#if !USING_FLXANIMATE
	@:noCompletion public var isAnimate(get, never):Bool;
	@:noCompletion inline function get_anim()
		return false;
	#end
}
