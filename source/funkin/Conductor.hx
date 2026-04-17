package funkin;

import funkin.data.ChartData.SwagSong;
import funkin.data.Song;
import flixel.math.FlxMath;
import flixel.util.FlxSignal;

// I hate time signatures it turns out

@:structInit
class TimeSegment {
	public var time:Float = 0;
	public var bpm:Float = 60;

	public var startBeat:Float = 0;
	public var startStep:Float = 0;
	public var startMeasure:Float = 0;

	// Time signatures are expressed as measureNotes / notation
	// A measure should have measureNotes notations (i.e 3/8 means each measure is 3 8ths)
	// Notation is effectively speed then
	public var measureNotes:Float = 4;
	public var notation:Float = 4;

	public function getBeatLength() {
		return ((60 / bpm) * (4 / notation)) * 1000;
	}

	public function getStepLength() {
		return ((60 / bpm) / 4) * 1000;
	}

	public function getMeasureLength() {
		return getBeatLength() * measureNotes;
	}

	public function getBeat(at:Float) {
		return startBeat + (at - time) / getBeatLength();
	}

	public function getStep(at:Float) {
		return startStep + (at - time) / getStepLength();
	}

	public function getMeasure(at:Float) {
		return startMeasure + (at - time) / getMeasureLength();
	}

	public function toString() {
		return 'Time: $time | BPM: $bpm | Time Sig: $measureNotes/$notation | Start Beat: $startBeat | Start Measure: $startMeasure | Start Step: $startStep';
	}
}

typedef BeatInfo = { // Returned by getBeatInfo
	beat:Float,
	step:Float,
	measure:Float
}

// TODO: The Great Member
class Conductor {
	// These should be moved away -Neb
	private inline static final _internalJackLimit:Float = 192 / 16;
	@:isVar public static var jackLimit(get, null):Float;

	@:deprecated("You shouid be getting the TimeSegment and calculating this yourself!")
	@:noCompletion static function get_jackLimit()
		return currentSegment.getStepLength() / _internalJackLimit;

	
	public inline static final ROWS_PER_BEAT:Int = 48;

	public static var onStepHit:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();
	public static var onBeatHit:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();
	public static var onMeasureHit:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();

	public static var timeSegments(default, set):Array<TimeSegment> = [];

	@:noCompletion inline static function set_timeSegments(value:Array<TimeSegment>) {
		value.sort((a, b) -> return Std.int(a.time - b.time));
		if(value.length == 0)value = [{}];
		currentSegment = value[0] ?? {};

		return timeSegments = value;
	}

	static var beatInfo:BeatInfo = {beat: 0, step: 0, measure: 0};
	static var currentSegment: TimeSegment = {};

	public static var time:Float = 0;

	public static var roundedStep:Int = 0;
	public static var roundedBeat:Int = 0;
	public static var roundedMeasure:Int = 0;

	public static var beat(get, never):Float;
	public static var step(get, never):Float;
	public static var measure(get, never):Float;

	public static var bpm(get, never):Float;

	public static var beatLength(get, never):Float;
	public static var stepLength(get, never):Float;

	public static var beatLengthSecs(get, never):Float;
	public static var stepLengthSecs(get, never):Float;

	public static var songOffset:Float = 0; // TODO: Implement

	public static var songSyncMode:SongSyncMode = LAST_MIX;
	
	public static var tracks:Array<FlxSound> = [];
	public static var pitch:Float = 1.0;

	public static var visualPosition:Float = 0;

	/** Whether the song is currently playing. Use startSong and pauseSong to change this **/
	public static var playing(default, null):Bool = false;

	/** real time at which the song started playing **/
	private static var songStartTimestamp:Float = 0;

	/** elapsed playback time before the song was paused **/
	private static var songStartOffset:Float = 0;

	public static function startSong(offset:Float = 0) {
		songStartTimestamp = Main.getTime();
		songStartOffset = offset;
		playing = true;
		time = offset;

		resyncTracks();
	}

	public static function resyncTracks() {
		Conductor.time = getAccPosition();
		for (snd in tracks) {
			snd.stop();
			snd.pitch = pitch;
			snd.play(true, getAccPosition());
		}

		lastMixPos = Conductor.time;
	}

	public static function pauseSong() {
		if (!Conductor.playing)
			return;

		Conductor.time = getAccPosition();
		Conductor.playing = false;

		for (snd in tracks) {
			snd.stop();
		}
	}

	public static function resumeSong() {
		if (Conductor.playing)
			return;

		startSong(Conductor.time);
	}

	public static function changePitch(pitch:Float) {
		var wasPlaying:Bool = Conductor.playing;
		Conductor.pauseSong();

		Conductor.pitch = pitch;
		for (track in tracks)
			track.pitch = pitch;

		if (wasPlaying)
			Conductor.resumeSong();
	}

	public static function getAccPosition():Float {
		return (!playing) ? time : switch (songSyncMode) {
			case DIRECT:
				tracks[0].time;
			case SYSTEM_TIME:
				songStartOffset + (Main.getTime() - songStartTimestamp) * pitch;
			default:
				time;
		}
	}

	public static function cleanup() {
		for (snd in tracks)
			snd.stop();

		Conductor.songStartTimestamp = 0;
		Conductor.songStartOffset = 0;

		time = 0;
		playing = false;
		pitch = 1.0;
		timeSegments = [];
		tracks = [];
	}


	// If we need speed we can binary search! But for now who gaf
	// This *should* be sorted
	public static function getSegmentFromTime(time:Float):TimeSegment {
		if (timeSegments.length == 0)
			return {};
		if (timeSegments.length == 1)
			return timeSegments[0];

		var seg:TimeSegment = timeSegments[0];
		for (segment in timeSegments) {
			if (segment.time <= time)
				seg = segment;
			else if (segment.time > time)
				return seg;
		}

		return seg;
	}

	public static function getSegmentFromBeat(beat:Float):TimeSegment {
		if (timeSegments.length == 0)
			return {};
		if (timeSegments.length == 1)
			return timeSegments[0];

		var seg:TimeSegment = timeSegments[0];
		for (segment in timeSegments) {
			if (segment.startBeat <= beat)
				seg = segment;
			else if (segment.startBeat > beat)
				return seg;
		}

		return seg;
	}

	public static function getTimeFromStep(step:Float): Float {
		if (timeSegments.length == 0)
			return 0;
		
		if (timeSegments.length == 1)
			return step * timeSegments[0].getStepLength();

		var seg:TimeSegment = timeSegments[0];
		for (segment in timeSegments) {
			if (segment.startStep <= step)
				seg = segment;
			else if (segment.startStep > step)
				break;
		}
		return seg.time + (step - seg.startStep) * seg.getStepLength();
	}

	public static function getTimeFromBeat(beat:Float):Float {
		if (timeSegments.length == 0)
			return 0;

		if (timeSegments.length == 1)
			return beat * timeSegments[0].getBeatLength();

		var seg:TimeSegment = timeSegments[0];
		for (segment in timeSegments) {
			if (segment.startBeat <= beat)
				seg = segment;
			else if (segment.startBeat > beat)
				break;
		}

		return seg.time + (beat - seg.startBeat) * seg.getBeatLength();
	}


	public static function getBeatInfoFromTime(time:Float, ?offset:Float = 0, ?segment: TimeSegment, ?existingInfo:BeatInfo):BeatInfo {
		var seg:TimeSegment = segment == null ? getSegmentFromTime(time) : segment;
		var info:BeatInfo = existingInfo != null ? existingInfo : {
			beat: 0,
			measure: 0,
			step: 0
		}
		
		var offsettedTime:Float = time - offset;

		info.beat = seg.getBeat(offsettedTime);
		info.measure = seg.getMeasure(offsettedTime);
		info.step = seg.getStep(offsettedTime);

		return info;
	}


	// MAYBE: Merge this with updateTime, and change all changes to Conductor.time to use updateTime
	public static function updateSteps(){
		currentSegment = getSegmentFromTime(time);
		
		beatInfo = getBeatInfoFromTime(time, ClientPrefs.noteOffset, currentSegment, beatInfo);

		if (Math.floor(beatInfo.measure) != roundedMeasure) {
			onMeasureHit.dispatch(roundedMeasure);
			roundedMeasure = Math.floor(beatInfo.measure);
		}

		if (Math.floor(beatInfo.beat) != roundedBeat) {
			onBeatHit.dispatch(roundedBeat);
			roundedBeat = Math.floor(beatInfo.beat);
		}

		if (Math.floor(beatInfo.step) != roundedStep) {
			onStepHit.dispatch(roundedStep);
			roundedStep = Math.floor(beatInfo.step);
		} 
	}

	private static var lastMixTimer:Float = 0;
	private static var lastMixPos:Float = 0;

	public static function update() {
		if (!playing) {
			trace("Conductor is not active");
			return;
		}

		var inst = tracks[0];
		if (inst == null) {
			trace("No tracks to sync :(");
			return;
		}

		@:privateAccess
		var elapsedMS:Float = FlxG.game._elapsedMS * inst.pitch;

		switch (songSyncMode)
		{
			case DIRECT:
				// Ludem Dare sync
				// Jittery and retarded, but works maybe
				Conductor.time = inst.time;

			case LEGACY:
				// Resync Vocals
				// FUCKING SUCKS DONT USE LMFAO! It's here just incase though
				Conductor.time += elapsedMS;
				
			case PSYCH_1_0:
				// Psych 1.0 method
				Conductor.time += elapsedMS;
				Conductor.time = FlxMath.lerp(inst.time, Conductor.time, Math.exp(-elapsedMS * 0.005));
				var timeDiff:Float = Math.abs(inst.time - Conductor.time);
				if (timeDiff > 1000)
					Conductor.time = Conductor.time + 1000 * FlxMath.signOf(timeDiff);

			case SYSTEM_TIME:
				Conductor.time = Conductor.getAccPosition();
			
			case LAST_MIX:
				// Stepmania method
				// Works for most people it seems??
				if (lastMixPos != inst.time) {
					lastMixPos = inst.time;
					lastMixTimer = 0;
				}else {
					lastMixTimer += elapsedMS;
				}
				
				Conductor.time = lastMixPos + lastMixTimer;

		}
	}

	public static function updateTime(time:Float) {
		Conductor.time = time;
	
		updateSteps();
	}


	public static function finalizeTimeSegments() {
		for (i in 1...timeSegments.length) {
			var segment:TimeSegment = timeSegments[i];
			var lastSegment:TimeSegment = timeSegments[i - 1];

			segment.startStep = lastSegment.getStep(segment.time);
			segment.startBeat = lastSegment.getBeat(segment.time);
			segment.startMeasure = lastSegment.getMeasure(segment.time);
		}
	}

	@:deprecated("Use Conductor.timeSegments to set up BPM changes")
	public static function changeBPM(bpm: Float){
		timeSegments = [{
			time: 0,
			bpm: bpm
		}];
	}
	
	public static function mapTimeSegments(song: SwagSong) {
		timeSegments = [{bpm: song.bpm}];

		var time: Float = 0;
		for(kirkingVictim in song.notes){ // get it because TREY'RE GONNA DIE SOON
			var sectionLength: Float = kirkingVictim.sectionBeats ?? 4.0;
			var segment:TimeSegment = {
				time: time,
				bpm: kirkingVictim.changeBPM ? kirkingVictim.bpm : timeSegments[timeSegments.length - 1].bpm
			}

			if (kirkingVictim.changeBPM) 
				timeSegments.push(segment);
			
			time += segment.getBeatLength() * sectionLength;
		}

		finalizeTimeSegments();
	}

	////
	@:noCompletion inline static function get_beat()
		return beatInfo.beat;		

	@:noCompletion inline static function get_step()
		return beatInfo.step;		

	@:noCompletion inline static function get_measure()
		return beatInfo.measure;	

	@:noCompletion inline static function get_bpm()
		return currentSegment.bpm;

	@:noCompletion inline static function get_beatLength()
		return currentSegment.getBeatLength();
	
	@:noCompletion inline static function get_stepLength()
		return currentSegment.getStepLength();
	
	@:noCompletion inline static function get_beatLengthSecs()
		return currentSegment.getBeatLength() * 0.001;
	
	@:noCompletion inline static function get_stepLengthSecs()
		return currentSegment.getStepLength() * 0.001;

	#if ALLOW_DEPRECATION
	@:deprecated("Use Conductor.beatLength")
	public static var crochet(get, null):Float;

	@:noCompletion inline static function get_crochet()
		return currentSegment.getBeatLength();

	@:deprecated("Use Conductor.stepLength")
	public static var stepCrochet(get, null):Float;

	@:noCompletion inline static function get_stepCrochet()
		return currentSegment.getStepLength();

	@:deprecated("Use Conductor.beatLength")
	public static var crotchet(get, null):Float;

	@:noCompletion inline static function get_crotchet()
		return currentSegment.getBeatLength();

	@:deprecated("Use Conductor.stepLength")
	public static var stepCrotchet(get, null):Float;

	@:noCompletion inline static function get_stepCrotchet()
		return currentSegment.getStepLength();

	@:deprecated("Use Conductor.beatInfo.step or Conductor.step")
	public static var curDecStep(get, null):Float;

	@:noCompletion inline static function get_curDecStep()
		return beatInfo.step;

	@:deprecated("Use Conductor.beatInfo.beat or Conductor.beat")
	public static var curDecBeat(get, null):Float;

	@:noCompletion inline static function get_curDecBeat()
		return beatInfo.beat;

	@:deprecated("Use Math.floor(Conductor.beatInfo.beat) or Conductor.roundedBeat")
	public static var curBeat(get, null):Int;

	@:noCompletion inline static function get_curBeat()
		return roundedBeat;

	@:deprecated("Use Math.floor(Conductor.beatInfo.step) or Conductor.roundedStep")
	public static var curStep(get, null):Int;

	@:noCompletion inline static function get_curStep()
		return roundedStep;

	@:deprecated("Use Conductor.time")
	public static var songPosition(get, set):Float;

	@:noCompletion inline static function get_songPosition()
		return time;

	@:noCompletion inline static function set_songPosition(value: Float)
		return time = value;
	#end
}

enum abstract SongSyncMode(String) to String {
	var DIRECT = "Direct";
	var LEGACY = "Legacy";
	var PSYCH_1_0 = "Psych 1.0";
	var LAST_MIX = "Last Mix";
	var SYSTEM_TIME = "System Time";
	
	public static function fromString(str:String):SongSyncMode {
		return switch (str) {
			case "Direct": DIRECT;
			case "Legacy": LEGACY;
			case "Psych 1.0": PSYCH_1_0;
			case "System Time": SYSTEM_TIME;
			//case "Last Mix": LAST_MIX;
			default: LAST_MIX;
		}
	} 
}