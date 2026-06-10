package funkin.data;

import funkin.Paths;
import haxe.Json;
using StringTools;

typedef VSliceStageProp = {
	?name:String,
	assetPath:String,
	position:Array<Float>,
	?zIndex:Int,
	?isPixel:Bool,
	?flipX:Bool,
	?flipY:Bool,
	?scale:haxe.ds.Either<Float, Array<Float>>,
	?alpha:Float,
	?danceEvery:Float,
	?scroll:Array<Float>,
	?animations:Array<funkin.data.VSliceCharacterData.VSliceAnimData>,
	?startingAnimation:String,
	?animType: String,
	?angle:Float,
	?blend:String,
	?color:String
}

typedef VSliceStageChar = {
	?zIndex:Int, 
	?position: Array<Float>,
	?scale: Float,
	?cameraOffsets:Array<Float>,
	?scroll: Array<Float>,
	?alpha:Float,
	?angle:Float
}

typedef VSliceStageFile = 
{
	version:String,
	name:String,
	props:Array<VSliceStageProp>,
	characters:{bf: VSliceStageChar, gf: VSliceStageChar, dad:VSliceStageChar},
	?cameraZoom: Float,
	?directory:String
}

// prop shit is kinda just here for vslice compat
// eventually we should make it all polished and add an editor and the like lol
// Also should prob make a generic prop typedef which both LevelProp and StageProp can extend from
// Also maybe a generic prop/bopper class lol

typedef StagePropData = {
	// Scripting
	?id:String,
	// Position shit
	?x:Float,
	?y:Float,
	?flipX:Bool,
	?flipY:Bool,
	
	// Visuals
	graphic:String,
	?alpha:Float,
	?scrollFactor:Array<Float>,
	?scale:Array<Float>,
	?antialiasing:Bool,
	?animations:Array<funkin.data.Level.LevelPropAnimation>,

	// Ordering
	?index:Int, // ZIndex within the layer (stage or foreground)
	?foreground:Bool, // Whether to put this in the foreground

	// Bopping
	?danceSequence:Array<String>, // Cycles through this every dance
	?danceBeat:Float, // What beat to dance on. 0 = disabled
}

typedef StageFile =
{
	var directory:String;
	var defaultZoom:Float;

	var boyfriend:Array<Dynamic>;
	var girlfriend:Array<Dynamic>;
	var opponent:Array<Dynamic>;
	@:optional var props:Array<StagePropData>;

	@:optional var hide_girlfriend:Bool;

	@:optional var camera_boyfriend:Array<Float>;
	@:optional var camera_opponent:Array<Float>;
	@:optional var camera_girlfriend:Array<Float>;
	@:optional var camera_speed:Null<Float>;

	@:optional var bg_color:Null<String>;

	// v-slice positioning using the character's width and height to offset them
	@:optional var alternate_char_pos:Bool;

	// title screen vars
	@:optional var camera_stage:Array<Float>; 
	@:optional var title_zoom:Float;

	// caching
	@:optional var preloadStrings:Array<String>;
	@:optional var preload:Array<funkin.data.Cache.AssetPreload>; // incase you would like to add more information, though you shouldnt really need to
}

typedef StageReference = {id:String, folder:String};

class StageData {
	public static function getStageFile(stageId:String):Null<StageFile> 
	{
		var json:Dynamic = Paths.json('stages/$stageId.json');
		if (json != null && Reflect.hasField(json, "version")){
			var json:VSliceStageFile = cast json;
			return StageData.convertVSlice(json);
		}
		return json;
	}
	/**
		Returns an array with references to stages defined in the `titleStageList.txt` files.
	**/ 
	public static function getTitleStages():Array<StageReference>
	{
		var daList:Array<StageReference> = [];

		for (cid in Paths.packList) {
			var cunt = Paths.packMap.get(cid);
			for (stageId in cunt.getTitleStages())
				daList.push({id: stageId, folder: cid});
		}

		return daList;
	}

	/**
		Returns an array with every stage in the stages folder(s).
	**/
	#if !sys
	@:noCompletion private static var _listCache:Null<Array<String>> = null;
	#end
	public static function getAllStages():Array<String>
	{
		#if !sys
		if (_listCache != null)
			return _listCache;

		var stages:Array<String> = _listCache = [];
		#else
		var stages:Array<String> = [];
		#end

		var _stages = new Map<String, Bool>();

		
		for (folderPath in Paths.getFolders("stages"))
		{
			for (fileName in Paths.readDirectory(folderPath)) {
				if (fileName==null) continue;
				if (!fileName.endsWith(".json")) continue;
	
				var name = fileName.substr(0, fileName.length - 5);
				_stages.set(name, true);
			}
		}

		for (name in _stages.keys())
			stages.push(name);

		return stages;
	}

	public inline static function convertVSliceProps(json: VSliceStageFile)
	{
		var props:Array<StagePropData> = [];

		for (v in json.props) {
			var scale:Array<Float> = [1, 1];
			if (v.scale is Float) {
				var c:Float = cast v.scale;
				scale = [c, c];
			} else if (v.scale is Array) scale = cast scale;

			var sequence = ["idle"];

			props.push({
				id: v.name,
				graphic: v.assetPath,
				x: v.position[0],
				y: v.position[1],
				flipX: v?.flipX ?? false,
				flipY: v?.flipY ?? false,
				alpha: v?.alpha ?? 1,
				scrollFactor: v?.scroll ?? [1],
				scale: scale,
				antialiasing: !(v?.isPixel ?? false),
				animations: [
					for (a in v.animations) {
						if (a.name == 'danceLeft') sequence = ["danceLeft", "danceRight"];

						{
							name: a.name,
							prefix: a.prefix,
							looped: a?.looped ?? false,
							fps: a?.frameRate ?? 24,
							indices: a.frameIndices,
							offset: a.offsets == null ? [0, 0] : [Std.int(a.offsets[0]), Std.int(a.offsets[1])],
							flipX: a?.flipX,
							flipY: a?.flipY
						}
					}
				],
				index: (v.zIndex >= json.characters.bf.zIndex) ? v.zIndex - json.characters.bf.zIndex : v.zIndex,
				foreground: v.zIndex >= json.characters.bf.zIndex,

				danceSequence: sequence,
				danceBeat: v?.danceEvery ?? 0
			});
		}

		trace(props);
	
		return props;

	}

	public static function convertVSlice(json: VSliceStageFile):StageFile 
	{
		return {
			props: StageData.convertVSliceProps(json),
			directory: "", // json.directory maybe idfk
			defaultZoom: json.cameraZoom,
			boyfriend: json.characters.bf.position,
			girlfriend: json.characters.gf.position,
			opponent: json.characters.dad.position,
			hide_girlfriend: false,
			camera_boyfriend: json.characters.bf.cameraOffsets == null ? [0, 0] : [json.characters.bf.cameraOffsets[0] * -1, json.characters.bf.cameraOffsets[1] * -1],
			camera_opponent: json.characters.dad.cameraOffsets,
			camera_girlfriend: json.characters.gf.cameraOffsets,
			camera_speed: 1,
			alternate_char_pos: true
		}
	}
}