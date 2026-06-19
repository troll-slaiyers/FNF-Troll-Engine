package funkin.data.content;

import funkin.data.BaseSong;
import funkin.data.Moonchart;
import moonchart.Moonchart;
import moonchart.backend.FormatDetector;
import moonchart.backend.FormatData;
import moonchart.backend.Util as MoonchartUtil;
import moonchart.formats.fnf.FNFVSlice;

import sys.FileSystem;
import sys.io.File;

import funkin.CoolUtil.alphabeticalSort;
import funkin.CoolUtil.stringSort;

using StringTools;

class MoonchartFolder extends Pack
{	
	private static var initialized = false;
	private static var formatMap = new Map<Format, SowyFormatData>();

	override function load() {
		if (initialized) return;

		////
		Moonchart.DEFAULT_DIFF = DEFAULT_CHART_ID;
		Moonchart.init();

		////
		var supportedFormats = new Array<Format>();
		for (format => formatData in FormatDetector.formatMap) {
			if (formatData.hasMetaFile != TRUE) // not dealing with ts
				supportedFormats.push(format);
		}
		supportedFormats.push(FNF_VSLICE);

		////
		var moonchartPath:String = '$path/moonchart';

		for (formatId in supportedFormats) {
			var folderPath:String = MoonchartUtil.extendPath(moonchartPath, formatId);
			var sowyData = new SowyFormatData(formatId, folderPath);
			formatMap.set(formatId, sowyData);

			if (sowyData.basicFormat.formatMeta.supportsDiffs) // why is this data stored on the instances 
				sowyData.diffFindFunc = (_, path, files) -> DiffFinder.fromFileDiffs(path, files, sowyData.basicFormat);
			else
				sowyData.diffFindFunc = (id, path, files) -> DiffFinder.fromFileSuffix(path, files, id);

			if (formatId.startsWith("FNF"))
				sowyData.diffSortFunc = stringSort.bind(FNF_DIFFICULTIES);
			
			FileSystem.createDirectory(sowyData.folderPath);
		}

		//// tweakin
		{
			var f = formatMap.get(FNF_VSLICE);
			var bf = cast(f.basicFormat, FNFVSlice);
			f.diffFindFunc = (id, path, files) -> DiffFinder.fromVSliceFiles(bf, path, files, id);
		}
		formatMap.get(STEPMANIA).diffSortFunc = stringSort.bind(SM_DIFFICULTIES);
		formatMap.get(STEPMANIA_SHARK).diffSortFunc = stringSort.bind(SM_DIFFICULTIES);

		////
		initialized = true;
	}

	override function unload() {
		//formatMap.clear();
	}

	override function getFreeplaySongs():Array<BaseSong> {
		var songList:Array<BaseSong> = [];

		for (sowyFormat in formatMap) {
			try {
				sowyFormat.scanSongs();
				var formatSongs:Array<MoonchartSong> = [];
				for (sowySong in sowyFormat.songs) {
					var song = new MoonchartSong(sowySong);
					//songs.set(song.songId, song);
					formatSongs.push(song);
				}
				formatSongs.sort((a, b) -> alphabeticalSort(a.songId, b.songId));
				for (song in formatSongs) songList.push(song);
			}catch(e) {
				trace("Error scanning format " + sowyFormat.ID + ": " + e);
				throw e;
			}
		}

		return songList;
	}
}
