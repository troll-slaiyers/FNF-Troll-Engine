package funkin.transitions;

import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

class FadeTransition extends Transition
{
	override public function start(status:TransitionStatus)
	{
		var zoom:Float = camera.zoom;
		var width:Float = camera.width / zoom;
		var height:Float = camera.height / zoom;

		var gradient = new FlxSprite();
		gradient.makeGraphic(1, 4, 0xFF000000, true, "FadeTransitionSprite");
		gradient.pixels.setPixel32(0,0,0);
		gradient.pixels.setPixel32(0,1,0);
		//gradient.antialiasing = true;
		gradient.setGraphicSize(width + 4, height * 3);
		gradient.updateHitbox();
		gradient.screenCenter(X);
		gradient.y = height * -2;
		add(gradient);

		var duration:Float = .48;

		//trace('transitioning $status');
		switch(status){
			case IN:
				duration = 0.6;
			case OUT:
				gradient.flipY = true;
			default:
				//trace("bruh");
		}

		FlxTween.tween(gradient, {y: 0}, duration, {
			onComplete: function(t:FlxTween){
				new FlxTimer().start(0.0, _ -> finish()); // force one last render call before exiting
			}
		});
	}
}