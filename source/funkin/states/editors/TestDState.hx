package funkin.states.editors;

import funkin.objects.cutscenes.DialogueBox;
import funkin.states.TitleState;

// dialogue test state
class TestDState extends MusicBeatState {
	public var box:DialogueBox;
	public var dialogue:String;

	var ended:Bool = false;

	public function new() {
		super();
		this.dialogue = 'data/testdialogue.json';
	}

	override function create() {
		box = new DialogueBox(dialogue);
		add(box);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (controls.ACCEPT && !ended) {
			box.progress();

			if (box.curLine >= box.dialogueFile.dialogue.length) {
				ended = true;
				MusicBeatState.switchState(new TitleState());

				return;
			}
		}
	}
}
