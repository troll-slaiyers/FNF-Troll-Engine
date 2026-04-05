package funkin.game.events;

class SongEventManager {
	private final eventMap:Map<String, SongEvent> = [];

	public function new() {}

	public function get(id:String):Null<SongEvent> {
		if (exists(id))
			return eventMap[id];

		var event:SongEvent;
		event = ScriptedSongEvent.fromName(id);
		event ??= new DefaultSongEvent(id);

		if (event != null)
			eventMap[id] = event;
			
		return event;
	}

	public function exists(id:String):Bool
		return eventMap.exists(id);

	public function update(elapsed:Float) {
		for (event in eventMap)
			event.update(elapsed);
	}

	public function destroy() {
		for (event in eventMap)
			event.destroy();
		eventMap.clear();
	}
}