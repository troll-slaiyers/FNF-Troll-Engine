package funkin.data.content;

import funkin.data.content.PackManager;
import flixel.util.FlxColor;

class Pack {
	/** Internal ID used by the engine **/
	public final id:String;

	/** Path to this content folder **/
	public final path:String;

	/** Whether assets from this folder can be loaded regardless of it being the currently played mod **/
	public var runsGlobally:Bool = false;

	public var dependencies:Array<String> = [];

	public var metadata:PackMetadata = {};

	public final extraData = new Map<String, Dynamic>();

	@:access(funkin.data.content.PackManager)
	private var active(default, default):Bool = false;

	public function new(id:String, path:String) {
		this.id = id;
		this.path = path;
	}

	public function toString():String
		return id;

	public function load():Void
		return;
	
	public function unload():Void
		return;

	/** 
		Switches to this mod's initial state.  
		`funkin.states.TitleState` by default.
	**/
	public function launch():Void {
		Paths.currentPackId = this.id;
		funkin.states.TitleState.initialized = false;
		funkin.states.base.MusicBeatState.switchState(new funkin.states.TitleState());
	}

	public inline function getPath(key:String):String
		return '$path/$key'; 

	/** Returns a list EVERY song belonging to this AssetFolder **/
	public function getSongs():Array<BaseSong>
		return [];

	/** Returns a list of songs to be displayed in the freeplay menus **/
	public function getFreeplaySongs():Array<BaseSong>
		return [];

	/** Returns a list of levels to be displayed in the story mode menus**/
	public function getStoryModeLevels():Array<Level>
		return [];

	/** Returns a list of credits to be used by CreditsSubstate **/
	public function getCredits():Array<CreditsOption>
		return [];

	/** Used by TitleState, returns a list of stages that can be picked for the title screen **/
	public function getTitleStages():Array<String>
		return [];

	/*
	public function getOptions():Array<String>
		return [];

	public function getWebsite():Null<String>
		return null;
	
	public function getRepo():funkin.api.Github.RepoInfo
		return null;
	*/
}

typedef PackMetadata = {
	@:optional var title:String;
	@:optional var description:String;
	@:optional var author:String;

	@:optional var accentColor:FlxColor;
	@:optional var bgColor:FlxColor;
}