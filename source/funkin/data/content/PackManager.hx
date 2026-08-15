package funkin.data.content;

import funkin.util.FileUtil;
import funkin.Paths.CONTENT_PATH;

// I chose to call them PACKS because of conflicts with functions from Paths (getContent, getFolders)
// Here comes packman

/** :v **/
@:noScripting
class PackManager {
	public static var engineAssets(default, null):Pack = null;

	public static var currentPackId(default, set):String = '';
	public static var currentPack(default, set):Pack = null;

	/** 
		The currently active pack, its dependencies and global packs.  
		Updated whenever `currentPackId` is changed.
	**/
	public static var readList:Array<Pack> = [];

	/** Map `[pack.id => pack]` of loaded packs **/
	public static var packMap:Map<String, Pack> = [];
	/** List of loaded packs id's, in loading order **/
	public static var packList:Array<String> = [];
	/** List of global packs id's, in loading order **/
	public static var globalPacks:Array<Pack> = [];

	/** A map of all packs, including packs that weren't loaded **/
	private static var allPacks:Map<String, Pack> = [];

	/** Dictates which packs and in which order they're added **/
	public static var entries = new EntryList();
	// TODO: "profiles" so that I don't have to make copies of the content folder :P

	#if true
	public static function refreshReadList() {
		readList.resize(0);

		for (pack in globalPacks)
			readList.push(pack);
		
		if (currentPack != null) {
			for (id in currentPack.dependencies) {
				var pack = packMap.get(id);
				if (pack != null)
					readList.push(pack);
			}
				
			readList.push(currentPack);
		}
		readList.reverse();
		trace('readList: $readList');
	}

	public static function reloadPackList()
	{
		//// Unload packs
		for (id in packList)
			packMap.get(id)?.unload();
		packMap.clear();
		packList.resize(0);
		globalPacks.resize(0);
		allPacks.clear();

		////
		var loadList:Array<Pack> = [];

		//
		var hcPacks:Array<Pack> = getHardcodedPacks();
		for (pack in hcPacks) {
			allPacks.set(pack.id, pack);
			// these can't be disabled
			packMap.set(pack.id, pack);
			loadList.push(pack);
		}

		//
		var modPacks:Array<Pack> = getModdedPacks();
		for (pack in modPacks) {
			if (!packMap.exists(pack.id)) {
				allPacks.set(pack.id, pack);
				if (entries.getEntry(pack.id).enabled) {
					packMap.set(pack.id, pack);
					loadList.push(pack);
				}
			}
		}

		//// Load packs
		for (pack in loadList) {
			try {
				pack.loadException = '';
				pack.load();
				pack.active = pack.loadException.length == 0;
			}catch(e) {
				var e = Std.string(e);
				var cs = CrashHandler.callstackToString(haxe.CallStack.exceptionStack());
				pack.loadException = '$e\n$cs';
				pack.active = false;
				print('Error loading ${pack.id}: ${pack.loadException}');
			}
		}

		for (pack in loadList) {
			if (!pack.active)
				continue;
			
			for (dependencyId in pack.dependencies) {
				if (!allPacks.exists(dependencyId))
					pack.loadException = 'Dependency "$dependencyId" is not present!';
				else if (!packMap.exists(dependencyId))
					pack.loadException = 'Dependency "$dependencyId" is not active!';
				else // you're good
					continue;
				break; // missing dependency!
			}

			if (pack.loadException.length != 0) {
				pack.active = false;
				continue;
			}

			if (pack.runsGlobally) 
				globalPacks.push(pack);
			packList.push(pack.id);
		}

		trace('packList $packList');
		trace('globalPacks: $globalPacks');
	}

	private static function getHardcodedPacks():Array<Pack> {
		var list:Array<Pack> = [];

		//// "assets" folder
		engineAssets = new ContentFolder('assets', Paths.ASSETS_PATH);
		engineAssets.runsGlobally = true;
		list.push(engineAssets);

		return list;
	}

	private static function getModdedPacks():Array<Pack> {
		var modPacks = [];
		
		#if MODS_ALLOWED
		reloadEntries();
		for (entry in entries) {
			//if (entry.enabled)
			{
				var pack = #if USING_MOONCHART if (entry.id == "moonchart")
					new MoonchartFolder(entry.id, '$CONTENT_PATH/${entry.id}');
				else #end					
					new ContentFolder(entry.id, '$CONTENT_PATH/${entry.id}');
				
				modPacks.push(pack);
			}
		}
		#end

		return modPacks;
	}
	#end

	#if MODS_ALLOWED // ENTRY LIST
	public static function reloadEntries() {
		var folderList:Array<String> = [];

		for (folderName in Paths.readDirectory(CONTENT_PATH)) {
			var folderPath = '$CONTENT_PATH/$folderName';
			if (Paths.isDirectory(folderPath))
				folderList.push(folderName);
		};

		readEntryList();
		trace('Entry list $entries');

		//// Remove entries for non-existent content folders
		while (entries.array.remove(null)) trace("wtf");
		for (i => entry in entries) {
			if (!folderList.contains(entry.id)) {
				trace('Folder for entry "${entry.id}" does not exist! Removing...');
				entries.array[i] = null;
			}
		}
		while (entries.array.remove(null)) {}

		//// Add entries for new content folders
		for (folderName in folderList) {
			if (!entries.hasEntry(folderName)) {
				trace('Found content folder "$folderName", adding to entry list');
				entries.array.push(new PackEntry(folderName, true));
			}
		}

		return;
	}
	
	#if sys
	private static inline function readEntryList():Void {
		var path:String = getEntryListSavePath();
		if (sys.FileSystem.exists(path))
			entries.parseString(sys.io.File.getContent(path));
	}

	public static inline function flushEntryList():Void {
		FileUtil.safeSaveFile(getEntryListSavePath(), entries.stringify());
	}
	
	inline static function getEntryListSavePath():String {
		return FileUtil.getFlxSavePath() + '/packList.txt';
	} 
	#end
	#end

	////
	static function set_currentPackId(v:String) {
		if (v.length == 0) {
			currentPack = null;
		}else {
			currentPack = packMap.get(v);
			if (currentPack == null) {
				trace('WARNING: currentPackId was set to a non-existant pack: "$v"');
			}
		}

		return currentPackId = v;
	}

	static function set_currentPack(v:Pack) {
		if (currentPack != v) {
			currentPack = v;
			currentPackId = (v == null) ? '' : v.id;
			refreshReadList();
		}

		return currentPack;
	}
}

// aura
@:forward(length, iterator, keyValueIterator)
abstract EntryList(Array<PackEntry>) {
	public function new() {
		this = [];
	}

	public var array(get, never):Array<PackEntry>; 
	inline function get_array()
		return this;

	public function getEntry(id:String):PackEntry {
		for (entry in this) {
			if (entry.id == id)
				return entry;
		}
		return null;
	}

	public function hasEntry(id:String):Bool {
		var r:Bool = false;
		for (entry in this) {
			if (entry.id == id) {
				r = true;
				break;
			}
		} 
		return r;
	}

	public function parseString(str:String, clear:Bool = true) {
		if (clear)
			this.resize(0);

		for (rawEntry in str.split('\n')) {
			if (rawEntry.length == 0)
				continue;
			
			var entry = PackEntry.fromString(rawEntry);
			if (hasEntry(entry.id)) {
				trace('WARNING: Duplicate entry found for ${entry.id}, skipping');
				continue;
			}

			this.push(entry);
		}
	}

	public function stringify():String {
		var buf = new StringBuf();
		for (entry in this) {
			buf.add(entry.toString());
			buf.addChar('\n'.code);
		}
		return buf.toString();
	}
}

/**
	Represents an entry in the pack list save.  	
**/
abstract PackEntry(haxe.ds.Vector<String>) {
	public var id(get, never):String;
	public var enabled(get, set):Bool;

	public function new(id:String, enabled:Bool) {
		this = new haxe.ds.Vector<String>(2);
		this.set(0, id);
		this.set(1, enabled ? "1" : "0");
	}

	/**
		Parses a `PackEntry` from a String.  
		Format: `"id=enabled"` (e.g. `"myMod=1"` or `"anotherMod=0"`)
		@param str The String to parse.
		@returns A `PackEntry` instance, or `null` if the String couldn't be parsed.
	**/
	public static function fromString(str:String):Null<PackEntry> {
		var splitIdx = str.lastIndexOf('=');
		if (splitIdx == -1) return null;
		var id:String = str.substring(0, splitIdx);
		var enabled:Bool = str.substring(splitIdx + 1) == "1";
		return new PackEntry(id, enabled);
	}

	/**
		Converts this PackEntry to a String.
		@returns A String representation of this PackEntry.
	**/
	public function toString():String
		return '${this.get(0)}=${this.get(1)}';

	function get_id():String return this.get(0);
	function get_enabled():Bool return this.get(1) == "1";
	function set_enabled(value:Bool):Bool {
		this.set(1, value ? "1" : "0");
		return value;
	}
}