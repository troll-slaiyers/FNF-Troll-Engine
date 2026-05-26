package funkin;

import funkin.data.ChartData.SwagSong;
import funkin.data.Song;
import flixel.math.FlxMath;
import flixel.util.FlxSignal;

typedef BeatInfo = { // Returned by getBeatInfo
	beat:Float,
	step:Float,
	measure:Float
}

// TODO: Turn ConductorInstance into Conductor
class Conductor {
	public static final instance:ConductorInstance = new ConductorInstance();

	public inline static final ROWS_PER_BEAT:Int = 48;

	public static var jackLimit(get, never):Float;
	@:noCompletion static function get_jackLimit():Float return instance.jackLimit;

	public static var onStepHit(get, never):FlxTypedSignal<Int->Void>;
	@:noCompletion static function get_onStepHit():FlxTypedSignal<Int->Void> return instance.onStepHit;

	public static var onBeatHit(get, never):FlxTypedSignal<Int->Void>;
	@:noCompletion static function get_onBeatHit():FlxTypedSignal<Int->Void> return instance.onBeatHit;

	public static var onMeasureHit(get, never):FlxTypedSignal<Int->Void>;
	@:noCompletion static function get_onMeasureHit():FlxTypedSignal<Int->Void> return instance.onMeasureHit;

	public static var timeSegments(get, set):Array<TimeSegment>;
	@:noCompletion static function get_timeSegments():Array<TimeSegment> return instance.timeSegments;
	@:noCompletion static function set_timeSegments(v):Array<TimeSegment> return instance.timeSegments = v;

	public static var time(get, set):Float;
	@:noCompletion static function get_time():Float return instance.time;
	@:noCompletion static function set_time(v):Float return instance.time = v;

	public static var roundedStep(get, never):Int;
	@:noCompletion static function get_roundedStep():Int return instance.roundedStep;

	public static var roundedBeat(get, never):Int;
	@:noCompletion static function get_roundedBeat():Int return instance.roundedBeat;

	public static var roundedMeasure(get, never):Int;
	@:noCompletion static function get_roundedMeasure():Int return instance.roundedMeasure;

	public static var beat(get, never):Float;
	@:noCompletion static function get_beat():Float return instance.beat;

	public static var step(get, never):Float;
	@:noCompletion static function get_step():Float return instance.step;

	public static var measure(get, never):Float;
	@:noCompletion static function get_measure():Float return instance.measure;

	public static var bpm(get, never):Float;
	@:noCompletion static function get_bpm():Float return instance.bpm;

	public static var beatLength(get, never):Float;
	@:noCompletion static function get_beatLength():Float return instance.beatLength;

	public static var stepLength(get, never):Float;
	@:noCompletion static function get_stepLength():Float return instance.stepLength;

	public static var beatLengthSecs(get, never):Float;
	@:noCompletion static function get_beatLengthSecs():Float return instance.beatLengthSecs;

	public static var stepLengthSecs(get, never):Float;
	@:noCompletion static function get_stepLengthSecs():Float return instance.stepLengthSecs;

	public static var songOffset(get, set):Float;
	@:noCompletion static function get_songOffset():Float return instance.songOffset;
	@:noCompletion static function set_songOffset(v):Float return instance.songOffset = v;

	public static var songSyncMode(get, set):SongSyncMode;
	@:noCompletion static function get_songSyncMode():SongSyncMode return instance.songSyncMode;
	@:noCompletion static function set_songSyncMode(v):SongSyncMode return instance.songSyncMode = v;

	public static var tracks(get, set):Array<FlxSound>;
	@:noCompletion static function get_tracks():Array<FlxSound> return instance.tracks;
	@:noCompletion static function set_tracks(v):Array<FlxSound> return instance.tracks = v;

	public static var pitch(get, set):Float;
	@:noCompletion static function get_pitch():Float return instance.pitch;
	@:noCompletion static function set_pitch(v):Float return instance.pitch = v;

	public static var visualPosition(get, set):Float;
	@:noCompletion static function get_visualPosition():Float return instance.visualPosition;
	@:noCompletion static function set_visualPosition(v):Float return instance.visualPosition = v;

	public static var playing(get, never):Bool;
	@:noCompletion static function get_playing():Bool return instance.playing;

	public static inline function startSong(offset:Float = 0) return instance.startSong(offset);

	public static inline function resyncTracks() return instance.resyncTracks();

	public static inline function pauseSong() return instance.pauseSong();

	public static inline function resumeSong() return instance.resumeSong();

	public static inline function changePitch(pitch:Float) return instance.changePitch(pitch);

	public static inline function getAccPosition():Float return instance.getAccPosition();

	public static inline function reset() return instance.reset();

	public static inline function getSegmentFromTime(time:Float):TimeSegment return instance.getSegmentFromTime(time);

	public static inline function getSegmentFromBeat(beat:Float):TimeSegment return instance.getSegmentFromBeat(beat);

	public static inline function getTimeFromStep(step:Float):Float return instance.getTimeFromStep(step);

	public static inline function getTimeFromBeat(beat:Float):Float return instance.getTimeFromBeat(beat);

	public static inline function getBeatInfoFromTime(time:Float, ?offset:Float = 0, ?segment: TimeSegment, ?existingInfo:BeatInfo):BeatInfo return instance.getBeatInfoFromTime(time, offset, segment, existingInfo);

	public static inline function updateSteps() return instance.updateSteps();

	public static inline function update() return instance.update();

	public static inline function updateTime(time:Float) return instance.updateTime(time);

	public static inline function finalizeTimeSegments() return instance.finalizeTimeSegments();

	public static inline function changeBPM(bpm: Float) return instance.changeBPM(bpm);

	public static inline function mapTimeSegments(song: SwagSong) return instance.mapTimeSegments(song);

	#if ALLOW_DEPRECATION
	@:deprecated("Use beatLength")
	public static var crochet(get, null):Float;

	@:noCompletion inline static function get_crochet()
		return beatLength;

	@:deprecated("Use stepLength")
	public static var stepCrochet(get, null):Float;

	@:noCompletion inline static function get_stepCrochet()
		return stepLength;

	@:deprecated("Use beatLength")
	public static var crotchet(get, null):Float;

	@:noCompletion inline static function get_crotchet()
		return beatLength;

	@:deprecated("Use stepLength")
	public static var stepCrotchet(get, null):Float;

	@:noCompletion inline static function get_stepCrotchet()
		return stepLength;

	@:deprecated("Use beatInfo.step or step")
	public static var curDecStep(get, null):Float;

	@:noCompletion inline static function get_curDecStep()
		return step;

	@:deprecated("Use beatInfo.beat or beat")
	public static var curDecBeat(get, null):Float;

	@:noCompletion inline static function get_curDecBeat()
		return beat;

	@:deprecated("Use Math.floor(beatInfo.beat) or roundedBeat")
	public static var curBeat(get, null):Int;

	@:noCompletion inline static function get_curBeat()
		return roundedBeat;

	@:deprecated("Use Math.floor(beatInfo.step) or roundedStep")
	public static var curStep(get, null):Int;

	@:noCompletion inline static function get_curStep()
		return roundedStep;

	@:deprecated("Use time")
	public static var songPosition(get, set):Float;

	@:noCompletion inline static function get_songPosition()
		return time;

	@:noCompletion inline static function set_songPosition(value: Float)
		return time = value;

	@:deprecated("Use reset()")
	@:noCompletion public static inline function cleanup() return instance.reset();
	#end
}

class ConductorInstance {
	// These should be moved away -Neb
	private inline static final _internalJackLimit:Float = 192 / 16;
	@:isVar public var jackLimit(get, null):Float;

	@:deprecated("You shouid be getting the TimeSegment and calculating this yourself!")
	@:noCompletion function get_jackLimit()
		return currentSegment.stepLength / _internalJackLimit;

	public var onStepHit:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();
	public var onBeatHit:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();
	public var onMeasureHit:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();

	public var timeSegments(default, set):Array<TimeSegment>;

	@:noCompletion inline function set_timeSegments(value:Array<TimeSegment>) {
		if (value.length == 0)
			value = [new TimeSegment(0, 100)];
		else
			value.sort((a, b) -> return Std.int(a.time - b.time));
		
		currentSegment = value[0];

		return timeSegments = value;
	}

	var beatInfo:BeatInfo = {beat: 0, step: 0, measure: 0};
	var currentSegment:TimeSegment;

	public function new() {
		timeSegments = [];
	}

	public var time:Float = 0;

	public var roundedStep:Int = 0;
	public var roundedBeat:Int = 0;
	public var roundedMeasure:Int = 0;

	public var beat(get, never):Float;
	public var step(get, never):Float;
	public var measure(get, never):Float;

	public var bpm(get, never):Float;

	public var beatLength(get, never):Float;
	public var stepLength(get, never):Float;

	public var beatLengthSecs(get, never):Float;
	public var stepLengthSecs(get, never):Float;

	public var songOffset:Float = 0; // TODO: Implement

	public var songSyncMode:SongSyncMode = LAST_MIX;
	
	public var tracks:Array<FlxSound> = [];
	public var pitch:Float = 1.0;

	public var visualPosition:Float = 0;

	/** Whether the song is currently playing. Use startSong and pauseSong to change this **/
	public var playing(default, null):Bool = false;

	/** real time at which the song started playing **/
	private var songStartTimestamp:Float = 0;

	/** elapsed playback time before the song was paused **/
	private var songStartOffset:Float = 0;

	/** Last inst.time value **/
	private var lastMixPos:Float = 0;
	/** Time passed since inst.time changed **/
	private var lastMixTimer:Float = 0;

	public function startSong(offset:Float = 0) {
		songStartTimestamp = Main.getTime();
		songStartOffset = offset;
		playing = true;
		time = offset;

		resyncTracks();
	}

	public function resyncTracks() {
		this.time = getAccPosition();

		for (snd in tracks) {
			snd.pause();
			snd.pitch = pitch;
			snd.play(true, Conductor.songPosition);
		}

		lastMixPos = this.time;
	}

	public function pauseSong() {
		if (!this.playing)
			return;

		this.time = getAccPosition();
		this.playing = false;

		for (snd in tracks) {
			snd.stop();
		}
	}

	public function resumeSong() {
		if (this.playing)
			return;

		startSong(this.time);
	}

	public function changePitch(pitch:Float) {
		var wasPlaying:Bool = this.playing;
		this.pauseSong();

		this.pitch = pitch;
		for (track in tracks)
			track.pitch = pitch;

		if (wasPlaying)
			this.resumeSong();
	}

	public function getAccPosition():Float {
		return (!playing) ? time : switch (songSyncMode) {
			case DIRECT:
				@:privateAccess
				tracks[0]._channel.position;
			case SYSTEM_TIME:
				songStartOffset + (Main.getTime() - songStartTimestamp) * pitch;
			default:
				time;
		}
	}

	public function reset() {
		for (snd in tracks)
			snd.stop();

		this.songStartTimestamp = 0;
		this.songStartOffset = 0;

		time = 0;
		playing = false;
		pitch = 1.0;
		timeSegments = [];
		tracks = [];
	}


	// If we need speed we can binary search! But for now who gaf
	// This *should* be sorted
	public function getSegmentFromTime(time:Float):TimeSegment {
		var seg:TimeSegment = timeSegments[0];

		for (segment in timeSegments) {
			if (segment.time <= time)
				seg = segment;
			else if (segment.time > time)
				break;
		}

		return seg;
	}

	public function getSegmentFromBeat(beat:Float):TimeSegment {
		var seg:TimeSegment = timeSegments[0];

		for (segment in timeSegments) {
			if (segment.startBeat <= beat)
				seg = segment;
			else if (segment.startBeat > beat)
				return seg;
		}

		return seg;
	}

	public function getTimeFromStep(step:Float):Float {
		if (timeSegments.length == 0)
			return 0;
		
		if (timeSegments.length == 1)
			return step * timeSegments[0].stepLength;

		var seg:TimeSegment = timeSegments[0];
		for (segment in timeSegments) {
			if (segment.startStep <= step)
				seg = segment;
			else if (segment.startStep > step)
				break;
		}
		return seg.time + (step - seg.startStep) * seg.stepLength;
	}

	public function getTimeFromBeat(beat:Float):Float {
		if (timeSegments.length == 0)
			return 0;

		if (timeSegments.length == 1)
			return beat * timeSegments[0].beatLength;

		var seg:TimeSegment = timeSegments[0];
		for (segment in timeSegments) {
			if (segment.startBeat <= beat)
				seg = segment;
			else if (segment.startBeat > beat)
				break;
		}

		return seg.time + (beat - seg.startBeat) * seg.beatLength;
	}


	public function getBeatInfoFromTime(time:Float, ?offset:Float = 0, ?segment: TimeSegment, ?existingInfo:BeatInfo):BeatInfo {
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


	// MAYBE: Merge this with updateTime, and change all changes to time to use updateTime
	public function updateSteps(){
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

	public function update() {
		if (!playing) {
			return;
		}

		var inst = tracks[0];
		if (inst == null) {
			return;
		}

		@:privateAccess
		var elapsedMS:Float = FlxG.game._elapsedMS * inst.pitch;

		switch (songSyncMode)
		{
			case DIRECT:
				// Ludem Dare sync
				// Jittery and retarded, but works maybe
				this.time = inst.time;

			case SYSTEM_TIME:
				this.time = this.getAccPosition();
			
			case LAST_MIX:
				// Stepmania method
				// Works for most people it seems??
				if (lastMixPos != inst.time) {
					lastMixPos = inst.time;
					lastMixTimer = 0;
				}else {
					lastMixTimer += elapsedMS;
				}
				
				this.time = lastMixPos + lastMixTimer;

			case NEVER2X:
				// It is basically just `songPos += elapsed` until it goes off sync
				// However that allegedly works better than Last Mix at high framerates
				if (lastMixPos != inst.time) {
					if (Math.abs(inst.time - this.time) >= elapsedMS)
						this.time = inst.time;
					else
						this.time += elapsedMS;

					lastMixPos = inst.time;
				}else {
					this.time += elapsedMS;
				}
		}
	}

	public function updateTime(time:Float) {
		this.time = time;
	
		updateSteps();
	}


	public function finalizeTimeSegments() {
		for (i in 1...timeSegments.length) {
			var segment:TimeSegment = timeSegments[i];
			var lastSegment:TimeSegment = timeSegments[i - 1];

			segment.startStep = lastSegment.getStep(segment.time);
			segment.startBeat = lastSegment.getBeat(segment.time);
			segment.startMeasure = lastSegment.getMeasure(segment.time);
		}
	}

	@:deprecated("Use timeSegments to set up BPM changes")
	public function changeBPM(bpm: Float){
		timeSegments = [new TimeSegment(0, bpm)];
	}
	
	public function mapTimeSegments(song: SwagSong) {
		timeSegments = [new TimeSegment(0, song.bpm)];

		var time: Float = 0;
		for(kirkingVictim in song.notes){ // get it because TREY'RE GONNA DIE SOON
			var sectionLength: Float = kirkingVictim.sectionBeats ?? 4.0;
			var segment = new TimeSegment(
				time,
				kirkingVictim.changeBPM ? kirkingVictim.bpm : timeSegments[timeSegments.length - 1].bpm
			);

			if (kirkingVictim.changeBPM) 
				timeSegments.push(segment);
			
			time += segment.beatLength * sectionLength;
		}

		finalizeTimeSegments();

		print('new BPM map BUDDY [');
		for (seg in timeSegments)
			print('\t$seg');
		print(']');
	}

	////
	@:noCompletion inline function get_beat()
		return beatInfo.beat;		

	@:noCompletion inline function get_step()
		return beatInfo.step;		

	@:noCompletion inline function get_measure()
		return beatInfo.measure;	

	@:noCompletion inline function get_bpm()
		return currentSegment.bpm;

	@:noCompletion inline function get_beatLength()
		return currentSegment.beatLength;
	
	@:noCompletion inline function get_stepLength()
		return currentSegment.stepLength;
	
	@:noCompletion inline function get_beatLengthSecs()
		return currentSegment.beatLengthSecs;
	
	@:noCompletion inline function get_stepLengthSecs()
		return currentSegment.stepLengthSecs;
}

// I hate time signatures it turns out

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

	public var beatLength:Float;
	public var stepLength:Float;
	public var measureLength:Float;

	public var beatLengthSecs:Float;
	public var stepLengthSecs:Float;

	public function new(time:Float, bpm:Float, measureNotes:Float = 4, notation:Float = 4) {
		this.time = time;
		this.bpm = bpm;
		this.measureNotes = measureNotes;
		this.notation = notation;

		this.beatLengthSecs = (60 / bpm) * (4 / notation);
		this.stepLengthSecs = (60 / bpm) / 4;

		this.beatLength = beatLengthSecs * 1000;
		this.stepLength = stepLengthSecs * 1000;
		this.measureLength = beatLength * measureNotes;
	}

	public function getBeat(at:Float) {
		return startBeat + (at - time) / beatLength;
	}

	public function getStep(at:Float) {
		return startStep + (at - time) / stepLength;
	}

	public function getMeasure(at:Float) {
		return startMeasure + (at - time) / measureLength;
	}

	public function toString() {
		return 'Time: $time | BPM: $bpm | Time Sig: $measureNotes/$notation | Start Beat: $startBeat | Start Measure: $startMeasure | Start Step: $startStep';
	}
}

enum abstract SongSyncMode(String) to String {
	var DIRECT = "Direct";
	var LAST_MIX = "Last Mix";
	var NEVER2X = "Never2x";
	var SYSTEM_TIME = "System Time";
	
	public static function fromString(str:String):SongSyncMode {
		return switch (str) {
			case "Direct": DIRECT;
			case "System Time": SYSTEM_TIME;
			case "Last Mix": LAST_MIX;
			case "Never2x": NEVER2X;
			default: LAST_MIX;
		}
	} 
}