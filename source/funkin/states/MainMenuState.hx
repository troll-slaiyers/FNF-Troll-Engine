package funkin.states;

import flixel.util.FlxTimer;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import funkin.states.base.TransitionableState;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import funkin.states.editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;
import funkin.states.base.MusicBeatState.switchState;

using StringTools;

#if DISCORD_ALLOWED
import funkin.api.Discord.DiscordClient;
#end

class MainMenuState extends MusicBeatState
{
	public static var curSelected:Int = 0;

	var optionShit:Array<String> = [
		'storymode',
		'freeplay',
		//'credits',
		//'donate',
		#if MODS_ALLOWED
		'content',
		#end
		'options',
	];

	var menuItems:FlxTypedGroup<FlxSprite>;
	var bg:FlxSprite;
	var magenta:FlxSprite;
	var bgTweenFunction:Float -> Void;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;

	var selectedSomethin:Bool = false;

	public var stateFreeplayTransition:Bool = false;

	override function create()
	{
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence({details: "In the Menus"});
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		persistentUpdate = persistentDraw = true;

		camFollow = new FlxObject();
		camFollowPos = new FlxObject();
		add(camFollow);
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, null, 1);

		////
		var yScroll:Float = Math.max(0.1, 0.25 - (0.05 * (optionShit.length - 4)));
		var bgScale = 1.175;
		
		bg = new FlxSprite(0, 0, Paths.image('menuBG'));
		bg.scrollFactor.set(0, yScroll);
		bg.screenCenter();
		bg.scale.set(bgScale, bgScale);
		add(bg);

		magenta = new FlxSprite(0, 0, Paths.image('menuBGMagenta'));
		magenta.scrollFactor.set(0, yScroll);
		magenta.screenCenter();
		magenta.scale.set(bgScale, bgScale);
		magenta.visible = false;
		add(magenta);

		var bgScale = bg.scale.x;
		var bgTargetScale = 1.0;//Math.max(FlxG.width / bg.frameWidth, FlxG.height / bg.frameHeight);
		var bgScroll = bg.scrollFactor.y;

		bgTweenFunction = function(progress:Float) {
			//var progress = progress / 1.125;

			var scale = FlxMath.lerp(bgScale, bgTargetScale, progress);
			magenta.scale.x = magenta.scale.y = bg.scale.x = bg.scale.y = scale;

			var scroll = FlxMath.lerp(bgScroll, 0.0, progress);
			bg.scrollFactor.y = magenta.scrollFactor.y = scroll;
		}

		////
		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var spacing:Float = 140;
		var offset:Float = 108 - Math.max(optionShit.length - 4, 0) * 80;
		var scr:Float = (optionShit.length < 6) ? 0 : (optionShit.length - 4) * 0.135;
		for (i => optionName in optionShit)
		{
			var menuItem:FlxSprite = new FlxSprite(0, offset + (i * spacing));
			
			menuItem.frames = Paths.sparrowAtlas('mainmenu/$optionName');
			menuItem.animation.addByPrefix('idle', '$optionName idle', 24);
			menuItem.animation.addByPrefix('selected', '$optionName selected', 24);
			menuItem.animation.play('idle');

			menuItem.scrollFactor.set(0, scr);
			menuItem.updateHitbox();
			menuItem.screenCenter(X);

			menuItem.ID = i;
			menuItems.add(menuItem);
		}

		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, 'Troll Engine ' + Main.Version.displayedVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		
		changeItem();

		super.create();

		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
			MusicBeatState.playMenuMusic();

		var curMusicVolume = FlxG.sound.music.volume; 
		if (curMusicVolume < 0.8){
			FlxG.sound.music.fadeIn((0.8 - curMusicVolume) * 2.0, curMusicVolume, 0.8);
		}

		Paths.clearUnusedMemory();
	}

	var magTwn:FlxTween = null;
	var transTwn:FlxTween = null;

	function bgFlicker() {
		magenta.visible = true;
		
		if (ClientPrefs.flashing){
			var loops = Math.floor(1 / 0.24);
			magenta.alpha = 1.0;
			magTwn = FlxTween.tween(magenta, {alpha: 0.0}, 0.12, {
				ease: FlxEase.circIn, 
				type: LOOPING,
				loopDelay: 0.12, 
				onComplete: (twn) -> if (--loops == 0) twn.cancel(),
			});
		}else{
			magenta.alpha = 0.0;
			magTwn = FlxTween.tween(magenta, {alpha: 1.0}, 0.96, {ease: FlxEase.quintOut});
		}
	}

	function onSelected() {		
		var shitToDo:Void -> Void = switch (optionShit[curSelected])
		{
			case 'storymode':
				switchState.bind(new StoryModeState());
			case 'freeplay':
				if (stateFreeplayTransition)
					switchState.bind(new FreeplayState());
				else function() {
					var cam = new FlxCamera();
					FlxG.cameras.add(cam);
					
					var ss = new FreeplayState();
					ss.camera = cam;

					this.persistentUpdate = false;
					openSubState(ss);

					this.subStateClosed.addOnce(_ -> {
						FlxG.cameras.remove(cam);
						undoSelectionTransition();
					});
				}
			case 'donate':
				return CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
			case 'credits':
				switchState.bind(new CreditsState());
			case 'options':
				switchState.bind(new funkin.states.options.OptionsState());
			case 'content':
				switchState.bind(new ContentManagerState());
			default:
				MusicBeatState.resetState.bind();
		}
		doSelectionTransition(shitToDo);
	}

	function doSelectionTransition(shitToDo:Null<Void -> Void>) {
		FlxG.sound.play(Paths.sound('confirmMenu'));

		selectedSomethin = true;

		////
		FlxTween.num(0.0, 1.0, 0.2, {ease: FlxEase.circOut}, bgTweenFunction);

		bgFlicker();

		////
		menuItems.forEach((spr:FlxSprite)->{
			if (curSelected != spr.ID)
				FlxTween.tween(spr, {alpha: 0.0}, 0.25, {ease: FlxEase.quadOut, onComplete: _->spr.kill()});
			else {
				transTwn = FlxTween.flicker(spr, 1, 0.12, {endVisibility: false, onComplete: _ -> shitToDo()});
			}
		});
	}

	function undoSelectionTransition() {
		selectedSomethin = false;

		FlxTween.num(1.0, 0.0, 0.264, {ease: FlxEase.circOut}, bgTweenFunction);

		magenta.alpha = 0.0;
		magenta.visible = false;
		
		menuItems.forEach((spr:FlxSprite)->{
			spr.revive();
			spr.alpha = 0.0;
			spr.visible = true;
			FlxTween.tween(spr, {alpha: 1.0}, 0.25, {ease: FlxEase.quadOut});
		});
	}

	override function update(elapsed:Float)
	{
		var lerpVal:Float = Math.exp(-elapsed * 7.5);
		camFollowPos.setPosition(
			FlxMath.lerp(camFollow.x, camFollowPos.x, lerpVal),
			FlxMath.lerp(camFollow.y, camFollowPos.y, lerpVal)
		);

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
			{
				#if FLX_MOUSE
				FlxG.mouse.visible = false;
				#end
				changeSelection(-1);
			}

			if (controls.UI_DOWN_P)
			{
				#if FLX_MOUSE
				FlxG.mouse.visible = false;
				#end
				changeSelection(1);
			}

			#if FLX_MOUSE
			if (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0)
			{
				FlxG.mouse.visible = true;
				var newIndex = checkMouseOverlap();
				if (newIndex != -1 && newIndex != curSelected)
					changeSelection(newIndex, true);
			}
			#end

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				switchState(new TitleState());
			}
			else if (controls.ACCEPT)
			{
				onSelected();
			}
			#if FLX_MOUSE
			else if (FlxG.mouse.justPressed)
			{
				var newIndex = checkMouseOverlap();
				if (newIndex != -1) {
					if (newIndex != curSelected)
						changeSelection(newIndex, true);
					onSelected();
				}
			}
			#end
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				TransitionableState.skipNextTransOut = true;
				switchState(new MasterEditorMenu());
			}
			#end
		}
		else if (controls.ACCEPT) {
			if (transTwn?.finished == false) {
				transTwn.onComplete(transTwn);
				transTwn.cancel();
				transTwn.destroy();
				transTwn = null;
				if (magTwn != null) {
					magTwn.cancel();
					magTwn.destroy();
					magTwn = null;
				}
			}
		}

		#if FLX_MOUSE
		if (selectedSomethin)
			FlxG.mouse.visible = false;
		#end

		super.update(elapsed);
	}

	function checkMouseOverlap():Int {
		var newIndex:Int = -1;

		#if FLX_MOUSE
		var closestDistance:Float = -1;
		var mousePos = FlxG.mouse.getPositionInCameraView();
		var objBounds = flixel.math.FlxRect.get();
		var objPos = flixel.math.FlxPoint.get();

		for (obj in menuItems) {
			obj.getScreenBounds(objBounds);

			// Check if the mouse overlaps the object
			if (!objBounds.containsPoint(mousePos))
				continue;

			// Get object midpoint
			objPos.set(objBounds.x + objBounds.width * 0.5, objBounds.y + objBounds.height * 0.5);

			var distance = objPos.distanceTo(mousePos);
			if (closestDistance == -1 || distance < closestDistance) {
				newIndex = obj.ID;
				closestDistance = distance;
			}
		}

		mousePos.put();
		objBounds.put();
		objPos.put();
		#end

		return newIndex;
	}

	function changeSelection(value:Int = 0, isAbs:Bool = false)
	{
		var prevSelected = curSelected;

		curSelected = isAbs ? value : CoolUtil.updateIndex(curSelected, value, menuItems.length);

		if (curSelected != prevSelected)
			FlxG.sound.play(Paths.sound('scrollMenu'));

		menuItems.forEach((spr:FlxSprite)->{
			if (spr.ID == curSelected) {
				spr.animation.play('selected');
				spr.centerOffsets();

				var add:Float = (menuItems.length > 4) ? (menuItems.length * 8) : 0;
				var mid = spr.getGraphicMidpoint();
				camFollow.setPosition(mid.x, mid.y - add);
				mid.put();
			}else {
				spr.animation.play('idle');
				spr.updateHitbox();
			}
		});
	}

	#if ALLOW_DEPRECATION
	@:deprecated inline function changeItem(huh:Int = 0)
		changeSelection(huh);
	#end
}