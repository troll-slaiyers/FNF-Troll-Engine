package funkin.objects.cutscenes;
import lime.utils.Assets;
import haxe.Json;

typedef BoxData = {
	var graphic:String;
	var antialiasing:Bool;
	var graphicScale:Float;
	var offsets:Array<Int>;
	var dialogueFont:String;
	var dialogueTalkSfx:String;
	var dialoguePressedSfx:String;
	var animations:Array<AnimsArray>;
}

typedef AnimsArray = {
	var animName:String;
	var animPrefix:String;
	var fps:Int;
	var looped:Bool;
	var offsets:Array<Int>;
}

class DialogueBox extends FlxSprite
{
	var jsonFile:BoxData;

	public var font:String = 'pixel.ttf';
	public var dialogueTalkSound:String = 'dialogue';
	public var dialoguePressedSound:String = 'dialogue';

    public function new(_boxtype:String)
    {
        super();
		var path:String = ('assets/boxes/$_boxtype.json');
		jsonFile = Paths.getJson(path);
		if(jsonFile == null)
		{
			trace('ERROR NO DIALOGUE OF TYPE: $_boxtype FOUND!!!\nreverting to pixel' );
			jsonFile = Paths.getJson('pixel');
		}

        x = jsonFile.offsets[0];
        y = jsonFile.offsets[1];
		
	    frames = Paths.getSparrowAtlas(jsonFile.graphic);
	    scrollFactor.set();
		for (anim in jsonFile.animations) {
				animation.addByPrefix(anim.animName, anim.animPrefix, anim.fps, anim.looped);
		}
		scale.set(jsonFile.graphicScale,jsonFile.graphicScale);

		antialiasing = jsonFile.antialiasing;

		font = jsonFile.dialogueFont;

		dialogueTalkSound = jsonFile.dialogueTalkSfx;
		dialoguePressedSound = jsonFile.dialoguePressedSfx;

	    updateHitbox();
    }
   
}
