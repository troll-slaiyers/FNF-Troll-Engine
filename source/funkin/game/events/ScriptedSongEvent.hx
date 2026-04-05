package funkin.game.events;

import funkin.scripts.ScriptedClassShit;
import funkin.scripts.FunkinHScript;
import hscript.Expr;

class ScriptedSongEvent extends SongEvent implements IScriptedClass {
	final script:FunkinHScript;

	private function new(id:String, expr:Expr) {
		super(id);
		this.script = FunkinHScript.fromExpr(expr, id, null, false, new InstanceInterp(this));
	}

	public function callOnScript(func:String, ?args:Array<Dynamic>):Dynamic
		return script.executeFunc(func, args);
	
	public function existsOnScript(func:String):Bool
		return script.exists(func);

	public static function fromName(name:String) {
		var path = Paths.getHScriptPath('events/$name');
		if (path == null) return null;

		var expr = FunkinHScript.parseFile(path);
		if (expr == null) return null;

		return new ScriptedSongEvent(name, expr);
	}
}