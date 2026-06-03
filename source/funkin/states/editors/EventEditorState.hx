package funkin.states.editors;

import funkin.data.StageData;
import funkin.data.CharacterData;
import flixel.addons.ui.FlxUICheckBox;
import flixel.text.FlxText;
import flixel.addons.ui.interfaces.IFlxUIWidget;
import flixel.group.FlxGroup;
import flixel.addons.ui.StrNameLabel;
import funkin.objects.ui.CustomFlxUI;
import funkin.data.SongEventData;
import funkin.states.base.CustomFlxUIState;

using StringTools;

class EventUIBullshit {
	public var uiGrp = new FlxGroup();
	
	public var definition:EventDataJSON;

	public function new(data:EventDataJSON) {
		this.definition = data;
	}
}

class EventEditorState extends CustomFlxUIState {
	var eventStuff:Array<EventDataJSON>;
	var eventList:Array<String>;
	var curEventDef:EventDataJSON;

	static final EVENT_FIELD_UI_PREFIX = 'eventField:';
	var eventUIGrp = new FlxGroup();

	var eventUIMap = new Map<String, EventUIBullshit>();
	var selectedEventUI:FlxGroup = null;

	override function create() {
		super.create();

		FlxG.mouse.useSystemCursor = true;
		FlxG.mouse.visible = true;

		eventStuff = SongEventData.getEventStuffV2();
		eventList = [for (stuff in eventStuff) stuff.id];

		/*
		for (stuff in eventStuff) {
			var bro:DropDownDef = {
				fieldName: "TEST_LOL",
				uiElement: DROPDOWN,
				optionsList: ["Real", "Dropdown", "Trust"],
			};
			bro = EventFieldDefUtil.validate(bro);
			stuff.fields.push(bro);
		}
		*/

		var snla = [for (stuff in eventStuff) new StrNameLabel(stuff.id, stuff.displayName ?? stuff.id)];
		var dd = new CustomFlxUIDropDownMenu(0, 0, snla);
		dd.callback = (id:String) -> {
			var data = eventStuff[eventList.indexOf(id)];
			setCurrentEvent(data);
		}
		add(dd);
		add(eventUIGrp);

		//lime.system.System.exit(0);
	}

	function setCurrentEvent(data:EventDataJSON) {
		trace(data);
		
		if (!eventUIMap.exists(data.id))
			generateEventUIBullshit(data);
		
		eventUIGrp.remove(selectedEventUI);
		curEventDef = data;
		
		selectedEventUI = eventUIMap.get(data.id).uiGrp;
		eventUIGrp.add(selectedEventUI);
	}

	function generateEventUIBullshit(data:EventDataJSON) {
		//// Generate bullshit
		var curX:Float = 200;
		var curY:Float = 20;

		var bullshit = new EventUIBullshit(data);
		eventUIMap.set(data.id, bullshit);

		for (fieldDef in data.fields) {
			// name for flixel-ui events
			final objName:String = EVENT_FIELD_UI_PREFIX + fieldDef.fieldName;

			inline function addUI(obj) {
				//uiMap.set('obj_${fieldDef.fieldName}', obj);
				bullshit.uiGrp.add(obj);
			}

			inline function makeLabel() {
				var label = new FlxText(curX, curY, 0, fieldDef.displayName);
				curY = label.y + label.height;

				//uiMap.set('label_${fieldDef.fieldName}', label);
				bullshit.uiGrp.add(label);
				
				return label;
			}

			switch(fieldDef.uiElement) {
				case TEXT_INPUT:
					makeLabel();

					var obj = new CustomFlxUIInputText(curX, curY, 150, fieldDef.defaultValue ?? "");
					obj.name = objName;
					curY = obj.y + obj.height + 12;
					addUI(obj);

				case CHECKBOX:
					var obj = new FlxUICheckBox(curX, curY, null, null, fieldDef.displayName);
					obj.name = objName;
					curY = obj.y + obj.height + 12;
					addUI(obj);

				case DROPDOWN | CHARACTER_PICKER | STAGE_PICKER | EASING_PICKER:
					var fieldDef:DropDownDef = cast fieldDef;
					var optionsList:Array<String>;

					inline function copyArray(ray:Array<Dynamic>)
						return ray == null ? [] : ray.copy();
					
					switch(fieldDef.uiElement) {
						case EASING_PICKER:
							optionsList = copyArray(fieldDef.optionsList);
							for (easeId in Type.getClassFields(flixel.tweens.FlxEase)) {
								if (Reflect.isFunction(Reflect.field(flixel.tweens.FlxEase, easeId)))
									optionsList.push(easeId);
							}
							
						case CHARACTER_PICKER:
							optionsList = copyArray(fieldDef.optionsList);
							for (id in CharacterData.getAllCharacters())
								optionsList.push(id);
							
						case STAGE_PICKER:
							optionsList = copyArray(fieldDef.optionsList);
							for (id in StageData.getAllStages())
								optionsList.push(id);
						
						default:
							optionsList = fieldDef.optionsList;
					}

					makeLabel();

					var snla:Array<StrNameLabel> = [
						for (id in optionsList)
							new StrNameLabel(id, id)
					];

					var obj = new CustomFlxUIDropDownMenu(curX, curY, snla);
					obj.name = objName;
					obj.selectedId = fieldDef.defaultValue;
					curY = obj.y + obj.header.height + 12;

					addUI(obj);

				case NUM_STEPPER:
					var fieldDef:NumStepperDef = cast fieldDef;

					makeLabel();

					var obj = new CustomFlxUINumericStepper(curX, curY, fieldDef.stepSize, fieldDef.defaultValue, fieldDef.min, fieldDef.max, fieldDef.decimals);
					curY = obj.y + obj.height + 12;
					
					addUI(obj);

				case SLIDER:
					var fieldDef:SliderDef = cast fieldDef;

					var obj = new CustomFlxUISlider(null, fieldDef.fieldName, curX, curY, fieldDef.min, fieldDef.max, null, null, null, 0xFFFFFFFF, 0xFFFFFFFF);
					obj.nameLabel.text = fieldDef.displayName;
					obj.name = fieldDef.fieldName;
					obj.setVariable = false;

					curY = obj.y + obj.height + 12;
					addUI(obj);

				#if true
				default:
					makeLabel();

					var obj = new flixel.addons.ui.FlxUIText(curX, curY, 0, 'ERROR: "${fieldDef.uiElement}" is not implemented');
					obj.color = 0xFF000000;
					obj.setBorderStyle(OUTLINE, 0xFFFF0000);
					curY = obj.y + obj.height + 12;
					
					addUI(obj);
				#end
			}
		}

		if (data.description != null && data.description.length > 0) {
			var label = new FlxText(curX, curY, 200, data.description);
			bullshit.uiGrp.add(label);
		}

		return bullshit;
	}

	function onEventFieldChanged(fieldName:String, value:Dynamic, uiObject:IFlxUIWidget, eventType:String) {
		trace(fieldName, value);
	}

	override function getEvent(name:String, sender:IFlxUIWidget, data:Dynamic, ?params:Array<Dynamic>) {
		if (sender.name.startsWith(EVENT_FIELD_UI_PREFIX)) {
			onEventFieldChanged(sender.name.substring(EVENT_FIELD_UI_PREFIX.length), data, sender, name);
			return;
		}
		
		super.getEvent(name, sender, data, params);
	}
}