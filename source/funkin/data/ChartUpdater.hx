package funkin.data;

import haxe.io.Path;
import funkin.data.ChartData;
import funkin.data.SongEventData;

using StringTools;

class ChartUpdater {
	public static function convertPsychV1Notes(songJson:JsonSong) {
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
			ChartData.onLoadEvents(songJson);
	
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

	public static function convertPsychEvents(psychEvents:Array<Array<Dynamic>>):Array<EventBunch> {
		var ray:Array<EventBunch> = [];

		for (eventNote in psychEvents) {
			var strumTime:Float = eventNote[0];
			var psychSubEvents:Array<Array<String>> = cast eventNote[1];

			////
			if (strumTime is Float && psychSubEvents is Array && psychSubEvents[0] is Array && psychSubEvents[0][0] is String) {
				// All's good
			}else {
				trace('Weird shit detected when converting Psych events, stopping. ($eventNote)');
				break;
			}
			
			var children:Array<EventChildData> = [];
			for (subEvent in psychSubEvents)
				children.push((subEvent:PsychSubEventData).toEventChildData()); 

			ray.push(EventBunch.fromValues(strumTime, children));
		}

		return ray;
	}

	/** Convert ancient Psych event notes, removing them from their section's notes **/
	public static function convertPsychEventNotes(sections:Array<SwagSection>, ?result:Array<EventBunch>):Array<EventBunch> {
		result ??= [];
		for (sec in sections) {
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

					result.push(EventBunch.fromValues(note[0], [subEvent]));
					notes.remove(note);
					len = notes.length;
				}
				else i++;
			}
		}
		return result;
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