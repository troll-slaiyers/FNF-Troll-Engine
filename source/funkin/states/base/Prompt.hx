package funkin.states.base;

import funkin.objects.ui.ScrollText;
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
	
	override function create():Void 
	{
		super.create();

		var textshit = new ScrollText(0, 0, 0);
		textshit.size = 16;
		textshit.text = theText;
		textshit.alignment = LEFT;
		textshit.scrollFactor.set();
		textshit.drawFrame(true);

		var padding:Int = 12;
		var buttonV:Int = Std.int(padding + buttonLeft.height);
		var boxWidth:Int = Std.int(padding + textshit.fieldWidth + padding);
		var boxHeight:Int = Std.int(FlxG.height * 2/3);

		// If the text is too big for the screen
		if (boxWidth > FlxG.width) {
			boxWidth = Std.int(FlxG.width * 5/8);
			textshit.fieldWidth = boxWidth - padding - padding;
			textshit.width = boxWidth;
		}

		// If the box is too big for the text
		if (boxHeight - padding - padding - buttonV > textshit.frameHeight + 16) {
			boxHeight = Std.int(padding + textshit.frameHeight + padding + buttonV);
		}

		panel = new FlxSprite(0, 0);
		panel.scrollFactor.set();
		makeSelectorGraphic(panel, boxWidth, boxHeight, 0xff999999);
		panel.screenCenter();
		panel.x = Std.int(panel.x);
		panel.y = Std.int(panel.y);
		
		panelbg = new FlxSprite(0, 0);
		panelbg.scrollFactor.set();
		makeSelectorGraphic(panelbg, boxWidth + 2, boxHeight + 2, 0xff000000);		
		panelbg.screenCenter();
		panelbg.x = Std.int(panelbg.x);
		panelbg.y = Std.int(panelbg.y);

		buttonLeft.screenCenter();
		buttonLeft.x = Std.int(buttonLeft.x);
		buttonLeft.y = panel.y + panel.height - buttonV;

		if (buttonLeft.text != buttonRight.text) {
			buttonLeft.x -= buttonRight.width/1.5;

			buttonRight.screenCenter();
			buttonRight.x += buttonRight.width/1.5;
			buttonRight.y = panel.y + panel.height - buttonV;
		}else {
			buttonRight.exists = false;
		}

		add(panelbg);
		add(panel);
		add(textshit);
		add(buttonLeft);
		add(buttonRight);

		textshit.x = panel.x + padding;
		textshit.y = panel.y + padding;
		textshit.minY = textshit.y;
		textshit.maxY = buttonLeft.y - padding;
	}

	override function update(elapsed:Float) {
		FlxG.mouse.visible = true;
		super.update(elapsed);
	}
	
	function makeSelectorGraphic(panel:FlxSprite,w,h,color:FlxColor)
	{
		panel.makeGraphic(w, h, color);
	}
	
}