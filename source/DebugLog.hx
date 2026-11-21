package;

import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import haxe.Constraints.Function;
import funkin.Paths;

inline final TEXT_LIFETIME:Float = 6;
inline final TEXT_FONT_SIZE:Int = 16;
inline final TEXT_SPACING:Int = TEXT_FONT_SIZE;

class DebugLog {
	public static var print:Function = Print.print;
	
	/** Whether messages should appear on the right of the screen **/
	public static var flipX(get, set):Bool;
	/** Whether messages should appear on the bottom of the screen **/
	public static var flipY(get, set):Bool;

	private static var instance(default, null):DebugLogGroup;

	public static function init() @:privateAccess {
		if (instance != null)
			return;

		// I don't want to rely on the last added camera (zooming)
		// I don't want to add zoomFactor (right now, just for this)
		// I don't want to be constantly making a new camera (i'll revise transitions once again soon)
		// I don't want to use OpenFL texts (no text borders)
		// fgsfds
		var camera = new FlxCamera();

		//// CameraFrontEnd code
		if (FlxG.renderTile) {
			FlxG.signals.preDraw.add(function() {
				camera.clearDrawStack();
				camera.canvas.graphics.clear();
				// Clearing camera's debug sprite
				#if FLX_DEBUG
				camera.debugLayer.graphics.clear();
				#end
			});
		}
		FlxG.signals.postDraw.add(camera.render);
		FlxG.signals.gameResized.add((w, h) -> camera.onResize());
		FlxG.game.addChildAt(camera.flashSprite, FlxG.game.getChildIndex(FlxG.game._inputContainer) + 1);

		////
		instance = new DebugLogGroup();
		instance.camera = camera;
		FlxG.plugins.addPlugin(camera); // so that camera.update gets called... for whatever that might be needed for
		FlxG.plugins.addPlugin(instance);

		print = Reflect.makeVarArgs(function(ray:Array<Dynamic>) {
			instance.addMessage(ray.join(', '), FlxColor.WHITE);
		});
	}

	public static inline function addMessage(msg:String, color:FlxColor = FlxColor.WHITE) {
		instance.addMessage(msg, color);
	}

	public static inline function clear() {
		instance.killMembers();
	}

	////
	private inline static function get_flipX():Bool
		return instance.flipX;
	private inline static function set_flipX(v:Bool):Bool
		return instance.flipX = v;

	private inline static function get_flipY():Bool
		return instance.flipY;
	private inline static function set_flipY(v:Bool):Bool
		return instance.flipY = v;
}

class DebugLogGroup extends FlxTypedGroup<DebugText> {
	/** Horizontal padding for message texts **/
	public var x:Float = 10;
	/** Vertical padding for message texts **/
	public var y:Float = 10;

	/** Whether messages should appear on the right of the screen **/
	public var flipX(default, set):Bool = false;
	/** Whether messages should appear on the bottom of the screen **/
	public var flipY(default, set):Bool = false;

	public var lifeTime:Float = TEXT_LIFETIME;

	private var _lastMsg:String;

	public function new(x:Float = 10, y:Float = 10, maxTexts = 0) {
		if (maxTexts <= 0) {
			maxTexts = Math.ceil((FlxG.height / 2 - 10) / TEXT_SPACING);
		}
		super(maxTexts);
		this.x = x;
		this.y = y;
		for (_ in 0...maxTexts)
			add(new DebugText());
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
	}

	public function addMessage(msg:String, color:FlxColor = FlxColor.WHITE) {
		if (_lastMsg == msg) {
			var last:Null<DebugText> = members[members.length - 1];
			last.revive();
			last.lifeTime = lifeTime;
			last.text = '$msg (x${++last.ID})';
			last.color = color;
			return;
		}

		var retxt:DebugText = members[0];
		for (txt in members) {
			if (!txt.alive)
				retxt = txt; // recycle last dead member to shorten array shifting (does this matter lmao)
			else {
				txt.y += flipY ? -TEXT_SPACING : TEXT_SPACING;
				if (txt.y < 0 || txt.y >= FlxG.height)
					txt.kill();
			}
		}

		retxt.revive();
		retxt.lifeTime = lifeTime;
		retxt.text = msg;
		retxt.color = color;
		retxt.setPosition(x, y);
		if (flipX) retxt.x = FlxG.width - retxt.width - retxt.x;
		if (flipY) retxt.y = FlxG.height - retxt.height - retxt.y;		
		retxt.ID = 1;
		members.remove(retxt);
		members.push(retxt);

		_lastMsg = msg;
	}

	////
	private function set_flipX(v:Bool) {
		if (flipX == v)
			return v;

		for (txt in members)
			txt.x = FlxG.width - txt.width - txt.x;

		return flipX = v;
	}

	private function set_flipY(v:Bool) {
		if (flipY == v)
			return v;

		for (txt in members)
			txt.y = FlxG.height - txt.height - txt.y;

		return flipY = v;
	}
}

private class DebugText extends FlxText
{
	public var lifeTime:Float = 6.0;

	public function new() {
		super(0, 0, 0);
		setFormat("troll-ui/fonts/ibmplexmono/semibold.ttf", TEXT_FONT_SIZE, 0xFFFFFFFF, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		antialiasing = true;
		scrollFactor.set();
		borderSize = 1;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		lifeTime -= elapsed;
		if (lifeTime <= 0) kill();
		else alpha = lifeTime;
	}

	override function regenGraphic():Void {
		if (textField == null || !_regen)
			return;
		
		var index = Paths.graphicDumpExclusions.indexOf(this.graphic);
		if (index == -1) index = Paths.graphicDumpExclusions.length;
		super.regenGraphic();
		Paths.graphicDumpExclusions[index] = this.graphic;
	}

	override function destroy() {
		Paths.graphicDumpExclusions.remove(this.graphic);
		super.destroy();
	}
}