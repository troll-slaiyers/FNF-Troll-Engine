package funkin.states.base;

import flixel.*;
import flixel.addons.ui.FlxUIPopup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import openfl.geom.Rectangle;

class Prompt extends MusicBeatSubstate
{
	var selected = 0;
	public var okc:Void->Void;
	public var cancelc:Void->Void;
	var theText:String = '';
	var panel:FlxSprite;
	var panelbg:FlxSprite;
	var buttonLeft:FlxButton;
	var buttonRight:FlxButton;
	var cornerSize:Int = 10;
	public function new(promptText:String = '', defaultSelected:Int = 0, okCallback:Void->Void = null, cancelCallback:Void->Void = null, option1:String = 'OK', option2:String = 'CANCEL') 
	{
		selected = defaultSelected;
		okc = okCallback;
		cancelc = cancelCallback;
		theText = promptText;
		buttonLeft = new FlxButton(473.3, 450, option1, ()->{if(okc != null) okc(); close();} );
		buttonRight = new FlxButton(633.3, 450, option2, ()->{if(cancelc != null) cancelc(); close();});
		super(FlxColor.fromRGBFloat(.0,.0,.0,.4));
	}
	
	override public function create():Void 
	{
		super.create();

		var width = 300;
		var height = 150;

		var textshit:FlxText = new FlxText(0, 0, width - 2, theText, 16);
		textshit.scrollFactor.set();
		textshit.alignment = CENTER;
		textshit.screenCenter();

		panel = new FlxSprite(0, 0);
		panel.scrollFactor.set();
		makeSelectorGraphic(panel, width, height, 0xff999999);
		panel.screenCenter();
		
		panelbg = new FlxSprite(0, 0);
		panelbg.scrollFactor.set();
		makeSelectorGraphic(panelbg, width + 1, height + 1, 0xff000000);		
		panelbg.screenCenter();

		buttonLeft.screenCenter();
		buttonLeft.y = panel.y + panel.height - buttonLeft.height - 8;

		if (buttonLeft.text != buttonRight.text) {
			buttonLeft.x -= buttonRight.width/1.5;

			buttonRight.screenCenter();
			buttonRight.x += buttonRight.width/1.5;
			buttonRight.y = panel.y + panel.height - buttonLeft.height - 8;
		}else {
			buttonRight.exists = false;
		}

		add(panelbg);
		add(panel);
		add(textshit);
		add(buttonLeft);
		add(buttonRight);
	}
	
	function makeSelectorGraphic(panel:FlxSprite,w,h,color:FlxColor)
	{
		panel.makeGraphic(w, h, color);
	}
	
}