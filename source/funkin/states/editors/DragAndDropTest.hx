package funkin.states.editors;

import lime.app.Event;

class DragAndDropTest extends MusicBeatState {
	private var eventHolder:Event<String -> Void>;

	override function create() {
		super.create();
		FlxG.mouse.visible = true;

		eventHolder = FlxG.stage.window.onDropFile;
		eventHolder.add(onDropFile);
	}

	function onDropFile(filePath:String) {
		trace("Dropped file: " + filePath);
	}

	override function destroy() {
		eventHolder.remove(onDropFile);
		super.destroy();
	}
}