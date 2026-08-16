package;

import funkin.*;
import funkin.states.base.MusicBeatState;

import funkin.data.Highscore;
import funkin.input.Controls;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.tweens.*;
import funkin.states.base.TransitionableState;

import DebugLog;

#if sys
import Sys.time as getTime;
#else
import haxe.Timer.stamp as getTime;
#end

#if MULTICORE_LOADING
import sys.thread.Thread;
import sys.thread.Mutex;
#end

#if (CHECK_FOR_UPDATES || display)
import funkin.states.UpdaterState;
#end

using StringTools;

@:structInit
private class ShitToDo {
	public var str:String;
	public var f:Void -> Void;
}

private inline function Run(str:String, f:Void -> Void):ShitToDo {
	return {str: str, f: f};
}

inline final COOLDOWN = 0.16;

class InitState extends TransitionableState
{
	public static var nextState:Class<FlxState> = funkin.states.TitleState;
	private static var loaded = false;

	private var step:Int = 0;
	private var working:Bool = false;
	private var cooldown:Float = COOLDOWN;
	private var loadingTime:Float = 0;
	
	var trollface:FlxSprite;
	var log:DebugLogGroup;
	var bar:FlxSprite;
	var loadTwn:FlxTween = null;

	static final shitToDo:Array<ShitToDo> = [
		Run("Setting up game", function() {
			FNFGame.specialKeysEnabled = true;
			FlxG.keys.preventDefaultKeys = [TAB];
			FlxG.fixedTimestep = false;

			TransitionableState.defaultTransition = funkin.transitions.FadeTransition;
		}),
		Run("Initializing assets", Paths.init),
		Run("Initializing controls", Controls.init),
		Run("Initializing preferences", ClientPrefs.initialize),
		Run("Loading preferences", ClientPrefs.load),
		Run("Loading high scores", Highscore.load),
		#if FUNNY_ALLOWED
		Run("Loading bread", function() {
			var bread = Main.bread;
			bread.bitmapData = Paths.image("Garlic-Bread-PNG-Images").bitmap;
			
			function onGameResize(stageWidth, stageHeight){
				var scaleFactor = stageHeight / FlxG.initialHeight;
				bread.scaleX = scaleFactor;
				bread.scaleY = scaleFactor;
				bread.x = (stageWidth - bread.width) / 2;
				bread.y = (stageHeight - bread.height) / 2;
			}
			
			onGameResize(FlxG.width, FlxG.height);
			FlxG.signals.gameResized.add(onGameResize);
		}),
		#end
		#if (CHECK_FOR_UPDATES || display)
		Run("Checking for updates", function() {
			UpdaterState.getRecentGithubRelease();
			UpdaterState.checkOutOfDate();
			UpdaterState.clearTemps("./");
		}),
		#end
		Run("All done!", () -> {
			goToState();
		}),
	];

	public function new()
	{
		super();
		// this.canBeScripted = false; // vv wait this isnt a musicbeatstate LOL!

		persistentDraw = true;
		persistentUpdate = true;

		this.transIn = null;
		this.transOut = funkin.transitions.FadeTransition;
	}

	override function create()
	{
		super.create();

		#if false
		var bmp = Paths.getBitmapData("assets/images/trollface.png");
		/*
		for (x in 0...bmp.width)
			for (y in 0...bmp.height)
				bmp.setPixel32(x, y, (bmp.getPixel32(x, y):flixel.util.FlxColor).getInverted());
		*/

		trollface = new FlxSprite();
		trollface.loadGraphic(bmp);
		trollface.antialiasing = false;
		trollface.blend = INVERT;
		trollface.screenCenter();
		trollface.alpha = 0.0;
		add(trollface);
		#end
		
		bar = new FlxSprite();
		bar.makeGraphic(1, 1, 0xFFCBFF9B, false);
		bar.scale.set(0, 8);
		bar.updateHitbox();
		bar.origin.x = 0;
		bar.setPosition(0, FlxG.height - bar.height);
		add(bar);

		log = new DebugLogGroup();
		log.lifeTime = 100;
		log.flipY = true;
		add(log);

		for (t in log.members)
			t.color = 0xFFCBFF9B;

		loadingTime = getTime();
	}

	override function update(elapsed:Float) {
		if (cooldown > 0.0) {
			cooldown -= elapsed;
		}
		else if (step < shitToDo.length) {
			doStuff();
		}
		
		super.update(elapsed);
	}

	function doStuff() {
		if (!working) {
			var todo = shitToDo[step];
			trace(todo.str);
			log.addMessage(todo.str);
			working = true;
		}
		else {
			var todo = shitToDo[step];
			todo.f();
			
			step++;
			working = false;

			cooldown = COOLDOWN;
			
			var perc = (1 / shitToDo.length);
			if (loadTwn != null) loadTwn.cancel();
			loadTwn = FlxTween.num(step * perc - perc, step * perc, cooldown, null, (v) -> {
				bar.scale.x = v * FlxG.width;
				#if false
				trollface.alpha = v;
				#end
			});
		}
	}

	static function goToState() {
		#if(CHECK_FOR_UPDATES || display)
		if (Main.outOfDate)
			MusicBeatState.switchState(new UpdaterState(Main.recentRelease)); // UPDATE!!
		else
		#end
		{
			MusicBeatState.switchState(Type.createInstance(nextState, []));
		}
	}
}