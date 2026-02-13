package funkin.objects.notes;

/**
 * Contains data for animations for a specific keycount.
 */
@:publicFields
@:structInit
class NoteAnimations {
	// Note animations.
	var noteAnimations:Array<String>;
	var holdAnimations:Array<String>;
	var tailAnimations:Array<String>;

	// Strum animations.
    var staticAnimations:Array<String>;
    var pressAnimations:Array<String>;
    var confirmAnimations:Array<String>;

	public inline function toString() {
	    return [for (fieldName in animFields) '$fieldName: ${Reflect.field(this, fieldName)}'].join('\n');
	}

	private static final animFields = [
		"noteAnimations",
		"holdAnimations",
		"tailAnimations",
		"staticAnimations",
		"pressAnimations",
		"confirmAnimations"
	];

	static final defaultAnims:NoteAnimations = {
		noteAnimations: ['purple', 'blue', 'green', 'red', 'square0'],
		holdAnimations: ['purple hold piece', 'blue hold piece', 'green hold piece', 'red hold piece', 'square hold piece'],
		tailAnimations: ['purple hold end', 'blue hold end', 'green hold end', 'red hold end', 'square hold end'],
		staticAnimations: ['arrowLEFT', 'arrowDOWN', 'arrowUP', 'arrowRIGHT', 'arrowSQUARE'],
		pressAnimations: ['left press', 'down press', 'up press', 'right press', 'square press'],
		confirmAnimations: ['left confirm', 'down confirm', 'up confirm', 'right confirm', 'square confirm']
	}

    static final current:NoteAnimations = CoolUtil.copyClass(defaultAnims);

	static final keyIndices:Array<Array<Int>> = [
		[4],
		[0, 3],
		[0, 4, 3],
		[0, 1, 2, 3],
		[0, 1, 4, 2, 3],
		[0, 1, 3, 0, 2, 3],
		[0, 1, 3, 4, 0, 2, 3],
		[0, 1, 2, 3, 0, 1, 2, 3],
		[0, 1, 2, 3, 4, 0, 1, 2, 3],
	];

   	public static function refreshKeyAnimations(keyCount:Int = 4) {
        Note.spriteScale = Note.spriteScales[keyCount - 1];
		Note.swagWidth = Note.spriteScale * 160;

		for (fieldName in animFields) {
			var defaults:Array<String> = Reflect.field(defaultAnims, fieldName);
			var toAdjust:Array<String> = Reflect.field(current, fieldName);
			remap4KArray(keyCount, defaults, toAdjust);
		}
	}

	public static inline function remap4KArray<T>(keyCount:Int, array:Array<T>, ?resultArray:Array<T>):Array<T> {
		resultArray ??= [];
		
		var SQUARE = (array.length == 5) ? 4 : 2;
		for (idx => ind in keyIndices[keyCount - 1])
			resultArray[idx] = array[ind == 4 ? SQUARE : ind];

		return resultArray;
	}
}
