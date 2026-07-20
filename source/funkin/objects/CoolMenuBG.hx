package funkin.objects;

import flixel.util.FlxColor;
import openfl.geom.ColorTransform;
import funkin.objects.shaders.AdjustColor;
import flixel.util.FlxGradient;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxSpriteGroup;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import funkin.objects.shaders.CoolBGShader;

class CoolMenuBG extends FlxSprite {
	public final coolShader:CoolBGShader;
	public var isCool(default, set):Bool;

	private var iTime:Array<Float> = [0.0];

	public function new(?simpleGraphic:FlxGraphicAsset, color:FlxColor = 0xFFFFFFFF) {
		super(0, 0, simpleGraphic);
		this.color = color;

		this.scrollFactor.set();
		
		this.coolShader = new CoolBGShader();
		this.coolShader.iTime.value = iTime;
		this.isCool = ClientPrefs.shaders != "None";
	}

	override function update(elapsed:Float) {
		iTime[0] += elapsed;
		super.update(elapsed);
	}

	override function destroy() {
		this.coolShader.iTime.value = null;
		super.destroy();
	}

	@:noCompletion function set_isCool(v) {
		this.shader = v ? coolShader : null;
		return isCool = v;
	}
}

class UnCoolMenuBG extends FlxSpriteGroup
{
	private var gradient:FlxSprite;
	private var backdrop:FlxBackdrop;
	private var bg:FlxSprite;

	public function new(simpleGraphic:FlxGraphicAsset, color:FlxColor = 0xFFFFFFFF) {
		super();
		this.scrollFactor.set();

		bg = new FlxSprite(0, 0, simpleGraphic);
		if (bg.pixels != null) {
			bg.loadGraphic(makeCoolBitmap(bg.pixels, color), false, 0, 0, false, 'CoolBG_instance_${bg.graphic.key}_$color');
			bg.blend = MULTIPLY;
		}

		var grid = new BitmapData(2, 2);
		grid.setPixel32(0, 0, 0xFFC0C0C0);
		grid.setPixel32(1, 1, 0xFFC0C0C0);

		var grid = FlxGraphic.fromBitmapData(grid, false, 'CoolBG_grid');

		backdrop = new FlxBackdrop(grid);
		backdrop.scrollFactor.set();
		backdrop.scale.x = backdrop.scale.y = FlxG.height / 3;
		backdrop.updateHitbox();
		backdrop.y -= backdrop.height / 2;
		backdrop.velocity.set(30, 30);
		backdrop.antialiasing = true;
		backdrop.color = color;
		backdrop.alpha = 0.5;
		backdrop.blend = ADD;

		gradient = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFFFFFF, 0xFF000000]);
		gradient.scrollFactor.set();

		bg.setGraphicSize(0, FlxG.height);
		bg.updateHitbox();
		bg.screenCenter();

		if (FlxG.height < FlxG.width)
			bg.scale.x = bg.scale.y = (FlxG.height * 1.05) / bg.frameHeight;
		else
			bg.scale.x = bg.scale.y = (FlxG.width * 1.05) / bg.frameWidth;

		add(gradient);
		add(backdrop);
		add(bg);
	}

	static function makeCoolBitmap(bitmap:BitmapData, color:FlxColor):BitmapData {
		var colorTransform = new ColorTransform(-1, -1, -1, 1,
			Std.int(255 + color.red / 3),
			Std.int(255 + color.green / 3),
			Std.int(255 + color.blue / 3),
			0
		);
		
		var cool = new BitmapData(bitmap.width, bitmap.height, 0x00000000);
		try {
			cool.draw(bitmap, null, colorTransform);
		}catch(e) {
			// fuck my gpu caching life	
		}
		return cool;
	}

	public static function makeCoolGraphic(graphic:FlxGraphic, color:FlxColor):FlxGraphic {
		var cool = makeCoolBitmap(graphic.bitmap, color);
		
		var gradient = new BitmapData(cool.width, cool.height, 0x00000000);
		for (y in 0...cool.height) {
			var grad = (1.0 - y / cool.height);
			var bd = FlxColor.fromRGBFloat(grad + color.redFloat * 0.5, grad + color.greenFloat * 0.5, grad + color.blueFloat * 0.5);
			for (x in 0...cool.width) {
				var fragColor:FlxColor = bd * cool.getPixel32(x, y);
				gradient.setPixel32(x, y, fragColor);
			}
		}

		return FlxGraphic.fromBitmapData(gradient, false, 'CoolBG_${graphic.key}_$color');
	}

	override function set_color(v:Int):Int {
		backdrop.color = v;
		bg.color = v;
		return color = v;
	}
}