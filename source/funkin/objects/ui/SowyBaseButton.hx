package funkin.objects.ui;

import openfl.ui.Mouse;
import openfl.ui.MouseCursor;
import flixel.ui.FlxButton;

class SowyBaseButton extends FlxButton{
	public function new(X:Float = 0, Y:Float = 0, ?OnClick:Void->Void)
	{
		super(X, Y, OnClick);
	}

	override function onOverHandler():Void{
		Mouse.cursor = MouseCursor.BUTTON;
		super.onOverHandler();
	}

	override function onOutHandler() {
		Mouse.cursor = MouseCursor.AUTO;
		super.onOutHandler();
	}
}