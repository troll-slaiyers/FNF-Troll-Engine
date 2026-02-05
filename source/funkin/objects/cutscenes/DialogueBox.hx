package funkin.objects.cutscenes;
import lime.utils.Assets;
import haxe.Json;
typedef BoxData = {
	var graphic:String;
	var antialiasing:Bool;
	var graphicScale:Float;
	var offsets:Array<Int>;
	var dialogueIdle:String; //replace this
	var dialoguePressed:String;
	var dialogueFont:String;
	var dialogueTalkSfx:String;
	var dialoguePressedSfx:String;
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

		//how animations are handled needs to be reworked but im keeping this here for now
	    //animation.addByPrefix('normal', jsonFile.dialogueIdle, 24);
		animation.addByPrefix('pressed', jsonFile.dialoguePressed, 24, false);

	    animation.play('pressed', false);

		scale.set(jsonFile.graphicScale,jsonFile.graphicScale);

		antialiasing = jsonFile.antialiasing;

		font = jsonFile.dialogueFont;

		dialogueTalkSound = jsonFile.dialogueTalkSfx;
		dialoguePressedSound = jsonFile.dialoguePressedSfx;

	    updateHitbox();
    }
   
}
