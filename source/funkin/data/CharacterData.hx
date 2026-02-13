package funkin.data;

import funkin.objects.Character;
import flixel.util.FlxColor;
import funkin.data.VSliceCharacterData;
import funkin.data.AndromedaCharacterData;
using StringTools;

typedef CharacterFile = {
	var animations:Array<AnimArray>;
	var image:String;
	@:optional var images: Array<String>;
	var scale:Float;
	var sing_duration:Float;
	
	var position:Array<Float>;
	var camera_position:Array<Float>;
	
	var flip_x:Bool;
	var no_antialiasing:Bool;

	var healthbar_colors:Array<Int>;
	var healthicon:String;

	@:optional var x_facing:Float;
	@:optional var death_name:String;
	@:optional var script_names:Array<String>;
	@:optional var script_name:String;
}

typedef AnimArray = {
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Float>;
	@:optional var image:String;
	@:optional var cameraOffset:Array<Float>;
}

class CharacterData {
	public static function getCharacterFile(characterName:String):Null<CharacterFile>
	{
		var json:Null<Dynamic> = Paths.json('characters/$characterName.json');

		if (json == null){
			trace('Could not find character "$characterName" JSON file');
			return null;
		}

		if (AndromedaCharacterData.isAndromedaFormat(json))
			return AndromedaCharacterData.toPsychData(json);

		if (VSliceCharacterData.isVSliceFormat(json))
			return VSliceCharacterData.toPsychData(json);

		var json:CharacterFile = json;
		
		try{
			for (anim in json.animations){
				try{
					if (anim.indices != null)
						anim.indices = parseIndices(anim.indices);
				}catch(e){
					trace('$characterName: Error parsing anim indices for ${anim.name}');
				}
			}

			if (json.healthbar_colors == null)
				json.healthbar_colors = [192, 192, 192];
			else if (json.healthbar_colors is String){
				var color:Null<FlxColor> = FlxColor.fromString(cast json.healthbar_colors);
				json.healthbar_colors = (color==null) ? null : [color.red, color.green, color.blue];
			}

			return json;
		}catch(e){
			trace('$characterName: Error loading character JSON file');
		}

		return null;
	}

	public static function parseIndices(indices:Array<Any>):Array<Int>
	{
		var parsed:Array<Int> = [];

		for (expr in indices)
		{
			if (expr is Int)
				parsed.push(expr);
			else if (expr is String)
			{
				var expr:String = Std.string(expr);
				var isRange:Bool = expr.contains("...");
				var exprArgs:Array<String> = expr.split(isRange ? "..." : "*");

				switch (exprArgs.length){
					case 0: 
						// Can't do anything lol
					case 1:
						parsed.push(Std.parseInt(exprArgs[0]));
					default:
						var exprA = Std.parseInt(exprArgs[0]);
						var exprB = Std.parseInt(exprArgs[1]);
						
						if (isRange){
							// starting from 'a' and ending on 'b'
							for (frameN in exprA...(exprB + 1))
								parsed.push(frameN);
						}else{
							// 'a' repeated 'b' times
							for (_ in 0...(exprB + 1))
								parsed.push(exprA);
						}
				}		
			}
		}

		return parsed;
	}

	/**	
		Returns "texture", "packer" or "sparrow"
	**/
	public static function getImageFileType(path:String):String
	{
		if (Paths.fileExists('images/$path/Animation.json', TEXT))
			return "texture";
		else if (Paths.fileExists('images/$path.txt', TEXT))
			return "packer";
		else
			return "sparrow";
	}

	public static function returnCharacterPreload(characterName:String):Array<funkin.data.Cache.AssetPreload>{
		var char = getCharacterFile(characterName);

		if (char == null)
			return [];

		return [
			{path: char.image}, // spritesheet
			{path: 'icons/${char.healthicon}'} // icon
		];
	}

	public static function getDefaultAnimCamOffset(name:String) return {
		if (!name.startsWith('sing'))
			[0.0, 0.0];
		else if (name.startsWith('singLEFT'))
			[-30.0, 0.0];
		else if (name.startsWith('singDOWN'))
			[0.0, 30.0];
		else if (name.startsWith('singUP'))
			[0.0, -30.0];
		else if (name.startsWith('singRIGHT'))
			[30.0, 0.0];
		else
			[0.0, 0.0];
	}

	public static function charToPsychData(char:Character){
		return {
			"animations": char.animationsArray,
			"image": char.imageFile,
			"scale": char.baseScale,
			"sing_duration": char.singDuration,
			"healthicon": char.healthIcon,

			"position": char.positionArray,
			"camera_position": char.cameraPosition,

			"flip_x": char.originalFlipX,
			"no_antialiasing": char.noAntialiasing,
			"healthbar_colors": char.healthColorArray
		};
	}

	/**
		Returns an array with every character file in the characters folder(s).
	**/
	#if !sys
	@:noCompletion private static var _listCache:Null<Array<String>> = null;
	#end
	public static function getAllCharacters(modsOnly = false):Array<String>
	{
		#if !sys
		if (_listCache != null)
			return _listCache;

		var characters:Array<String> = _listCache = [];
		#else
		var characters:Array<String> = [];
		#end

		var _characters = new Map<String, Bool>();

		function readFileNameAndPush(fileName:String){
			var dot = fileName.lastIndexOf('.');
			var name = dot>0 ? fileName.substr(0, dot) : fileName;
			_characters.set(name, true);
		}
		
		for (folderPath in Paths.getFolders("characters", modsOnly))
		{
			Paths.iterateDirectory(folderPath, readFileNameAndPush);
		}

		for (name in _characters.keys())
			characters.push(name);

		return characters;
	}
}