package funkin.objects.cutscenes;

import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.tweens.FlxTween;

/**
	Base cutscene class
**/
class Cutscene extends FlxTypedGroup<FlxBasic> {
	public var onEnd:FlxTypedSignal<(wasSkipped:Bool) -> Void> = new FlxTypedSignal();
	public var sounds:Array<FlxSound> = [];
	public var music:FlxSound;

	// TODO: could use bit-shift bullshit and enums or sum shit lmao
	// though thats overcomplicating it so 3 bools it is
	//// yea don't do that '_'

	/** Whether the pause menu can be opened during this cutscene **/
	public var canPause:Bool = true;
	/** Whether this cutscene can be skipped through the cutscene pause menu  **/
	public var canSkip:Bool = true;
	/** Whether this cutscene can be restarted through the cutscene pause menu **/
	public var canRestart:Bool = true;

	public function new() {
		super();
		onEnd.addOnce((_:Bool) -> {
			clearSounds();
		});
	}

	/** 
	 * Called by the state before this Cutscene gets played.  
	 * Override this function, NOT the constructor, to initialize or set up your Cutscene.
	**/
	public function createCutscene():Void {
		return;
	}

	public function pause():Void {
		for (s in sounds)
			s.pause();
	}

	public function resume():Void {
		for (s in sounds)
			s.resume();
	}

	public function restart():Void {
		clearSounds();
	}

	////
	public function newSound(path:String, obeysPitch:Bool = true):FlxSound {
		var newSound = new FlxSound().loadEmbedded(Paths.sound(path));
		newSound.exists = true;
		if (obeysPitch)
			newSound.pitch = FlxG.timeScale;

		FlxG.sound.list.add(newSound);
		sounds.push(newSound);
		return newSound;
	}

	public function playMusic(path:FlxSoundAsset, volume:Float = 1, fadeIn:Float = 0, fadeOut:Float = 0.25):FlxSound {
		if (music != null) {
			if (fadeOut > 0) {
				var oldMusic:FlxSound = music;
				music.fadeOut(fadeOut, 0, (twn:FlxTween)->{
					oldMusic.stop();
					FlxG.sound.list.remove(oldMusic);
					sounds.remove(oldMusic);

					oldMusic.destroy();
				});
				music = new FlxSound();
			}
		}else {
			music = new FlxSound();
		}

		FlxG.sound.list.add(music);
		if(!sounds.contains(music))
			sounds.push(music);

		music.stop();
		music.context = MUSIC;
		music.loadEmbedded(path, true);
		music.volume = volume;
		music.play(true);
		if (fadeIn > 0)
			music.fadeIn(fadeIn, 0, volume);

		return music;
	}

	function clearSounds():Void
	{
		for (s in sounds) {
			FlxG.sound.list.remove(s);
			s.destroy();
		}
		sounds.resize(0);
	}
}