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
			var stepCrotchet:Float = Conductor.calculateStepCrochet(songJson.bpm);
			var keyCount:Int = songJson.keyCount ?? 4;
			for (section in songJson.notes){
				if (section.changeBPM)
					stepCrotchet = Conductor.calculateStepCrochet(section.bpm);

				for (note in section.sectionNotes){
					var note:Array<Dynamic> = cast note;
					note[1] = (section.mustHitSection ? note[1] : (note[1] + keyCount)) % (keyCount * 2);
					note[2] -= stepCrotchet;
					note[2] = note[2] > 0 ? note[2] : 0;
				}
			}
			songJson._path = filePath;
			return updateLegacyJson(songJson);
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
				return updateChart(cast updateLegacyJson(songJson));
			case LEGACY_V1:
				trace("Converting from LEGACY_V1");
				songJson.events = SongEventData.convertPsychEvents(cast songJson.events);
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
		
	public static function updateLegacyJson(songJson:JsonSong):JsonSong {
		////
		songJson.stage ??= 'stage';
		/*
		songJson.player1 ??= "bf";
		songJson.player2 ??= "dad";
		songJson.gfVersion ??= songJson.player3 ?? "gf";
		*/

		// If gfVersion isn't set on the json file, use player3 or default to gf
		songJson.gfVersion = !Reflect.hasField(songJson, 'gfVersion') ? (songJson.player3 ?? "gf") : songJson.gfVersion;
		
		if (songJson.arrowSkin == null || songJson.arrowSkin.trim().length == 0)
			songJson.arrowSkin = "NOTE_assets";

		if (songJson.splashSkin == null || songJson.splashSkin.trim().length == 0)
			songJson.splashSkin = "noteSplashes";

		songJson.hudSkin ??= 'default';

		songJson.offset ??= 0.0;
		songJson.keyCount ??= switch(songJson.mania) {
			case 3: 9;
			case 2: 7;
			case 1: 6;
			default: 4;
		}

		if (songJson.notes == null || songJson.notes.length == 0) {		
			//// must have at least one section
			songJson.notes = [{
				sectionNotes: [],
				typeOfSection: 0,
				mustHitSection: true,
				gfSection: false,
				bpm: 0,
				changeBPM: false,
				altAnim: false,
				sectionBeats: 4
			}];
			
		}else {
			onLoadEvents(songJson);
	
		////
		var keyCount:Int = songJson.keyCount ?? 4;
		for (section in songJson.notes) {
			if (null == Reflect.field(section, "sectionBeats"))
				section.sectionBeats = 4;
			
			for (note in section.sectionNotes) {
					var note:Array<Dynamic> = cast note;
					note[1] = (section.mustHitSection ? note[1] : (note[1] + keyCount)) % (keyCount * 2);
					note[3] = NoteData.resolveNoteType(note[3]);
				}
			}
		}		
		
		//// new tracks system
		if (songJson.tracks == null) {
			songJson.tracks = makeTrackData(songJson);
			trace(songJson.tracks);
		}

		songJson.trollEngine = LEGACY_V2;

		return songJson;
	}

	public static function onLoadEvents(songJson:JsonEvents, checkPsych:Bool = true) {
		if (songJson.events == null){
			songJson.events = [];
		}else {
			SongEventData.convertPsychEvents(cast songJson.events);
		}

		//// convert ancient psych event notes
		if (checkPsych && (cast songJson:JsonSong).notes != null) {
			for (sec in (cast songJson:JsonSong).notes) {
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				var i:Int = 0;
				while(i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if (note[1] < 0)
					{
						var subEvent:EventChildData = {eventId: note[2]};
						subEvent.setValue('value1', note[3]);
						subEvent.setValue('value2', note[4]);

						songJson.events.push(EventBunch.fromValues(note[0], [subEvent]));
						notes.remove(note);
						len = notes.length;
					}
					else i++;
				}
			}
		}	

		return songJson;
	}

	public static function getEventNotes(rawEventsData:Array<EventBunch>, ?resultArray:Array<EventInstanceData>):Array<EventInstanceData>
	{
		if (resultArray==null) resultArray = [];
		
		var eventsData:Array<EventBunch> = [];
		
		for (event in rawEventsData) {
			// TODO: Probably just add a button in the chart editor to consolidate events, instead of automatically doing it
			// As automatically doing this breaks some charts vv

/* 			var last = eventsData[eventsData.length-1];
			
			if (last != null && Math.abs(last[0] - event[0]) <= Conductor.jackLimit){
				var fuck:Array<Array<Dynamic>> = event[1];
				for (shit in fuck) eventsData[eventsData.length - 1][1].push(shit);
			}else */
				eventsData.push(event);
		}

		for (event in eventsData) //Event Notes
		{
			for (event in event.getEvents()) {
				event.strumTime += ClientPrefs.noteOffset;
				resultArray.push(event);
			}
		}

		return resultArray;
	}

	public static function makeTrackData(songJson:JsonSong):SongTracks {
		var instTracks:Array<String> = ["Inst"];
		if (songJson.extraTracks != null) {
			for (name in songJson.extraTracks)
				instTracks.push(name);
		}

		if (songJson.needsVoices == false) {
			// Song doesn't play vocals
			return {inst: instTracks, player: [], opponent: []};
		}
		else if (songJson._path == null) {
			// Default
			return {inst: instTracks, player: ["Voices-Player"], opponent: ["Voices-Opponent"]};
		}
		else {
			var folderPath:String = new Path(songJson._path).dir;
			inline function check(name:String):Null<String> // returns name if it exists, and null if not
				return Paths.exists(Path.join([folderPath, name + "." + Paths.SOUND_EXT])) ? name : null;

			inline function getVariantless(str):String
				return str.split('-')[0];

			var playerTrack:String = check('Voices-' + songJson.player1) ?? check('Voices-' + getVariantless(songJson.player1)) ?? check("Voices-Player") ?? 'Voices';
			var opponentTrack:String =  check('Voices-' + songJson.player2) ?? check('Voices-' + getVariantless(songJson.player2)) ?? check("Voices-Opponent") ?? 'Voices';			
			return {inst: instTracks, player: [playerTrack], opponent: [opponentTrack]};
		}
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

abstract PsychSubEventData(Array<String>) from Array<String> to Array<String>
{
	inline function new(data:Array<String>)
		this = data;

	public var eventName(get, set):String;
	public var value1(get, set):String;
	public var value2(get, set):String;

	inline function get_eventName() return this[0];
	inline function set_eventName(value:String) return this[0] = value;

	inline function get_value1() return this[1];
	inline function set_value1(value:String) return this[1] = value;

	inline function get_value2() return this[2];
	inline function set_value2(value:String) return this[2] = value;

	inline public function clone():PsychSubEventData
		return this.copy();

	inline public function toEventChildData():EventChildData
	{
		var cd:EventChildData = {eventId: eventName};
		cd.setValue('value1', value1);
		cd.setValue('value2', value2);
		return cd;
	}
}