package funkin.game.events;

import funkin.scripts.Globals;

using StringTools;

/*
	Song event classes to be used by PlayState only!!!
	TODO: get rid of that psych value1 value2 bs!!!
	Might make a json for the description, event data structure definition, maybe support to change chart editor icon? lmao 
	Will be handled by a diff class tho (SongEventData), don't want to pozz this class, it should be for PlayState shit only!
*/
class SongEvent {
	public final id:String;

	private function new(id:String)
		this.id = id;

	public function onLoad():Void {}

	/**
		@returns Whether this event data should be pushed into the events list or not.
	**/
	public function shouldPush(data:EventData):Bool return true;

	/**
		@returns Offset time in milliseconds, how much earlier should this event be triggered.
	**/
	public function getOffset(data:EventData):Float return 0.0;

	/** 
		Called for every event data with this `SongEvent`'s `id`.  
		@param data Event data
	**/
	public function onPush(data:EventData):Void {}

	public function onTrigger(data:EventData, ?time:Float):Void {}

	public function update(elapsed:Float):Void {}

	public function destroy():Void {}
}