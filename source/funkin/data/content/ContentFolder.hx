package funkin.data.content;

import haxe.io.Path;
import funkin.Paths;
import funkin.data.content.Pack;

class ContentFolder extends Pack {
	override function load() {
		var metaJson:PackMetadata = Paths.getJson('$path/pack.json');
		if (metaJson == null) {
			trace('No pack file found for $id, $path');
			return;
		}

		this.metadata = metaJson;
		this.runsGlobally = metaJson.runsGlobally ?? false;
		this.dependencies = metaJson.dependencies ?? [];
		if (metaJson.bgColor is String)
			metaJson.bgColor = CoolUtil.colorFromString(cast metaJson.bgColor);
	}

	override function getSongs():Array<Song> {
		var songList:Array<Song> = [];

		var songsPath = '$path/songs/';
		for (folderName in Paths.readDirectory(songsPath)) {
			if (Paths.isDirectory(songsPath + folderName)) {
				// trace(songList.length, folderName);
				songList.push(new FNFSong(folderName, this.id));
			}
		}

		return songList;
	}

	override function getFreeplaySongs():Array<Song> {
		var list:Array<Song> = [];
		var songIdMap:Map<String, Bool> = [];

		//// level songs
		for (level in this.getStoryModeLevels()) {
			if (!level.isUnlocked())
				continue;
			
			for (song in level.getFreeplaySongs()) {
				songIdMap.set(song.songId, true);
				list.push(song);
			}
		}

		var rawList:Null<String> = Paths.getContent('$path/data/freeplaySongList.txt');
		if (rawList != null) {
			// If `data/freeplaySongList.txt` only add songs within the list.
			for (songId in CoolUtil.listFromString(rawList)) {
				if (!songIdMap.exists(songId)) {
					songIdMap.set(songId, true);
					list.push(new FNFSong(songId, this.id));
				}
			}
		}else {
			// Otherwise, add every song belonging to the mod.
			for (song in this.getSongs()) {
				if (!songIdMap.exists(song.songId)) {
					songIdMap.set(song.songId, true);
					list.push(song);
				}
			}
		}
		
		return list;
	}

	override function getStoryModeLevels():Array<Level> {
		var levelDir = '$path/levels/';

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

		var rawList:Null<String> = Paths.getContent('$path/data/storyLevelList.txt');
		if (rawList != null) {
			// If `data/storyLevelList.txt` file exists, sort levels by their order on the list
			// If a level isn't present in the list, it will be added at the end of it

			var order:Map<String, Int> = [];
			var splitList = CoolUtil.listFromString(rawList);
			for (i => levelId in splitList)
				order.set(levelId, -(splitList.length - i));

			contentLevels.sort((a, b) -> (order.get(a.id) ?? 0) - (order.get(b.id) ?? 0));
		}

		return contentLevels;
	}

	override function getTitleStages():Array<String> {
		var daList:Array<String> = [];
		
		var rawList = Paths.getContent('$path/data/titleStageList.txt');
		if (rawList != null && StringTools.trim(rawList).length > 0) {
			for (shit in rawList.split("\n"))
				daList.push(StringTools.replace(StringTools.trim(shit), "\n", ""));
		}
			
		return daList;
	}
}