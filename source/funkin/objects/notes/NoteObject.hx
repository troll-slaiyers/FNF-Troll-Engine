package funkin.objects.notes;

import haxe.exceptions.NotImplementedException;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxPoint;
import math.Vector3;
import funkin.objects.shaders.NoteColorSwap;

using StringTools;

enum abstract ObjectType(#if cpp cpp.UInt8 #else Int #end) {
	var UNKNOWN = -1;
	var NOTE;
	var STRUM;
	var SPLASH;
}

class NoteObject extends FlxSprite {
	public var extraData:Map<String, Dynamic> = [];

	public var objType:ObjectType;
	public var zIndex:Float = 0;
	public var column:Int = 0;

	public var colorSwap:NoteColorSwap;
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var defScale:FlxPoint = FlxPoint.get(); // for modcharts to keep the scaling

	public var handleRendering:Bool = true;
	public var vec3Cache:Vector3 = new Vector3(); // for vector3 operations in modchart code

	#if ALLOW_DEPRECATION
	@:deprecated("noteData is deprecated! Use `column` instead.")
	public var noteData(get, set):Int; // backwards compat

	inline function get_noteData()
		return column;

	inline function set_noteData(v)
		return column = v;
	#end

	public function new(objType:ObjectType = UNKNOWN) {
		this.objType = objType;
		super();
	}

	override function toString() {
		return '(column: $column | visible: $visible)';
	}

	override function draw() {
		if (handleRendering)
			return super.draw();
	}

	override function drawComplex(camera:FlxCamera):Void {
		prepareMatrix(camera);
		camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader, colorSwap);
	}

	override function destroy() {
		defScale = FlxDestroyUtil.put(defScale);
		super.destroy();
	}

	// gonna make this the thing you can call from all subclasses later
	public static function getNoteAnimations(keyCount:Int) {
		throw new NotImplementedException();
	}

	function getNoteColours(anims:NoteAnimation) { // i had to resist the urge to spell it without the u to keep it consistent
		var anim:String = anims.noteAnimations[column % anims.noteAnimations.length];
		if (anim.contains("purple")) {
			return ClientPrefs.arrowHSV[0];
		} else if (anim.contains("blue")) {
			return ClientPrefs.arrowHSV[1];
		} else if (anim.contains("green")) {
			return ClientPrefs.arrowHSV[2];
		} else if (anim.contains("red")) {
			return ClientPrefs.arrowHSV[3];
		} else if (anim.contains("square")) {
			return ClientPrefs.arrowHSV[4];
		}
		return [0, 0, 0];
	}

	public static function getAnimsInd(data:Int, anims:Array<String>, ?targetArray:Array<String>):Int {
		for (i in 0...4) {
			if (anims[data % anims.length] == targetArray[i]) {
				return i;
			}
		}
		return 0;
	}
}
