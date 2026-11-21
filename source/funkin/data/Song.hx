package funkin.data;

import funkin.data.ChartData.SongMetadata;
import funkin.data.ChartData.SwagSong;
import funkin.states.LoadingState;
import funkin.states.PlayState;
import flixel.system.FlxAssets.FlxSoundAsset;

inline final DEFAULT_CHART_ID = "normal";

abstract class Song
{
	public static function get(songId:String, packId:String):Null<Song> {
		var pack = funkin.data.content.PackManager.packMap.get(packId);
		if (pack != null) {
			for (song in pack.songs) {
				if (song.songId == songId)
					return song;
			}
		}
		trace('Song.get($songId, $packId) returned null');
		return null;
	}

	public final songId:String;
	public final packId:String;

	#if ALLOW_DEPRECATION
	@:deprecated("`folder` is deprecated! Use `packId` instead!")
	public var folder(get, never):String;
	@:noCompletion inline function get_folder() return packId;
	#end

	public function new(songId:String, packId:String = '')
	{
		this.songId = songId;
		this.packId = packId;
	}

	public function play(chartId:String = ''):Void
		playSong(this, chartId);

	public function toString():String
		return '$packId:$songId';

	/**
	 * Returns metadata for the requested chartId. 
	 * If it doesn't exist, metadata for the default chart is returned instead
	 * 
	 * @param chartId The song chart for which you want to request metadata
	**/
	abstract public function getMetadata(chartId:String = DEFAULT_CHART_ID):SongMetadata;

	/**
	 * Returns chart data for the requested chartId. 
	 * If it doesn't exist, null is returned instead
	 * 
	 * @param chartId The song chart for which you want to request chart data
	**/
	abstract public function getSwagSong(chartId:String = DEFAULT_CHART_ID):Null<SwagSong>;

	/**
	 * Returns a path to a file of name fileName that belongs to this song
	**/
	abstract public function getSongFile(fileName:String):String;

	/**
	 * Returns an array of charts available for this song
	**/
	abstract public function getCharts():Array<String>;
	
	public function getChartId(id:String = ""):String
	{
		return id.length > 0 ? id : {
			var charts = getCharts();
			charts.contains(DEFAULT_CHART_ID) ? DEFAULT_CHART_ID : charts[0];
		}
	}

	/**
		Returns an FlxSoundAsset for the track of name trackName
	**/
	public function getTrackSound(trackName:String):FlxSoundAsset
	{
		return Paths.returnSound(this.getSongFile(trackName + "." + Paths.SOUND_EXT));
	}

	////
	/** Loads a singular song to be played on PlayState **/
	public inline static function loadSong(song:Song, chartId:String = "") {
		PlayState.loadPlaylist([song], song.getChartId(chartId));
	}

	/** Loads a singular song to be played on PlayState, then switches to it **/
	public inline static function playSong(song:Song, chartId:String = "")
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