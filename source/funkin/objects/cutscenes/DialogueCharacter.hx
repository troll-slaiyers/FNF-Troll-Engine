package funkin.objects.cutscenes;
#if USING_FLXANIMATE
import animate.FlxAnimate;
import animate.FlxAnimateFrames;
import animate.FlxAnimateController;
#end
import flixel.FlxSprite;
import funkin.data.CharacterData;

typedef DialogueCharacterFile = {
	var graphic:String;
	var offsets:Array<Int>;
	var antialiasing:Bool;
	var scale:Float;

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
	public function new( _character:String)
    {
        super();
		
        final path:String = ('assets/boxes/characters/$_character.json');

		jsonFile = Paths.getJson(path);

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

		//todo: add multisprite support?
		switch (fileType)
		{
			case "texture":	
				frames = Paths.getTextureAtlas(jsonFile.graphic);
				isAnimateAtlas = true;
			case "packer":	frames = Paths.getPackerAtlas(jsonFile.graphic);
			case "sparrow":	frames = Paths.getSparrowAtlas(jsonFile.graphic);

		}
        x = jsonFile.offsets[0];
        y = jsonFile.offsets[1];

        antialiasing = jsonFile.antialiasing;
        scale.set(jsonFile.scale, jsonFile.scale);
	
        for (curAnim in jsonFile.animations)
		{
			#if USING_FLXANIMATE
			if(isAnimateAtlas)
				anim.addBySymbol(curAnim.name, curAnim.prefix, curAnim.fps, curAnim.looped);
			else  #end anim.addByPrefix(curAnim.name, curAnim.prefix, curAnim.fps, curAnim.looped);
		}
	}
}