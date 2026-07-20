package funkin.objects;

/**
	An FlxTV is a sprite that makes a camera to be rendered on it.
**/
class FlxTV extends FlxSprite {
	public final feedcamera:FlxTVCamera;

	public function new(x:Float = 0.0, y:Float = 0.0, cameraWidth:Int = 0, cameraHeight:Int = 0, addDefaultTarget:Bool = true) {
		super(x, y);
		this.makeGraphic(cameraWidth, cameraHeight, 0xFF000000, true);

		feedcamera = new FlxTVCamera(this, cameraWidth, cameraHeight, addDefaultTarget);
	}
}

private class FlxTVCamera extends FlxCamera {
	var tvSprite:FlxTV;

	public function new(tvSprite, cameraWidth = 0, cameraHeight = 0, addDefaultTarget = true) {
		this.tvSprite = tvSprite;
		super(123456, 1234567, cameraWidth, cameraHeight);
		setupFlxCamera(addDefaultTarget);
	}

	public function setupFlxCamera(addDefaultTarget:Bool = true) @:privateAccess {
		//FlxG.cameras.add(this, true);
		FlxG.cameras.list.insert(0, this); // inserting at the start of the list so it renders before any other camera
		if (addDefaultTarget)
			FlxG.cameras.defaults.push(this);
	}
	
	override function render() @:privateAccess {
		super.render();
		//tvSprite.pixels.__resize(Math.ceil(this.canvas.width), Math.ceil(this.canvas.height));
		tvSprite.pixels.draw(this.canvas);
	}

	override function destroy() @:privateAccess {
		super.destroy();
		FlxG.cameras.remove(this, false);
	}
}