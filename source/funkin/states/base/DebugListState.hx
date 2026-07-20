package funkin.states.base;

import flixel.text.FlxText;

#if DISCORD_ALLOWED
import funkin.api.Discord.DiscordClient;
#end

@:noScripting
class DebugListState extends MusicBeatSubstate
{		
	public var textStrings:Array<String>;
	public var textStrings2:Array<String>;

	public var textObjects:Array<FlxText> = [];
	public var textObjects2:Array<FlxText> = [];

	public var curSelected:Int = 0;
	var curTextIdx:Int = -1;

	var ySecsHolding = 0.0;

	var cam:FlxCamera = null;

	public function new(textStrings:Array<String>, ?textStrings2:Array<String>) {
		this.textStrings = textStrings;
		this.textStrings2 = textStrings2;
		super();
	}

	override public function create() 
	{
		super.create();

		if (_parentState == null) {
			#if DISCORD_ALLOWED
			DiscordClient.changePresence({details: "In the Menus"});
			#end
		}else {
			cam = new FlxCamera();
			cam.bgColor = 0;
			FlxG.cameras.add(cam, false);
			this.camera = cam;
			if (this._bgSprite != null)
				this._bgSprite._cameras = this._cameras;
		}

		var hPadding = 64;
		var vPadding = 64;
		var spacing = 4; // space between texts
		var width = (FlxG.width - hPadding - hPadding);
		var height = (FlxG.height - vPadding - vPadding);
		var textSize = 16;

		var ySpace = (textSize+spacing);
		var width = Math.ceil(width / 2);
		var txts = Math.floor(height / ySpace);

		for (i in 0...txts)
		{
			var text = new FlxText(
				hPadding, 
				vPadding + (ySpace * i), 
				width, 
				"" + i,
				textSize
			);
			text.wordWrap = false;
			text.antialiasing = false;
			textObjects.push(text);
			add(text);
		}

		if (textObjects2 != null) {
			for (i in 0...txts) {
				var text = new FlxText(
					hPadding + width, 
					vPadding + (ySpace * i), 
					width, 
					"" + i,
					textSize
				);
				text.wordWrap = false;
				text.antialiasing = false;
				textObjects2.push(text);
				add(text);
			}
		}

		changeSelection(curSelected, true);
	}

	override public function update(e)
	{
		final stepSize:Int = 1;
		final turboSpeed:Float = 20;
		final turboChargeTime:Float = 0.5;

		if (controls.UI_UP || controls.UI_DOWN)
		{
			var p = controls.UI_VERTICAL_P;
			if (p != 0) {
				changeSelection(stepSize * p);
				ySecsHolding = 0;
			}

			var checkLastHold:Int = Math.floor((ySecsHolding - turboChargeTime) * turboSpeed);
			ySecsHolding += e;
			var checkNewHold:Int = Math.floor((ySecsHolding - turboChargeTime) * turboSpeed);

			if (ySecsHolding > 0.35 && checkNewHold - checkLastHold > 0)
				changeSelection((checkNewHold - checkLastHold) * controls.UI_VERTICAL * stepSize);
		}

		if (controls.ACCEPT) 
		{
			onSelect(curSelected);
		}

		if (controls.BACK) 
		{
			goBack();
		}

		super.update(e);
	}

	function changeSelection(val:Int, isAbs:Bool = false) {
		if (textStrings.length == 0)
			return;

		curSelected = isAbs ? val : curSelected + val;

		if (curSelected < 0 || curSelected >= textStrings.length)
			curSelected = curSelected % textStrings.length;
		if (curSelected < 0)
			curSelected = textStrings.length + curSelected;

		////
		var listEndIdx = Math.round(curSelected + textObjects.length / 2);
		if (listEndIdx > textStrings.length) listEndIdx = textStrings.length;
		
		var listStartIdx = listEndIdx - textObjects.length;
		if (listStartIdx < 0) listStartIdx = 0;

		//trace(listStartIdx, curSelected, listEndIdx, textObjects.length);

		for (i in 0...textObjects.length) {
			var listIdx = listStartIdx + i;
			var textObj = textObjects[i];
			var textObj2 = textObjects2[i];
			
			var textStr = textStrings[listIdx];
			if (textObj != null && (textObj.exists = textStr != null)) {
				textObj.text = textStr;
				textObj.color = (listIdx == curSelected) ? 0xFFFFFF00 : 0xFFFFFFFF;
			}
			else {
				if (textObj2 != null)
					textObj2.exists = false;
				continue;
			}

			var textStr2 = textStrings2 != null ? textStrings2[listIdx] : null;
			if (textObj2 != null && (textObj2.exists = textStr2 != null)) {
				textObj2.text = textStr2;
				textObj2.color = textObj2.color;
			} 
			
			if (listIdx == curSelected)
				curTextIdx = i;
		}
	}

	dynamic public function onSelect(idx:Int) {
		
	}

	dynamic public function goBack() {
		close();
	}

	override function destroy() {
		super.destroy();
		if (cam != null)
			FlxG.cameras.remove(cam);
	}
}