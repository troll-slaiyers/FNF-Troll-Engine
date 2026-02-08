package funkin.data;

class MusicData 
{
	////
	public var path:String;
	
	/** The display name of this song **/
	public var songName:String = "Unknown";

	public var artist:String;

	/** Whether or not this song should loop. **/
	public var looped:Bool = true;

	/** At which point to start playing the song, in milliseconds. **/
	public var startTime:Float = 0.0;
	
	/** In case of looping, the point (in milliseconds) from where to restart the song when it loops back **/
	public var loopTime:Float = 0.0;
	
	/** At which point to stop playing the song, in milliseconds. If not set / null, the song completes normally. **/
	public var endTime:Null<Float> = null;

	public var bpm:Float = 100;

	public function new(path:String) {
		this.path = path;
	}

	/**
		@param snd Optional `FlxSound` instance to load and play music data onto.
		@returns An `FlxSound` instance playing this song.
	**/
	public function play(?sound:FlxSound, volume:Float = 1.0):FlxSound {
		var snd = sound ?? FlxG.sound.list.recycle(FlxSound);
		snd.loadEmbedded(Paths.returnSound(path), looped, false);
		snd.volume = volume;
		snd.play(false, startTime, endTime);
		snd.loopTime = loopTime;

		if (sound == null) {
			snd.context = MUSIC;
			FlxG.sound.defaultMusicGroup.add(snd);
		}

		return snd;
	}

	////
	public static function fromFilePaths(soundPath:String, jsonPath:String):Null<MusicData> {
		if (!Paths.exists(soundPath))
			return null;

		var jsonData:MusicDataJSON = Paths.getJson(jsonPath);
		if (jsonData == null)
			return null;
		
		var md = new MusicData(soundPath);
		md.songName = jsonData.songName ?? "Unknown";
		md.artist = jsonData.artist ?? "Unknown";
		md.looped = jsonData.looped != false;
		md.startTime = jsonData.startTime ?? 0.0;
		md.loopTime = jsonData.loopTime ?? 0.0;
		md.endTime = jsonData.endTime;
		md.bpm = jsonData.bpm ?? 100;
		return md;
	}

	public static function fromName(name:String):Null<MusicData>
	{
		var soundPath:String = Paths.getPath('music/$name.${Paths.SOUND_EXT}');
		var jsonPath:String = {
			var p = new haxe.io.Path(soundPath);
			p.ext = 'json';
			p.toString();
		}

		return fromFilePaths(soundPath, jsonPath);
	}
}

typedef MusicDataJSON = {
	@:optional var songName:String;
	@:optional var artist:String;
	
	@:optional var looped:Bool;
	@:optional var endTime:Float;
	@:optional var loopTime:Float;
	@:optional var startTime:Float;
	
	@:optional var bpm:Float;
	//@:optional var bpmChangeMap:Array<Dynamic>;
	// TODO: bpm change data that's not tied to sections¿
}