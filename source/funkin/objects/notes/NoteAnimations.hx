package funkin.objects.notes;

final class NoteAnimations {
	public static final twoKey:NoteAnimation = {
		noteAnimations: ['purple', 'red'],
		holdAnimations: ['purple hold piece', 'red hold piece'],
		tailAnimations: ['purple hold end', 'red hold end'],
		staticAnimations: ['arrowLEFT', 'arrowRIGHT'],
		pressAnimations: ['left press', 'right press'],
		confirmAnimations: ['left confirm', 'right confirm']
	};

	public static final fourKey:NoteAnimation = {
		noteAnimations: ['purple', 'blue', 'green', 'red'],
		holdAnimations: ['purple hold piece', 'blue hold piece', 'green hold piece', 'red hold piece'],
		tailAnimations: ['purple hold end', 'blue hold end', 'green hold end', 'red hold end'],
		staticAnimations: ['arrowLEFT', 'arrowDOWN', 'arrowUP', 'arrowRIGHT'],
		pressAnimations: ['left press', 'down press', 'up press', 'right press'],
		confirmAnimations: ['left confirm', 'down confirm', 'up confirm', 'right confirm']
	};

	public static final sixKey:NoteAnimation = {
		noteAnimations: ['purple', 'green', 'red', 'purple', 'blue', 'red'],
		holdAnimations: [
			'purple hold piece',
			'green hold piece',
			'red hold piece',
			'purple hold piece',
			'blue hold piece',
			'red hold piece'
		],
		tailAnimations: [
			'purple hold end',
			'green hold end',
			'red hold end',
			'purple hold end',
			'blue hold end',
			'red hold end'
		],
		staticAnimations: ['arrowLEFT', 'arrowUP', 'arrowRIGHT', 'arrowLEFT', 'arrowDOWN', 'arrowRIGHT'],
		pressAnimations: [
			'left press',
			'up press',
			'right press',
			'left press',
			'down press',
			'right press'
		],
		confirmAnimations: [
			'left confirm',
			'up confirm',
			'right confirm',
			'left confirm',
			'down confirm',
			'right confirm'
		]
	};
}
