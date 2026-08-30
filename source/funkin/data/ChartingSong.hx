package funkin.data;

class ChartingSong extends Song {
	private var localTrackPaths:Map<String, String>;
	private var bitch:Song;

	public function new(song:Song) {
		this.bitch = song;
		super('ChartingSong', song.packId);
	}

	override function toString() {
		return 'ChartingSong[${bitch.toString()}]';
	}

	/**
	 * Returns metadata for the requested chartId. 
	 * If it doesn't exist, metadata for the default chart is returned instead
	 * 
	 * @param chartId The song chart for which you want to request metadata
	**/
	public function getMetadata(chartId:String = DEFAULT_CHART_ID):SongMetadata
	{
		return bitch.getMetadata(chartId);
	}

	/**
	 * Returns chart data for the requested chartId. 
	 * If it doesn't exist, null is returned instead
	 * 
	 * @param chartId The song chart for which you want to request chart data
	**/
	public function getSwagSong(chartId:String = DEFAULT_CHART_ID):Null<SwagSong>
	{
		return bitch.getSwagSong(chartId);
	}

	/**
	 * Returns a path to a file of name fileName that belongs to this song
	**/
	public function getSongFile(fileName:String):String
	{
		return bitch.getSongFile(fileName);
	}

	/**
	 * Returns an array of charts available for this song
	**/
	public function getCharts():Array<String>
	{
		return bitch.getCharts();
	}

	public function getChartId(id:String = ""):String
	{
		return bitch.getChartId(id);
	}

	/**
		Returns an FlxSoundAsset for the track of name trackName
	**/
	override function getTrackSound(trackName:String):FlxSoundAsset
	{
		if (localTrackPaths.exists(trackName)) 
			return Paths.returnSound(localTrackPaths.get(trackName));
		else
			return super.getTrackSound(trackName);		
	}
}