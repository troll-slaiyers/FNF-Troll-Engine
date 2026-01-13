package funkin.objects.notes;

/**
 * Contains data for animations for a specific keycount.
 * Keycounts divisible by that keycount are wrapped around.
 */
@:publicFields
typedef NoteAnimation = {
	// Note animations.
	var noteAnimations:Array<String>;
	var holdAnimations:Array<String>;
	var tailAnimations:Array<String>;
	// Strum animations.
    var staticAnimations:Array<String>;
    var pressAnimations:Array<String>;
    var confirmAnimations:Array<String>;
}
