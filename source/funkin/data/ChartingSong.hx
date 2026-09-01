package funkin.data;

import funkin.data.Song;
import funkin.data.ChartData;
import flixel.system.FlxAssets.FlxSoundAsset;
import funkin.api.Native;
import haxe.io.Path;

/** 
	Song class used for a temporary song that only exist in memory.
**/
@:inheritDoc
class ChartingSong extends Song {
	private static var path:String = Path.join([Native.getTempDirectory(), "ChartingSong"]);
	private var localTrackPaths:Map<String, String> = [];
	private var chartData:SwagSong;

	public function new(chartData:SwagSong) {
		this.chartData = chartData;
		super('ChartingSong', Paths.currentPackId);
	}

	public function addSongFile(filePath:String) {
		localTrackPaths.set(filePath, filePath);
	}

	public function getMetadata(chartId:String = DEFAULT_CHART_ID):SongMetadata
	{
		return null;
	}

	public function getSwagSong(chartId:String = DEFAULT_CHART_ID):Null<SwagSong>
	{
		return chartData;
	}

	public function getSongFile(fileName:String):String
	{
		return '$path/$fileName';
	}

	public function getCharts():Array<String>
	{
		return [];
	}

	override function getTrackSound(trackName:String):FlxSoundAsset
	{
		if (localTrackPaths.exists(trackName)) 
			return Paths.returnSound(localTrackPaths.get(trackName));
		else
			return null;
	}	
}

/*
@:inheritDoc
class ChartingSong extends Song {
	private var localTrackPaths:Map<String, String> = [];
	private var bitch:Song;

	public function new(song:Song) {
		this.bitch = song;
		super('ChartingSong', song.packId);
	}

	override function toString() {
		return 'ChartingSong[${bitch.toString()}]';
	}

	public function getMetadata(chartId:String = DEFAULT_CHART_ID):SongMetadata
	{
		return bitch.getMetadata(chartId);
	}

	public function getSwagSong(chartId:String = DEFAULT_CHART_ID):Null<SwagSong>
	{
		return bitch.getSwagSong(chartId);
	}

	public function getSongFile(fileName:String):String
	{
		return bitch.getSongFile(fileName);
	}

	public function getCharts():Array<String>
	{
		return bitch.getCharts();
	}

	override function getChartId(id:String = ""):String
	{
		return bitch.getChartId(id);
	}

	override function getTrackSound(trackName:String):FlxSoundAsset
	{
		if (localTrackPaths.exists(trackName)) 
			return Paths.returnSound(localTrackPaths.get(trackName));
		else
			return super.getTrackSound(trackName);		
	}
}
*/