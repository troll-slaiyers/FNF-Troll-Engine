package funkin.data;

import funkin.objects.Character;
import funkin.data.CharacterData;

@:publicFields
class VSliceCharacterData {
	static function isVSliceFormat(data:Dynamic):Bool {
		// Fuck everything
		return Reflect.field(data, "version") != null;
	}

	#if true // Functions to convert to Psych format
	static function toPsychData(data:Dynamic):CharacterFile {
		var data: VSliceCharJson = data;
		// TODO: render type shit
		return {
			script_name: "vslice",
			animations: [for(anim in data.animations) toPsychAnim(anim)],
			image: data.assetPath,
			scale: (data?.scale ?? 1) * ((data?.isPixel ?? false) ? 6 : 1),
			sing_duration: data?.singTime ?? 4,
			
			position: data?.offsets ?? [0, 0],
			camera_position: data?.cameraOffsets ?? [0, 0],

			flip_x: data?.flipX ?? false,
			no_antialiasing: data?.isPixel ?? false,

			healthicon: data?.healthIcon?.id ?? 'bf',
			healthbar_colors: [255, 0, 0]
		}
	}

	static function toPsychAnim(anim:VSliceAnimData):AnimArray return {
		anim: anim.name,
		name: anim.prefix,
		fps: anim.frameRate ?? 24,
		indices: anim.frameIndices,
		loop: anim.looped ?? false,
		offsets: anim.offsets,
	}
	#end

	#if true // Functions to convert to VSlice format
	static function characterToVSliceData(char:Character){
		return {
			"generatedBy": "TROLL ENGINE",
			"version": "1.0.0",

			"name": char.characterId,
			"assetPath": char.imageFile,
			"renderType": CharacterData.getImageFileType(char.imageFile),
			"flipX": char.originalFlipX,
			"scale": char.baseScale,
			"isPixel": char.noAntialiasing == true, // i think // isPixel also assumes its scaled up by 6 so

			"offsets": char.positionArray,
			"cameraOffsets": char.cameraPosition,

			"singTime": char.singDuration, 
			"danceEvery": char.danceEveryNumBeats,
			"startingAnimation": char.danceIdle ? "danceLeft" : "idle",

			"healthIcon": {
				"id": char.healthIcon,
				"offsets": [0, 0],
				"isPixel": StringTools.endsWith(char.healthIcon, "-pixel"),
				"flipX": false,
				"scale": 1
			},

			"animations": [for (anim in char.animationsArray) toVSliceAnim(anim)],
		};
	}

	static function toVSliceAnim(anim:AnimArray):VSliceAnimData return {
		"name": anim.anim,
		"prefix": anim.name,
		"offsets": anim.offsets,
		"looped": anim.loop,
		"frameRate": 24,
		"flipX": false,
		"flipY": false
	}
	#end
}


typedef VSliceDeathData = {
	?cameraOffsets:Array<Float>,
	?cameraZoom:Float,
	?preTransitionDelay:Float
}
typedef VSliceHealthIconData = {
	id: Null<String>,
	scale: Null<Float>,
	flipX: Null<Bool>,
	isPixel: Null<Bool>,
	offsets: Null<Array<Float>>
}
typedef VSliceAnimData = {
	name:String,
	?prefix:String,
	?assetPath:String,
	?offsets:Array<Float>,
	?looped:Bool,
	?flipX:Bool,
	?flipY:Bool,
	?frameRate:Int,
	?frameIndices:Array<Int>
};	

typedef VSliceCharJson = {
	var version: String;
	var name: String;
	var renderType: String;
	var assetPath: String;
	var scale: Null<Float>;
	var healthIcon: Null<VSliceHealthIconData>;
	var death: Null<VSliceDeathData>;
	var offsets: Null<Array<Float>>;
	var cameraOffsets: Array<Float>;
	var isPixel: Null<Bool>;
	var danceEvery: Null<Float>;
	var singTime: Null<Float>;
	var animations: Array<VSliceAnimData>;
	var startingAnimation: Null<String>; // ???? WHAT IS THE POINT OF THIS
	var flipX: Null<Bool>;
}