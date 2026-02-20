package funkin.objects.cutscenes;

import funkin.scripts.*;

typedef BoxData = {
	var graphic:String;
	var antialiasing:Bool;
	var scale:Float;
	var offsets:Array<Int>;
	var dialogue_talk_sfx:Array<String>;
	var dialogue_pressed_sfx:String;
	var animations:Array<AnimsArray>;
	var text:TextData;
}

/**
 * Typedef used for the actual text stuff.
 */
typedef TextData = {
	var size:Int;
	var font:String;
	var offsets:Array<Int>;
	var width:Int;
	var color:String;
	var shadow_color:String;
	var shadow_width:Float;
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
	public var textSize:Int = 42;
	public var textColor:String;
	public var shadowTextColor:String;
	public var dialogueTalkSound:Array<String> = null;
	public var dialoguePressedSound:String = 'dialogue';
	public var script:FunkinHScript;
	var currentBoxStyle:String;
	public var shadowWidth:Float;
	public var textOffsets:Array<Int>= [170, 450];
	public var textWidth:Int = 700;
	
	public function new(_boxtype:String)
	{
		super();
		jsonFile = Paths.json('boxes/$_boxtype.json');

		if (jsonFile != null) {
			currentBoxStyle = _boxtype;
			loadJSON();
		}else
			trace('Couldnt load $_boxtype dialogue box!');
	}

	function loadJSON()
	{	
		frames = Paths.getSparrowAtlas(jsonFile.graphic);

		for (anim in jsonFile.animations) 
			animation.addByPrefix(anim.animName, anim.animPrefix, anim.fps, anim.looped);

		x = jsonFile.offsets[0];
		y = jsonFile.offsets[1];
		scale.set(jsonFile.scale,jsonFile.scale);

		//this can probably be fixed, i dont think we need all ts
		antialiasing = jsonFile.antialiasing;
		font = jsonFile.text.font;
		textSize = jsonFile.text.size;
		textColor = jsonFile.text.color;
		shadowTextColor = jsonFile.text.shadow_color;
		shadowWidth = jsonFile.text.shadow_width;
		textOffsets = jsonFile.text.offsets;
		textWidth = jsonFile.text.width;
		dialogueTalkSound = jsonFile.dialogue_talk_sfx;
		dialoguePressedSound = jsonFile.dialogue_pressed_sfx;

		scrollFactor.set();

		updateHitbox();

		startScript();
	}

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

		script = FunkinHScript.fromFile(file);
		//variables
		script.set("this", this);
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
