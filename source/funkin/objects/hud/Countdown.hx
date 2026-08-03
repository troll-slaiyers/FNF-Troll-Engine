package funkin.objects.hud;

import math.CoolMath;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

import funkin.states.PlayState;
import funkin.scripts.Globals;

/**
 * @author crowplexus
 * Handles Gameplay countdown, also optionally used in the Pause Menu if `ClientPrefs.countUnpause` is set to true.
**/
class Countdown extends FlxBasic {
	public var sprite:Null<FlxSprite>;
	public var sound:Null<FlxSound>;
	public var tween:FlxTween;

	public var introAlts:Array<Null<String>> = ["onyourmarks", 'ready', 'set', 'go'];
	public var introSnds:Array<Null<String>> = ["intro3", 'intro2', 'intro1', 'introGo'];
	public var introSoundsSuffix:String = "";

	public var onTick:(counter:Int)->Void;
	public var onComplete:()->Void;

	/** How many times this countdown has ticked (index) **/
	public var position:Int = 0; // originally swagCounter

	/** Time between ticks in seconds **/
	public var tickDuration:Float = 0.5;

	/** Whether the countdown has reached completion **/
	public var finished:Bool = false;

	/** Time elapsed since the last tick **/
	private var time:Float = 0.0;

	private var game:PlayState;

	public function new(?game:PlayState):Void {
		super();
		this.active = false;
		this.game = game;
		if (game != null)
			this.cameras = [game.camHUD];
	}

	public function start(?tickDuration:Float = -1):Countdown {
		if (this._cameras == null)
			this._cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		this.tickDuration = (tickDuration == -1) ? Conductor.beatLength : tickDuration;
		this.position = 0;
		this.finished = false;
		this.active = true;

		return this;
	}

	public function tick(curPos:Int):Void
	{
		var sprImage:Null<flixel.graphics.FlxGraphic> = Paths.image(introAlts[curPos]);
		if (sprImage != null)
		{
			if (tween != null) deleteTween();
			if (sprite != null) deleteSprite();

			// ↓ I had no idea how to make script calls not weird, so I just did this
			// you might wanna replace it with something else and stuff @crowplexus
			var ret:Dynamic = Globals.Function_Continue;
			if (game != null && game.hudSkinScript != null)
				ret = game.hudSkinScript.call("makeCountdownSprite", [sprImage, curPos]);

			if (ret != Globals.Function_Stop && ret != Globals.Function_Halt)
			{
				// default behaviour, create sprite w/ the specified sprImage
				sprite = new FlxSprite(0, 0, sprImage);
				sprite.scrollFactor.set();
				sprite.cameras = this._cameras;
				sprite.updateHitbox();
				sprite.screenCenter();
			}
			else if (ret is FlxSprite)
			{
				// returned a sprite, so use it as the countdown sprite (use default transition etc)
				sprite = cast ret;
			}

			inline function normalTween() {
				tween = FlxTween.tween(sprite, {alpha: 0.0}, Conductor.beatLength, {
					ease: FlxEase.cubeInOut,
					onComplete: function(twn)
					{
						deleteSprite();
						deleteTween();
					}
				});
			}

			inline function finalTween() {
				var psx = sprite.scale.x;
				var psy = sprite.scale.y; // gangnam style
				sprite.scale.add(0.4 * sprite.scale.x, 0.4 * sprite.scale.y);
				var ssx = sprite.scale.x;
				var ssy = sprite.scale.x;

				var sa = sprite.alpha;
				var sang = sprite.angle;

				inline function twnv(prog:Float, start:Float, end:Float, low:Float, high:Float, ?ease:EaseFunction) {
					if (ease != null) {
						prog = ease(CoolMath.scale(prog, start, end, 0.0, 1.0));
						return CoolMath.scale(prog, 0.0, 1.0, low, high);
					}else {
						return CoolMath.scale(prog, start, end, low, high);
					}
				}

				tween = FlxTween.num(0, 1.5, Conductor.beatLength * 1.5, {onComplete: _ -> {deleteSprite(); deleteTween();}}, v -> {
					if (v < 1.0) {
						sprite.scale.x = twnv(v, 0.0, 1.0, ssx, psx, FlxEase.backIn);
						sprite.scale.y = twnv(v, 0.0, 1.0, ssy, psy, FlxEase.backIn);
					}else {
						sprite.alpha = twnv(v, 1.0, 1.5, sa, 0.0);
						sprite.scale.x = twnv(v, 1.0, 1.5, psx, 0.0);
						sprite.scale.y = twnv(v, 1.0, 1.5, psy, 0.0);
						sprite.angle = twnv(v, 1.0, 3.0, sang, 360.0, FlxEase.smoothStepInOut);
					}
				});
			}

			if (sprite != null)
				(curPos >= introAlts.length-1) ? finalTween() : normalTween();

			if (game != null) {
				game.callOnScripts('onCountdownSpritePost', [sprite, curPos]);
				if (game.hudSkinScript != null)
					game.hudSkinScript.call("onCountdownSpritePost", [sprite, curPos]);
			}
		}

		var soundName:Null<String> = introSnds[curPos];
		if (soundName != null)
		{
			var ret:Dynamic = Globals.Function_Continue;
			if (game != null && game.hudSkinScript != null)
				ret = game.hudSkinScript.call("playCountdownSound", [soundName, introSoundsSuffix, curPos]);

			if (ret != Globals.Function_Stop && ret != Globals.Function_Halt)
			{
				// default behaviour
				var snd:FlxSound = null;
				snd = FlxG.sound.play(Paths.sound(soundName + introSoundsSuffix), 0.6, false, null, true, () ->
				{
					if (sound == snd)
						sound = null;
				});

				if (game != null && game.sndEffect != null)
					snd.effect = game.sndEffect;

				sound = snd;
			}
		}

		if (game != null) {
			game.callOnScripts('onCountdownTick', [curPos]);
			if (game.hudSkinScript != null)
				game.hudSkinScript.call("onCountdownTick", [curPos]);
		}
		if (onTick != null) onTick(curPos);
	}

	public function complete() {
		this.finished = true;
		this.active = false;
		this.position = 0;

		if (onComplete != null) onComplete();
	}

	override public function update(elapsed:Float):Void {
		time += elapsed;

		if (!finished && time >= tickDuration) {
			time -= tickDuration;
			tick(position++);
			
			if (position >= 5)
				complete();
		}

		if (sprite != null) sprite.update(elapsed);
		super.update(elapsed);
	}

	override public function draw():Void {
		if (sprite != null) sprite.draw();
		super.draw();
	}

	override public function destroy():Void {
		deleteTween();
		deleteSprite();
		sound = null;
		position = 0;
		game = null;

		super.destroy();
	}

	function deleteSprite():Void {
		if (sprite != null) {
			sprite.destroy();
			sprite = null;
		}
	}

	function deleteTween():Void {
		if (tween != null) {
			tween.cancel();
			tween.destroy();
			tween = null;
		}
	}
}
