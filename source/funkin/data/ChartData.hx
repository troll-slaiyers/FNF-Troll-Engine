package funkin.data;

import funkin.data.SongEventData.EventBunch;
import funkin.data.SongEventData.EventInstanceData;
import funkin.data.SongEventData.EventChildData;
import haxe.io.Path;
import haxe.Json;

using StringTools;

typedef SongMetadata = {
	/** The display name of this song **/
	var ?songName:String;
	
	@:optional var artist:String;
	@:optional var charter:String;
	@:optional var modcharter:String;
	@:optional var extraInfo:Array<String>;
	
	@:optional var freeplayIcon:String;
	@:optional var freeplayBgGraphic:String;
	@:optional var freeplayBgColor:String;
}

typedef SwagSong = {
	////
	var notes:Array<SwagSection>;
	
	var keyCount:Int;

	/** Offsets the chart notes **/
	var offset:Float;
	
	/** How spread apart the notes should be **/
	var speed:Float;

	////
	var song:String;

	/** Starting BPM of the song **/
	var bpm:Float;
	
	/** Song track data containing the file names of the song's tracks **/
	var tracks:SongTracks;

	////
	var player1:Null<String>;
	var player2:Null<String>;
	var gfVersion:Null<String>;
	var stage:String;
	var hudSkin:String;

	var arrowSkin:String;
	var splashSkin:String;

	////
	@:optional var trollEngine:ChartVersion;
	@:optional var events:Array<EventBunch>;
	
	//// internal
	@:optional var metadata:SongMetadata;
	var validScore:Bool;
}

typedef JsonEvents = {
	@:optional var events:Array<EventBunch>;
}

typedef JsonSong = {
	> SwagSong,
	var _path:String; // for internal use
	@:optional var offset:Float;
	@:optional var keyCount:Int;

	@:optional var player3:String; // old psych
	@:optional var extraTracks:Array<String>; // old te
	@:optional var needsVoices:Bool; // fnf
	@:optional var mania:Int; // vs shaggy
}

typedef SwagSection = {
	var sectionNotes:Array<NoteData>;
	//var lengthInSteps:Int;
	var typeOfSection:Int;
	var mustHitSection:Bool;
	var gfSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
	var sectionBeats:Float;
}

typedef SongTracks = {
	var inst:Array<String>;
	var ?player:Array<String>;
	var ?opponent:Array<String>;
}

typedef PsychEvent = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

// Used for compatibility with Psych 0.1 - 0.3.2 charts, though, you should add your hardcoded custom note types here too.
final defaultNoteTypeList:Array<String> = [
	'',
	'Alt Animation',
	'Hey!',
	'Mine',
	'GF Sing',
	'No Animation'
];

enum abstract ChartVersion(String) from String to String {
	var LEGACY_FNF = "l.0.0"; // legacy fnf format!
	var LEGACY_V1 = "l.1.0"; // legacy fnf format, but mustHitSection doesn't swap note behaviour!
	var LEGACY_V2 = "l.2.0"; // New event structure format
	var CURRENT = LEGACY_V2;
}

class ChartData
{
	public static function _parseJson(filePath:String):Null<Dynamic> {
		var rawJson:Null<String> = Paths.getContent(filePath);
		if (rawJson == null) throw 'File not found';

		// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		rawJson = rawJson.trim();
		while (!rawJson.endsWith("}"))
			rawJson = rawJson.substr(0, rawJson.length - 1);

		return Json.parse(rawJson);
	}

	public static function parseSongJson(filePath:String):Null<SwagSong> {
		try {
			return _parseSongJson(filePath);
		}catch(e) {
			print(CrashHandler.callstackToString(haxe.CallStack.exceptionStack(true)));
			trace('ERROR parsing song JSON: $filePath', e.message);
			throw e;
		}
	}

	/** Unsafe version of `parseSongJson` **/
	public static function _parseSongJson(filePath:String):SwagSong {
		var uncastedJson:Dynamic = _parseJson(filePath);
		var songJson:JsonSong;
		
		// why did shadowmario make such a useless format change oh my god :sob:
		if (uncastedJson.format is String && (uncastedJson.format:String).startsWith("psych_v1"))
		{
			trace('Loading Psych Engine v1.0.0 Chart');
			songJson = cast uncastedJson;
			ChartUpdater.convertPsychV1Notes(songJson);
			songJson._path = filePath;
			return ChartUpdater.updateLegacyJson(songJson);
		}else
			songJson = cast uncastedJson.song;

		songJson._path = filePath;
		return onLoadJson(songJson);
	}

	public static function parseEventsJson(filePath:String):Null<JsonEvents> {
		try {
			return _parseEventsJson(filePath);
		}catch(e) {
			print(CrashHandler.callstackToString(haxe.CallStack.exceptionStack(true)));
			trace('ERROR parsing events JSON: $filePath', e.message);
			return null;
		}
	}

	/** Unsafe version of `parseEventsJson` **/
	public static function _parseEventsJson(filePath:String):JsonEvents {
		var uncastedJson:Dynamic = _parseJson(filePath);
		var eventsJson:JsonEvents;

		if (uncastedJson.format is String && (uncastedJson.format:String).startsWith("psych_v1"))		
			eventsJson = cast uncastedJson;
		else
			eventsJson = cast uncastedJson.song;
		
		return onLoadEvents(eventsJson);
	}

	public static function onLoadJson(songJson:JsonSong):SwagSong
	{
		var swagSong:SwagSong = updateChart(songJson);	
		swagSong.validScore = true;
		return swagSong;
	}

	public static function updateChart(songJson:JsonSong):SwagSong {
		var swagSong:SwagSong;
		var version:Null<ChartVersion> = songJson.trollEngine;
		switch(version) {
			case null | LEGACY_FNF:
				trace("Converting from LEGACY_FNF");
				return updateChart(cast ChartUpdater.updateLegacyJson(songJson));
			case LEGACY_V1:
				trace("Converting from LEGACY_V1");
				songJson.events = ChartUpdater.convertPsychEvents(cast songJson.events);
				songJson.trollEngine = LEGACY_V2;
				return updateChart(songJson);
			case CURRENT:
				trace('Loading chart version $version');
				swagSong = songJson;
			default:
				swagSong = null;
				throw 'Unknown chart version: $version';
		}
		
		return swagSong;
	}

	public static function onLoadEvents(songJson:JsonEvents, checkPsych:Bool = true) {
		if (songJson.events == null){
			songJson.events = [];
		}else {
			ChartUpdater.convertPsychEvents(cast songJson.events);
		}

		//// remove and convert ancient psych event notes
		if (checkPsych) {
			var sections = (cast songJson:JsonSong).notes;
			if (sections != null) {
				ChartUpdater.convertPsychEventNotes(sections, songJson.events);
			}
		}	

		return songJson;
	}

	public static inline function getEventNotes(bunches:Array<EventBunch>, ?resultArray:Array<EventInstanceData>):Array<EventInstanceData>
	{
		return SongEventData.getEventInstanceData(bunches, resultArray);
	}

	/** Return an array of strings related to the song's credits **/
	public static function getMetadataInfo(metadata:SongMetadata):Array<String> {
		var info:Array<String> = [];
		
		inline function pushInfo(str:String) {
			for (string in str.split('\n'))
				info.push(string);
		}

		if (metadata != null) {
			if (metadata.artist != null && metadata.artist.length > 0)		
				pushInfo("Artist: " + metadata.artist);

			if (metadata.charter != null && metadata.charter.length > 0)
				pushInfo("Chart: " + metadata.charter);

			if (metadata.modcharter != null && metadata.modcharter.length > 0)
				pushInfo("Modchart: " + metadata.modcharter);
		}

		if (metadata != null && metadata.extraInfo != null) {
			for (extraInfo in metadata.extraInfo)
				pushInfo(extraInfo);
		}

		return info;
	}
}

abstract ChartObject(Array<Dynamic>) to Array<Dynamic> from Array<Dynamic> {
	public var strumTime(get, set):Float;
	inline function get_strumTime() return this[0];
	inline function set_strumTime(value:Float) return this[0] = value;
}

abstract NoteData(Array<Dynamic>) to Array<Dynamic> to ChartObject
{
	public var strumTime(get, set):Float;
	public var column(get, set):Int;
	public var sustainLength(get, set):Float;
	public var noteType(get, set):String;

	inline function get_strumTime() return this[0];
	inline function set_strumTime(value:Float) return this[0] = value;

	inline function get_column() return this[1];
	inline function set_column(value:Int) return this[1] = value;

	inline function get_sustainLength() return this[2];
	inline function set_sustainLength(value:Float) return this[2] = value;

	inline function get_noteType() return this[3];
	inline function set_noteType(value:String) return this[3] = value;

	private function new(data:Array<Dynamic>)
		this = data;

	public function clone():NoteData
		return fromValues(strumTime, column, sustainLength, noteType);

	public static function fromValues(strumTime:Float, column:Int, sustainLength:Float, noteType:String):NoteData {
		var data:Array<Dynamic> = [strumTime, column, sustainLength, noteType];
		return new NoteData(data);
	}

	public static function fromData(data:Array<Dynamic>):NoteData		
		return isNoteData(data) ? new NoteData(data) : null;

	public static function resolveNoteType(value:Any):String {
		var noteType:String = {
			if (Std.isOfType(value, String))
				(value == 'Hurt Note' ? 'Mine' : value)
			else if (Std.isOfType(value, Int) && (value:Int) > 0)
				defaultNoteTypeList[(value:Int)]
			else if (value == true)
				"Alt Animation"
			else
				'';
		};
		return noteType;
	}

	public static function isNoteData(data:Array<Dynamic>):Bool
		return data != null && Std.isOfType(data[0], Float) && Std.isOfType(data[1], Int) && data[1] >= 0;
}