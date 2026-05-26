package funkin.objects.hud;

import flixel.math.FlxAngle.TO_RAD;
import flixel.text.FlxText;

class BotplayText extends FlxText
{
	public var sineProgress:Float = Math.PI; // 0.0 alpha
	public var sineSpeed:Float = 180 * TO_RAD;

	public function new(){
		super(0, (ClientPrefs.downScroll ? (FlxG.height - 107) : 89), FlxG.width, Paths.getString("botplayMark"), 32);
		this.setFormat(Paths.font("vcr.ttf"), 32, 0xFFFFFFFF, CENTER);
		this.setBorderStyle(OUTLINE, 0xFF000000, 1.25);
		this.scrollFactor.set();
	}

	override function update(elapsed:Float) {
		if (PlayState.instance.cpuControlled)
			sineProgress += sineSpeed * elapsed;
		else
			sineProgress = Math.PI;
		
		super.update(elapsed);
	}

	override function draw(){
		if (PlayState.instance.cpuControlled) {
			alpha = (1.0 + Math.cos(sineProgress)) * 0.5;
			super.draw();
		}
	}
}