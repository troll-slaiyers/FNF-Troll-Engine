package funkin.transitions;

import flixel.FlxBasic;
import flixel.group.FlxGroup;

class Transition extends FlxTypedGroup<FlxBasic>
{
	public var finishCallback:Void->Void;

	private var _created:Bool = false;
	private var _parentState:TransitionableState = null;

	/**
		Override this function to create objects that will be used in your transition.
	**/
	public function create():Void {}

	/**
		Override this function to start your transition. Make sure to call `finish()` when the transition is done!
	**/
	public function start(status:TransitionStatus):Void {
		finish();
	}

	/**
		Call this function when the transition is done
	**/
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

enum abstract TransitionStatus(Int)
{
	var NULL = -1;
	var IN = 0;
	var OUT = 1;
}