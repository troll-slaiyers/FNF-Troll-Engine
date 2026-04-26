package funkin.modchart;
// @author Riconuts

import funkin.objects.playfields.NoteField;
import funkin.scripts.ScriptedClassShit;
import funkin.scripts.FunkinHScript;
import funkin.modchart.Modifier;
import math.Vector3;

class HScriptModifier extends Modifier implements IScriptedClass
{
	public var script:FunkinHScript = null;
	public var name:String = "unknown";

	public function new(modMgr:ModManager, ?parent:Modifier)
	{
		super(modMgr, parent);
	}

	public function callOnScript(call:String, ?args:Array<Dynamic>):Dynamic
	{
		return script.call(call, args);
	}

	public function existsOnScript(call:String):Bool
	{
		return script != null && script.exists(call);
	}

	@:noCompletion
	private static final _scriptEnums:Map<String, Dynamic> = [
		"NOTE_MOD" => NOTE_MOD,
		"MISC_MOD" => MISC_MOD,

		"FIRST" => FIRST,
		"PRE_REVERSE" => PRE_REVERSE,
		"REVERSE" => REVERSE,
		"POST_REVERSE" => POST_REVERSE,
		"DEFAULT" => DEFAULT,
		"LAST" => LAST
	];

	public static function fromString(modMgr:ModManager, ?parent:Modifier, scriptSource:String):HScriptModifier
	{
		var mod = new HScriptModifier(modMgr, parent);
		mod.script = FunkinHScript.fromString(scriptSource, "HScriptModifier", _scriptEnums, false, new InstanceInterp(mod));
		return mod; 
	}

	public static function fromName(modMgr:ModManager, ?parent:Modifier, scriptName:String):Null<HScriptModifier>
	{		
		var filePath:String = Paths.getHScriptPath('modifiers/$scriptName');
		if(filePath == null){
			trace('Modifier script: $scriptName not found!');
			return null;
		}

		var mod = new HScriptModifier(modMgr, parent);
		mod.name = scriptName;
		mod.script = FunkinHScript.fromFile(filePath, filePath, _scriptEnums, false, new InstanceInterp(mod));
		return mod;

	}
}