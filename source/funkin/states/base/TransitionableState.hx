package funkin.states.base;
// modified by Nebula the Zorua for Andromeda Engine 1.0
// replaces the TransitionData bullshit with substates
// the substate should have a start, setStatus and finishCallback property
// after that, how the substate behaves is up to you.

// modified by riconuts for Troll Engine 0.3
// replaces the substate bullshit with a custom Transition class
// custom transitions should override the create and start methods, then call finish when they're done.

import flixel.FlxState;
import funkin.transitions.Transition;

class TransitionableState extends FlxState
{
	public static var defaultTransition:Class<Transition> = null;

	public static var skipNextTransIn:Bool = false;
	public static var skipNextTransOut:Bool = false;

	/** Intro transition to use after switching to this state **/
	public var transIn:Class<Transition>;
	/** Outro transition to use before switching to another state **/
	public var transOut:Class<Transition>;

	/** Transition instance **/
	public var transition:Transition = null;

	////
	var transitionCamera:FlxCamera = null;

	static var _lastTransition:Transition = null;

	var _requestedTransition:Transition;
	var _requestTransitionReset:Bool;
	var _requestedTransitionStatus:TransitionStatus;

	var _exiting:Bool = false;
	var _onExit:Void->Void;

	////

	/**
	 * Create a state with the ability to do visual transitions
	 * @param	TransIn		Plays when the state begins
	 * @param	TransOut	Plays when the state ends
	 */
	public function new(?TransIn:Class<Transition>, ?TransOut:Class<Transition>)
	{
		this.transIn = TransIn ?? defaultTransition;
		this.transOut = TransOut ?? defaultTransition;

		super();
	}

	override public function destroy():Void
	{
		closeTransition();
		super.destroy();
		transIn = null;
		transOut = null;
		_onExit = null;
	}

	override public function create():Void
	{
		super.create();
		transitionIn();
	}

	override function tryUpdate(elapsed:Float)
	{
		if (persistentUpdate || transition == null)
			super.tryUpdate(elapsed);
		
		if (_requestTransitionReset)
		{
			_requestTransitionReset = false;
			resetTransition();
		}
		if (transition != null)
		{
			transition.update(elapsed);
		}
	}

	override function draw():Void
	{
		super.draw();

		if (transition != null)
			transition.draw();
	}

	override function startOutro(onOutroComplete:() -> Void)
	{
		// play the exit transition, and when it's done call FlxG.switchState
		_exiting = true;
		transitionOut(onOutroComplete);
	}

	/**
	 * Starts the in-transition. Can be called manually at any time.
	 */
	public function transitionIn():Void
	{
		if (skipNextTransIn || transIn == null) {
			skipNextTransIn = false;
			finishTransIn();
			return;
		}

		_startTransition(transIn, IN, finishTransIn);
	}

	/**
	 * Starts the out-transition. Can be called manually at any time.
	 */
	public function transitionOut(?OnExit:Void->Void):Void
	{
		_onExit = OnExit;

		if (skipNextTransOut || transOut == null) {
			skipNextTransOut = false;
			finishTransOut();
			return;
		}

		_startTransition(transOut, OUT, finishTransOut);
	}

	function _startTransition(cl:Class<Transition>, status:TransitionStatus, onComplete:Void->Void) {
		if (!_lastTransition?.exists || !Std.isOfType(_lastTransition, cl)) {
			_lastTransition?.destroy(); // just in case
			_lastTransition = Type.createInstance(cl, []);
		}else {
			// Prevent resetTransition from nuking the current transition
			if (transition == _lastTransition)
				transition = null;
		}

		_lastTransition.finishCallback = onComplete;
		startTransition(_lastTransition, status);
	}

	public function startTransition(requestedTrans:Transition, status:TransitionStatus)
	{
		_requestedTransition = requestedTrans;
		_requestedTransitionStatus = status;	
		_requestTransitionReset = true;
	}

	public function closeTransition()
	{
		_requestedTransition = null;
		_requestedTransitionStatus = NULL;
		_requestTransitionReset = true;
	}

	public function resetTransition()
	{
		// Close the old state (if there is an old state)
		if (transition != null) {
			transition.destroy();
			transition = null;
		}

		if (transitionCamera != null) {
			FlxG.cameras.remove(transitionCamera, true);
			transitionCamera = null;
		}

		// Assign the requested state (or set it to null)
		transition = _requestedTransition;
		_requestedTransition = null;

		@:privateAccess
		if (transition != null) {
			transition._parentState = this;
			transition.camera = getTransCamera();

			if (!transition._created)
			{
				transition._created = true;
				transition.create();
			}

			transition.start(_requestedTransitionStatus);
		}
	}

	function getTransCamera() {
		//return FlxG.cameras.list[FlxG.cameras.list.length-1];
		return transitionCamera ??= makeTransCamera();
	}

	function makeTransCamera() {
		var camera = new FlxCamera();
		camera.bgColor = 0;
		FlxG.cameras.add(camera, false);
		return camera;
	}

	function finishTransIn()
	{
		if (transition != null)
			transition.close();
	}

	function finishTransOut()
	{
		if (transition != null && !_exiting)
		{
			transition.close();
		}

		if (_onExit != null)
		{
			_onExit();
		}
	}
}