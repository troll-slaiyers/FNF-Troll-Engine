package flixel.addons.transition;
// modified by Nebula the Zorua for Andromeda Engine 1.0
// replaces the TransitionData bullshit with substates
// the substate should have a start, setStatus and finishCallback property
// after that, how the substate behaves is up to you.


import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;

class FlxTransitionableState extends FlxState
{
	/** Default intro transition. Used when `transIn` is null **/
	public static var defaultTransIn:Class<Transition> = null;
	/** Default outro transition. Used when `transOut` is null **/
	public static var defaultTransOut:Class<Transition> = null;

	public static var skipNextTransIn:Bool = false;
	public static var skipNextTransOut:Bool = false;

	/** Intro transition to use after switching to this state **/
	public var transIn:Class<Transition>;
	/** Outro transition to use before switching to another state **/
	public var transOut:Class<Transition>;

	public var hasTransIn(get, never):Bool;
	public var hasTransOut(get, never):Bool;

	/** Transition substate **/
	public var transition:Transition;

	////
	var transitionCamera:FlxCamera = null;
	var transOutFinished:Bool = false;

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
		this.transIn = (TransIn == null) ? defaultTransIn : TransIn;
		this.transOut = (TransOut == null) ? defaultTransOut : TransOut;

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
		if (!hasTransOut)
			onOutroComplete();
		else if (!_exiting)
		{
			// play the exit transition, and when it's done call FlxG.switchState
			_exiting = true;
			transitionOut(onOutroComplete);
			
			if (skipNextTransOut)
			{
				skipNextTransOut = false;
				finishTransOut();
			}
		}
	}

	/**
	 * Starts the in-transition. Can be called manually at any time.
	 */
	public function transitionIn():Void
	{
		if (skipNextTransIn || !hasTransIn) {
			skipNextTransIn = false;
			finishTransIn();
			return;
		}

		var transition = Type.createInstance(transIn, []);
		transition.finishCallback = finishTransIn;
		startTransition(transition, IN);
	}

	/**
	 * Starts the out-transition. Can be called manually at any time.
	 */
	public function transitionOut(?OnExit:Void->Void):Void
	{
		_onExit = OnExit;

		if (hasTransOut){
			var transition = Type.createInstance(transOut, []);
			transition.finishCallback = finishTransOut;
			startTransition(transition, OUT);
		}else{
			_onExit();
		}
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

	function get_hasTransIn():Bool
	{
		return transIn != null;
	}

	function get_hasTransOut():Bool
	{
		return transOut != null;
	}

	function finishTransIn()
	{
		if (transition != null)
			transition.close();
	}

	function finishTransOut()
	{
		transOutFinished = true;

		if (!_exiting)
		{
			transition.close();
		}

		if (_onExit != null)
		{
			_onExit();
		}
	}
}
