package funkin.data.content;

import haxe.io.Path;
import funkin.Paths;
import funkin.data.content.Pack;

class ContentFolder extends Pack {
	public var jsonData:ContentMetadata = {};

	override function load() {
		var metaJson:PackMetadata = Paths.getJson('$path/pack.json');
		if (metaJson != null) {
			if (metaJson.bgColor is String)
				metaJson.bgColor = CoolUtil.colorFromString(cast metaJson.bgColor);
			this.metadata = metaJson;
		}
		
		////
		var metaJson:ContentMetadata = Paths.getJson('$path/metadata.json');
		
		if (metaJson == null) {
			trace('No metadata file found for $id, $path');
			return;
		}

		this.jsonData = metaJson;
		this.runsGlobally = metaJson.runsGlobally;
		this.dependencies = metaJson.dependencies ?? [];
	}

	inline static function updateContentMetadataStructure(data:Dynamic):ContentMetadata
	{
		#if ALLOW_DEPRECATION
		inline function getFreeplaySongs():Array<String> {
			var list:Array<String> = [];
			
			var fs:Dynamic = Reflect.field(data, "freeplaySongs");
			if (fs is Array) {
				var fs:Array<Dynamic> = cast fs;
				
				if (fs.length == 0) {
					// none
				}else if (fs[0] is String) {
					for (s in fs) list.push(Std.string(s));
				}
				else if (Reflect.isObject(fs[0])) {
					for (s in fs) {
						var v = Reflect.field(s, "name");
						if (v != null) list.push(Std.string(v));
					}
				}
			}
			
			return list;
		}

		if (Reflect.hasField(data, "freeplaySongs"))
			Reflect.setField(data, "freeplaySongs", getFreeplaySongs());
		#end

		return data;
	}

	override function getSongs():Array<BaseSong> {
		var songList:Array<BaseSong> = [];

		var songsPath = this.path + '/songs/';
		for (folderName in Paths.readDirectory(songsPath)) {
			if (Paths.isDirectory(songsPath + folderName)) {
				// trace(songList.length, folderName);
				songList.push(new Song(folderName, this.id));
			}
		}

		return songList;
	}

	override function getFreeplaySongs():Array<BaseSong> {
		var list:Array<BaseSong> = [];
		var songIdMap:Map<String, Bool> = [];

		inline function sowy(songId:String) {
			if (!songIdMap.exists(songId)) {
				songIdMap.set(songId, true);
				list.push(new Song(songId, this.id));
			}
		}

		//// level songs
		for (level in this.getStoryModeLevels()) {
			if (!level.isUnlocked())
				continue;
			
			for (song in level.getFreeplaySongs()) {
				songIdMap.set(song.songId, true);
				list.push(song);
			}
		}

		// metadata file freeplay songs
		if (jsonData.freeplaySongs != null) {
			for (songId in jsonData.freeplaySongs)
				sowy(songId);
		}

		// freeplaySonglist.txt
		var rawList:Null<String> = Paths.getContent('$path/data/freeplaySonglist.txt');
		if (rawList != null) {
			for (songId in CoolUtil.listFromString(rawList)) {
				#if ALLOW_DEPRECATION
				// old tgt shit '$id:$category'
				var split:Array<String> = songId.split(":");
				sowy(split.length > 1 ? split[0] : songId);
				#else
				sowy(songId);
				#end
			}
		}
		
		// default category shit
		// should prob just make a autoAddToFreeplay bool or sum shit idk lol
		if (jsonData.defaultCategory != null && jsonData.defaultCategory.length > 0){
			var dir = '$path/songs';

			for (file in Paths.readDirectory(dir)) {
				if (sys.FileSystem.isDirectory('$dir/$file')) {
					sowy(file);
				}
			}
		}
		
		return list;
	}

	override function getStoryModeLevels():Array<Level> {
		var levelDir = this.path + '/levels/';

		var contentLevelPaths:Array<String> = [];
		for (file in Paths.readDirectory(levelDir)) {
			var name = Path.withoutExtension(levelDir + file);
			if(!contentLevelPaths.contains(name))
				contentLevelPaths.push(name);
		}

		var contentLevels:Array<Level> = [];
		for (filePath in contentLevelPaths) {
			var levelId:String = Path.withoutDirectory(filePath);
			var index:Int = contentLevelPaths.indexOf(filePath);
			contentLevels.push(Level.fromFile(filePath, levelId, this.id, index));
		}

		contentLevels.sort((a,b)-> return a.getIndex() - b.getIndex());
		return contentLevels;
	}

	override function getTitleStages():Array<String> {
		return jsonData.titleStages ?? {
			var daList:Array<String> = [];
			
			var rawList = Paths.getContent('$path/data/stageList.txt');
			if (rawList != null && StringTools.trim(rawList).length > 0) {
				for (shit in rawList.split("\n"))
					daList.push(StringTools.replace(StringTools.trim(shit), "\n", ""));
			}
			
			daList;
		};
	}
}

typedef ContentMetadata = {
	/** API Version **/
	@:optional var trollEngine:String;
	
	/**
		This mod will always run, regardless of whether it's currently being played or not.
		(Custom HUDs, etc, will find this useful, as you can have stuff run across every song without adding to the global folder)
	**/
	@:optional var runsGlobally:Bool;
	
	/**
		Content that will load before this content.
	**/
	@:optional var dependencies:Array<String>;

	/**
		Stages that can appear in the title menu
	**/
	@:optional var titleStages:Array<String>;

	/**
		Songs to be placed into the freeplay menu
	**/
	@:optional var freeplaySongs:Array<String>;

	/**
		Categories to be placed into the freeplay menu
	**/
	@:optional var freeplayCategories:Array<FreeplayCategoryMetadata>;
	
	/**
		If this is specified, then songs don't have to be added to freeplaySongs to have them appear
		As anything in the songs folder will appear in this category instead
	**/
	@:optional var defaultCategory:String;
}

typedef FreeplayCategoryMetadata = {
	/**
		Displayed Name of the category
		This is used to show the category in the freeplay list
	**/
	var name:String;

	/**
		ID of the category
		This gets used when adding songs to the category
		(Defaults are main, side and remix)
	**/
	var id:String;
}