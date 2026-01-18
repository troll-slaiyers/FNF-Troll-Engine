package funkin.objects.notes;

/**
 * Contains data for animations for a specific keycount.
 * Keycounts divisible by that keycount are wrapped around.
 */
@:publicFields
@:structInit
class NoteAnimation {
	// Note animations.
	var noteAnimations:Array<String>;
	var holdAnimations:Array<String>;
	var tailAnimations:Array<String>;
	// Strum animations.
    var staticAnimations:Array<String>;
    var pressAnimations:Array<String>;
    var confirmAnimations:Array<String>;

    static var current:NoteAnimation = null;

   	public static function refreshKeyAnimations(count:Int = 4) {
        Note.spriteScale = Note.spriteScales[count - 1];
		Note.swagWidth = Note.spriteScale * 160;

       	final halfKeyCount:Int = Math.floor(count / 2);
       	final keyCountFloor:Int = halfKeyCount * 2;

       	if (keyCountFloor % 6 == 0) {
       		current = CoolUtil.copyClass(NoteAnimations.sixKey);
        } else if(keyCountFloor % 4 == 0){
            current = CoolUtil.copyClass(NoteAnimations.fourKey);
       	} else if (keyCountFloor == 2) {
           	current = CoolUtil.copyClass(NoteAnimations.twoKey);
       	}

       	if (count % 2 == 1) { // Odd keycount, add middle note.
       		if ((current.staticAnimations[halfKeyCount] != 'arrowUP')
       			&& current.staticAnimations.length != count) {
       			current.staticAnimations.insert(halfKeyCount, 'arrowUP');
       		}
       		if (current.pressAnimations[halfKeyCount] != 'up press'
       			&& current.pressAnimations.length != count) {
       			current.pressAnimations.insert(halfKeyCount, 'up press');
       		}
       		if (current.confirmAnimations[halfKeyCount] != 'up confirm'
       			&& current.confirmAnimations.length != count) {
       			current.confirmAnimations.insert(halfKeyCount, 'up confirm');
       		}
      		if (current.noteAnimations[halfKeyCount] != 'green' && current.noteAnimations.length != count) {
				current.noteAnimations.insert(halfKeyCount, 'green');
			}
			if (current.holdAnimations[halfKeyCount] != 'green hold piece'
				&& current.holdAnimations.length != count) {
				current.holdAnimations.insert(halfKeyCount, 'green hold piece');
			}
			if (current.tailAnimations[halfKeyCount] != 'green hold end'
				&& current.tailAnimations.length != count) {
				current.tailAnimations.insert(halfKeyCount, 'green hold end');
			}
       	}
	}

	public inline function toString(){
	    return 'staticAnimations: $staticAnimations\npressAnimations: $pressAnimations\nconfirmAnimations: $confirmAnimations\nnoteAnimations: $noteAnimations\nholdAnimations: $holdAnimations\ntailAnimations: $tailAnimations';
	}
}
