package funkin.data;

import funkin.data.LocalizationMap;
import funkin.Paths;

private final languageNames:Map<String, String> = [
	'en' => "English",
	'es' => "Español",
	'pt-BR' => "Português (Brasil)"
];

class Language {
	/** Language ID **/
	public static var locale(default, set):String;

	/** Language ID => Language Name **/
	public static var localeList:Map<String, String> = [];
	
	private static final currentStrings:Map<String, String> = [];

	public static inline function getString(key:String):Null<String>
		return currentStrings.get(key);

	public static inline function hasString(key:String):Bool
		return currentStrings.exists(key);

	public static function reloadStrings():Void {
		currentStrings.clear();
		// trace("refreshing strings");

		for (filePath in Paths.getFolders("data")) {
			inline function readFile(path) {
				if (Paths.exists(path)) {
					var file = LocalizationMap.fromFile(path);
					for (k => v in file) {
						if (!currentStrings.exists(k))
							currentStrings.set(k, v);
					}
				}
			}
			readFile('$filePath/lang/$locale.txt');
			readFile('$filePath/lang/$locale.lang');
			readFile('$filePath/lang/en.txt');
			readFile('$filePath/strings.txt');
		}
	}

	public static function reloadList():Void {
		localeList.clear();

		for (folderPath in Paths.getFolders("data/lang")) {
			for (fileName in Paths.readDirectory(folderPath)) {
				var exti = fileName.lastIndexOf('.');
				if (exti == -1 || exti == fileName.length - 1)
					continue;
				
				var ext = fileName.substring(exti+1, fileName.length); 
				if (ext != 'txt' && ext != 'lang')
					continue;

				var fileStem = fileName.substring(0, exti);
				var displayName = languageNames.get(fileStem) ?? fileStem;

				trace(fileStem, displayName);
				localeList.set(fileStem, displayName);
			}
		}
	}

	////
	@:noCompletion static function set_locale(l:String){
		if (l == 'default')
			l = openfl.system.Capabilities.language;

		if (l != locale) {
			locale = l;
			reloadStrings();
		}
		return locale;
	}
}