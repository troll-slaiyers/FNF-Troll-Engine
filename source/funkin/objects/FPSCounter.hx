package funkin.objects;

import flixel.math.FlxMath;
#if cpp
import funkin.api.Memory;
#end
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

class FPSCounter extends TextField {
	/** Allows the FPS counter to lie about your framerate because Lime sucks and framerates goes above whats desired **/
	public var canLie:Bool = true;

	/** The current frame rate, expressed using frames-per-second **/
	public var currentFPS(default, null):Int = 0;

	/** The current state class name **/
	public var currentState(default, null):String = "";

	/** Whether to show a memory usage counter or not **/
	public var showDebug(default, set):Bool = #if final false #else true #end;

	public var align(default, set):TextFormatAlign;

	public var getDebugText:Void->String = null;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0xFFFFFF) {
		super();

		this.x = x;
		this.y = y;

		mouseEnabled = false;
		selectable = false;

		background = true;
		backgroundColor = 0x000000;

		multiline = true;
		embedFonts = false;
		defaultTextFormat = new TextFormat("_sans", 12, color);

		////
		addEventListener(Event.ADDED_TO_STAGE, (e:Event) -> {
			if (align == null)
				align = #if mobile CENTER #else LEFT #end;
		});

		addEventListener(Event.ENTER_FRAME, onEnterFrame);

		FlxG.signals.gameResized.add(onGameResized);

		FlxG.signals.preStateCreate.add((nextState) -> {
			currentState = Type.getClassName(Type.getClass(nextState));
		});
	}

	private var _framesPassed:Int = 0;
	private var _previousTime:Float = 0;
	private var _updateClock:Float = 999999;

	private function onEnterFrame(e:Event):Void {
		_framesPassed++;
		final deltaTime:Float = Math.max(Main.getTime() - _previousTime, 0);
		_updateClock += deltaTime;

		_previousTime = Main.getTime();
		if (_updateClock >= 1000) {
			currentFPS = (canLie && FlxG.drawFramerate > 0) ? FlxMath.minInt(_framesPassed, FlxG.drawFramerate) : _framesPassed;
			var text:String = 'FPS: $currentFPS';

			if (showDebug)
				text += '\n' + _getDebugText();

			if (currentFPS <= FlxG.drawFramerate * 0.5)
				textColor = 0xFFFF0000;
			else
				textColor = 0xFFFFFFFF;

			this.text = text;

			_framesPassed = 0;
			_updateClock = 0;
		}
		_previousTime = Main.getTime();
	}

	inline function onGameResized(windowWidth:Int, ?windowHeight:Int) {
		align = align;
	}

	@:noCompletion
	private inline function _getDebugText():String {
		return 'MEM: ' + get_memoryUsageString() + '\nState: $currentState' + (getDebugText != null ? "\n" + getDebugText() : "");
	}

	@:noCompletion
	inline function set_showDebug(debug:Bool) {
		_updateClock = 1000;
		return this.showDebug = debug;
	}

	@:noCompletion
	private function set_align(val) {
		return align = defaultTextFormat.align = switch (val) {
			default:
				this.x = 10;
				autoSize = LEFT;
				LEFT;

			case CENTER:
				this.x = (this.stage.stageWidth - this.textWidth) * 0.5;
				autoSize = CENTER;
				CENTER;

			case RIGHT:
				this.x = (this.stage.stageWidth - this.textWidth) - 10;
				autoSize = RIGHT;
				RIGHT;
		}
	}

	@:noCompletion
	private static inline function get_memoryUsageString():String {
		#if cpp
		return CoolUtil.formatMemory(Memory.getCurrentRSS()) + " / " + CoolUtil.formatMemory(Memory.getPeakRSS());
		#else
		return CoolUtil.formatMemory(openfl.system.System.totalMemoryNumber);
		#end
	}
}
