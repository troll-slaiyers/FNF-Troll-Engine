package funkin.objects;

import openfl.geom.Rectangle;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import openfl.display.BlendMode;
import openfl.display.BitmapData;
import openfl.geom.ColorTransform;

class AFT extends FlxSprite {
	public var framerate:Float = 60;
	public var aftBlend:BlendMode = NORMAL;
	public var srcRect:Rectangle;
	public var dstMatrix:FlxMatrix = new FlxMatrix();
	public var aftColorTransform:ColorTransform;
	public var recursive:Bool = false;
	public var autoUpdate:Bool = false;
	public var backgroundColor:FlxColor = FlxColor.TRANSPARENT;

	var bitmapData:BitmapData;
	var targetCamera:FlxCamera;

	override public function new(targetCamera:FlxCamera, x:Float = 0, y:Float = 0, autoUpdate:Bool = false) {
		super(x, y);

		makeGraphic(targetCamera.width, targetCamera.height, FlxColor.TRANSPARENT);
		bitmapData = new BitmapData(Std.int(width), Std.int(height), true, FlxColor.TRANSPARENT);
		bitmapData.disposeImage();
		srcRect = new Rectangle(0, 0, targetCamera.width, targetCamera.height);
		dstMatrix.identity();
		aftColorTransform = new ColorTransform();

		this.targetCamera = targetCamera;
		this.autoUpdate = autoUpdate;

		framerate = ClientPrefs.framerate;
	}

	public function clear() {
		bitmapData.fillRect(srcRect, backgroundColor);
	}

	public function drawAFT() {
		if (!recursive) {
			inline clear();
		}
		bitmapData.draw(targetCamera.canvas, dstMatrix, aftColorTransform, aftBlend, srcRect, antialiasing);
		pixels = bitmapData;
		updateTimer = 0;
	}

	var updateTimer:Float = 0;

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (!autoUpdate) {
			return;
		}
		updateTimer += elapsed;
		if (framerate != 0 && updateTimer >= 1 / framerate) {
			drawAFT();
		}
	}
}
