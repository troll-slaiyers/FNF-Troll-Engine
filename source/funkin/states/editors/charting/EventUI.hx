package funkin.states.editors.charting;

import funkin.data.StageData;
import funkin.data.CharacterData;
import flixel.addons.ui.FlxUICheckBox;
import flixel.text.FlxText;
import flixel.addons.ui.interfaces.IFlxUIWidget;
import flixel.group.FlxSpriteGroup;
import flixel.addons.ui.StrNameLabel;
import funkin.objects.ui.CustomFlxUI;
import funkin.data.SongEventData;
import funkin.states.base.CustomFlxUIState;

using StringTools;

// Did all of this on a separate module/file because ChartingState is getting a bit too cluttered lol, it's scary to edit.

/** Prefix used for FlxUI object names **/
private inline final EVENT_FIELD_UI_PREFIX = 'eventField:';

/**
	Handles the event UI elements and actions.  
	TODO: undo/redo support for actions
**/
class EventUI extends FlxSpriteGroup {
	var eventStuff:Array<EventDefinitionJSON>;
	var eventList:Array<String>;

	var eventUIGrp = new FlxSpriteGroup();
	var eventUIMap = new Map<String, EventUIBullshit>();

	// UI
	var currentEventDefinition:EventDefinitionJSON = null;
	var currentEventBullshit:EventUIBullshit = null;

	// Chart editor
	public var currentBunch:EventBunch = null;
	public var currentChildIndex:Int = 0;
	public var currentChild(get, never):EventChildData;

	inline function get_currentChild()
		return currentBunch?.eventData[currentChildIndex];

	inline public function new(x:Float = 0, y:Float = 0) {
		super(x, y);

		eventStuff = SongEventData.getEventStuffV2();
		eventList = [for (stuff in eventStuff) stuff.id];

		add(eventUIGrp);
	}

	public function makeEventListDropdown() {
		var snla = [for (stuff in eventStuff) new StrNameLabel(stuff.id, stuff.displayName ?? stuff.id)];
		return new CustomFlxUIDropDownMenu(0, 0, snla, setCurrentDefinition);
	}

	/**
		Show the appropiate UI elements for the event `id`
	**/
	public function setCurrentDefinition(id:String) {
		var data = getDefinitionJSON(id);
		trace(data);
		
		if (!eventUIMap.exists(data.id))
			generateEventUIBullshit(data);
		
		var grp = currentEventBullshit?.uiGrp;
		if (grp != null)
			eventUIGrp.remove(grp);
		
		currentEventDefinition = data;
		currentEventBullshit = eventUIMap.get(data.id);

		grp = currentEventBullshit?.uiGrp;
		if (grp != null)
			eventUIGrp.add(grp);
	}

	/**
		Shows the appropiate UI elements and values from the selected event.  
		Called when selecting an event bunch or when pressing the < > buttons.
	**/
	public function selectEventBunch(bunch:EventBunch, childIndex:Int = 0) {		
		if (bunch == null) {
			currentBunch = null;
			currentChildIndex = -1;
			return;
		}
		
		var child:EventChildData = bunch.eventData[childIndex] ?? bunch.eventData[childIndex = 0];
		if (child == null)
			throw 'Uh oh! Attempt to select an empty bunch?';

		currentBunch = bunch;
		currentChildIndex = childIndex;

		onChildSelected(child);
	}

	/**
		Shows the appropiate UI elements and values from the selected event.  
		Called when pressing the < > buttons.
	**/
	public function changeSelectedChild(value:Int, isAbs:Bool = false) {
		selectEventBunch(currentBunch, isAbs ? value : CoolUtil.updateIndex(currentChildIndex, value, currentBunch.eventData.length));
	}

	/**
		Duplicates the current selected child.  
		Called when pressing the + button.
	**/
	public function duplicateChild() {
		if (currentBunch == null || currentChild == null)
			return;

		var clone = currentChild.clone();
		currentBunch.eventData.insert(currentChildIndex + 1, clone);
		currentChildIndex++;
		onChildSelected(clone);
	}

	/**
		Removes the current selected child.  
		Called when pressing the `-` button.
	**/
	public function removeChild() {
		if (currentBunch == null || currentChild == null)
			return;
		
		currentBunch.eventData.remove(currentChild);
		selectEventBunch(currentBunch, currentChildIndex - 1);
	}

	/** 
		@returns A new `EventBunch` generated from the currently selected event and its values 
	**/
	public function generateEventBunch():EventBunch {
		return currentEventBullshit?.generateBunch() ?? {strumTime: 0, eventData: [{eventId: ''}]};
	}

	/** 
		Called when an UI element dispatches a value change event  
		Updates the value of the changed field of the currently selected child event.
	**/
	public function onDataFieldChanged(fieldName:String, value:Dynamic, uiObject:IFlxUIWidget, eventType:String):Void {
		trace(fieldName, value);
		currentChild?.setValue(fieldName, value);
	}

	/**
		Intended usage:  
		```hx
		override function getEvent(name:String, sender:IFlxUIWidget, data:Dynamic, ?params:Array<Dynamic>) {
			if (handleFlixelUIEvent(name, sender, data, params))
				return;
			super.getEvent(name, sender, data, params);
		}
		```
		@returns Whether the event was answered (UI event belongs to the event UI xS)
	**/
	public function handleFlixelUIEvent(name:String, sender:IFlxUIWidget, data:Dynamic, ?params:Array<Dynamic>):Bool {
		if (sender.name.startsWith(EVENT_FIELD_UI_PREFIX)) {
			onDataFieldChanged(sender.name.substring(EVENT_FIELD_UI_PREFIX.length), data, sender, name);
			return true;
		}
		return false;
	}

	private function onChildSelected(child:EventChildData) {
		setCurrentDefinition(child.eventId);
		for (fieldDef in currentEventDefinition.fields) {
			var fieldName:String = fieldDef.fieldName;
			currentEventBullshit.setValue(fieldName, child.getValue(fieldName));
		}
	}

	inline function getDefinitionJSON(id:String):EventDefinitionJSON {
		return eventStuff[eventList.indexOf(id)];
	}

	function generateEventUIBullshit(data:EventDefinitionJSON) {
		var bullshit = new EventUIBullshit(data);
		bullshit.generateUIElements();
		eventUIMap.set(data.id, bullshit);
		return bullshit;
	}
}

private class EventUIBullshit {
	public var uiGrp = new FlxSpriteGroup();
	
	public var definition:EventDefinitionJSON;

	public function new(data:EventDefinitionJSON) {
		this.definition = data;
	}

	public function generateUIElements() {
		var curX:Float = 0;
		var curY:Float = 0;
		for (fieldDef in definition.fields) {
			// name for flixel-ui events
			final objName:String = EVENT_FIELD_UI_PREFIX + fieldDef.fieldName;

			inline function addUI(obj) {
				//uiMap.set('obj_${fieldDef.fieldName}', obj);
				uiGrp.add(obj);
			}

			inline function makeLabel() {
				var label = new FlxText(curX, curY, 0, fieldDef.displayName);
				curY = label.y + label.height;

				//uiMap.set('label_${fieldDef.fieldName}', label);
				uiGrp.add(label);
				
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
					obj.name = objName;
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

		if (definition.description != null && definition.description.length > 0) {
			var label = new FlxText(curX, curY, 200, definition.description);
			uiGrp.add(label);
		}
	}

	public function getValue(fieldName):Dynamic {
		var fieldData:EventFieldDef<Dynamic> = getFieldDefinition(fieldName);
		if (fieldData == null) {
			trace('Attempt to get value for non-existent field "$fieldName"');
			return null;
		}

		var uiObj:Dynamic = getUIObject(fieldName);
		if (uiObj == null) {
			trace('No UI object found for field "$fieldName"');
			return fieldData.defaultValue;
		}

		return switch(fieldData.uiElement) {
			case TEXT_INPUT:
				(uiObj:CustomFlxUIInputText).text;
			case DROPDOWN | EASING_PICKER | CHARACTER_PICKER | STAGE_PICKER:
				(uiObj:CustomFlxUIDropDownMenu).selectedId;
			case NUM_STEPPER:
				(uiObj:CustomFlxUINumericStepper).value;
			case SLIDER:
				(uiObj:CustomFlxUISlider).value;
			case CHECKBOX:
				(uiObj:FlxUICheckBox).checked;
			case COLOR_PICKER:
				null; // TODO: (uiObj:FlxUICheckBox)
		}
	}

	/** Updates the displayed value of the appropiate UI element(s) of an event field. **/
	public function setValue(fieldName:String, value:Dynamic) {
		var fieldData:EventFieldDef<Dynamic> = getFieldDefinition(fieldName);
		if (fieldData == null) {
			trace('Attempt to update value for non-existent field "$fieldName"');
			return;
		}

		var uiObj:Dynamic = getUIObject(fieldName);
		if (uiObj == null) {
			trace('No UI object found for field "$fieldName"');
			return;
		}

		switch(fieldData.uiElement) {
			case TEXT_INPUT:
				(uiObj:CustomFlxUIInputText).text = value;
			case DROPDOWN | EASING_PICKER | CHARACTER_PICKER | STAGE_PICKER:
				(uiObj:CustomFlxUIDropDownMenu).selectedId = value;
			case NUM_STEPPER:
				(uiObj:CustomFlxUINumericStepper).value = value;
			case SLIDER:
				(uiObj:CustomFlxUISlider).value = value;
			case CHECKBOX:
				(uiObj:FlxUICheckBox).checked = value;
			// TODO:
			case COLOR_PICKER:
			//	(uiObj:FlxUICheckBox)
		}
	}

	public function generateBunch():EventBunch {
		return {
			strumTime: 0,
			eventData: [generateChild()],
		};
	}

	function generateChild():EventChildData {
		var son:EventChildData = {eventId: definition.id};
		for (fieldDef in definition.fields)
			son.setValue(fieldDef.fieldName, getValue(fieldDef.fieldName));
		return son;
	}

	function getFieldDefinition(fieldName:String):EventFieldDef<Dynamic> {
		for (data in definition.fields) {
			if (data.fieldName == fieldName)
				return data;
		}
		return null;
	}

	function getUIObject(fieldName:String):Dynamic {
		for (obj in uiGrp) {
			if ((obj:Dynamic).name == fieldName)
				return obj;
		}
		return null;
	}
}