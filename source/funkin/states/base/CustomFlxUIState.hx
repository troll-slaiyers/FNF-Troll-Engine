package funkin.states.base;

#if flixel_ui
import flixel.addons.ui.FlxUICursor;
import flixel.addons.ui.FlxUITooltip;
import flixel.addons.ui.FlxUITooltipManager;
import flixel.addons.ui.interfaces.IEventGetter;
import flixel.addons.ui.interfaces.IFlxUIState;
import flixel.addons.ui.interfaces.IFireTongue;
import flixel.addons.ui.interfaces.IFlxUIWidget;
import flixel.addons.ui.interfaces.IFlxUIButton;

/**
	Not an extension of FlxUIState!
	Just a blank state that implements the ui interfaces to receive ui events, and to add tooltips.
	No flixel-ui xml features because none of the editors use those.  
**/
@:noScripting
class CustomFlxUIState extends MusicBeatState implements IEventGetter implements IFlxUIState {
	public function new() {
		super();
		tooltips = new CustomFlxUITooltipManager();
		@:privateAccess tooltips.tooltip.visible = false;
		tooltips.delay = 0.3;
	}

	override function tryUpdate(elapsed:Float):Void
	{
		super.tryUpdate(elapsed);
		if (tooltips != null) {
			@:privateAccess
			if (tooltips.tooltip != null && tooltips.tooltip.exists && tooltips.tooltip.active)
				tooltips.tooltip.update(elapsed);
			tooltips.update(elapsed);
		}
	}

	override function draw() {
		super.draw();
		@:privateAccess
		if (tooltips?.tooltip != null && tooltips.tooltip.exists && tooltips.tooltip.visible)
			tooltips.tooltip.draw();
	}

	override function destroy():Void
	{
		super.destroy();

		if (tooltips != null) {
			tooltips.destroy();
			tooltips = null;
		}
	}
	
	public function getEvent(name:String, sender:IFlxUIWidget, data:Dynamic, ?params:Array<Dynamic>):Void
	{
		return;
	}

	public function getRequest(name:String, sender:IFlxUIWidget, data:Dynamic, ?params:Array<Dynamic>):Dynamic
	{
		return null;
	}

	public function onShowTooltip(t:FlxUITooltip):Void
	{
		return;
	}

	public function forceFocus(b:Bool, thing:IFlxUIWidget):Void
	{
		return;
	}

	public var tooltips(default, null):FlxUITooltipManager;
	#if FLX_MOUSE
	public var cursor:FlxUICursor;
	#end
	private var _tongue:IFireTongue;
}

private class CustomFlxUITooltipManager extends FlxUITooltipManager {
	override function update(elapsed:Float):Void
	{
		// iterate over all our buttons and watch their states
		for (i in 0...list.length)
		{
			var btn = list[i].btn;
			var obj = list[i].obj;

			if (list[i].enabled == false)
			{
				if (current == i)
				{
					hide(i);
				}
				list[i].count = 0;
				continue;
			}

			if (obj != null)
			{
				btn.x = obj.x;
				btn.y = obj.y;
				btn.width = obj.width;
				btn.height = obj.height;
				btn.visible = obj.visible;
			}

			if (list[i].sticky == false && (false == btn.visible || btn.justMousedOut || btn.mouseIsOut))
			{
				list[i].count = 0;
				hide(i);
			}
			else if (btn.justMousedOver || btn.mouseIsOver)
			{
				if (btn.mouseIsOver)
				{
					list[i].count += elapsed;
				}
			}

			if (list[i].data.delay >= 0 ? (list[i].count > list[i].data.delay) : list[i].count > delay)
			// changed line ^ if the data delay is set, use that instead of the default delay for the tooltip manager
			{
				if (current != i)
				{
					show(i);
				}
				else if (list[i].data.moving)
				{
					show(i);
				}
			}
		}
	}
}
#end
