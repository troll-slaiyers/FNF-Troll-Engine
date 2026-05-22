package funkin.input;

import haxe.Int64;
import funkin.util.Int64Tools;
import lime.ui.KeyCode;
import flixel.input.keyboard.FlxKey;

typedef QueuedInput = {
	var timestamp:Int64;
	var column:Int;
	var player:Int;
}

class PreciseInputHandler
{
	static final NS_PER_MS:Int64 = 1000000;

	public var keyBinds:Array<Array<FlxKey>> = [];

	public var pressQueue:Array<QueuedInput> = [];
	public var releaseQueue:Array<QueuedInput> = [];

	var pressed:Map<Int, Bool> = [];

	public function new() {
		init();
	}

	public function init() {
		FlxG.stage.window.onKeyDownPrecise.add(handleDownEvent);
		FlxG.stage.window.onKeyUpPrecise.add(handleUpEvent);
	}

	public function destroy() {
		FlxG.stage.window.onKeyDownPrecise.remove(handleDownEvent);
		FlxG.stage.window.onKeyUpPrecise.remove(handleUpEvent);	
	}

	private function handleDownEvent(keyCode:KeyCode, keyMod, timestamp:Int64) {
		final column = getColumnFromKeyCode(keyCode);
		if (column == -1)
			return;
		
		if (pressed.get(column)) 
			return;
		pressed.set(column, true);

		pressQueue.push({
			timestamp: timestamp,
			column: column,
			player: -1,
		});
	}
	
	private function handleUpEvent(keyCode:KeyCode, keyMod, timestamp:Int64) {
		final column = getColumnFromKeyCode(keyCode);
		if (column == -1)
			return;
		
		pressed.set(column, false);

		releaseQueue.push({
			timestamp: timestamp,
			column: column,
			player: -1,
		});
	}

	private function getColumnFromKeyCode(keyCode:KeyCode):Int {
		final key = convertKeyCode(keyCode);
		if (key != -1) {
			for (i in 0...keyBinds.length) {
				for (j in 0...keyBinds[i].length) {
					if(key == keyBinds[i][j])
						return i;
				}
			}
		}
		return -1;
	}

	/** 
		Get the time difference between a timestamp and the current time 
		@param timestamp Precise timestamp, in nanoseconds
		@returns Time difference, in milliseconds
	**/
	public static inline function getLatency(timestamp:Int64):Float
	{
		var latency:Int64 = getCurrentTimestamp() - timestamp;
		latency /= NS_PER_MS;
		return Int64Tools.toFloat(latency);
	}

	/**
	* Returns a precise timestamp, measured in nanoseconds.
	* Timestamp is only useful for comparing against other timestamps.
	*
	* @return Int64
	*/
	@:access(lime._internal.backend.native.NativeCFFI)
	public static function getCurrentTimestamp():Int64
	{
		#if (lime_cffi && lime_funkin)
		return Int64.fromFloat(lime._internal.backend.native.NativeCFFI.lime_system_get_timer());
		#else
		// NOTE: This timestamp isn't that precise on standard HTML5 builds.
		// This is because of browser safeguards against timing attacks.
		// See https://web.dev/coop-coep to enable headers which allow for more precise timestamps.
		return Int64.fromFloat(Main.getTime()) * NS_PER_MS;
		#end
	}

	public static inline function convertKeyCode(input:KeyCode):FlxKey
	{
		@:privateAccess
		return openfl.ui.Keyboard.__convertKeyCode(input);
	}
}