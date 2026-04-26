#if SCRIPTABLE_STATES
package funkin.states.scripting;

import funkin.scripts.FunkinHScript;

class HScriptOverridenState extends HScriptedState 
{
	public var parentClass:Class<MusicBeatState>;

	override function _startExtensionScript(folder:String, scriptName:String) 
		return;

	private function new(parentClass:Class<MusicBeatState>, expr:hscript.Expr) 
	{
		if (parentClass == null)
			throw 'HScriptOverridenState parentClass argument is null';

		this.parentClass = parentClass;		
		super(expr, [getShortClassName(parentClass) => parentClass]);
	}

	override function toString() {
		return '$displayPath';
	}

	public static function findClassOverride(cl:Class<MusicBeatState>):Null<HScriptOverridenState> 
	{
		var fullName = Type.getClassName(cl);
		var shortName = shortenClassName(fullName);

		for (filePath in Paths.getFolders("states")) {
			// `override/funkin.states.MainMenuState`
			var key = 'override/$fullName';
			// `override/funkin/states/MainMenuState`
			var folderedKey = 'override/' + StringTools.replace(fullName, ".", "/");
			#if ALLOW_DEPRECATION
			// `override/MainMenuState`
			var keyLegacy = 'override/$shortName';
			#end

			for (ext in Paths.HSCRIPT_EXTENSIONS) {
				// TODO: Trim off the funkin.states and check that, too.
				
				var expr = FunkinHScript.parseFile(filePath + key + '.$ext');
				expr ??= FunkinHScript.parseFile(filePath + folderedKey + '.$ext');
				#if ALLOW_DEPRECATION
				expr ??= FunkinHScript.parseFile(filePath + keyLegacy + '.$ext');
				#end

				if (expr != null)
					return new HScriptOverridenState(cl, expr);
			}
		}

		return null;
	}

	public static inline function requestOverride(state:MusicBeatState):Null<HScriptOverridenState>
	{
		if (state != null && state.canBeScripted)
			return findClassOverride(Type.getClass(state));
		
		return null;
	}

	public static inline function fromAnother(state:HScriptOverridenState):Null<HScriptOverridenState>
	{
		var expr = FunkinHScript.parseFile(state.scriptPath);
		return (expr != null) ? new HScriptOverridenState(state.parentClass, expr) : null;
	}

	/** Returns just the class name without the package **/
	private static inline function getShortClassName(cl):String {
		return shortenClassName(Type.getClassName(cl));
	}
	
	private static inline function shortenClassName(name:String):String {
		var didx = name.lastIndexOf('.');
		return name.substring(didx + 1, name.length);	
	}
}
#end