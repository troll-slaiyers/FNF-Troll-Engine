package funkin.macros;

import haxe.macro.Expr.Field;

// what DOES sowy mean
class Sowy
{
	/**
		Returns the build date as a String
	**/
	public static macro function getBuildDate()
	{
		return macro $v{Date.now().toString()};
	}

	/**
	 * Returns a map of all conditional compilation flags that were set.
	 */
	public static macro function getDefines() 
	{
		return macro $v{haxe.macro.Context.getDefines()};
	}

	/**
		Returns the contents of a file at compile time
	**/
	public static macro function readFile(path:String, throwException:Bool = true) {
		if (!sys.FileSystem.exists(path)) {
			if (throwException)
				haxe.macro.Context.error('File "$path" does not exist', haxe.macro.Context.currentPos());
			return macro $v{null};
		}
		return macro $v{sys.io.File.getContent(path)};
	}

	public static function findByName(fields:Array<Field>, name:String):Null<Field>{
		for (field in fields){
			if (field.name == name)
				return field;
		}
		return null;
	}
}