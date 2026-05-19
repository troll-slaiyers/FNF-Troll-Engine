package funkin.objects;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.FlxSprite;
import flixel.FlxBasic;

class ChangingMenuBG extends FlxTypedGroup<FlxSprite> {
	var curBG:FlxSprite;

	public function fadeToBg(graphic, color:FlxColor) {
		if (curBG != null && curBG.graphic == graphic && curBG.color == color)
			return;

		var prevBG = curBG;
		
		if (this.members.length > 4) {
			curBG = this.members[0];
			curBG.exists = true;
			FlxTween.cancelTweensOf(curBG);

			var sowy = this.members[1];
			sowy.alpha = 1.0;
			FlxTween.cancelTweensOf(sowy);
		}else {
			curBG = this.recycle(FlxSprite, makeBgSprite);
		}
		this.members.remove(curBG);
		this.members.push(curBG);
		
		curBG.loadGraphic(graphic);
		curBG.screenCenter();
		curBG.color = color;
		curBG.alpha = 1.0;

		if (prevBG != null) {
			curBG.alpha = 0.0;
			FlxTween.tween(curBG, {alpha: 1.0}, 0.4, {ease: FlxEase.sineInOut});
		}
	}

	static function makeBgSprite(){
		var spr = new FlxSprite();
		spr.active = false;
		spr.moves = false;
		return spr;
	}
}