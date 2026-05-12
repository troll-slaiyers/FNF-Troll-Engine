import flixel.FlxG;

class CoolerStringTools {
	static public function isAlpha(s:String):Bool
		return s.toLowerCase() != s.toUpperCase();

	static public function capitalize(s:String):String {
		return switch(s.length) {
			case 0: "";
			case 1: s.toUpperCase();
			default:
				var buf = new StringBuf();
				var pc = " ";
				for (i in 0...s.length) {
					var c = s.charAt(i);
					buf.add(isAlpha(pc) ? c.toLowerCase() : c.toUpperCase());
					pc = c;
				}
				buf.toString();
		}
	}
	
	public static function shuffle(s:String):String {
		var characters:Array<String> = s.split("");
		FlxG.random.shuffle(characters);
		return characters.join("");
	}

	/**
		`formatDecimal(0, 2)` => `0.00`
	**/
	public static function formatDecimal(Number:Float, Precision = 2):String {
		var mult:Float = 1;
		for (_ in 0...Precision)
			mult *= 10;
		
		var formatted = Std.string(Math.fround(Number * mult) / mult);
		var sowy = formatted.lastIndexOf('.');

		if (sowy == -1) {
			formatted += '.';
			sowy = 0;
		}else
			sowy = formatted.length - sowy - 1;

		for (_ in sowy...Precision)
			formatted += '0';

		return formatted;
	}
}
