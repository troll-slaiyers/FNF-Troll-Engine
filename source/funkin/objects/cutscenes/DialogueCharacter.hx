package funkin.objects.cutscenes;

import funkin.data.CharacterData;
import flixel.graphics.frames.FlxAtlasFrames;

#if USING_FLXANIMATE
import animate.FlxAnimate;
#end

typedef DialogueCharacterFile = {
	var graphic:String;
	var extra_graphics:Array<String>;
	var offsets:Array<Int>;
	var antialiasing:Bool;
	var scale:Float;
	var talk_sound:Array<String>;

	var animations:Array<DialogueAnimArray>;
}

typedef DialogueAnimArray = {
	var name:String;
	var fps:Int;
	var prefix:String;
	var looped:Bool;
}
#if USING_FLXANIMATE
class DialogueCharacter extends FlxAnimate
#else
class DialogueCharacter extends FlxSprite
#end
{
	/**
	 * JSON file to be used.
	 */
	var jsonFile:DialogueCharacterFile;
	/**
	 *  Current character thats loaded.
	 *  Defaults to bf-pixel
	 */
	public var curChar:String = 'bf-pixel';
	public var talkSound:Array<String> = null;
	public function new( _character:String)
	{
		super();
		
		jsonFile = Paths.json('boxes/characters/$_character.json');

		if(jsonFile != null)// fuck me pls
		{
			curChar = _character;
			loadJSON();

		} else trace('Couldnt load $_character');
		 
	}

	private function loadJSON()
	{
		var fileType:String = CharacterData.getImageFileType(jsonFile.graphic);
		var isAnimateAtlas:Bool = false;
		var atlases:Array<String> = [jsonFile.graphic];

		switch (fileType)
		{
			case "texture":	
				frames = Paths.getTextureAtlas(jsonFile.graphic);
				isAnimateAtlas = true;
			case "packer":	
				frames = Paths.getPackerAtlas(jsonFile.graphic);
			case "sparrow":	
				//this probably be something in a diff file tbh
				var frames:FlxAtlasFrames = Paths.getSparrowAtlas(jsonFile.graphic);
				if(jsonFile.extra_graphics != null && jsonFile.extra_graphics.length > 0){
					for(i in jsonFile.extra_graphics){
						if (!atlases.contains(i)) {
							atlases.push(i);
							var subAtlas:FlxAtlasFrames = Paths.getSparrowAtlas(i);
							if (subAtlas==null)continue;
							@:privateAccess
							if (!frames.usedGraphics.contains(subAtlas.parent))
								frames.addAtlas(subAtlas, true);
						}
					}
				}
				this.frames = frames;


		}
		x = jsonFile.offsets[0];
		y = jsonFile.offsets[1];

		antialiasing = jsonFile.antialiasing;
		scale.set(jsonFile.scale, jsonFile.scale);
		talkSound  = jsonFile.talk_sound;
		for (curAnim in jsonFile.animations)
		{
			#if USING_FLXANIMATE
			if(isAnimateAtlas)
				anim.addBySymbol(curAnim.name, curAnim.prefix, curAnim.fps, curAnim.looped);
			else  #end anim.addByPrefix(curAnim.name, curAnim.prefix, curAnim.fps, curAnim.looped);
		}
	}
}