package funkin;

import haxe.io.Bytes;
import openfl.utils.ByteArray;
import haxe.ds.StringMap;
import funkin.data.content.Pack;
import funkin.data.content.PackManager;
import funkin.data.LocalizationMap;
import flixel.addons.display.FlxRuntimeShader;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import openfl.media.Sound;
import openfl.display.BitmapData;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import haxe.Json;

using StringTools;

#if FILESYSTEM_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

//// idgaf about asset libraries
@:access(openfl.display.BitmapData)
class Paths
{
	#if ASSET_REDIRECT
	inline public static final ASSETS_PATH:String = '${funkin.macros.Sowy.getProjectDirectory()}/assets';
	inline public static final CONTENT_PATH:String = '${funkin.macros.Sowy.getProjectDirectory()}/content';
	#else
	inline public static final ASSETS_PATH:String = 'assets';
	inline public static final CONTENT_PATH:String = 'content';
	#end

	inline public static final IMAGE_EXT = "png";
	inline public static final SOUND_EXT = "ogg";

	public static final HSCRIPT_EXTENSIONS:Array<String> = ["hscript", "hxs",];
	public static final SCRIPT_EXTENSIONS:Array<String> = [
		"hscript",
		"hxs",
	];

	public static var localTrackedAssets:Array<String> = [];
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static var currentTrackedSounds:Map<String, Sound> = [];

	public static var dumpExclusions:Array<String> = [
		'$ASSETS_PATH/music/freakyIntro.$SOUND_EXT',
		'$ASSETS_PATH/music/freakyMenu.$SOUND_EXT',
		'$ASSETS_PATH/music/breakfast.$SOUND_EXT',
		'$CONTENT_PATH/global/music/freakyIntro.$SOUND_EXT',
		'$CONTENT_PATH/global/music/freakyMenu.$SOUND_EXT',
		'$CONTENT_PATH/global/music/breakfast.$SOUND_EXT',
		'$ASSETS_PATH/images/Garlic-Bread-PNG-Images.$IMAGE_EXT'
	];
	public static var graphicDumpExclusions:Array<FlxGraphic> = [];
	public static var soundDumpExclusions:Array<Sound> = [];

	public static var whitePixel:flixel.graphics.frames.FlxFrame;

	public static function init() {
		{ //ACTUAL white pixel, instead of 10x10 white pixels fuck flixel piece of shit good for nothing
			var bd = new BitmapData(1, 1, true, 0xFFFFFFFF);
			var graphic:FlxGraphic = FlxG.bitmap.add(bd, true, "whitePixel");
			graphic.persist = true;
			whitePixel = graphic.imageFrame.frame;
			graphicDumpExclusions.push(graphic);
		}
		graphicDumpExclusions.push(FlxG.bitmap.whitePixel.parent);

		#if READ_EMBEDDED_ASSETS
		AltFilePaths.initPaths();
		#end

		PackManager.reloadPackList();
		PackManager.refreshReadList();
	}

	public static function excludeAsset(path:String)
	{
		if (!dumpExclusions.contains(path))
			dumpExclusions.push(path);
	}

	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory()
	{
		// clear non local assets in the tracked assets list
		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				// get rid of it
				var obj = currentTrackedAssets.get(key);
				@:privateAccess
				if (obj != null && !graphicDumpExclusions.contains(obj))
				{
					destroyGraphic(obj);
					currentTrackedAssets.remove(key);
					// trace('cleared $key');
				}
			}
		}
		// run the garbage collector for good measure lmfao
		openfl.system.System.gc();
	}

	/** removeBitmap(FlxSprite.graphic.key); **/
	public static function removeBitmap(key:String)
	{
		var obj = currentTrackedAssets.get(key);
		@:privateAccess
		if (obj != null)
		{
			localTrackedAssets.remove(key);
			destroyGraphic(obj);
			currentTrackedAssets.remove(key);		
		}
	}

	inline static function destroyGraphic(graphic:FlxGraphic)
	{
		// free some gpu memory
		graphic?.bitmap?.__texture?.dispose();
		FlxG.bitmap.remove(graphic);
	}

	public static function clearStoredMemory()
	{
		// clear anything not in the tracked assets list
		@:privateAccess
		for (key => obj in FlxG.bitmap._cache) {
			if (obj != null && !currentTrackedAssets.exists(key) && !graphicDumpExclusions.contains(obj) && !dumpExclusions.contains(key)) {
				// trace('cleared $key');
				destroyGraphic(obj);
			}
		}

		// clear all sounds that are cached
		for (key => obj in currentTrackedSounds) {
			if (obj != null && !localTrackedAssets.contains(key) && !soundDumpExclusions.contains(obj) && !dumpExclusions.contains(key)) {
				Assets.cache.removeSound(key);
				currentTrackedSounds.remove(key);
			}
		}

		// flags everything to be cleared out next unused memory clear
		localTrackedAssets.resize(0);
	}

	public static function getPath(key:String, ?packId:String):Null<String>
	{
		if (packId != null) {
			var pack = PackManager.packMap.get(packId);
			if (pack != null) {
				var path = '${pack.path}/$key';
				if (exists(path))
					return path;
				
				for (packId in pack.dependencies) {
					// No null check, if the dependency doesn't exist then the main pack shouldn't have been loaded to the list in the first place
					var pack = PackManager.packMap.get(packId);
					var path = '${pack.path}/$key';
					if (exists(path))
						return path;
				}
			}
			return null;
		}

		for (pack in PackManager.readList) {
			var path = '${pack.path}/$key';
			if (exists(path))
				return path;
		}

		return null;
	}

	public static inline function getFolderPath(packId:String):String
		return PackManager.packMap.get(packId).path;

	public static function getFolders(dir:String):Array<String>
		return [for (pack in PackManager.readList)
			'${pack.path}/$dir/'
		];

	public static inline function getPaths(key:String)
		return new PackPathsIterator(key);

	public static function getFileWithExtensions(scriptPath:String, extensions:Array<String>):Null<String> {
		for (fileExt in extensions) {
			var fullPath = getPath('$scriptPath.$fileExt');
			if (fullPath != null)
				return fullPath;
		}

		return null;
	}

	/*
	inline static public function txt(key:String):String
		return 'data/$key.txt';

	inline static public function png(key:String):String
		return 'images/$key.png';

	inline static public function xml(key:String):String
		return 'images/$key.xml';

	inline static public function songJson(key:String):String
		return 'songs/$key.json';

	inline static public function shaderFragment(key:String):String
		return 'shaders/$key.frag';

	inline static public function shaderVertex(key:String):String
		return 'shaders/$key.vert';
	*/

	inline static public function font(key:String)
	{
		return getPath('fonts/$key');
	}

	public inline static function video(key:String, ext:String = "mp4"):String
	{
		return getPath('videos/$key.$ext');
	}

	public inline static function getShaderFragment(name:String):Null<String>
	{
		return getPath('shaders/$name.frag');
	}
	
	public inline static function getShaderVertex(name:String):Null<String>
	{
		return getPath('shaders/$name.vert');
	}

	public inline static function getHScriptPath(scriptPath:String):Null<String>
	{
		#if HSCRIPT_ALLOWED
		return getFileWithExtensions(scriptPath, Paths.HSCRIPT_EXTENSIONS);
		#else
		return null;
		#end
	}

	public inline static function hscript(key:String):Null<String> {
		#if HSCRIPT_ALLOWED
		return getFileWithExtensions(key, Paths.HSCRIPT_EXTENSIONS);
		#else
		return null;
		#end
	}

	inline static public function sound(key:String, ?library:String):Null<Sound>
	{
		return returnFolderSound('sounds', key, library);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String):Null<Sound>
	{
		return returnFolderSound('music', key, library);
	}

	inline static public function track(song:String, track:String):Null<Sound>
	{
		return returnFolderSound('songs', '${formatToSongPath(song)}/$track');
	}

	inline static public function voices(song:String):Null<Sound>
	{
		return track(song, "Voices");
	}

	inline static public function inst(song:String):Null<Sound>
	{
		return track(song, "Inst");
	}

	public static function isHScript(file:String){
		for(ext in Paths.HSCRIPT_EXTENSIONS)
			if(file.endsWith('.$ext'))
				return true;
		
		return false;
	}
		
	inline static public function withoutEndingSlash(path:String)
		return path.endsWith("/") ? path.substr(0, -1) : path;

	inline static public function exists(path:String, ?type:AssetType):Bool {
		#if FILESYSTEM_ALLOWED 
		if (FileSystem.exists(path))
			return true;
		#end
		#if READ_EMBEDDED_ASSETS
		if (Assets.exists(path, type))
			return true;
		#end
		return false;
	}
	inline static public function getContent(path:String):Null<String> {
		#if FILESYSTEM_ALLOWED
		if (FileSystem.exists(path))
			return File.getContent(path);
		#end
		#if READ_EMBEDDED_ASSETS
		if (Assets.exists(path))
			return Assets.getText(path);
		#end
		return null;
	}
	inline static public function getBytes(path:String):Null<haxe.io.Bytes> {
		#if FILESYSTEM_ALLOWED
		if (FileSystem.exists(path))
			return File.getBytes(path);
		#end
		#if READ_EMBEDDED_ASSETS
		if (Assets.exists(path))
			return Assets.getBytes(path);
		#end
		return null;
	}
	inline static public function isDirectory(path:String):Bool {
		#if FILESYSTEM_ALLOWED
		if (FileSystem.exists(path))
			return FileSystem.isDirectory(path);
		#end
		#if READ_EMBEDDED_ASSETS
		if (AltFilePaths.isDirectory(path))
			return true;
		#end
		return false;
	}
	inline static public function getDirectoryFileList(path:String):Array<String> {
		#if FILESYSTEM_ALLOWED
		if (FileSystem.isDirectory(path))
			return FileSystem.readDirectory(path);
		#end
		#if READ_EMBEDDED_ASSETS
		if (AltFilePaths.isDirectory(path))
			return AltFilePaths.getDirectoryFileList(path);
		#end
		return [];
	}

	inline public static function getText(path:String):Null<String> {
		#if FILESYSTEM_ALLOWED
		if (FileSystem.exists(path))
			return File.getContent(path);
		#end

		#if READ_EMBEDDED_ASSETS
		if (Assets.exists(path))
			return Assets.getText(path);
		#end

		return null;
	}
	inline public static function getBitmapData(path:String):Null<BitmapData> {
		#if FILESYSTEM_ALLOWED
		if (FileSystem.exists(path))
			return BitmapData.fromFile(path);
		#end

		#if READ_EMBEDDED_ASSETS
		if (Assets.exists(path, IMAGE))
			return Assets.getBitmapData(path);
		#end

		return null;
	}
	inline public static function getSound(path:String):Null<Sound> {
		#if FILESYSTEM_ALLOWED
		if (FileSystem.exists(path))
			return Sound.fromFile(path);
		#end

		#if READ_EMBEDDED_ASSETS
		if (Assets.exists(path))
			return Assets.getSound(path);
		#end

		return null;
	}
	static public function getJson(path:String):Null<Dynamic>
	{
		var raw = Paths.getContent(path);
		if (raw == null)
			return null;

		try {
			return Json.parse(raw);
		}
		catch(e:haxe.Exception) {
			var e = e.message;
			
			/* LIKE SI TE VALE BERGA */
			inline function includeLinePosition() {
				var matchStr = 'at position ';
				var matchIdx = e.lastIndexOf(matchStr);
				if (matchIdx == -1) return;

				var position:String = e.substring(matchIdx + matchStr.length, e.length);
				var position:Null<Int> = Std.parseInt(position);
				//if (position == null) return;
				
				var line:Int = 1;
				for (i in 0...position)
					if (raw.fastCodeAt(i) == '\n'.code)
						line++;
				
				if (line > 1)
					e += ' (line $line)';

				return;
			}
			includeLinePosition();

			print('$path: $e');
		}

		return null;
	}

	inline static public function sparrowAtlas(key:String, ?library:String, allowGPU:Bool = true):FlxAtlasFrames
	{
		var rawXml = Paths.getContent(getPath('images/$key.xml'));
		return rawXml == null ? null : FlxAtlasFrames.fromSparrow(
			image(key, library, allowGPU),
			Xml.parse(rawXml)
		);
	}

	inline static public function packerAtlas(key:String, ?library:String, allowGPU:Bool = true):FlxAtlasFrames
	{
		var rawTxt:String = Paths.getContent(getPath('images/$key.txt'));
		return rawTxt == null ? null : FlxAtlasFrames.fromSpriteSheetPacker(
			image(key, library, allowGPU),
			rawTxt
		);
	}

	inline static public function asepriteAtlas(key:String, ?library:String, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var raw:String = Paths.getContent(getPath('images/$key.json'));
		return raw == null ? null : FlxAtlasFrames.fromTexturePackerJson(
			image(key, library, allowGPU),
			raw
		);		
	}

	inline static public function animateAtlas(key:String, ?library:String)
	{
		#if USING_FLXANIMATE
		var path = animateAtlasPath(key, library);
		return animate.FlxAnimateFrames.fromAnimate(path);
		#else
		return null;
		#end
	}

	#if ALLOW_DEPRECATION
	@:deprecated("getSparrowAtlas is deprecated, use sparrowAtlas instead.")
	inline static public function getSparrowAtlas(key:String, ?library:String, allowGPU:Bool = true):FlxAtlasFrames
	{
		return sparrowAtlas(key, library, allowGPU);
	}

	@:deprecated("getPackerAtlas is deprecated, use packerAtlas instead.")
	inline static public function getPackerAtlas(key:String, ?library:String, allowGPU:Bool = true):FlxAtlasFrames
	{
		return packerAtlas(key, library, allowGPU);
	}

	@:deprecated("getAsepriteAtlas is deprecated, use asepriteAtlas instead.")
	inline static public function getAsepriteAtlas(key:String, ?library:String, allowGPU:Bool = true)
	{
		return asepriteAtlas(key, library, allowGPU);
	}

	@:deprecated("getTextureAtlas is deprecated, use animateAtlas instead.")
	inline static public function getTextureAtlas(key:String, ?library:String)
	{
		return animateAtlas(key, library);
	}
	#end

	/** returns a FlxRuntimeShader but with file names lol **/ 
	public static function getShader(fragFile:String = null, vertFile:String = null, version:Int = null):FlxRuntimeShader
	{
		try{
			return new FlxRuntimeShader(
				fragFile==null ? null : Paths.getContent(getShaderFragment(fragFile)), 
				vertFile==null ? null : Paths.getContent(getShaderVertex(vertFile))
			);
		}catch(e:Dynamic){
			trace("Shader compilation error:" + e.message);
		}

		return null;		
	}

	/** 
		Iterates through a directory and calls a function with the name of each file contained within it
		Returns true if the directory was a valid folder and false if not.
	**/
	@:deprecated('iterateDirectory is deprecated. Use readDirectory instead!')
	inline static public function iterateDirectory(path:String, func:haxe.Constraints.Function):Bool
	{
		#if FILESYSTEM_ALLOWED
		if (FileSystem.exists(path) && FileSystem.isDirectory(path)) {
			for (name in FileSystem.readDirectory(path))
				func(name);
			
			return true;	
		}
		#end
		#if READ_EMBEDDED_ASSETS
		return AltFilePaths.iterateDirectory(path, func);
		#else
		return false;
		#end
	}

	public static inline function _readDirectory(path:String):Null<Array<String>> {
		return if (FileSystem.exists(path) && FileSystem.isDirectory(path))
			FileSystem.readDirectory(path);
		else
			null;
	}

	public static inline function readDirectory(path:String):Array<String> {
		var ret:Array<String>;

		#if FILESYSTEM_ALLOWED
		ret = Paths._readDirectory(path);
		if (ret != null) return ret; 
		#end
		
		#if READ_EMBEDDED_ASSETS
		ret = AltFilePaths._readDirectory(path);
		if (ret != null) return ret; 
		#end
		
		ret = [];
		return ret;
	}

	inline static public function fileExists(key:String, ?type:AssetType, ?library:String):Bool
	{
		return getPath(key) != null;
	}

	/** Returns the contents of a file as a string. **/
	inline public static function text(key:String):Null<String>
		return getContent(getPath(key));

	inline public static function bytes(key:String):Null<Bytes>
		return getBytes(getPath(key));

	inline static public function formatToSongPath(path:String) {
		var finalPath = "";

		for (idx in 0...path.length)
		{
			var char = path.charAt(idx);
			switch(char) {
				case '.' | '!' | '?' | '%' | '"' | "," | "'":
					continue;
				
				case ' ' | '#' | '>' | '<' | ':' | ';' | '\\' | '~' | '&':
					finalPath += "-";
				
				default:
					finalPath += char;
			}
		}

		return finalPath.toLowerCase();
	}

	public static function getGraphic(path:String, cache:Bool = true, gpu:Bool = true):Null<FlxGraphic>
	{
		var newGraphic:FlxGraphic;

		if (cache && currentTrackedAssets.exists(path)) {
			newGraphic = currentTrackedAssets.get(path);
			if (!localTrackedAssets.contains(path)) 
				localTrackedAssets.push(path);
		}
		else {
			var bitmap:BitmapData = getBitmapData(path);
			if (bitmap == null) return null;

			// GPU caching made by Raltyro
			if (gpu && ClientPrefs.cacheOnGPU && bitmap.image != null) {
				bitmap.lock();
				if (bitmap.__texture == null)
				{
					bitmap.image.premultiplied = true;
					bitmap.getTexture(FlxG.stage.context3D);
				}
				bitmap.getSurface();
				bitmap.disposeImage();
				bitmap.image.data = null;
				bitmap.image = null;
				bitmap.readable = true;
			}

			newGraphic = FlxGraphic.fromBitmapData(bitmap, false, path, cache);
			newGraphic.persist = true;
			newGraphic.destroyOnNoUse = false;

			if (cache) {
				localTrackedAssets.push(path);
				currentTrackedAssets.set(path, newGraphic);
			}
		}

		return newGraphic;
	}

	inline public static function cacheGraphic(path:String):Null<FlxGraphic>
		return getGraphic(path, true);

	/** Like Paths.image, but it gets a path from the base folder instead of the images folder **/
	public static function graphic(key:String, ?pack:String, allowGPU:Bool = true):Null<FlxGraphic>
	{
		var path:String = getPath('$key.$IMAGE_EXT', pack);

		var graphic = (path==null) ? null : getGraphic(path, true, allowGPU);
		if (graphic==null && Main.showDebugTraces)
			trace('bitmap "$key" => "$path" returned null.');

		return graphic;
	}

	public static function image(key:String, ?pack:String, allowGPU:Bool = true):Null<FlxGraphic>
	{
		return graphic('images/$key', pack, allowGPU);
	}

	inline public static function imagePath(key:String, ?pack:String):Null<String>
		return getPath('images/$key.$IMAGE_EXT', pack);

	inline public static function imageExists(key:String):Bool
		return imagePath(key) != null;

	inline public static function soundPath(path:String, key:String, ?library:String)
	{
		return getPath('$path/$key.$SOUND_EXT');
	}

	inline public static function animateAtlasPath(key:String, ?library:String):String
	{
		return getPath('images/$key');
	}
	
	inline public static function returnFolderSound(path:String, key:String, ?library:String)
		return returnSound(soundPath(path, key, library), library);

	public static function returnSound(path:String, ?library:String)
	{	
		if (currentTrackedSounds.exists(path)) {
			if (!localTrackedAssets.contains(path))
				localTrackedAssets.push(path);

			return currentTrackedSounds.get(path);
		}
		
		var sound = getSound(path);
		if (sound != null) {
			currentTrackedSounds.set(path, sound);
	
			if (!localTrackedAssets.contains(path))
				localTrackedAssets.push(path);	
			
			return sound;
		}
		
		if (Main.showDebugTraces)
			trace('sound $path returned null');
		
		return null;
	}

	/** Return the contents of a file, parsed as a JSON. **/
	static public function json(key:String):Null<Dynamic>
	{
		var path:Null<String> = getPath(key);
		return (path == null) ? null : getJson(path);
	}

	////
	public static var currentPack(get, set):Pack;
	public static var currentPackId(get, set):String;
	public static var packList(get, never):Array<String>;
	public static var packMap(get, never):Map<String, Pack>;

	static inline function get_currentPack() return PackManager.currentPack;
	static inline function set_currentPack(v:Pack) return PackManager.currentPack = v;
	static inline function get_currentPackId() return PackManager.currentPackId;
	static inline function set_currentPackId(v:String) return PackManager.currentPackId = v;
	static inline function get_packList() return PackManager.packList;
	static inline function get_packMap() return PackManager.packMap;
	
	#if ALLOW_DEPRECATION
	@:deprecated('contentFolderName is deprecated! Use CONTENT_PATH instead.')
	public static var contentFolderName(get, never):String;
	static inline function get_contentFolderName() return CONTENT_PATH;

	@:deprecated('currentModDirectory is deprecated! Use currentPackId instead.')
	public static var currentModDirectory(get, set):String;
	static inline function get_currentModDirectory() return currentPackId;
	static inline function set_currentModDirectory(v:String) return currentPackId = v;
	#end

	//// String stuff, should maybe move this to a diff class¿¿¿
	public static var locale(default, set):String;
	
	private static final currentStrings:Map<String, String> = [];
	
	@:noCompletion static function set_locale(l:String){
		if (l != locale) {
			locale = l;
			getAllStrings();
		}
		return locale;
	}

	public static function getAllStrings():Void {
		currentStrings.clear();
		// trace("refreshing strings");

		var checkFiles = ['lang/$locale.txt', 'lang/$locale.lang', "lang/en.txt", "strings.txt"]; 
		for (filePath in Paths.getFolders("data")) {
			for (fileName in checkFiles) {
				var path:String = filePath + fileName;
				if (!Paths.exists(path)) continue;
				
				var file = LocalizationMap.fromFile(path);
				for (k => v in file) {
					if (!currentStrings.exists(k))
						currentStrings.set(k, v);
				}
			}
		}
	}

	public static inline function hasString(key:String):Bool
		return currentStrings.exists(key);

	public static inline function getString(key:String):Null<String>{
		return currentStrings.get(key);
	}
}

class PackPathsIterator {
	var key:String;
	var i:Int = 0;

	public inline function new(key:String) {
		this.key = key;
		i = 0;
	}

	public inline function hasNext():Bool {
		return i < PackManager.readList.length;
	}

	public inline function next():{k:Pack, v:String} {
		return {k: PackManager.readList[i++], v: PackManager.readList[i].getPath(key)};
	}
}

private class AltFilePaths {
	#if READ_EMBEDDED_ASSETS
	// Directory => Array with file/sub-directory names
	static var dirMap = new Map<String, Array<String>>();

	public static function initPaths(){	
		dirMap.clear();
		dirMap.set("", []);

		for (path in Assets.list())
		{
			//trace("WORKING WITH PATH:", path);

			var file:String = path.split("/").pop();
			var parent:String = path.substr(0, path.length - (file.length + 1)); // + 1 to remove the ending slash

			var parentTree = parent.split("/");
			for (totality in 1...parentTree.length+1)
			{
				var totality = parentTree.length - totality;
				var dirPathSplit = [for (i in 0...totality+1) {parentTree[i];}];
				var dirPath = dirPathSplit.join("/");
				
				if (!dirMap.exists(dirPath)){
					dirMap.set(dirPath, []);
					//trace("reg folder", dirPath, "from", path);
				//}else{
					//trace("did NOT reg folder", dirPath, "from", path);
				}
			}
			
			dirMap.get(parent).push(file);
			//trace("END");
		}
		
		////
		for (path => dir in dirMap)
		{
			var name:String = path.split("/").pop();
			var parent:String = path.substr(0, path.length - (name.length + 1)); // + 1 to remove the ending slash

			if (dirMap.exists(parent)){
				var parentDir = dirMap.get(parent);
				if (!parentDir.contains(name)){
					parentDir.push(name);
				}
			}
		}

		// trace(dirMap["assets/songs"]);

		return dirMap;
	}

	inline static public function withoutEndingSlash(path:String)
		return path.endsWith("/") ? path.substr(0, -1) : path;

	inline static public function isDirectory(path:String):Bool {
		return dirMap.exists(withoutEndingSlash(path));
	}

	inline static public function getDirectoryFileList(path:String):Array<String> {
		var dir:String = withoutEndingSlash(path);
		return !dirMap.exists(dir) ? [] : [for (i in dirMap.get(dir)) i];
	}

	/** 
		Iterates through a directory and calls a function with the name of each file contained within it
		Returns true if the directory was a valid folder and false if not.
	**/
	inline static public function iterateDirectory(path:String, Func:haxe.Constraints.Function)
	{
		var dir:String = withoutEndingSlash(path);

		if (!dirMap.exists(dir)){
			trace('Directory $dir does not exist?');
			return false;
		}

		for (i in dirMap.get(dir))
			Func(i);
		
		return true;
	}

	public static inline function _readDirectory(path:String):Null<Array<String>> {
		if (dirMap.exists(dir))
			dirMap.get(dir);
		else	
			null;
	}
	#end
}
