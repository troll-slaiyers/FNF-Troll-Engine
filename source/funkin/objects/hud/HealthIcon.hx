package funkin.objects.hud;

import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxFramesCollection;
import funkin.data.CharacterData.AnimArray;
import funkin.states.editors.ChartingState;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.FlxGraphic;
import flixel.FlxSprite;

using StringTools;

class HealthIcon extends FlxSprite
{
	public var autoUpdatesAnims:Bool = true;

	public var sprTracker:FlxObject;
	private var isOldIcon:Bool = false;
	private var isPlayer:Bool = false;
	public var char:String = '';
	public var baseScale:Float = 1.0;
	public var baseOffset:FlxPoint = FlxPoint.get();

	public var relativePercent(default, set):Float = 0;

	function set_relativePercent(percent:Float){
		if (autoUpdatesAnims)
			updateState(percent);
		
		return relativePercent = percent;
	}

	public var losingPercent:Float = 20;
	public var winningPercent:Float = 80;

	// Done to allow more customization by simply extending HealthIcon
	// Can also be used by scripts to do stuff w/ health icons
	// I.e adding transitions between animations
	
	public function getAnimation(relativePercent:Float){
		if (relativePercent <= losingPercent)
			return 'losing';
		else if(relativePercent >= winningPercent)
			return 'winning';

		return 'idle';

	}
	
	public function updateState(relativePercent:Float){
		var animationName = getAnimation(relativePercent);
		if (animation.name != animationName)
			animation.play(animationName);
	}

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		this.isPlayer = isPlayer;

		changeIcon(char);

		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	
		super.update(elapsed);
	}

	override function draw()
	{
		var ox:Float = baseOffset.x * scale.x * (flipX ? -1 : 1);
		var oy:Float = baseOffset.y * scale.y * (flipY ? -1 : 1);
		offset.subtract(ox, oy);
		super.draw();
		offset.add(ox, oy);
	}

	override function destroy()
	{
		baseOffset.put();
		super.destroy();
	}

	/** @returns Whether the image was properly set up **/
	function setupImage(key:String, addDefaultAnims:Bool = true):Bool
	{
		var allowGPU:Bool = !(FlxG.state is ChartingState);

		var atlasFrames = Paths.sparrowAtlas(key, null, allowGPU);
		if (atlasFrames != null) {
			frames = atlasFrames;

			if (addDefaultAnims) {
				animation.addByPrefix("idle", "idle", 24, false, isPlayer);
				animation.addByPrefix("losing", "losing", 24, false, isPlayer);
				animation.addByPrefix("winning", "winning", 24, false, isPlayer);
			}

			animation.play('idle');
			return true;
		}

		var graphic = Paths.image(key, null, allowGPU);
		if (graphic != null) {
			var iSize:Float = Math.round(graphic.width / graphic.height);
			loadGraphic(graphic, true, Math.floor(graphic.width / iSize), Math.floor(graphic.height));
			
			if (addDefaultAnims) {
				for (i in 0...frames.frames.length) {
					var anim = switch(i) {
						case 0: "idle";
						case 1: "losing";
						case 2: "winning";
						default: break;
					}
					animation.add(anim, [i], 0, false, isPlayer);
				}
			}
			animation.play('idle');
			return true;
		}
		
		return false;
	}

	function setupFromData(data:HealthIconData)
	{
		setupImage("icons/" + data.image);
		antialiasing = !data.no_antialiasing;

		baseScale = data.scale ?? 1.0;
		scale.set(baseScale, baseScale);

		if (data.offset != null)
			baseOffset.set(data.offset[0], data.offset[1]);
		else
			baseOffset.set();
	}

	public function swapOldIcon() 
	{
		if (!isOldIcon){
			if (setupImage('icons/$char-old')) {
				isOldIcon = true;
			}
		}else {
			changeIcon(char);
			isOldIcon = false;
		}
	}

	public function changeIcon(char:String) {
		this.char = char;
		this.isOldIcon = false;
		setupImage('icons/$char') || setupImage('icons/face');
		antialiasing = !char.endsWith("-pixel");
		scale.set(1.0, 1.0);
		baseOffset.set();
	}

	public function getCharacter():String {
		return char;
	}
}

typedef HealthIconData = {
	var image:String;
	@:optional var no_antialiasing:Bool;
	@:optional var scale:Float;
	@:optional var flipX:Bool;
	@:optional var offset:Array<Float>;
	//var animations:Array<AnimArray>;
}