package funkin.objects.ui;

import math.CoolMath;
import funkin.objects.ui.CustomFlxUI.CustomFlxUINumericStepper;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.ui.FlxButton;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxSubState;
import openfl.display.BitmapData;
using SpriteTools;

class ColorPicker extends FlxButton {
	public var callback:FlxColor -> Void;

	public var state:FlxState = null;

	public function new(x:Float = 0, y:Float = 0, text:String = '', callback:FlxColor -> Void = null, defaultValue:FlxColor = FlxColor.WHITE) {
		super(x, y, text);
		this.callback = callback;
		this.color = defaultValue;

		/* initLabel is fuckign inlined */
		label.fieldWidth = 0;
		label.color = 0xFFFFFFFF;
		label.drawFrame(true);

		var x = width + 8; var y = 3;
		for (p in labelOffsets)
			p.set(x, y);
			
		for (i in 0...labelAlphas.length)
			labelAlphas[i] = 1;
	}

	override function loadDefaultGraphic() {
		var sqr_bmp = CoolUtil.makeOutlinedGraphic(16, 16, 0xFFFFFFFF, 1, 0xFF000000);
		loadGraphic(sqr_bmp);
	}

	override function onUpHandler() {
		super.onUpHandler();
		openColorPicker();
	}
	
	function openColorPicker() {
		var state = this.state ?? FlxG.state;
		if (state == null)
			return;

		var ss = new ColorPickerSubstate(color, onColorPickedHandler, text);
		state.openSubState(ss);
	}

	function onColorPickedHandler(color:FlxColor) {
		this.color = color;

		if (callback != null)
			callback(color);
	}
}

/*
	the ugliest piece of ui ever made
*/
class ColorPickerSubstate extends FlxSubState {
	var ccamera:FlxCamera;

	var hueSatSpr:FlxSprite;
	var hueSatPointer:FlxSprite;
	var brightnessSpr:FlxSprite;
	var brightnessPointer:FlxSprite;

	var rStepper:CustomFlxUINumericStepper;
	var gStepper:CustomFlxUINumericStepper;
	var bStepper:CustomFlxUINumericStepper;

	var hexInput:FlxInputText;

	var hStepper:CustomFlxUINumericStepper;
	var sStepper:CustomFlxUINumericStepper;
	var vStepper:CustomFlxUINumericStepper;

	public var color:FlxColor;
	var colorPreview:FlxSprite;

	public var title:String;
	public var acceptCallback:FlxColor->Void;

	inline function makeOutline(spr:FlxSprite, size:Float = 1, color:FlxColor = 0xFF000000) {
		var ol = CoolUtil.blankSprite(spr.width + size + size, spr.height + size + size, color);
		ol.setPosition(spr.x - size, spr.y - size);
		ol.scrollFactor.copyFrom(spr.scrollFactor);
		return ol;
	}

	public function new(?initialColor:FlxColor, ?acceptCallback:FlxColor->Void, title:String = "Color Picker") {
		this.color = initialColor ?? 0x000000;
		this.acceptCallback = acceptCallback;
		this.title = title;

		super(FlxColor.fromRGBFloat(.0,.0,.0,.4));
	}

	override function create() {
		if (_cameras == null || _cameras[0] == null) {
			ccamera = new FlxCamera();
			ccamera.bgColor = 0;
			FlxG.cameras.add(ccamera, false);			
			camera = ccamera;
		}

		// suck my dick
		if (_bgSprite != null)
			_bgSprite.camera = camera;
		
		var bmpHueSat = new BitmapData(360, 255);
		for (hue in 0...bmpHueSat.width) {
			for (sat in 0...bmpHueSat.height) {
				bmpHueSat.setPixel32(hue, sat, FlxColor.fromHSB(hue, sat / bmpHueSat.height, 1.0));
			}
		}

		var bmpBrt = new BitmapData(1, 255);
		for (v in 0...bmpBrt.height) {
			bmpBrt.setPixel32(0, v, FlxColor.fromRGB(v, v, v));
		}

		var bg = CoolUtil.blankSprite(480, 360, 0xff999999);
		bg.scrollFactor.set();
		bg.screenCenter();

		var titleTxt = new FlxText(bg.x, bg.y + 16, bg.width - 32, title);
		titleTxt.alignment = CENTER;

		hueSatSpr = new FlxSprite(0, 0, bmpHueSat);
		hueSatSpr.setGraphicSize(256, 256);
		hueSatSpr.updateHitbox();
		hueSatSpr.scrollFactor.set();

		hueSatPointer = new FlxSprite(0, 0, 'stageeditor/originMarker');
		hueSatPointer.offset.x += hueSatPointer.width / 2;
		hueSatPointer.offset.y += hueSatPointer.height / 2;

		hueSatSpr.objectCenter(bg, Y);
		hueSatSpr.x = bg.x + (hueSatSpr.y - bg.y);

		brightnessSpr = new FlxSprite(0, 0, bmpBrt);
		brightnessSpr.setGraphicSize(16, 256);
		brightnessSpr.updateHitbox();
		brightnessSpr.scrollFactor.set();

		brightnessPointer = new FlxSprite(0, 0, 'optionsMenu/arrow');
		brightnessPointer.setGraphicSize(0, 8);
		brightnessPointer.updateHitbox();
		//brightnessPointer.offset.x += brightnessPointer.width / 2; // offset doesn't rotate lol
		brightnessPointer.offset.y += brightnessPointer.height / 2;
		brightnessPointer.color = 0xFF000000;
		brightnessPointer.angle = 90;

		brightnessSpr.x = hueSatSpr.x + hueSatSpr.width + 16;
		brightnessSpr.objectCenter(bg, Y);

		////
		var x = brightnessSpr.x + brightnessSpr.width + 16 + 16;
		var y = brightnessSpr.y;

		////
		rStepper = new CustomFlxUINumericStepper(x, y += 20, 1, color.red, 0, 255);
		rStepper.callback = rgbStepperCallback;
		rStepper.scrollFactor.set();

		gStepper = new CustomFlxUINumericStepper(x, y += 20, 1, color.green, 0, 255);
		gStepper.callback = rgbStepperCallback;
		gStepper.scrollFactor.set();

		bStepper = new CustomFlxUINumericStepper(x, y += 20, 1, color.blue, 0, 255);
		bStepper.callback = rgbStepperCallback;
		bStepper.scrollFactor.set();

		////
		hexInput = new FlxInputText(x, y += 20, 57);
		hexInput.customFilterPattern = ~/[^a-fA-F0-9]*/g; // hex
		hexInput.filterMode = 4; // CUSTOM_FILTER
		updateHex();
		hexInput.callback = (_, action) -> {
			if (action == "enter")
				hexUpdated();
		};

		y += 20;

		////
		hStepper = new CustomFlxUINumericStepper(x, y += 20, 1, Std.int(color.hue), 0, 360);
		hStepper.callback = hsbStepperCallback;
		hStepper.scrollFactor.set();

		sStepper = new CustomFlxUINumericStepper(x, y += 20, 1, Std.int(color.saturation * 100), 0, 100);
		sStepper.callback = hsbStepperCallback;
		sStepper.scrollFactor.set();

		vStepper = new CustomFlxUINumericStepper(x, y += 20, 1, Std.int(color.brightness * 100), 0, 100);
		vStepper.callback = hsbStepperCallback;
		vStepper.scrollFactor.set();

		////
		colorPreview = CoolUtil.blankSprite(57, 57, color);
		colorPreview.x = x;
		colorPreview.y = y += 40;

		////
		var acceptButton = new FlxButton("Accept");
		acceptButton.allowSwiping = false; // flixel-ui is dogshit by design, you have to turn off the "behave like shit" option lmfao
		acceptButton.onUp.callback = function() {
			if (this.acceptCallback != null)
				this.acceptCallback(color);
			close();
		}

		var cancelButton = new FlxButton("Cancel");
		cancelButton.allowSwiping = false;
		cancelButton.onUp.callback = function() {
			close();
		}

		cancelButton.x = bg.x + bg.width - cancelButton.width - 16;
		cancelButton.y = bg.y + bg.height - cancelButton.height - 16;

		acceptButton.x = cancelButton.x - acceptButton.width - 8;
		acceptButton.y = cancelButton.y;

		////
		add(makeOutline(bg));
		add(bg);
		add(titleTxt);
		add(makeOutline(hueSatSpr));
		add(hueSatSpr);
		add(hueSatPointer);
		add(makeOutline(brightnessSpr));
		add(brightnessSpr);
		add(brightnessPointer);

		add(new FlxText(rStepper.x - 16, rStepper.y - 16, 64, "RGB"));
		add(new FlxText(rStepper.x - 16, rStepper.y, 16, "R:"));
		add(rStepper);
		add(new FlxText(gStepper.x - 16, gStepper.y, 16, "G:"));
		add(gStepper);
		add(new FlxText(bStepper.x - 16, bStepper.y, 16, "B:"));
		add(bStepper);

		//add(new FlxText(hexInput.x - 16, hexInput.y, 20, "Hex:"));
		add(hexInput);

		add(new FlxText(hStepper.x - 16, hStepper.y - 16, 64, "HSB"));
		add(new FlxText(hStepper.x - 16, hStepper.y, 16, "H:"));
		add(hStepper);
		add(new FlxText(sStepper.x - 16, sStepper.y, 16, "S:"));
		add(sStepper);
		add(new FlxText(vStepper.x - 16, vStepper.y, 16, "B:"));
		add(vStepper);

		add(makeOutline(colorPreview));
		add(colorPreview);

		add(cancelButton);
		add(acceptButton);

		// alright i had enough
		for (obj in members) {
			if (obj is FlxSprite)
				cast(obj, FlxSprite).scrollFactor.set();
		}
	}

	function rgbStepperCallback(_, action:String) {
		if (action == FlxUINumericStepper.CHANGE_EVENT)
			rgbUpdated();
	}

	function hsbStepperCallback(_, action:String) {
		if (action == FlxUINumericStepper.CHANGE_EVENT)
			hsbUpdated();
	}

	function rgbUpdated() {
		color = FlxColor.fromRGB(Std.int(rStepper.value), Std.int(gStepper.value), Std.int(bStepper.value));

		if (color != 0xFFFFFFFF && color != 0xFF000000)
			hStepper.value = color.hue;

		if (color != 0xFF000000)
			sStepper.value = color.saturation * 100;

		vStepper.value = color.brightness * 100;
		updateHex();
	}

	function hsbUpdated() {
		color = FlxColor.fromHSB(hStepper.value, sStepper.value / 100, vStepper.value / 100);
		rStepper.value = color.red;
		gStepper.value = color.green;
		bStepper.value = color.blue;
		updateHex();
	}

	var prevHex:String = '';

	function hexUpdated() {
		var newHex = hexInput.text;

		if (newHex.length < 6) {
			hexInput.text = prevHex;
			return;
		}

		color = CoolUtil.colorFromString(newHex);
		prevHex = newHex;
		
		rStepper.value = color.red;
		gStepper.value = color.green;
		bStepper.value = color.blue;

		var c24 = color.to24Bit();
		if (c24 != 0xFFFFFF && c24 != 0x000000)
			hStepper.value = color.hue;

		if (c24 != 0x000000)
			sStepper.value = color.saturation * 100;

		vStepper.value = color.brightness * 100;
	}

	function updateHex() {
		hexInput.text = color.toHexString(false, false);
		prevHex = hexInput.text;
	}

	// null=none ; false=huesat ; true=brightness
	var holding:Null<Bool> = null;

	override function update(elapsed:Float) {
		if (holding == null && FlxG.mouse.justPressed) {
			if (FlxG.mouse.overlaps(hueSatSpr))
				holding = false;
			else if (FlxG.mouse.overlaps(brightnessSpr))
				holding = true;
		}
		else if (!FlxG.mouse.pressed)
			holding = null;

		////
		if (holding != null) {
			var pos = FlxG.mouse.getPositionInCameraView(camera);

			if (holding == false) {
				hStepper.value = CoolMath.scale(pos.x, hueSatSpr.x, hueSatSpr.x + hueSatSpr.width, 0, 360);
				sStepper.value = CoolMath.scale(pos.y, hueSatSpr.y, hueSatSpr.y + hueSatSpr.height, 0, 100);
			}
			else if (holding == true) {
				vStepper.value = CoolMath.scale(pos.y, brightnessSpr.y, brightnessSpr.y + brightnessSpr.height, 0, 100);
			}

			pos.put();
			hsbUpdated();
		}

		////
		hueSatPointer.setPosition(
			hueSatSpr.x + hueSatSpr.width * (hStepper.value / 360),	
			hueSatSpr.y + hueSatSpr.height * (sStepper.value / 100),	
		);
		hueSatPointer.setPosition(
			Std.int(hueSatPointer.x * hueSatSpr.frameWidth) / hueSatSpr.frameWidth,
			Std.int(hueSatPointer.y * hueSatSpr.frameHeight) / hueSatSpr.frameHeight
		);

		brightnessPointer.setPosition(
			brightnessSpr.x + brightnessSpr.width + 2,	
			brightnessSpr.y + brightnessSpr.height * (vStepper.value / 100),	
		);
		brightnessPointer.y = Std.int(brightnessPointer.y * brightnessSpr.frameHeight) / brightnessSpr.frameHeight;

		colorPreview.color = color;
		super.update(elapsed);
	}

	override function destroy() {
		FlxG.cameras.remove(ccamera);
		super.destroy();
	}
}