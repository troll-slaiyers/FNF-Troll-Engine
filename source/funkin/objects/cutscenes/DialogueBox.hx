package funkin.objects.cutscenes;
import lime.utils.Assets;
import haxe.Json;
import funkin.scripts.*;

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
	public var script:FunkinHScript;
	var currentBoxStyle:String;
    public function new(_boxtype:String)
    {
        super();
		var path:String = ('assets/boxes/$_boxtype.json');
		jsonFile = Paths.getJson(path);
		if(jsonFile == null)
		{
			trace('ERROR NO DIALOGUE OF TYPE: $_boxtype FOUND!!!\nreverting to pixel' );
		}

		currentBoxStyle = _boxtype;
		startScript();
        x = jsonFile.offsets[0];
        y = jsonFile.offsets[1];
		
	    frames = Paths.getSparrowAtlas(jsonFile.graphic);
	    scrollFactor.set();
		for (anim in jsonFile.animations) {
				animation.addByPrefix(anim.animName, anim.animPrefix, anim.fps, false);
		}
		scale.set(jsonFile.graphicScale,jsonFile.graphicScale);

		antialiasing = jsonFile.antialiasing;

		font = jsonFile.dialogueFont;

		dialogueTalkSound = jsonFile.dialogueTalkSfx;
		dialoguePressedSound = jsonFile.dialoguePressedSfx;

	    updateHitbox();
		postLayer();
    }
	
	
	/**
	 * ripped this from a stage script lol
	 */
	public function startScript()
	{
		if (script != null) {
			trace("Script already started!");
			return;
		}   

		var file = Paths.getHScriptPath('boxes/$currentBoxStyle');
		if (file == null) {
			script = null;
			return;
		}
		
		//script.set("post", postLayer);

		script = FunkinHScript.fromFile(file);
		//variables
				//script.set("add", add);
				script.set("post", postLayer);

	}
	public function postLayer()
	{
		//used in scripts
	}
	override function destroy()
	{
		if (script != null){
			script.call("onDestroy");
			script.stop();
			script = null;
		}
		
		super.destroy();
	}
   
}
