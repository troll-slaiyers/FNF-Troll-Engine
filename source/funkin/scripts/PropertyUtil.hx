package funkin.scripts;

import funkin.states.PlayState.instance as game;
import Type.ValueType;

using StringTools;

class PropertyUtil
{
	public static function getProperty(variable:String) {
		var killMe:Array<String> = variable.split('.');
		if (killMe.length > 1)
			return getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
		else
			return getVarInArray(game, variable);
	}

	public static function setProperty(variable:String, value:Dynamic) {
		var killMe:Array<String> = variable.split('.');
		if (killMe.length > 1)
			setVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1], value);
		else
			setVarInArray(game, variable, value);
	}

	////
	public static function getPropertyFromClass(classVar:String, variable:String) {
		var killMe:Array<String> = variable.split('.');
		if(killMe.length > 1) {
			var coverMeInPiss:Dynamic = getVarInArray(Type.resolveClass(classVar), killMe[0]);
			for (i in 1...killMe.length-1) {
				coverMeInPiss = getVarInArray(coverMeInPiss, killMe[i]);
			}
			return getVarInArray(coverMeInPiss, killMe[killMe.length-1]);
		}
		return getVarInArray(Type.resolveClass(classVar), variable);
	}

	public static function setPropertyFromClass(classVar:String, variable:String, value:Dynamic) {
		var killMe:Array<String> = variable.split('.');
		if(killMe.length > 1) {
			var coverMeInPiss:Dynamic = getVarInArray(Type.resolveClass(classVar), killMe[0]);
			for (i in 1...killMe.length-1) {
				coverMeInPiss = getVarInArray(coverMeInPiss, killMe[i]);
			}
			setVarInArray(coverMeInPiss, killMe[killMe.length-1], value);
			return true;
		}
		setVarInArray(Type.resolveClass(classVar), variable, value);
		return true;
	}

	////
	public static function getPropertyLoopThingWhatever(killMe:Array<String>):Dynamic {
		var coverMeInPiss:Dynamic = getObjectDirectly(killMe[0]);
		for (i in 1...killMe.length-1)
			coverMeInPiss = getVarInArray(coverMeInPiss, killMe[i]);

		return coverMeInPiss;
	}

	inline public static function getObjectDirectly(tag:String):Null<Dynamic>
		return getVarInArray(game, tag);

	public static function getObject(tag:String):Null<Dynamic> {
		var killMe:Array<String> = tag.split('.');
		if (killMe.length > 1)
			return getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
		else
			return Reflect.getProperty(game, killMe[0]);
	}

	public static function setVarInArray(obj:Dynamic, variable:String, value:Dynamic):Any
	{
		var shit:Array<String> = variable.split('[');
		if (shit.length > 1) {
			var blah:Dynamic = Reflect.getProperty(obj, shit[0]);
			for (i in 1...shit.length) {
				var leNum:Dynamic = shit[i].substr(0, shit[i].length - 1);
				if (i >= shit.length-1) //Last array
					blah[leNum] = value;
				else //Anything else
					blah = blah[leNum];
			}
			return blah;
		}

		if (isMap(obj))
			obj.set(variable, value);
		else
			Reflect.setProperty(obj, variable, value);

		return true;
	}
	public static function getVarInArray(obj:Dynamic, variable:String):Any
	{
		var shit:Array<String> = variable.split('[');
		if (shit.length > 1) {
			var blah:Dynamic = Reflect.getProperty(obj, shit[0]);
			for (i in 1...shit.length) {
				var leNum:Dynamic = shit[i].substr(0, shit[i].length - 1);
				blah = blah[leNum];
			}
			return blah;
		}
		
		if (isMap(obj))
			return obj.get(variable);
		else
			return Reflect.getProperty(obj, variable);
	}

	public static function getGroupStuff(leArray:Dynamic, variable:String) {
		var killMe:Array<String> = variable.split('.');
		if(killMe.length > 1) {
			var coverMeInPiss:Dynamic = Reflect.getProperty(leArray, killMe[0]);
			for (i in 1...killMe.length-1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			if (isMap(coverMeInPiss))
				return coverMeInPiss.get(killMe[killMe.length-1]);
			else
				return Reflect.getProperty(coverMeInPiss, killMe[killMe.length-1]);
		}

		if (isMap(leArray))
			return leArray.get(variable);
		else
			return Reflect.getProperty(leArray, variable);
	}

	public static function setGroupStuff(leArray:Dynamic, variable:String, value:Dynamic) {
		var killMe:Array<String> = variable.split('.');
		if(killMe.length > 1) {
			var coverMeInPiss:Dynamic = Reflect.getProperty(leArray, killMe[0]);
			for (i in 1...killMe.length-1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			Reflect.setProperty(coverMeInPiss, killMe[killMe.length-1], value);
			return;
		}
		Reflect.setProperty(leArray, variable, value);
	}

	public static function isOfTypes(value:Any, types:Array<Dynamic>):Bool {
		for (type in types) {
			if (Std.isOfType(value, type))
				return true;
		}
		return false;
	}

	inline public static function isMap(obj:Dynamic) {
		return switch(Type.typeof(obj)) {
			case ValueType.TClass(haxe.ds.StringMap) | ValueType.TClass(haxe.ds.ObjectMap) | ValueType.TClass(haxe.ds.IntMap) | ValueType.TClass(haxe.ds.EnumValueMap):
				true;
			default:
				false;
		};
	}
}