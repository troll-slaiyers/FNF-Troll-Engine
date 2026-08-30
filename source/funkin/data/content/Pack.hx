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

	/** 
		List of pack id's that this pack depends on.  
		Will throw an error if any of the dependencies aren't loaded when this pack is loaded.
	**/
	public var dependencies:Array<String> = [];

	public var metadata:PackMetadata = {};

	public final extraData = new Map<String, Dynamic>();

	/** 
		Whether this pack has been successfully loaded by `PackManager`.  
		If an error occured, this will be false and the error will be stored in `loadException`.
	**/
	@:allow(funkin.data.content)
	private var active:Bool = false;

	/** If this pack threw an exception during loading, it will be stored here. **/
	public var loadException:String = '';

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
	public function getSongs():Array<Song>
		return [];

	/** Returns a list of songs to be displayed in the freeplay menus **/
	public function getFreeplaySongs():Array<Song>
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
	/**
		This mod will always run, regardless of whether it's currently being played or not.
		(Custom HUDs, etc, will find this useful, as you can have stuff run across every song without adding to the global folder)
	**/
	@:optional var runsGlobally:Bool;
	
	/** Content that will load before this content. **/
	@:optional var dependencies:Array<String>;
	
	/** API Version **/
	@:optional var trollEngine:String;

	@:optional var title:String;
	@:optional var description:String;
	@:optional var author:String;

	@:optional var accentColor:FlxColor;
	@:optional var bgColor:FlxColor;
}