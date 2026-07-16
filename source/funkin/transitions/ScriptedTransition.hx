package funkin.transitions;

import funkin.transitions.Transition;
import funkin.scripts.ScriptedClassShit;
import funkin.scripts.FunkinHScript;
import hscript.Expr;

private final SCRIPT_CONSTANTS:Map<String, Dynamic> = [
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

abstract TransitionReference(Dynamic) from Class<Transition> from Transition from String {
	public function createInstance():Null<Transition> {
		return if (this is Class) {
			Type.createInstance(this, []);
		}
		else if (this is Transition) {
			this;
		}
		else if (this is String) {
			fromString(this);
		}
		else {
			null;
		}
	}

	public function toString():String {
		if (this is String)
			return this;
		else if (this is Class)
			return Type.getClassName(this);
		else if (this is ScriptedTransition)
			return @:privateAccess this.name;
		else if (this is Transition)
			return Type.getClassName(Type.getClass(this));
		else
			return 'null';
	}

	private static function fromString(str:String):Null<Transition> {
		var instance:Null<Transition> = null;
		
		// haxe is being retarded, only on linux for some reason
		instance = fromScriptName(str);
		//instance = ScriptedTransition.fromName(str);
		
		if (instance == null) {
			var cl = Type.resolveClass(str);
			if (cl != null)
				instance = Type.createInstance(cl, []);
		}

		return instance;
	}

	private static function fromScriptName(name:String) {
		var path = Paths.getHScriptPath('transitions/$name');
		if (path == null) return null;

		var expr = FunkinHScript.parseFile(path);
		if (expr == null) return null;

		@:privateAccess
		return new ScriptedTransition(name, expr);
	}
}