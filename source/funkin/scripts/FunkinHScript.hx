package funkin.scripts;

import funkin.scripts.*;
import funkin.scripts.Globals.*;

import funkin.states.PlayState;
import funkin.states.base.MusicBeatState;
import funkin.states.base.MusicBeatSubstate;
import funkin.Conductor;
import funkin.ClientPrefs;

import funkin.input.Controls;
import funkin.api.Windows;

import flixel.FlxG;

#if linc_filedialogs
import filedialogs.FileDialogs;
#end
import lime.app.Application;
import haxe.Constraints.Function;

import hscript.*;

using StringTools;

class FunkinHScript
{
	public static final parser:Parser = {
		var parser = new Parser();

		parser.allowMetadata = true;
		parser.allowJSON = true;
		parser.allowTypes = true;

		parser.preprocesorValues = funkin.macros.Sowy.getDefines();
		parser.preprocesorValues.set("TROLL_ENGINE", Main.Version.semanticVersion);

		parser;
	};
	
	public static final defaultVars:Map<String, Dynamic> = new Map<String, Dynamic>();

	public static function init() // BRITISH
	{
		
	}

	public static function _parseString(script:String, ?name:String = "Script"):Expr
	{
		parser.line = 1;
		return parser.parseString(script, name);
	}

	public static function parseString(script:String, ?name:String = "Script"):Null<Expr>
	{
		try {
			return _parseString(script, name);
		}
		catch (e:haxe.Exception) {
			final msg = e.message;
			print(msg);

			#if desktop
			Application.current.window.alert(msg, "Error parsing script!");
			#end
		}

		return null;
	}

	public static function parseFile(file:String, ?name:String):Null<Expr>
	{
		try {
			var fileContent = Paths.getContent(file);
			if (fileContent != null) {
				//print('Loading haxe script from: $file');
				return _parseString(fileContent, name ?? file);
			}else {
				//print('HScript file "$file" not found!');
			}
		}
		catch(e:haxe.Exception) {
			final title = "Error parsing script!";
			final msg = e.message;
			print(e.message);

			#if WINDOWS_CRASH_HANDLER
			if (Windows.msgBox(msg, title, RETRYCANCEL | ERROR) == RETRY)
				return parseFile(file, name);
			/* I get weird cpp compile errors so IDK
			#elseif (UNIX_CRASH_HANDLER && linc_filedialogs)
			if (FileDialogs.message(title, msg, Choice.Retry_Cancel, Icon.Error) == Button.Retry)
				return parseFile(file, name);
			*/
			#else
			Application.current.window.alert(msg, title);
			#end
		}

		return null;
	}

	public static inline function blankScript(?name, ?additionalVars, ?interp:Interp)
	{
		return new FunkinHScript(null, name, additionalVars, false, interp);
	}

	public static inline function fromExpr(parsed:Expr, ?name:String, ?additionalVars:Map<String, Any>, ?doCreateCall:Bool = true, ?interp:Interp):Null<FunkinHScript>
	{
		return new FunkinHScript(parsed, name, additionalVars, doCreateCall, interp);
	}

	/**
		Creates a `FunkinHScript` instance with code from a string.  
		If a parsing error occurs, a message box is displayed.

		@param script The script code.
		@param name An optional name to give the script.
		@param additionalVars A map of variables to define on this script before running its code.
		@param doCreateCall Whether to call `onCreate` on this script.
		@returns A `FunkinHScript` instance.
	**/
	public static inline function fromString(script:String, ?name:String = "Script", ?additionalVars:Map<String, Any>, ?doCreateCall:Bool = true, ?interp:Interp):Null<FunkinHScript>
	{
		return fromExpr(parseString(script, name), name, additionalVars, doCreateCall, interp);
	}

	/**
		Creates a `FunkinHScript` instance with code from a file.  
		If a parsing error occurs, a message box is displayed.  

		@param file The *full* path containing the script code.
		@param name An optional name to give the script.
		@param additionalVars A map of variables to define on this script before running its code.
		@param doCreateCall Whether to call `onCreate` on this script.
		@returns A `FunkinHScript` instance.
	**/
	public static inline function fromFile(file:String, ?name:String, ?additionalVars:Map<String, Any>, ?doCreateCall:Bool = true, ?interp:Interp):Null<FunkinHScript>
	{
		return fromExpr(parseFile(file, name), name, additionalVars, doCreateCall, interp);
	}

	public static function fromName(key:String, ?name:String, ?additionalVars:Map<String, Any>, ?doCreateCall:Bool = true, ?interp:Interp):Null<FunkinHScript>
	{
		var file = Paths.getHScriptPath(key);
		if (file != null)
			return fromFile(file, name, additionalVars, doCreateCall, interp);
		
		print('HScript file "$key" not found!');
		return null;
	}

	private static inline function trim_redundant_error_trace(message:String, posInfo:haxe.PosInfos):String
	{
		if (message.startsWith(posInfo.fileName)) {
			var to_remove = posInfo.fileName + ":" + posInfo.lineNumber + ": ";
			message = message.substr(to_remove.length); 
		}

		return message;
	}

	////
	public var scriptName:String;

	private var interpreter(default, null):Interp;

	public function new(?parsed:Expr, ?name:String, ?additionalVars:Map<String, Any>, ?doCreateCall:Bool = true, ?interp:Interp)
	{
		name ??= parsed?.origin ?? "HScript";
		interpreter = interp ??= new Interp();
		this.scriptName = name;

		set("Std", Std);
		set("Type", Type);
		set("Reflect", Reflect);
		set("Math", Math);
		set("StringTools", StringTools);
		set("Main", Main);

		set("StringMap", haxe.ds.StringMap);
		set("ObjectMap", haxe.ds.ObjectMap);
		set("EnumValueMap", haxe.ds.EnumValueMap);
		set("IntMap", haxe.ds.IntMap);

		set("Date", Date);
		set("DateTools", DateTools);
		
		set("getClass", Type.resolveClass);
		set("getEnum", Type.resolveEnum);
		set("importClass", importClass);
		set("importEnum", importEnum);

		set("print", Print.print);
		set("debugPrint", DebugLog.print);
		
		set("script", this);
		set("funkinScript", this);

		set("global", Globals.variables);
		set("FunkinHScript", FunkinHScript);

		setDefaultVars();
		setFlixelVars();
		setFNFVars();

		for (variable => arg in defaultVars)
			set(variable, arg);

		if (additionalVars != null)
		{
			for (key => value in additionalVars)
				set(key, value);
		}

		if (parsed != null){
			print('Running haxe script ${parsed.origin}');
			run(parsed);
			
			if (doCreateCall)
				call('onCreate');
		}
	}

	/**
		Helper function
		Sets a bunch of basic variables for the script depending on the state
	**/
	inline function setDefaultVars() {
		set("scriptName", scriptName);

		set('Function_Continue', Globals.Function_Continue);
		set('Function_Stop', Globals.Function_Stop);
		set('Function_Halt', Globals.Function_Halt);
		set('Function_StopAll', Globals.Function_Halt);

		set('teVersion', StringTools.trim(Main.Version.displayedVersion));
		set("trollEngine", true); // so if any psych mods wanna add troll engine specific stuff well there they go

		#if windows
		set('buildTarget', 'windows');
		#elseif linux
		set('buildTarget', 'linux');
		#elseif mac
		set('buildTarget', 'mac');
		#elseif html5
		set('buildTarget', 'browser');
		#elseif android
		set('buildTarget', 'android');
		#else
		set('buildTarget', 'unknown');
		#end
		
		set('curBpm', Conductor.bpm);
		set('crochet', Conductor.crochet);
		set('stepCrochet', Conductor.stepCrochet);

		set('curBeat', 0);
		set('curStep', 0);
		set('curDecBeat', 0.0);
		set('curDecStep', 0.0);

		var currentState = flixel.FlxG.state;

		set("inTitlescreen", (currentState is funkin.states.TitleState));
		set('inGameOver', false);
		set('inChartEditor', false);

		if (currentState is PlayState && currentState == PlayState.instance) {
			set("inPlaystate", true);
			
			set("curSection", -1);
			set("sectionData", null);
		}else{
			set("inPlaystate", false);
			set("showDebugTraces", Main.showDebugTraces);
		}
		
		set("state", currentState);
		set("game", PlayState.instance);
	}

	inline function setFlixelVars() 
	{
		set("FlxG", FlxG);
		set("FlxSprite", FlxSprite);
		set("FlxCamera", FlxCamera);
		set("FlxSound", FlxSound);
		set("FlxText", flixel.text.FlxText);
		set("FlxMath", flixel.math.FlxMath);
		set("FlxGroup", flixel.group.FlxGroup);
		set("FlxSpriteGroup", flixel.group.FlxSpriteGroup);
		set("FlxTween", flixel.tweens.FlxTween);
		set("FlxEase", flixel.tweens.FlxEase);
		set("FlxTimer", flixel.util.FlxTimer);
		set("FlxSave", flixel.util.FlxSave); // should probably give it 1 save instead of giving it FlxSave
		set("FlxBar", flixel.ui.FlxBar);

		set("FlxParticle", flixel.effects.particles.FlxParticle);
		set("FlxTypedEmitter", flixel.effects.particles.FlxEmitter.FlxTypedEmitter);

		#if flixel_addons
		set("FlxBackdrop", flixel.addons.display.FlxBackdrop);
		set("FlxSkewedSprite", flixel.addons.effects.FlxSkewedSprite);
		set("FlxTiledSprite", flixel.addons.display.FlxTiledSprite);
		set("FlxRuntimeShader", flixel.addons.display.FlxRuntimeShader);
		#end
		#if USING_FLXANIMATE
		set("FlxAnimate", animate.FlxAnimate);
		set("FlxAnimateFrames", animate.FlxAnimateFrames);
		set("FlxSpriteElement", animate.internal.elements.FlxSpriteElement);
		#end
		#if VIDEOS_ALLOWED
		set("FlxVideo", hxvlc.flixel.FlxVideo);
		set("FlxVideoSprite", hxvlc.flixel.FlxVideoSprite);
		#end
		// Enums
		set("FlxBarFillDirection", flixel.ui.FlxBar.FlxBarFillDirection);
		set("FlxTextBorderStyle", flixel.text.FlxText.FlxTextBorderStyle);
		set("FlxCameraFollowStyle", flixel.FlxCamera.FlxCameraFollowStyle);

		// Abstracts
		set("BlendMode", Wrappers.BlendMode);
		set("FlxTextAlign", Wrappers.FlxTextAlign);
		set("FlxTweenType", Wrappers.FlxTweenType);
		set("FlxAxes", Wrappers.FlxAxes);
		set("FlxColor", Wrappers.SowyColor);
		set("FlxPoint", Wrappers.FlxPoint);

		set("ShaderFilter", openfl.filters.ShaderFilter);
	}

	inline function setFNFVars() {
		// FNF-specific things
		set("controls", Controls.firstActive);
		set("get_controls", () -> return Controls.firstActive);
		set("newShader", Paths.getShader);
		
		set("Paths", funkin.Paths);
		set("ClientPrefs", funkin.ClientPrefs);
		set("CoolUtil", funkin.CoolUtil);
		set("Conductor", funkin.Conductor);
		set("Song", funkin.data.Song);
		set("Highscore", funkin.data.Highscore); // Useful for stuff like levels showing diff songs before and after finishing (i.e Weekend 1)

		set("MusicBeatState", MusicBeatState);
		set("MusicBeatSubstate", MusicBeatSubstate);
		set("HScriptedState", funkin.states.scripting.HScriptedState);
		set("HScriptedSubstate", funkin.states.scripting.HScriptedSubstate);
		set("PlayState", PlayState);
		set("GameOverSubstate", funkin.states.GameOverSubstate);

		set("Note", funkin.objects.notes.Note);
		set("NoteObject", funkin.objects.notes.NoteObject);
		set("NoteSplash", funkin.objects.notes.NoteSplash);
		set("StrumNote", funkin.objects.notes.StrumNote);
		set("PlayField", funkin.objects.playfields.PlayField);
		set("NoteField", funkin.objects.playfields.NoteField);

		set("ProxyField", funkin.objects.proxies.ProxyField);
		set("ProxySprite", funkin.objects.proxies.ProxySprite);

		set("BGSprite", funkin.objects.BGSprite);
		set("AltBGSprite", funkin.objects.BGSprite.AltBGSprite);
		set("FlxSprite3D", funkin.objects.FlxSprite3D);

		set("AttachedSprite", funkin.objects.AttachedSprite);
		set("AttachedText", funkin.objects.AttachedText);

		set("Character", funkin.objects.Character);
		set("HealthIcon", funkin.objects.hud.HealthIcon);
		set("RatingSprite", funkin.objects.hud.RatingGroup.RatingSprite);

		set("JudgmentManager", funkin.data.JudgmentManager);
		set("Judgement", Wrappers.Judgment);
		set("Wife3", funkin.data.JudgmentManager.Wife3);
		set("PBot", funkin.data.JudgmentManager.PBot);

		set("ModManager", funkin.modchart.ModManager);
		set("Modifier", funkin.modchart.Modifier);
		set("SubModifier", funkin.modchart.SubModifier);
		set("NoteModifier", funkin.modchart.NoteModifier);
		set("EventTimeline", funkin.modchart.EventTimeline);
		set("StepCallbackEvent", funkin.modchart.events.StepCallbackEvent);
		set("CallbackEvent", funkin.modchart.events.CallbackEvent);
		set("ModEvent", funkin.modchart.events.ModEvent);
		set("EaseEvent", funkin.modchart.events.EaseEvent);
		set("SetEvent", funkin.modchart.events.SetEvent);

		set("HScriptedHUD", funkin.objects.huds.HScriptedHUD);
		set("HScriptModifier", funkin.modchart.HScriptModifier);
	} 

	function importClass(className:String)
	{
		// importClass("flixel.util.FlxSort") should give you FlxSort.byValues, etc
		// whereas importClass("scripts.Globals.*") should give you Function_Stop, Function_Continue, etc
		// i would LIKE to do like.. flixel.util.* but idk if I can get everything in a namespace
		var classSplit:Array<String> = className.split(".");
		var daClassName = classSplit[classSplit.length - 1]; // last one

		if (daClassName == '*')
		{
			var daClass = Type.resolveClass(className);

			while (classSplit.length > 0 && daClass == null)
			{
				daClassName = classSplit.pop();
				daClass = Type.resolveClass(classSplit.join("."));
				if (daClass != null)
					break;
			}
			if (daClass != null)
			{
				for (field in Reflect.fields(daClass))
					set(field, Reflect.field(daClass, field));
			}
			else
			{
				FlxG.log.error('Could not import class $className');
			}
		}
		else
		{
			set(daClassName, Type.resolveClass(className));
		}
	}

	function importEnum(enumName:String)
	{
		// same as importClass, but for enums
		// and it cant have enum.*;
		var splitted:Array<String> = enumName.split(".");
		var daEnum = Type.resolveEnum(enumName);
		if (daEnum != null)
			set(splitted.pop(), daEnum);
	}

	/**
	 * Parses and executes string code
	 */
	public function executeCode(source:String):Dynamic
		return run(parseString(source, scriptName));
	
	public function run(parsed:Expr) {
		try {
			return interpreter.execute(parsed);
		}
		catch(e:Dynamic) {
			onError(e);
		}
		return null;
	}

	public dynamic function onError(e:Dynamic) {
		traceException(e);
	}

	inline function traceException(e:Dynamic):Void {
		final str = e.toString();
		print(str);
		DebugLog.addMessage(str, 0xFFFF0000);
		/*
		var posInfo = interpreter.posInfos();
		var message = trim_redundant_error_trace(e.message, posInfo);
		print(haxe.Log.formatOutput(message, posInfo));
		*/
	}

	public function get(varName:String):Dynamic
	{
		return (interpreter == null) ? null : interpreter.variables.get(varName);
	}

	public function set(varName:String, value:Dynamic):Void
	{
		if (interpreter != null)
			interpreter.variables.set(varName, value);
	}

	public function exists(varName:String):Bool
	{
		return interpreter != null && interpreter.variables.exists(varName);
	}

	/**
	 * Calls a function within the script
	**/
	public function call(funcName:String, ?parameters:Array<Dynamic>):Dynamic
	{
		var daFunc:Function = get(funcName);
		if (daFunc == null)
			return null;

		if (parameters == null)
			parameters = [];

		var returnVal:Dynamic = null;
		try {
			returnVal = Reflect.callMethod(null, daFunc, parameters);
		}
		catch (e:Dynamic)
		{
			print('$scriptName: Error calling `$funcName(' +  parameters.join(', ') + ')`');
			onError(e);
		}

		return returnVal;
	}

	/**
	 * Calls a function within the script
	**/
	public function executeFunc(funcName:String, ?parameters:Array<Dynamic>, ?parentObject:Any, ?extraVars:Map<String, Dynamic>):Dynamic
	{
		var daFunc:Function = get(funcName);
		if (daFunc == null)
			return null;

		if (parameters == null)
			parameters = [];

		if (parentObject != null){
			if (extraVars == null) extraVars = [];
			extraVars.set("this", parentObject);
		}

		var prevVals:Map<String, Dynamic> = null;

		if (extraVars != null) {
			prevVals = [];

			for (name => value in extraVars) {
				prevVals.set(name, get(name));
				set(name, value);
			}
		}

		var returnVal:Dynamic = null;
		try {
			returnVal = Reflect.callMethod(parentObject, daFunc, parameters);
		}
		catch (e:Dynamic)
		{
			print('$scriptName: Error executing `$funcName(' +  parameters.join(', ') + ')`');
			onError(e);
		}

		if (prevVals != null) {
			for (name => value in prevVals)
				set(name, value);
		}

		return returnVal;
	}

	public function stop()
	{
		//trace('stopping $scriptName');

		// idk if there's really a stop function or anythin for hscript so
		if (interpreter != null && interpreter.variables != null)
			interpreter.variables.clear();

		interpreter = null;
	}
}