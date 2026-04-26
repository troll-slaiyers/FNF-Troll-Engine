package funkin.states.scripting;

import funkin.scripts.ScriptedClassShit.InstanceInterp;
import funkin.scripts.FunkinHScript;

#if !SCRIPTABLE_STATES
@:build(funkin.macros.ScriptingMacro.addScriptingCallbacks([
	"create",
	"update",
	"draw",
	"destroy",
	"openSubState",
	"closeSubState",
	"stepHit",
	"beatHit",
	"sectionHit"
]))
#end
class HScriptedState extends MusicBeatState 
{
	public var scriptPath:String;
	public var displayPath:String;

	private function new(expr:hscript.Expr, ?scriptVars:Map<String, Dynamic>)
	{
		super(false); // false because the whole point of this state is its scripted lol

		this.scriptPath = expr.origin;
		this.displayPath = shortenScriptPath(expr.origin);

		var vars = _getScriptDefaultVars();

		if (scriptVars != null) {
			for (k => v in scriptVars)
				vars[k] = v;
		}

		this._extensionScript = FunkinHScript.fromExpr(expr, scriptPath, vars, false, new InstanceInterp(this));
		this._extensionScript.call("new", []);
	}

	override function toString():String {
		return '$displayPath';
	}

	public static function fromName(name:String, ?scriptVars):Null<HScriptedState>
	{
		for (filePath in Paths.getFolders("states"))
		{
			for(ext in Paths.HSCRIPT_EXTENSIONS){
				var state = fromPath(filePath + '$name.$ext', scriptVars);
				if (state != null)
					return state;
			}
		}

		return null;
	}

	public static inline function fromPath(path:String, ?scriptVars):Null<HScriptedState> {
		return fromExpr(FunkinHScript.parseFile(path));
	}

	public static inline function fromExpr(expr:hscript.Expr, ?scriptVars):Null<HScriptedState> {
		return (expr != null) ? new HScriptedState(expr, scriptVars) : null;
	}

	private static inline function shortenScriptPath(path:String):String {
		var sp = path.split('/');
		
		if (sp[0] == Paths.contentFolderName)
			sp.shift();

		var contentFolder = sp.shift();

		// no states folder
		sp.shift();

		var fileName:String = sp.pop();
		fileName = fileName.substring(0, fileName.lastIndexOf('.'));
		sp.push(fileName);

		return contentFolder + ':' + sp.join('/');
	}
}
