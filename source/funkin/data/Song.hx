package funkin.data;

import funkin.states.LoadingState;
import funkin.states.PlayState;
import funkin.data.ChartData;
import funkin.data.BaseSong;
import haxe.io.Path;

using CoolerStringTools;
using StringTools;

final defaultDifficultyOrdering:Array<String>  = ["easy", "normal", "hard", "erect", "nightmare"];

class Song extends BaseSong
{
	public var songPath:String;

	private var _charts:Array<String> = null;
	private var metadataCache = new Map<String, SongMetadata>();

	public function new(songId:String, ?packId:String)
	{
		super(songId, packId);
		this.songPath = Paths.getFolderPath(this.packId) + '/songs/$songId';
	}

	/**
	 * Returns a path to a file of name fileName that belongs to this song
	**/
	public function getSongFile(fileName:String) {
		return '$songPath/$fileName';
	}

	/** get uncached metadata **/
	private function _getMetadata(chartId:String):Null<SongMetadata> {
		var suffix = getDifficultyFileSuffix(chartId);
		var fileName:String = 'metadata' + suffix + '.json';
		var path:String = getSongFile(fileName);
		return Paths.getJson(path);
	}

	/**
	 * Returns metadata for the requested chartId. 
	 * If it doesn't exist, metadata for the default chart is returned instead
	 * 
	 * @param chartId The song chart for which you want to request metadata
	**/
	public function getMetadata(chartId:String = DEFAULT_CHART_ID):SongMetadata {
		if (chartId=="")
			chartId=DEFAULT_CHART_ID;

		if (metadataCache.exists(chartId)) {
			//trace('$this: Returning cached metadata for $chartId');
			return metadataCache.get(chartId);
		}

		var meta = _getMetadata(chartId);
		if (meta != null) {
			//trace('$this: Found metadata for $chartId');
		}
		else if (chartId != DEFAULT_CHART_ID) {
			if (Main.showDebugTraces)
				trace('$this: Metadata not found for [$chartId]. Using default');
			return getMetadata(DEFAULT_CHART_ID);
		}
		else {
			if (Main.showDebugTraces)
				trace('$this: No metadata found! Maybe add some?');
			meta = {};
		}
		meta.songName ??= songId.replace("-", " ").capitalize();

		metadataCache.set(chartId, meta);
		return meta;
	}

	/**
	 * Returns chart data for the requested chartId. 
	 * If it doesn't exist, null is returned instead
	 * 
	 * @param chartId The song chart for which you want to request chart data
	**/
	public function getSwagSong(chartId:String = DEFAULT_CHART_ID):Null<SwagSong> {
		if (chartId == '')
			chartId = DEFAULT_CHART_ID;

		var suffix = getDifficultyFileSuffix(chartId);
		var path = getSongFile(songId + suffix + ".json");
		return ChartData.parseSongJson(path);
	}

	/**
	 * Returns an array of charts available for this song
	**/
	public function getCharts():Array<String>
		return _charts ?? (_charts = _getCharts());

	public inline function play(chartId:String = ''):Void
		Song.playSong(this, chartId);

	private function _getCharts():Array<String>
	{		
		final songPath = getSongFile("");
		final charts:Map<String, Bool> = [];

		for (fileName in Paths.readDirectory(songPath)) {
			var woExtension:String = Path.withoutExtension(fileName);
			if (woExtension == songId) {
				charts.set("normal", true);
			}
			else if (woExtension.startsWith('$songId-')){
				var diff = woExtension.substr(songId.length + 1);
				charts.set(diff, true);
			}
		}

		var chartNames:Array<String> = [for (name in charts.keys()) name];
		chartNames.sort(sortChartDifficulties);
		return chartNames;
	}

	public inline static function getDifficultyFileSuffix(diff:String) {
		diff = Paths.formatToSongPath(diff);
		return (diff=="" || diff=="normal") ? "" : '-$diff';
	}

	public inline static function sortChartDifficulties(a:String, b:String) {
		return CoolUtil.stringSort(defaultDifficultyOrdering, a.toLowerCase(), b.toLowerCase());
	}

	/** Return an array of strings related to the song's credits **/
	public inline static function getMetadataInfo(metadata:SongMetadata):Array<String> {
		return ChartData.getMetadataInfo(metadata);
	}

	/** Loads a singular song to be played on PlayState **/
	public inline static function loadSong(song:BaseSong, chartId:String = "") {
		PlayState.loadPlaylist([song], song.getChartId(chartId));
	}

	/** Loads a singular song to be played on PlayState, then switches to it **/
	public inline static function playSong(song:BaseSong, chartId:String = "")
	{
		loadSong(song, chartId);
		switchToPlayState();
	}

	public inline static function switchToPlayState()
	{
		if (FlxG.sound.music != null)
			FlxG.sound.music.volume = 0;

		LoadingState.loadAndSwitchState(new PlayState());
	}
}