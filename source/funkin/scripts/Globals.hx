package funkin.scripts;

import funkin.states.PlayState;
import funkin.states.GameOverSubstate;

enum abstract FunctionReturn(String) to String
{
	final STOP = 'FUNC_STOP';
	final CONTINUE = 'FUNC_CONT'; // i take back what i said
	final HALT = 'FUNC_HALT';
}

class Globals
{
	public static final Function_Stop:String = FunctionReturn.STOP;
	public static final Function_Continue:String = FunctionReturn.CONTINUE; // i take back what i said
	public static final Function_Halt:String = FunctionReturn.HALT;

	public static final variables:Map<String, Dynamic> = new Map(); // it MAKES WAY MORE SENSE FOR THIS TO BE HERE THAN IN PLAYSTATE GRRR BARK BARK
	
	public static final persistentVariables:Map<String, Dynamic> = new Map(); // These don't get wiped on state change

	public static inline function callOnScripts(scripts:Array<FunkinScript>, funcName:String, ?args:Array<Dynamic>):Dynamic {
		#if HSCRIPT_ALLOWED
		if (args == null)
			args = [];

		var returnVal:Dynamic = Globals.Function_Continue;
		for (script in scripts) {			
			var ret:Dynamic = script.call(funcName, args);
			if (ret == Globals.Function_Halt) {
				returnVal = Globals.Function_Stop;
				break;
			}
			else if (ret != Globals.Function_Continue && ret != null)
				returnVal = ret;
		}

		return returnVal;
		#else
		return Globals.Function_Continue;
		#end
	}
}