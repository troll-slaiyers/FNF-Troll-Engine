package funkin.objects;

import funkin.data.StageData;
import flixel.system.FlxAssets.FlxGraphicAsset;

#if USING_FLXANIMATE
import animate.FlxAnimate;
import animate.FlxAnimateFrames;
#end

class StageProp extends FlxSprite {
	public var canDance:Bool = true;
	public var bopTime:Float = 0;
	public var idleSequence:Array<String> = ['idle'];
	public var offsets:Map<String, Array<Float>> = [];
	public var interruptDanceAnims:Array<String> = [];

	var sequenceIndex:Int = 0;

	var nextDanceBeat:Float = 0;

	override public function new(?x:Float, ?y:Float, ?graphic:FlxGraphicAsset) {
		nextDanceBeat = Conductor.curDecBeat;
		super(x, y, graphic);
	}

	public function dance() {
		if (!canDance || animation.curAnim != null && interruptDanceAnims.contains(animation.curAnim.name)) 
			return;
		

		sequenceIndex++;
		if (sequenceIndex >= idleSequence.length)
			sequenceIndex = 0;

		playAnim(idleSequence[sequenceIndex], true);
	}

	public function playAnim(animName:String, forced:Bool, reversed:Bool = false, frame:Int = 0) {
		animation.play(animName, forced, reversed, frame);
		var theOffset = offsets.get(animName) ?? [0, 0];
		offset.set(theOffset[0], theOffset[1]);
	}

	override function update(elapsed:Float) {
		if (bopTime > 0) {
			while (Conductor.curDecBeat >= nextDanceBeat) {
				nextDanceBeat += bopTime;
				dance();
			}
		} else
			nextDanceBeat = Conductor.curBeat;

		super.update(elapsed);
	}

	public static function buildFromData(propData:StagePropData) {
		var prop:StageProp = new StageProp(propData.x ?? 0.0, propData.y ?? 0.0);

		#if (USING_FLXANIMATE && false)
		if (Paths.fileExists('images/${propData.graphic}/Animation.json', TEXT))
			prop.frames = FlxAnimateFrames.fromAnimate(Paths.animateAtlasPath(propData.graphic));
		else
		#end
		if (Paths.fileExists('images/${propData.graphic}.txt', TEXT))
			prop.frames = Paths.packerAtlas(propData.graphic);
		else if (Paths.fileExists('images/${propData.graphic}.xml', TEXT))
			prop.frames = Paths.sparrowAtlas(propData.graphic);
		else
			prop.loadGraphic(Paths.image(propData.graphic));

		if (propData.scale != null)
			prop.scale.set(propData.scale[0], propData.scale[1]);
		prop.updateHitbox();

		// TODO: allow FlxAnimate and multisparrow
		if (propData.animations != null) {
			for (animation in propData.animations) {
				if (animation.indices != null)
					prop.animation.addByIndices(animation.name, animation.prefix, animation.indices, '', animation.fps ?? 24, animation.looped ?? false,
						animation?.flipX ?? false, animation?.flipY ?? false);
				else
					prop.animation.addByPrefix(animation.name, animation.prefix, animation.fps ?? 24, animation.looped ?? false, animation?.flipX ?? false, animation?.flipY ?? false);

				if (animation.offset != null && animation.offset.length == 2)
					prop.offsets.set(animation.name, animation.offset);

				if (animation.haltsDancing == true)
					prop.interruptDanceAnims.push(animation.name);
				
				if (prop.animation.curAnim == null)
					prop.playAnim(animation.name, true);
			}
		}

		if (propData.antialiasing != null)
			prop.antialiasing = propData.antialiasing; // if null then dont set, because default antialiasing should be affecting it

		if (propData.danceSequence != null)
			prop.idleSequence = propData.danceSequence;

		if (propData.danceBeat != null) {
			prop.bopTime = propData.danceBeat;
			prop.playAnim(prop.idleSequence[0], true);
		}

		prop.alpha = propData?.alpha ?? 1.0;
		prop.flipX = propData?.flipX ?? false;
		prop.flipY = propData?.flipY ?? false;

		if(propData.scrollFactor != null)
			prop.scrollFactor.set(propData.scrollFactor[0], propData.scrollFactor[1]);

		prop.antialiasing = propData?.antialiasing ?? false;

		return prop;
	}
}