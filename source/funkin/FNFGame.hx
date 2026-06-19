package funkin;

import funkin.scripts.Globals;
import funkin.states.base.MusicBeatState;

import funkin.states.base.TransitionableState;
import flixel.util.typeLimit.NextState;
import flixel.input.keyboard.FlxKey;

import lime.app.Application.current as application;

import openfl.events.KeyboardEvent;

#if SCRIPTABLE_STATES
import funkin.states.scripting.HScriptOverridenState;
#end

class FNFGame extends FlxGame
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
	public static var specialKeysEnabled(default, set):Bool;

	public static var antialiasing(default, set):Bool;
	public static var framerate(default, set):Float;
	public static var uncappedFramerate(default, set):Bool;
	#if VSYNC_ALLOWED
	public static var vSyncMode(default, set):String;
	#end

	public function new(gameWidth = 0, gameHeight = 0, ?initialState:InitialState, updateFramerate = 60, drawFramerate = 60, skipSplash = false, ?startFullscreen:Bool)
	{
		@:privateAccess FlxG.initSave();
		startFullscreen = startFullscreen ?? FlxG.save.data.fullscreen;

		#if FLX_TROLL
		this.getTimer = Main.getTime;
		#end

		super(gameWidth, gameHeight, initialState, updateFramerate, drawFramerate, skipSplash, startFullscreen);

		FlxG.sound.volume = FlxG.save.data.volume;
		FlxG.mouse.useSystemCursor = true;
		FlxG.mouse.visible = false;

		////
		FlxG.signals.gameResized.add((w, h) -> resetSpriteCache());
		FlxG.signals.focusGained.add(resetSpriteCache);

		////
		FlxG.stage.addEventListener(
			KeyboardEvent.KEY_DOWN, 
			_onKeyPress, 
			false, 
			100
		);

		FlxG.stage.addEventListener(
			openfl.events.FullScreenEvent.FULL_SCREEN, 
			(e) -> FlxG.save.data.fullscreen = e.fullScreen
		);
	}

	private function _onKeyPress(e:KeyboardEvent) {
		switch (e.keyCode:FlxKey) {
			#if (windows || linux) // No idea if this also applies to any other targets
			case ENTER:
				// Prevent Flixel from listening to key inputs when pressing Alt+Enter
				if (e.altKey)
					e.stopImmediatePropagation();
			#end
			case F11:
				FlxG.fullscreen = !FlxG.fullscreen;
			case F3:
				if (!Main.fpsVar.visible) {
					Main.fpsVar.visible = true;
					Main.fpsVar.showDebug = false;
				}else if (!Main.fpsVar.showDebug) {
					Main.fpsVar.showDebug = true;
				}else {
					Main.fpsVar.visible = false;
					Main.fpsVar.showDebug = false;
				}
			case F5:
				if (e.shiftKey) {
					funkin.Paths.clearStoredMemory();
					funkin.Paths.clearUnusedMemory();
					funkin.data.content.PackManager.reloadPackList();

					if (_state != null) _state.visible = false;
					TransitionableState.skipNextTransIn = true;
					TransitionableState.skipNextTransOut = true;
					MusicBeatState.switchState(() -> new funkin.states.MainMenuState());
				}else {
					MusicBeatState.resetState();
				}
			default:
		}
	}

	override function switchState():Void
	{
		#if SCRIPTABLE_STATES
		if (_nextState is MusicBeatState)
		{
			var ogState:MusicBeatState = cast _nextState;
			var nuState = HScriptOverridenState.requestOverride(ogState);
			
			if (nuState != null) {
				ogState.destroy();
				_nextState = nuState;
			}
		}
		#end

		Globals.variables.clear();
		super.switchState();
	}

	// shader coords fix
	public function resetSpriteCache() {
		for (cam in FlxG.cameras.list) {
			if (cam != null && cam.filters != null)
				Main.resetSpriteCache(cam.flashSprite);
		}
		Main.resetSpriteCache(this);
	}

	public static function updateFramerateValues() {
		inline function nocap():Bool return #if VSYNC_ALLOWED (vsyncMode == "On") || #end uncappedFramerate;
		inline function ongod():Int return #if lime_funkin 0 #else 9000 #end;

		var v = nocap() ? ongod() : Math.ceil(framerate);
		if (v > FlxG.drawFramerate) {
			FlxG.updateFramerate = v;
			FlxG.drawFramerate = v;
		} else {
			FlxG.drawFramerate = v;
			FlxG.updateFramerate = v;
		}
		return v;
	}

	@:noCompletion inline static function set_antialiasing(v:Bool) {
		FlxG.stage.quality = v ? BEST : LOW; // This affects ShaderFilter quality :o
		FlxSprite.defaultAntialiasing = v;
		return v;
	}

	@:noCompletion inline static function set_framerate(v:Float) {
		framerate = v;
		updateFramerateValues();
		return v;
	}

	@:noCompletion inline static function set_uncappedFramerate(v:Bool) {
		uncappedFramerate = v;
		updateFramerateValues();
		return v;
	}

	#if VSYNC_ALLOWED
	@:noCompletion inline static function set_vsyncMode(v:String) {
		FlxG.stage.window.setVSyncMode(switch(vsyncMode = v) {
			case "Adaptive": ADAPTIVE;
			case "On": ON;
			default: OFF;
		});
		updateFramerateValues();
		return v;
	}
	#end

	@:noCompletion inline public static function set_specialKeysEnabled(val)
	{
		if (val) {
			FlxG.sound.muteKeys = muteKeys;
			FlxG.sound.volumeDownKeys = volumeDownKeys;
			FlxG.sound.volumeUpKeys = volumeUpKeys;
		}
		else {
			FlxG.sound.muteKeys = [];
			FlxG.sound.volumeDownKeys = [];
			FlxG.sound.volumeUpKeys = [];
		}

		return specialKeysEnabled = val;
	}
}