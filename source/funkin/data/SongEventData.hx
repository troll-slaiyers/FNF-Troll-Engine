package funkin.data;

import haxe.io.Path;

private var psychEventStuff = [ 
	['Hey!', "Plays the \"Hey!\" animation from Bopeebo,\nValue 1: BF = Only Boyfriend, GF = Only Girlfriend,\nSomething else = Both.\nValue 2: Custom animation duration,\nleave it blank for 0.6s"],
	['Set GF Speed', "Sets GF head bopping speed,\nValue 1: 1 = Normal speed,\n2 = 1/2 speed, 4 = 1/4 speed etc.\nUsed on Fresh during the beatbox parts.\n\nWarning: Value must be integer!"],
	['Add Camera Zoom', "Used on MILF on that one \"hard\" part\nValue 1: Camera zoom add (Default: 0.015)\nValue 2: UI zoom add (Default: 0.03)\nLeave the values blank if you want to use Default."],
	['Play Animation', "Plays an animation on a Character,\nonce the animation is completed,\nthe animation changes to Idle\n\nValue 1: Animation to play.\nValue 2: Character (Dad, BF, GF)"],
	['Camera Follow Pos', "Value 1: X\nValue 2: Y\n\nThe camera won't change the follow point\nafter using this, for getting it back\nto normal, leave both values blank."],
	["Change Focus", "Sets who the camera is focusing on.\nNote that the must hit changing on a section will reset\nthe focus.\nValue 1: Who to focus on (dad, bf)"],
	
	['Stage Event', 'Event whose behaviour defined by the stage.'],
	['Song Event', 'Event whose behaviour defined by the song.'],
	['Set Property', "Value 1: Variable name\nValue 2: New value"],
	
	['Alt Idle Animation', "Sets a specified suffix after the idle animation name.\nYou can use this to trigger 'idle-alt' if you set\nValue 2 to -alt\n\nValue 1: Character to set (Dad, BF or GF)\nValue 2: New suffix (Leave it blank to disable)"],
	['Screen Shake', "Value 1: Camera shake\nValue 2: HUD shake\n\nEvery value works as the following example: \"1, 0.05\".\nThe first number (1) is the duration.\nThe second number (0.05) is the intensity."],
	['Change Character', "Value 1: Character to change (dad, bf, gf)\nValue 2: New character's name"],
	
	['Game Flash', "Value 1: Hexadecimal Color (0xFFFFFFFF is default)\nValue 2: Duration in seconds (0.5 is default)"],

	['Change Scroll Speed', "Value 1: Scroll Speed Multiplier (1 is default)\nValue 2: Time it takes to change fully in seconds."],
	[
		"Constant SV", 
		"Speed changes which don't affect note positions.\n(For example, a speed of 0 stops notes\ninstead of making them go onto the receptors.)\nValue 1: New Speed. Defaults to 1"
		#if EASED_SVs
		+ "\nValue 2: Tween settings\n(Duration and EaseFunc seperated by a / (ex. 1/quadOut))"
		#end
	],
	[
		"Mult SV", 
		"Speed changes which don't affect note positions.\n(For example, a speed of 0 stops notes\ninstead of making them go onto the receptors.)\nValue 1: Speed Multiplier. Defaults to 1"
		#if EASED_SVs
		+ "\nValue 2: Tween settings\n(Duration and EaseFunc seperated by a /(ex. 1/quadOut))"
		#end
	]
];

class SongEventData {
	public static function getEventStuff():Array<Array<String>> {
		var eventStuff = psychEventStuff.copy();

		var eventsLoaded:Map<String, Bool> = new Map();
		for (directory in Paths.getFolders('events')) {
			for (file in Paths.readDirectory(directory)) {
				var fp = new Path(file);
				if (fp.ext.toLowerCase() != 'txt')
					continue;

				var eventName:String = fp.file;
				if (eventsLoaded.exists(eventName))
					continue;

				eventsLoaded.set(eventName, true);
				eventStuff.push([eventName, Paths.getContent(Path.join([directory, file]))]);			
			}
		}

		return eventStuff;
	}

	public static function getEventStuffV2():Array<EventDefinitionJSON> {
		var eventStuff:Array<EventDefinitionJSON> = [];
		var eventsLoaded:Map<String, Bool> = [];

		for (stuff in psychEventStuff) {
			eventsLoaded.set(stuff[0], true);
			eventStuff.push({
				id: stuff[0],
				description: stuff[1],
				fields: EventFieldDefUtil.getPsychFieldDefs()
			});
		}

		for (directory in Paths.getFolders('events')) {
			for (file in Paths.readDirectory(directory)) {
				var eventId = Path.withoutExtension(file);
				if (eventsLoaded.exists(eventId))
					continue;

				inline function push(data:Dynamic) {
					data.id = eventId;
					eventStuff.push(data);
					eventsLoaded.set(eventId, true);
				}
				
				var basePath:String = Path.join([directory, eventId]);
				
				var json:EventDefinitionJSON = Paths.getJson('$basePath.json');
				if (json != null) {
					trace('Found json: $basePath.json');
					json.fields = EventFieldDefUtil.validateFields(json.fields);
					push(json);
					continue;
				}

				var description:Null<String> = Paths.getContent('$basePath.txt');
				if (description != null || Paths.isHScript(file)) {
					push({
						description: description, 
						fields: EventFieldDefUtil.getPsychFieldDefs()
					});
					continue;
				}
			}
		}

		return eventStuff;
	}
}

// AHHHHHHHHHHHHHHHHH
/*
class PsychSongEvent extends ScriptedSongEvent {
	public var description:String;

	public function new(name:String, description:String = "", ?script:FunkinHScript) {
		this.description = description;
		super(name, script);
	}

	override function toString():String
		return 'PsychSongEvent($id)';
}
*/



/** 
	Event data structure used by `ChartingState` and the event chart format.
**/
typedef EventBunch = {
	var strumTime:Float;
	var eventData:Array<EventChildData>;
	/** Layer in which this event is placed in the editor **/
	// @:optional var layer:Int;
}

/*
@:forward
abstract EventBunch(_EventBunch) from _EventBunch to _EventBunch {
	public function new(strumTime:Float = 0, eventData:Array<EventChildData>) {
		this = {strumTime: strumTime, eventData: eventData}
	}
}
*/

/** 
	Dynamic structure containing field values for a specific event.
	Meant to be part of an `EventBunch`'s `eventData` array.  
**/
@:forward
abstract EventChildData(Dynamic) from {eventId:String} {
	public var eventId(get, set):String;
	inline function get_eventId() return this.eventId;
	inline function set_eventId(v) return this.eventId = v;

	public inline function getValue(field:String):Null<Dynamic>
		return Reflect.field(this, field);

	public inline function setValue(field:String, value:Dynamic):Void
		return Reflect.setField(this, field, value);

	public inline function clone():EventChildData {
		return Reflect.copy(this);
	}

	/** 
		Deletes every field from this structure, except for `eventId` 
	**/
	public function wipe():Void {
		for (fieldName in Reflect.fields(this)) {
			if (fieldName != 'eventId')
				Reflect.deleteField(this, fieldName);
		}
	}
}

/** 
	Event data structure used by `PlayState`.  
	Generated from an `EventBunch` structure.
**/
typedef EventInstanceData = {
	/** Which event will handle this data **/
	var eventId:String;
	/** Song timestamp, in milliseconds, at which this data will be executed **/
	var strumTime:Float;
}

typedef EventDefinitionJSON = {
	@:optional var id:String;

	/** Name of this event to be shown in the chart editor  **/
	@:optional var displayName:String;

	/** A description of this event to be shown in the chart editor **/
	var description:String;

	/** Field definitions to be used in the chart editor events tab **/
	var fields:Array<EventFieldDef>;

	///** Whether the field definition is dynamic and should be handled by the event script **/
	//@:optional var dynamicFields:Bool;
} 

enum abstract UIElementType(String) from String to String {
	var TEXT_INPUT;
	var DROPDOWN;
	var NUM_STEPPER;
	var SLIDER;
	var CHECKBOX;
	var COLOR_PICKER;

	//// specialized dropdowns
	var EASING_PICKER;
	var CHARACTER_PICKER;
	var STAGE_PICKER;
}

typedef EventFieldDef<T = Dynamic> = {
	/** Name used to store the value of this field in the event's instance data **/
	var fieldName:String;

	/** UI element used to modify the value of this field in the chart editor **/
	var uiElement:UIElementType;

	/** Default value of this field **/
	@:optional var defaultValue:T;

	/** Display name used for this field in the chart editor **/
	@:optional var displayName:String;

	/** Tooltip message shown when hovering over this field's UI element in the chart editor. **/
	@:optional var tooltip:String;
}

typedef InputTextDef = {
	> EventFieldDef<String>,
}

typedef SliderDef = {
	> EventFieldDef<Float>,
	var min:Float; 
	var max:Float;
	@:optional var decimals:Int;
}

typedef CheckBoxDef = {
	> EventFieldDef<Bool>,
}

typedef DropDownDef = {
	> EventFieldDef<String>,
	var optionsList:Array<String>;
	@:optional var allowCustom:Bool;
}

typedef NumStepperDef = {
	> EventFieldDef<Float>,
	var stepSize:Float;
	@:optional var min:Float;
	@:optional var max:Float;
	@:optional var decimals:Int;
}

class EventFieldDefUtil {
	/**
		Validates an event field definition.  
		Adds default values whereever possible.  
		@param data An `EventFieldDef` data structure
		@returns `data` if valid or `null` if not.
	**/
	public static function validate(data:Dynamic):Null<Dynamic>
	{
		if (!Reflect.hasField(data, "fieldName"))
			return null;

		if (!Reflect.hasField(data, "uiElement"))
			return null;

		switch((data.fieldName:Null<String>)) {
			case "strumTime": return null;
			case "id": return null;
			case null: return null;
		}

		data.displayName ??= data.fieldName;

		return switch((data.uiElement:UIElementType)) {
			case TEXT_INPUT:
				data.defaultValue ??= "";
				data;

			case NUM_STEPPER:
				data.stepSize ??= 1.0;
				data.defaultValue ??= 0.0;
				data.min ??= -999.0;
				data.max ??= 999.0;
				data.decimals ??= 0;
				data;
			
			case SLIDER: 
				data.decimals ??= 1;
				data;

			default: data;
		}
	}

	public static function validateFields(fields:Array<Dynamic>) {
		if (fields == null || !(fields is Array))
			return [];

		var offi = 0;
		for (i => fieldDef in fields) {
			fields[i - offi] = validate(fieldDef);
			if (fields[i] == null) offi++;
		}
		fields.resize(fields.length - offi);

		return fields;
	}

	public static function getPsychFieldDefs():Array<InputTextDef> {
		return [
			{fieldName: "value1", displayName: "Value 1", uiElement: TEXT_INPUT, defaultValue: ""},
			{fieldName: "value2", displayName: "Value 2", uiElement: TEXT_INPUT, defaultValue: ""},
		];
	}
}