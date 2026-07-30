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

class DebugLog extends FlxTypedGroup<DebugText> {
	public static var print:Function = Print.print;
	
	/** Whether messages should appear on the right of the screen **/
	public static var flipX(default, set):Bool = false;
	/** Whether messages should appear on the bottom of the screen **/
	public static var flipY(default, set):Bool = false;

	private static var instance(default, null):DebugLog;
	private static var _lastMsg:String;

	public static function init() {
		if (instance != null)
			return;

		instance = new DebugLog();
		FlxG.plugins.addPlugin(instance);

		print = Reflect.makeVarArgs(function(ray:Array<Dynamic>) {
			instance._addMessage(ray.join(', '), FlxColor.WHITE);
		});
	}

	public static function addMessage(msg:String, color:FlxColor = FlxColor.WHITE) {
		instance._addMessage(msg, color);
	}

	////
	private function new() @:privateAccess {
		var maxTexts:Int = Math.ceil((FlxG.height / 2 - 10) / TEXT_SPACING);
		super(maxTexts);

		for (_ in 0...maxTexts)
			add(new DebugText());

		// I don't want to rely on the last added camera (zooming)
		// I don't want to add zoomFactor
		// I don't want to be constantly making a new camera
		// I don't want to use OpenFL texts (text borders)
		// fgsfds
		camera = new FlxCamera();

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
	}

	override function update(elapsed:Float) {
		camera.update(elapsed);
		super.update(elapsed);
	}

	private inline function _addMessage(msg:String, color:FlxColor) {
		if (_lastMsg == msg) {
			var last:Null<DebugText> = members[members.length - 1];
			last.revive();
			last.text = '$msg (x${++last.ID})';
			last.color = color;
			return;
		}

		var retxt:DebugText = members[0];
		for (txt in members) {
			if (!txt.alive)
				retxt = txt; // recycle last dead member to shorten array shifting (does this matter lmao)
			else
				txt.y += flipY ? -TEXT_SPACING : TEXT_SPACING;
		}

		retxt.revive();
		retxt.text = msg;
		retxt.color = color;
		retxt.setPosition(10, 10);
		if (flipX) retxt.x = FlxG.width - retxt.width - retxt.x;
		if (flipY) retxt.y = FlxG.height - retxt.height - retxt.y;		
		retxt.ID = 1;
		members.remove(retxt);
		members.push(retxt);

		_lastMsg = msg;
	}

	////
	private static inline function set_flipX(v:Bool) {
		if (flipX == v)
			return v;

		for (txt in instance.members)
			txt.x = FlxG.width - txt.width - txt.x;

		return flipX = v;
	}

	private static inline function set_flipY(v:Bool) {
		if (flipY == v)
			return v;

		for (txt in instance.members)
			txt.y = FlxG.height - txt.height - txt.y;

		return flipY = v;
	}
}

private class DebugText extends FlxText
{
	public var lifeTime:Float = TEXT_LIFETIME;

	public function new() {
		super(0, 0, 0);
		setFormat("troll-ui/fonts/ibmplexmono/semibold.ttf", TEXT_FONT_SIZE, 0xFFFFFFFF, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		antialiasing = true;
		scrollFactor.set();
		borderSize = 1;
	}

	override function revive() {
		super.revive();
		lifeTime = TEXT_LIFETIME;
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