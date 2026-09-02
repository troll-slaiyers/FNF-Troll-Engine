package funkin.objects.ui;

import math.CoolMath;
import flixel.util.FlxColor;

class ScrollBar extends FlxSprite {
	/** How much of the page can be seen on screen **/
	public var viewHeight(default, null):Float;
	/** How big is the page in total **/
	public var pageHeight(default, null):Float;

	/** How far up the bar sprite can go **/
	public var barMinY(get, never):Float;
	/** How far down the bar sprite can go **/
	public var barMaxY(default, null):Float;

	public var barSprite:FlxSprite;
	public var barWidth:Float = 12;

	/** Whether the bar is currently being held **/
	public var holding:Bool = false;

	/** 
		How far the bar has been moved.  
		0 means that the bar is at the top of the page.
		1 means that the bar is at the bottom of the page.
	**/
	public var progress:Float = 0.0;

	/** Called when the bar is dragged **/
	public var callback:(percent:Float) -> Void = null;
	
	/**
		@param x The X position of the scrollbar
		@param y The Y position of the scrollbar
		@param pageHeight The height of the page that is being scrolled through
		@param viewHeight The height of the viewable area that can show the page
		@param barWidth The width of the bar sprite. If left at -1, it will use the width of the provided sprite or the default 12 if no sprite is provided.
		@param sprite A sprite to use for the bar. If left as null, it will use a default gray rectangle.
	**/
	public function new(x:Float = 0.0, y:Float = 0.0, pageHeight:Float, viewHeight:Float, ?barWidth:Float, ?sprite:FlxSprite) {
		super(x, y);
		this.moves = false;
		this.makeGraphic(1, 1);
		this.color = FlxColor.GRAY;
		
		this.barSprite = sprite ??= new FlxSprite().makeGraphic(12, 1);
		this.setPageSize(pageHeight, viewHeight, barWidth);
	}

	public function setPageSize(pageHeight:Float, viewHeight:Float, ?barWidth:Float) {
		this.pageHeight = pageHeight;
		this.viewHeight = viewHeight;

		var viewPercent = (viewHeight / pageHeight);
		if (viewPercent >= 1.0) {
			barSprite.visible = false;
		}else {
			this.barWidth = barWidth ?? barSprite.frameWidth;

			var barHeight = Math.max(viewPercent * viewHeight, viewHeight / 10);

			barSprite.visible = true;
			barSprite.setGraphicSize(barWidth, barHeight);
			barSprite.updateHitbox();

			this.setGraphicSize(barSprite.width, viewHeight);
			this.updateHitbox();

			barMaxY = this.y + viewHeight - barSprite.height;
		}
	}

	////
	override function update(elapsed:Float) {
		if (!barSprite.visible)
			holding = false;
		else if (!holding && FlxG.mouse.justPressed && FlxG.mouse.overlaps(barSprite, barSprite.camera))
			holding = true;
		
		if (holding) {
			if (!FlxG.mouse.pressed)
				holding = false;
			else if (FlxG.mouse.deltaY != 0.0) {
				barSprite.y += FlxG.mouse.deltaY;
				progress = CoolMath.scale(barSprite.y, barMinY, barMaxY, 0, 1);
				progress = CoolMath.boundTo(progress, 0, 1);
				if (callback != null) callback(progress);
			}
		}

		super.update(elapsed);
	}

	override function draw() {
		if (barSprite.visible) {
			super.draw();

			barSprite.x = this.x;
			barSprite.y = CoolMath.scale(progress, 0, 1, barMinY, barMaxY);
			barSprite.cameras = this.cameras;
			barSprite.scrollFactor.copyFrom(this.scrollFactor);
			barSprite.draw();
		}
	}

	override function destroy() {
		barSprite.destroy();
		super.destroy();
	}

	////
	inline function get_barMinY()
		return this.y;
}

class CameraScrollBar extends ScrollBar {

}