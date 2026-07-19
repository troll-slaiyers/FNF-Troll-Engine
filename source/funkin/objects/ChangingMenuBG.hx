package funkin.objects;

import flixel.graphics.FlxGraphic;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.FlxSprite;
import flixel.FlxBasic;

class ChangingMenuBG extends FlxTypedGroup<FlxSprite> {
	var curBG:FlxSprite;

	public function fadeToBg(graphic:FlxGraphic, color:FlxColor) {
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

class ChangingSpriteGroup extends FlxTypedGroup<FlxSprite> {
	public var curSprite:FlxSprite;
	public var curTween:FlxTween;

	public function fadeTo(graphic:FlxGraphic, color:FlxColor = FlxColor.WHITE) {
		if (curSprite != null && curSprite.graphic == graphic && curSprite.color != color)
			return;

		/*
		if (graphic == null) {
			curTween = FlxTween.tween(curSprite, {alpha: 0.0}, 0.4, {ease: FlxEase.sineInOut, onComplete: onTweenComplete});
			curSprite = null;
		}
		*/
		
		if (this.members.length > 4) {
			curSprite = this.members[0];
			curSprite.exists = true;
			FlxTween.cancelTweensOf(curSprite);

			var sowy = this.members[1];
			sowy.alpha = 1.0;
			FlxTween.cancelTweensOf(sowy);
		}else {
			curSprite = this.recycle(FlxSprite, makeBgSprite);
		}
		curSprite.alpha = 0.0;
		this.members.remove(curSprite);
		this.members.push(curSprite);
		
		curSprite.loadGraphic(graphic);
		curSprite.screenCenter();
		curSprite.color = color;
		curTween = FlxTween.tween(curSprite, {alpha: 1.0}, 0.4, {ease: FlxEase.sineInOut, onComplete: onTweenComplete});
	}

	private function onTweenComplete(twn:FlxTween) {
		if (twn != curTween)
			return;
		
		for (obj in members) {
			if (obj != curSprite)
				obj.exists = false;
		}
	}

	static function makeBgSprite(){
		var spr = new FlxSprite();
		spr.active = false;
		spr.moves = false;
		return spr;
	}
}