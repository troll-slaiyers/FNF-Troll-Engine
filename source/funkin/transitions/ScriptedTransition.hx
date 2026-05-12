package funkin.transitions;

import funkin.transitions.Transition;
import funkin.scripts.ScriptedClassShit;
import funkin.scripts.FunkinHScript;
import hscript.Expr;

final SCRIPT_CONSTANTS:Map<String, Dynamic> = [
	"TransitionStatus" => {
		IN: TransitionStatus.IN,
		OUT: TransitionStatus.OUT,
		NULL: TransitionStatus.NULL,
	},
	"IN" => TransitionStatus.IN,
	"OUT" => TransitionStatus.OUT,
];

class ScriptedTransition extends Transition implements IScriptedClass {
	final script:FunkinHScript;

	private function new(name:String, expr:Expr) {
		this.script = FunkinHScript.fromExpr(expr, name, SCRIPT_CONSTANTS, false, new InstanceInterp(this));
		super();
	}
	
	public function callOnScript(func:String, ?args:Array<Dynamic>):Dynamic
		return script.executeFunc(func, args);
	
	public function existsOnScript(func:String):Bool
		return script.exists(func);

	public static function fromName(name:String) {
		var path = Paths.getHScriptPath('transitions/$name');
		if (path == null) return null;

		var expr = FunkinHScript.parseFile(path);
		if (expr == null) return null;

		return new ScriptedTransition(name, expr);
	}
}