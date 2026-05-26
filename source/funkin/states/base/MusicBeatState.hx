package funkin.states.base;

import funkin.data.MusicData;
import flixel.math.FlxMath;
import funkin.input.Controls;
import funkin.Conductor;
import funkin.states.base.TransitionableState;
import openfl.media.Sound;
import openfl.ui.MouseCursor;
import openfl.ui.Mouse;
import haxe.io.Path;

import flixel.util.typeLimit.NextState;

#if HSCRIPT_ALLOWED
import funkin.scripts.FunkinHScript;
import funkin.states.scripting.HScriptedState;
#end

#if SCRIPTABLE_STATES
import funkin.states.scripting.HScriptOverridenState;
#end

#if SCRIPTABLE_STATES
@:autoBuild(funkin.macros.ScriptingMacro.addScriptingCallbacks([
	"create",
	"update",
	"draw",
	"destroy",
	"openSubState",
	"closeSubState",
	"stepHit",
	"beatHit",
	"sectionHit",
	"getDebugText",
]))
#end
class MusicBeatState extends TransitionableState
{
	private var curSection:Int = 0;
	private var curStep(get, set):Int;
	private var curBeat(get, set):Int;
	private var curDecStep(get, set):Float;
	private var curDecBeat(get, set):Float;

	private var updateSongPos:Bool = true;
	private var songSyncMode(default, set):SongSyncMode;
	private var controls(get, never):Controls;

	public var canBeScripted(get, default):Bool = false;

	private var sectionEndStep:Int = 0;

	//// To be defined by the scripting macro
	@:noCompletion public var _extensionScript:FunkinHScript;

	@:noCompletion public function _getScriptDefaultVars() 
		return new Map<String, Dynamic>();
	
	@:noCompletion public function _startExtensionScript(folder:String, scriptName:String) 
		return;

	////
	@:noCompletion inline function get_curStep() return Conductor.curStep;
	@:noCompletion inline function get_curBeat() return Conductor.curBeat;
	@:noCompletion inline function get_curDecStep() return Conductor.curDecStep;
	@:noCompletion inline function get_curDecBeat() return Conductor.curDecBeat;
	@:noCompletion inline function set_curStep(v) return Conductor.curStep=v;
	@:noCompletion inline function set_curBeat(v) return Conductor.curBeat=v;
	@:noCompletion inline function set_curDecStep(v) return Conductor.curDecStep=v;
	@:noCompletion inline function set_curDecBeat(v) return Conductor.curDecBeat=v;

	@:noCompletion function set_songSyncMode(v:SongSyncMode):SongSyncMode {
		return Conductor.songSyncMode = v;
	}

	@:noCompletion inline function get_controls():Controls
		return funkin.input.Controls.firstActive;

	@:noCompletion function get_canBeScripted()
		return canBeScripted;

	////
	public function new(canBeScripted:Bool = true) {
		super();
		this.canBeScripted = canBeScripted;
		this.songSyncMode = LAST_MIX;
	}

	override function create()
	{
		FlxG.autoPause = ClientPrefs.autoPause;
		super.create();
	}

	override function update(elapsed:Float)
	{
		if (updateSongPos)
			updateSongPosition();
		super.update(elapsed);
	}

	override public function destroy()
	{
		super.destroy();
		
		if (_extensionScript != null) {
			_extensionScript.stop();
			_extensionScript = null;
		}
	}

	public function stepHit():Void
	{
		//trace('Step: ' + curStep);
	}

	public function beatHit():Void
	{
		//trace('Beat: ' + curBeat);
	}

	public function sectionHit():Void
	{
		//trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
	}

	public function getDebugText():String {
		return 'curSection: ${curSection} • curBeat: ${curBeat} • curStep: ${curStep}';
	}

	override function toString():String {
		return Type.getClassName(Type.getClass(this));
	}

	private function updateSongPosition(?_:FlxSound):Void {
		Conductor.update();
		updateSteps();
	}

	private function updateSteps() {
		var oldStep:Int = Conductor.curStep;
		Conductor.updateSteps();
		var curStep:Int = Conductor.curStep;

		if (oldStep != curStep) {
			if (curStep > 0) {
				stepHit();
				if (curStep % 4 == 0)
					beatHit();
			}

			var prevSection:Int = curSection;

			if (PlayState.SONG != null) {
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}

			if (curSection > prevSection)
				sectionHit();
		}
	}

	private function updateSection():Void
	{
		if (sectionEndStep < 1)
			sectionEndStep = getStepsOnSection();
		
		while (curStep >= sectionEndStep) {
			curSection++;
			sectionEndStep += getStepsOnSection();
			_sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if (curStep < 0)
			return;

		var lastSection:Int = curSection;

		////
		curSection = 0;
		sectionEndStep = getStepsOnSection();

		while (curStep >= sectionEndStep) {
			curSection++;
			sectionEndStep += getStepsOnSection();
		}

		////
		if (curSection > lastSection)
			_sectionHit();
	}

	private function _sectionHit() {
		var sectionData = PlayState.SONG.notes[curSection];
		if (sectionData?.changeBPM)
			Conductor.changeBPM(sectionData.bpm);
	}

	function resyncTracks() {
		Conductor.resyncTracks();
	}

	inline function getStepsOnSection():Int
	{		
		var section = PlayState?.SONG.notes[curSection];
		return section==null ? 16 : Math.round(Conductor.sectionSteps(section));
	}

	////
	public static var curMusic:String = "";
	public static var menuVox:FlxSound; // jukebox

	public static function stopMenuMusic(){
		if (FlxG.sound.music != null){
			FlxG.sound.music.stop();
			FlxG.sound.music.destroy();
			FlxG.sound.music = null;
		}

		if (MusicBeatState.menuVox != null)
		{
			MusicBeatState.menuVox.stop();
			MusicBeatState.menuVox.destroy();
			MusicBeatState.menuVox = null;
		}
	}

	public static inline function isPlayingMusic(?key:String):Bool
		return (key != null && key == curMusic) && FlxG.sound.music?.playing;

	public static function playMusic(key:String, force:Bool = false) {
		if (!force && isPlayingMusic(key))
			return;
		MusicBeatState.stopMenuMusic();
		
		var md = MusicData.fromName(key);
		if (md != null) {
			FlxG.sound.music = md.play(new FlxSound());
			FlxG.sound.music.persist = true;
			FlxG.sound.music.context = MUSIC;
			FlxG.sound.defaultMusicGroup.add(FlxG.sound.music);

			Conductor.changeBPM(md.bpm);
		}else {
			FlxG.sound.playMusic(Paths.music(key));
		}

		Conductor.tracks = [FlxG.sound.music];
		Conductor.startSong(FlxG.sound.music.time);
		curMusic = key;
	}

	// TODO: check the jukebox selection n shit and play THAT instead? idk lol
	// ^ this was a TGT comment but re-adding the jukebox menu as part of freeplay would be nice I think
	public static function playMenuMusic(force:Bool = false) {
		if (!force && isPlayingMusic())
			return;

		MusicBeatState.playMusic('freakyMenu', true);
		FlxG.sound.music.looped = true;
	}

	public static function switchState(nextState:NextState)
	{
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		Mouse.cursor = MouseCursor.AUTO;

		FlxG.switchState(nextState); // just because im too lazy to goto every instance of switchState and change it to a FlxG call
	}

	public static function resetState(?skipTrans:Bool = false) {
		if (skipTrans) {
			TransitionableState.skipNextTransIn = true;
			TransitionableState.skipNextTransOut = true;
		}

		#if SCRIPTABLE_STATES
		if (FlxG.state is HScriptOverridenState) {
			var state:HScriptOverridenState = cast FlxG.state;
			FlxG.switchState(function() {
				var overriden = HScriptOverridenState.fromAnother(state);	
				if (overriden != null)
					return overriden;

				trace("State override script file is gone!", "Switching to", state.parentClass);
				return Type.createInstance(state.parentClass, []);
			});
		} else
		#end
		if (FlxG.state is HScriptedState) {
			var state:HScriptedState = cast FlxG.state;
			FlxG.switchState(function() {
				var nextState = HScriptedState.fromPath(state.scriptPath);
				if (nextState != null)
					return nextState;
				
				trace("State script file is gone!", "Switching to main menu");
				return new funkin.states.MainMenuState();
			});
		}else
			FlxG.resetState();
	}

	public static function getState():MusicBeatState
	{
		return cast FlxG.state;
	}
}
