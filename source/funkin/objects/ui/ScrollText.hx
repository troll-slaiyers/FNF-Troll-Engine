package funkin.objects.ui;

import flixel.text.FlxText;
import flixel.math.FlxRect;
import math.CoolMath;

class ScrollText extends FlxText {
	public var minY:Float = 32;
	public var maxY:Float = FlxG.height - 32;
	public var viewHeight(get, never):Float;

	public var bg:FlxSprite;
	public var scrollBar:FlxSprite;

	override public function new(x:Float, y:Float, fw:Float) {
		bg = new FlxSprite().makeGraphic(1, 1);
		bg.exists = false;

		scrollBar = new FlxSprite().makeGraphic(1, 1);
		scrollBar.scale.x = 12;

		super(x, y, fw);
	}

	override function graphicLoaded() {
		super.graphicLoaded();
	}
	
	override function update(elapsed:Float) {
		bg.update(elapsed);
		super.update(elapsed);
		scrollBar.update(elapsed);
		
		final viewHeight = viewHeight;
		final canScroll = viewHeight < (this.frameHeight * this.scale.y);

		if (canScroll) {
			if (FlxG.mouse.wheel != 0 && (FlxG.mouse.overlaps(this) || FlxG.mouse.overlaps(scrollBar))) 
				this.y += FlxG.mouse.wheel * this.size;
			
			if (FlxG.keys.pressed.PAGEUP)
				this.y += elapsed * viewHeight;
			if (FlxG.keys.pressed.PAGEDOWN)
				this.y -= elapsed * viewHeight;
		}
		
		scrollBar.exists = canScroll;
		if (scrollBar.exists) {
			scrollBar.scale.y = viewHeight * (viewHeight / this.height);
			scrollBar.updateHitbox();
			
			var hovering = FlxG.mouse.overlaps(scrollBar);
			if (hovering && FlxG.mouse.justPressed)
				scrollBar.active = true;

			scrollBar.color = (hovering || scrollBar.active) ? 0xFFFFFFFF : 0xFF999999;
			
			if (scrollBar.active) {
				if (FlxG.mouse.pressed) {
					scrollBar.y += FlxG.mouse.deltaY;
					final maxSprY = maxY - this.height;
					final minSprY = minY;		
					final minBarY = minY;
					final maxBarY = maxY - scrollBar.height;
					this.y = CoolMath.scale(scrollBar.y, minBarY, maxBarY, minSprY, maxSprY);
				}else {
					scrollBar.active = false;
				}
			}
		}
		
		if (canScroll)
			this.y = CoolMath.boundTo(this.y, maxY - this.height, minY);
		else
			this.y = minY;
	}
	
	override function draw() {
		if (bg.exists && bg.visible) {
			bg.setPosition(this.x, minY);
			bg.setGraphicSize(this.width, viewHeight);
			bg.updateHitbox();
			bg.scrollFactor.copyFrom(this.scrollFactor);
			bg.draw();
		}

		{
			var rect = this.clipRect ?? new FlxRect();
			var bottom = this.y + this.height;
			
			rect.set(0, 0, this.width, this.height);
			rect.y = Math.max(0.0, minY - this.y);
			rect.height = this.height - (bottom - maxY) - rect.y;
			
			this.clipRect = rect;
			super.draw();
		}
		
		if (scrollBar.exists && scrollBar.visible) {
			// this.y when you reach the bottom
			final maxSprY = maxY - this.height;
			// this.y when you're at the beggining
			final minSprY = minY;
		
			// bar.y when you're at the beggining
			final minBarY = minY;
			// bar.y when you reach the bottom
			final maxBarY = maxY - scrollBar.height;
		
			scrollBar.x = this.x + this.width + 2;
			scrollBar.y = CoolMath.scale(this.y, minSprY, maxSprY, minBarY, maxBarY);
			scrollBar.y = CoolMath.boundTo(scrollBar.y, minBarY, maxBarY);
			scrollBar.draw();
		}
	}

	override function destroy() {
		super.destroy();
		bg.destroy();
		scrollBar.destroy();
	}

	inline function get_viewHeight() return maxY - minY;
}