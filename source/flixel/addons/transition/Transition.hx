package flixel.addons.transition;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;

class Transition extends FlxTypedGroup<FlxBasic>
{
	public var finishCallback:Void->Void;

	private var _created:Bool = false;
	private var _parentState:FlxTransitionableState = null;

	public function create():Void {}

	public function start(status:TransitionStatus):Void {
		finish();
	}

	public function finish():Void {
		if (finishCallback != null) {
			finishCallback();
			finishCallback = null;
		}
	}

	public function close():Void {
		if (_parentState != null && _parentState.transition == this)
			_parentState.closeTransition();
	}
}
