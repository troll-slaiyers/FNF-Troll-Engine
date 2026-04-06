package funkin.objects.notes;

import haxe.Constraints.Function;
import funkin.objects.notes.Note;
import funkin.objects.playfields.PlayField;
import funkin.data.JudgmentManager;
import funkin.scripts.Globals.FunctionReturn;
#if HSCRIPT_ALLOWED
import hscript.Expr;
import funkin.scripts.ScriptedClassShit;
import funkin.scripts.FunkinHScript;
#end

private final defaultNoteTypes:Map<String, Class<NoteType>> = [
	'' => DefaultNoteType,
	'Alt Note' => AltAnimNoteType,
	'Hey!' => HeyNoteType,
	'GF Sing' => GfNoteType,
	'No Animation' => NoAnimNoteType,
];

class NoteType {
	public final id:String;
	function new(id:String) {
		this.id =id;
	}

	public function update(elapsed:Float) {}
	public function draw() {}
	public function destroy() {}

	#if true
	public function setupNote(note:Note) {}

	public function onUpdateColours(note:Note) {}

	public function onNoteUpdate(note:Note, elapsed:Float) {}

	public function judgeNote(note:Note, hitDiff:Float):Null<Judgment> return null;
	public function transformJudgeData(note:Note, judgeData:JudgmentData):JudgmentData return judgeData;

	public function onSpawnNotePost(note:Note, field:PlayField) {}

	public function onGoodNoteHit(note:Note, field:PlayField):FunctionReturn return CONTINUE;
	public function onGoodNoteHitPost(note:Note, field:PlayField) {}

	public function onOpponentNoteHit(note:Note, field:PlayField):FunctionReturn return CONTINUE;
	public function onOpponentNoteHitPost(note:Note, field:PlayField) {}

	public function onNoteHit(note:Note, field:PlayField):FunctionReturn return CONTINUE;
	public function onNoteHitPost(note:Note, field:PlayField) {}

	public function onNoteMiss(note:Note, field:PlayField):FunctionReturn return CONTINUE;
	public function onNoteMissPost(note:Note, field:PlayField) {}

	public function playSingAnim(note:Note, field:PlayField, characters:Array<Character>):FunctionReturn return CONTINUE;
	public function playMissAnim(note:Note, field:PlayField, characters:Array<Character>):FunctionReturn return CONTINUE;

	public function onHoldStep(note:Note, field:PlayField) {}
	public function onHoldPress(note:Note, field:PlayField) {}
	public function onHoldRelease(note:Note, field:PlayField) {}
	#end
}

class NoteTypeManager {
	static final map:Map<String, NoteType> = [];

	public static function get(id:String):Null<NoteType>
		return map.exists(id) ? map[id] : map[id] = _get(id);

	private static function _get(id:String):Null<NoteType> {
		#if HSCRIPT_ALLOWED
		var nt = ScriptedNoteType.fromId(id);
		if (nt != null) return nt;
		#end

		var c = defaultNoteTypes.get(id);
		if (c != null)
			return Type.createInstance(c, [id]);

		//trace('Note type handler "$id" not found.');
		return null;
	}

	public static function cleanup() {
		for (nt in map)
			nt?.destroy();
		map.clear();
	}
}

#if HSCRIPT_ALLOWED
class ScriptedNoteType extends NoteType implements IScriptedClass {
	final script:FunkinHScript;

	private function new(id:String, expr:Expr) {
		super(id);
		this.script = FunkinHScript.fromExpr(expr, 'NoteType:$id', null, false, new InstanceInterp(this));
	}

	public function callOnScript(func:String, ?args:Array<Dynamic>):Dynamic
		return script.executeFunc(func, args);
	
	public function existsOnScript(func:String):Bool
		return script.exists(func);

	public static function fromId(id:String):Null<ScriptedNoteType> {
		var path = Paths.getHScriptPath('notetypes/$id');
		if (path == null) return null;

		var expr = FunkinHScript.parseFile(path);
		if (expr == null) return null;

		return new ScriptedNoteType(id, expr);
	}
}
#end

class DefaultNoteType extends NoteType {
	function new() {
		super('');
	}
}

class AltAnimNoteType extends NoteType {
	override function setupNote(note:Note) {
		note.characterHitAnimSuffix = "-alt";
		note.characterMissAnimSuffix = "-altmiss";
	}
}

class HeyNoteType extends NoteType {
	override function setupNote(note:Note) {
		note.characterHitAnimName = 'hey';
		// TODO
	}
}

class GfNoteType extends NoteType {
	override function setupNote(note:Note) {
		note.gfNote = true;
	}
}

class NoAnimNoteType extends NoteType {
	override function setupNote(note:Note) {
		note.noAnimation = true;
		note.noMissAnimation = true;
	}
}