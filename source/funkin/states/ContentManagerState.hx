package funkin.states;

import funkin.objects.shaders.WarmBGShader;
import funkin.input.Controls;
import funkin.objects.ui.CustomFlxUI.CustomFlxInputText;
import funkin.objects.ChangingMenuBG;
import funkin.input.InputFormatter;
import funkin.objects.ui.ScrollBar;
import trollui.SlicedSprite;
import funkin.objects.ui.ScrollText;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import funkin.data.content.PackManager;
import funkin.data.content.Pack;
import math.CoolMath;
import flixel.math.FlxRect;

using StringTools;

// Used to get the path and menu styles
@:access(funkin.data.content.PackManager.allPacks)
class ContentManagerState extends MusicBeatState {	
	var entries:EntryList;

	var listBoxStartY:Float = 0;
	var listBoxHeight:Float = 64;
	var listBoxSpacing:Float = 8;

	var listCamera:FlxCamera;
	var listScrollBar:ScrollBar;
	var listGrp = new FlxTypedGroup<EntryBox>();
	var listSelectedIndex:Int = 0;
	var listHoveredIndex:Int = -1;

	var _lastListScrollY:Float = 0;
	var dragging:Bool = false;

	var bgManager:ChangingMenuBG;
	var bgShader = new WarmBGShader();
	
	var rightCamera:FlxCamera;
	var packCardBG:FlxSprite;
	var packCardTitle:FlxText;
	var packCardAuthor:FlxText;
	var packCardBannerGroup:ChangingSpriteGroup;
	var packDescriptionText:ScrollText;

	var dropdown:Dropdown;
	
	var topCamera:FlxCamera;

	/** Whether to save the entry list and reload packs after leaving this state **/
	var didChanges:Bool = false;

	final displayData = new PackDisplayData();

	inline function stringToHue(str:String):Int {
		var h = StringTools.fastCodeAt(str, 0);
		for (i in 1...str.length) {
			h = (h * 31 + StringTools.fastCodeAt(str, i)) & 0xFFFFFFFF;
		}
		return h % 360;
	}

	inline function getDisplayData(entry:PackEntry) {
		final pack = PackManager.allPacks.get(entry.id);
		final data:PackMetadata = pack.metadata ?? {};
		
		displayData.packIsLoaded = PackManager.packMap.exists(entry.id);
		displayData.runsGlobally = pack.runsGlobally;

		////
		displayData.title = data.title ?? entry.id;
		displayData.description = data.description ?? "No description provided";
		displayData.author = data.author;//?? "Unknown";

		displayData.bgColor = data.bgColor ?? data.accentColor ?? FlxColor.fromHSB(stringToHue(entry.id), 0.75, FlxG.random.float(0.467, 0.512)); //0xFFea71fd;
		displayData.accentColor = data.accentColor ?? FlxColor.WHITE;

		displayData.bannerAsset = packGraphic(pack, 'packbanner');
		displayData.bgAsset = packGraphic(pack, 'images/menuDesat') ?? packGraphic(PackManager.engineAssets, 'images/contentmenu/menuDesat') ?? FlxGraphic.fromRectangle(FlxG.width, FlxG.height, 0xFFE1E1E1, false, 'contentmanager_nobg');
	
		////
		@:privateAccess
		if (pack.loadException.length > 0) {
			displayData.description = 'An error occurred when loading this pack:\n' + pack.loadException;
		}
	}

	override function create() {
		PackManager.reloadPackList();
		entries = PackManager.entries;

		// Move disabled mods to the end of the list
		entries.array.sort((a, b) -> (a.enabled == b.enabled) ? (a.enabled ? 0 : CoolUtil.alphabeticalSort(a.id, b.id)) : (b.enabled ? 1 : -1));

		////
		if (FlxG.sound.music?.playing && FlxG.sound.music.volume > 0.1) {
			MusicBeatState.cacheMusic('contentmanager');
			FlxG.sound.music.fadeOut(0.4, 0.0, _ -> MusicBeatState.playMusic('contentmanager', true));
		}else {
			MusicBeatState.playMusic('contentmanager');
		}

		FlxG.camera.bgColor = 0xFF4C4C4C;
		//add(new funkin.objects.CoolMenuBG('menuDesat', 0xFFffFFFF));
		bgManager = new ChangingMenuBG();
		add(bgManager);

		////
		FlxG.mouse.visible = true;

		var borderHPadding = 20;
		var borderVPadding = 80;
		
		var listX = borderHPadding;
		var listY = borderVPadding;
		var listWidth = Std.int(FlxG.width / 3 - borderHPadding);
		var listHeight:Int = FlxG.height - borderVPadding * 2;
		
		#if true
		listBoxHeight = 64;
		listBoxSpacing = 8;
		#else
		var boxes:Int = 8;
		listBoxSpacing = 8;
		var listBoxHeight:Float = (listHeight - (boxes + 1) * listBoxSpacing) / boxes;

		// floor listBoxHeight and recalc spacing
		listBoxHeight = Math.fround(listBoxHeight);
		listBoxSpacing = (listHeight - listBoxHeight * boxes) / (boxes + 1);
		#end

		if (false) {
			var searchBox = new CustomFlxInputText(0, 0, listWidth - 8 * 2, "", 16, FlxColor.WHITE, FlxColor.TRANSPARENT);
			searchBox.setFormat(Paths.font("quantico.ttf"), 16);
			searchBox.text = "Search";
			searchBox.drawFrame();
			searchBox.updateHitbox();
			
			var searchBG = new FlxSprite(borderHPadding, listY + 8);

			final searchBoxTextPadding = 6;
			final searchBoxHeight = Std.int(searchBox.height) + searchBoxTextPadding * 2;
			
			searchBG.makeGraphic(1, 1);
			searchBG.color = 0xFF000000;
			searchBG.alpha = 0.64;
			searchBG.scale.set(listWidth, searchBoxHeight);
			searchBG.updateHitbox();
			add(searchBG);

			SpriteTools.objectCenter(searchBox, searchBG);
			add(searchBox);
			
			listY = Std.int(searchBG.y + searchBG.height) + 8;
			listHeight = FlxG.height - listY - borderVPadding;
		}

		////
		listCamera = new FlxCamera(listX, listY, listWidth, listHeight);
		listCamera.bgColor = FlxColor.fromRGBFloat(0, 0, 0, 0.25);
		//listCamera.targetOffset.y = -26; // what's up with this
		//okay so it has something to do with using LOCKON target following but i don't wanna add camFollow camFollowPos bs here so suck it
		listCamera.minScrollX = 0;
		listCamera.minScrollY = listBoxSpacing;
		listCamera.maxScrollY = listBoxSpacing + listBoxSpacing;
		FlxG.cameras.add(listCamera, false);

		////
		listGrp.camera = listCamera;
		add(listGrp);

		var maxScrollY = listCamera.maxScrollY + (listBoxHeight + listBoxSpacing) * entries.length;
		var boxWidth = listCamera.width;

		if (maxScrollY - listCamera.minScrollY > listCamera.height) {
			// scroll bar will be visible
			boxWidth -= 12 + 4;
		}

		listBoxStartY = listCamera.maxScrollY;

		for (i => entry in entries) {
			var curOpt = new EntryBox(boxWidth, listBoxHeight);
			listGrp.add(curOpt);
		}
		updateListBoxes();
		listCamera.maxScrollY = maxScrollY;

		listScrollBar = new ScrollBar(0, 0, listCamera.maxScrollY, listCamera.height, 8);
		listScrollBar.camera = listCamera;
		listScrollBar.x = listCamera.width - listScrollBar.width;
		listScrollBar.scrollFactor.set();
		add(listScrollBar);

		listScrollBar.callback = function(perc:Float) {
			listCamera.follow(null);
			listCamera.scroll.y = CoolMath.scale(perc, 0, 1, listCamera.minScrollY, listCamera.maxScrollY - listCamera.viewHeight);
			// this is annoying and a troll thing only :/
			@:privateAccess listCamera._scrollInternal.y = listCamera.scroll.y;
		}

		////
		var topB = new SlicedSprite(
			listCamera.x, 
			borderVPadding,
			listCamera.width, 
			64,
			"contentmenu/9slice_top",
			[4, 4, 24, 28]
		);
		topB.y -= topB.height;
		add(topB);

		var titleText = new FlxText(topB.x + 16, 0, topB.width - 16 * 2, "Content Manager");
		titleText.setFormat(Paths.font("quanticob.ttf"), 24, 0xFF000000, LEFT);
		//titleText.setBorderStyle(OUTLINE, 0xFF000000, 1);
		titleText.pixelPerfectRender = true; // suck ya dad
		titleText.drawFrame();
		titleText.updateHitbox();
		SpriteTools.objectCenter(titleText, topB);
		add(titleText);

		////
		var botB = new SlicedSprite(
			listCamera.x, 
			listCamera.y + listCamera.height,
			listCamera.width, 
			64,
			"contentmenu/9slice_bot",
			[4, 4, 24, 28]
		);
		add(botB);

		var TOGGLE_BIND = InputFormatter.getBindString('accept').toUpperCase();
		var OPTIONS_BIND = 'CTRL';
		var SHIFT_BIND = 'SHIFT';

		var str = '[$TOGGLE_BIND] Toggle Mod';
		str += '\n[$OPTIONS_BIND] Mod options';
		str += '\n[$SHIFT_BIND] Change order';

		var hintText = new FlxText(botB.x + 8, 0, (botB.width - 8 * 2), str);
		hintText.setFormat(Paths.font("vcr.ttf"), 16, 0xFF000000, LEFT);
		//hintText.setBorderStyle(OUTLINE, 0xFF000000, 1);
		hintText.drawFrame();
		hintText.updateHitbox();
		add(hintText);

		SpriteTools.objectCenter(hintText, botB, Y);
		hintText.y -= 1;

		////
		rightCamera = new FlxCamera();
		rightCamera.bgColor = 0;
		rightCamera.x = listCamera.x + listCamera.width + 56;
		rightCamera.y = topB.y;
		rightCamera.width = Std.int(FlxG.width - rightCamera.x - borderHPadding);
		rightCamera.height = Std.int(FlxG.height - rightCamera.y * 2);
		FlxG.cameras.add(rightCamera, false);

		////
		var packCardBGBorder = CoolUtil.blankSprite(rightCamera.width, 112, 0xFF000000);
		packCardBGBorder.x = rightCamera.x;
		packCardBGBorder.y = rightCamera.y;
		
		packCardBG = CoolUtil.blankSprite(packCardBGBorder.width - 4 - 4, packCardBGBorder.height - 4 - 8);
		packCardBG.x = packCardBGBorder.x + 4;
		packCardBG.y = packCardBGBorder.y + 4;

		packCardBannerGroup = new ChangingSpriteGroup();
		
		packCardTitle = new FlxText(0, 0, packCardBG.width - 16 * 2, "");
		packCardTitle.setFormat(Paths.font("quanticob.ttf"), 26, 0xFF000000, LEFT);
		packCardTitle.pixelPerfectRender = true;

		packCardAuthor = new FlxText(0, 0, packCardTitle.width, "");
		packCardAuthor.setFormat(Paths.font("quanticob.ttf"), 18, 0xFF000000, LEFT);
		packCardAuthor.pixelPerfectRender = true;
		
		add(packCardBGBorder);
		add(packCardBG);
		add(packCardBannerGroup);
		add(packCardTitle);		
		add(packCardAuthor);		

		var offy = Std.int(packCardBGBorder.height + 16);
		offy += Std.int((rightCamera.height - offy) - packCardBGBorder.height); // copy pack height lol

		rightCamera.y += offy;
		rightCamera.height -= offy;

		////
		var descBG = CoolUtil.blankSprite(rightCamera.width, rightCamera.height, FlxColor.BLACK);
		descBG.x = rightCamera.x;
		descBG.y = rightCamera.y;
		descBG.alpha = 0.6;
		add(descBG);

		final descPadding = 8;
		final scrollBarWidth = 12;
		
		packDescriptionText = new ScrollText(rightCamera.x + descPadding, rightCamera.y + descPadding, rightCamera.width - descPadding * 2 - scrollBarWidth);
		packDescriptionText.setFormat(Paths.font("quantico.ttf"), 18, FlxColor.WHITE, LEFT);
		packDescriptionText.minY = packDescriptionText.y;
		packDescriptionText.maxY = rightCamera.y + rightCamera.height - descPadding;
		add(packDescriptionText);

		packDescriptionText.scrollBar.scale.x = 8;

		////
		dropdown = new Dropdown();
		dropdown.exists = false;
		add(dropdown);

		topCamera = new FlxCamera();
		topCamera.bgColor = 0;
		FlxG.cameras.add(topCamera, false); 

		////
		changeSelected(0);

		super.create();
	}

	function focusOnSelectedEntry() {
		var curOpt = listGrp.members[listSelectedIndex];
		if (curOpt != null) {
			//curOpt.onSelected();
			listCamera.follow(curOpt.bg, LOCKON, 0.25);
		}
	}

	function changeSelected(val:Int, isAbs:Bool = false) {
		var prevSelected = listSelectedIndex;
		listSelectedIndex = isAbs ? val : CoolUtil.updateIndex(listSelectedIndex, val, listGrp.length);
		
		if (listHoveredIndex != -1) {
			listGrp.members[listHoveredIndex].unSelected();
			listHoveredIndex = -1;
		}

		dropdown.exists = false;

		var prevOpt = listGrp.members[prevSelected];
		if (prevOpt != null) prevOpt.unSelected();

		var curOpt = listGrp.members[listSelectedIndex];
		if (curOpt != null) {
			curOpt.onSelected();
			focusOnSelectedEntry();
		}

		////
		final entry = entries.array[listSelectedIndex];

		getDisplayData(entry);
		//trace(displayData);
		
		if (displayData.author != null) {
			var midY = packCardBG.y + packCardBG.height / 2;
			
			packCardTitle.text = displayData.title;
			SpriteTools.objectCenter(packCardTitle, packCardBG, X);
			packCardTitle.y = midY - packCardTitle.height + 8;
			
			packCardAuthor.text = displayData.author;
			SpriteTools.objectCenter(packCardAuthor, packCardBG, X);
			packCardAuthor.y = midY;
			packCardAuthor.exists = true;
		}else {
			packCardTitle.text = displayData.title;
			SpriteTools.objectCenter(packCardTitle, packCardBG, XY);
			
			packCardAuthor.exists = false;
		}

		var packCardBanner:FlxSprite;
		if (displayData.bannerAsset != null) {
			packCardBannerGroup.fadeTo(displayData.bannerAsset);	
			packCardBanner = packCardBannerGroup.curSprite;
			packCardBanner.setGraphicSize(0, packCardBG.height);
			packCardBanner.updateHitbox();
		}else {
			packCardBannerGroup.fadeTo(Paths.whitePixel.parent);
			packCardBanner = packCardBannerGroup.curSprite;
			packCardBanner.setGraphicSize(packCardBG.width, packCardBG.height);
			packCardBanner.updateHitbox();
		}
		packCardBanner.x = packCardBG.x + packCardBG.width - packCardBanner.width;
		SpriteTools.objectCenter(packCardBanner, packCardBG, Y);

		var descStr = displayData.description;
		/*
		if (displayData.runsGlobally)
			descStr += '\n\nNOTE: This pack runs globally';
		*/

		packDescriptionText.text = descStr;

		bgManager.fadeToBg(displayData.bgAsset, displayData.bgColor);
		@:privateAccess bgManager.curBG.shader = bgShader;
	}

	function changeHovered(index:Int) {
		if (listHoveredIndex != -1 && listHoveredIndex != listSelectedIndex)
			listGrp.members[listHoveredIndex].unSelected();
		
		listHoveredIndex = index;
		if (listHoveredIndex != -1)
			listGrp.members[listHoveredIndex].onSelected();
	}

	function shiftSelectedOrder(val:Int, isAbs:Bool = false, insert:Bool = false) {
		var newIndex = isAbs ? val : listSelectedIndex + val;
		if (newIndex < 0 || newIndex >= entries.length)
			return;

		if (insert) {
			final entry = entries.array[listSelectedIndex];
			entries.array[listSelectedIndex] = null;
			entries.array.insert(newIndex, entry);
			while (entries.array.remove(null)) {}
		}else {
			final entry = entries.array[listSelectedIndex];
			entries.array[listSelectedIndex] = entries.array[newIndex];
			entries.array[newIndex] = entry;
		}
		
		didChanges = true;
		updateListBoxes();
		changeSelected(newIndex, true);
	}

	function getEntryOptions(entry:PackEntry) {
		var options:Array<ModOption> = [];
		final packIsLoaded = entry.enabled && PackManager.packMap.exists(entry.id);

		if (packIsLoaded)
			options.push(LAUNCH_MOD);
		
		options.push(OPEN_MOD_LOCATION);
		//options.push(entry.favorite ? REMOVE_FAVORITE : ADD_FAVORITE);
		
		if (packIsLoaded)
			options.push(OPEN_PACK_OPTIONS);

		return options;
	}

	function openDropdown() {
		final entry = entries.array[listSelectedIndex];
		final options:Array<ModOption> = getEntryOptions(entry);
		final strings:Array<String> = [
			for (opt in options)
				Paths.getString('contentmanager_packoption_$opt') ?? CoolerStringTools.snakeToPascal(opt)
		];

		dropdown.exists = true;
		dropdown.setList(strings);
		dropdown.callback = function(_, index:Int) {
			acceptOption(entry, options[index]);
		}
	}

	function acceptOption(entry:PackEntry, opt:ModOption) {
		final pack = PackManager.allPacks.get(entry.id);
		
		switch(opt) {
			case LAUNCH_MOD:
				pack.launch();

			case OPEN_MOD_LOCATION:
				lime.system.System.openFile(funkin.util.FileUtil.getSystemPath(pack.path));
				dropdown.exists = false;

			case OPEN_PACK_OPTIONS:
			case ADD_FAVORITE:
			case REMOVE_FAVORITE:
		}
	}

	/** @returns Index of the `BoxEntry` that the mouse is currently hovering over **/
	function getHoverIndex():Int {
		var index = -1;
		for (i => box in listGrp.members) {
			if (CoolUtil.overlapsMouse(box.bg, listCamera)) {
				index = i;
				break;
			}
		}
		return index;
	}

	/** @returns Index of the `BoxEntry` that the mouse is currently hovering over **/
	function getHoverIndex2(excludeIndex:Int):Int {
		var index = -1;
		for (i => box in listGrp.members) {
			if (i == excludeIndex)
				continue;

			if (CoolUtil.overlapsMouse(box.bg, listCamera)) {
				index = i;
				break;
			}
		}
		return index;
	}

	function updateListBoxes() {
		for (i => box in listGrp) {
			final entry = entries.array[i];
			box.setEntry(entry);
			box.y = listBoxStartY + (listBoxHeight + listBoxSpacing) * i;
		}
	}

	function toggleEntry(index:Int) {
		var entry = entries.array[index];
		entry.enabled = !entry.enabled;
		listGrp.members[index].updateToggleSprite();
		didChanges = true;
	}

	function launchSelected() {
		var entry = entries.array[listSelectedIndex];
		var pack = PackManager.packMap.get(entry.id);
		pack?.launch();
	}

	function updateListKeyboardInput() {
		var change:Int = Controls.firstActive.UI_VERTICAL_P;
		if (change != 0)
			FlxG.keys.pressed.SHIFT ? shiftSelectedOrder(change) : changeSelected(change);

		if (FlxG.keys.justPressed.CONTROL && listHoveredIndex == -1) {
			openDropdown();
			dropdown.changeSelected(0, true);
			//focusOnSelectedEntry();
		}

		if (controls.ACCEPT && listHoveredIndex == -1)
			toggleEntry(listSelectedIndex);

		if (controls.BACK) {
			handleBack();
		}
	}

	function handleBack() {
		if (didChanges) {
			PackManager.entries = entries;
			PackManager.flushEntryList();
			PackManager.reloadPackList();
		}

		var packsWithErrors = [];
		for (pack in PackManager.packMap) {
			if (pack.loadException.length > 0) {
				packsWithErrors.push(pack);
			}
		}

		if (packsWithErrors.length != 0) {
			var errorMsg = 'The following packs had errors and were disabled:\n\n';
			for (pack in packsWithErrors) {
				errorMsg += '- "${pack.id}"\n${pack.loadException}\n\n';
			}
			trace(errorMsg);
			updateListBoxes();
		}else {
			MusicBeatState.switchState(new funkin.states.MainMenuState());
		}
	}

	override function update(elapsed:Float) {
		if (!dropdown.exists) {
			updateListKeyboardInput();
		}

		var cameraMoved:Bool = _lastListScrollY != listCamera.scroll.y;
		if (cameraMoved) _lastListScrollY = listCamera.scroll.y;

		var exitDropdown:Bool = false;

		#if FLX_MOUSE
		var overlapsScrollBar:Bool = CoolUtil.overlapsMouse(listScrollBar, listScrollBar.camera);

		/*
		if (FlxG.mouse.justPressed && overlapsScrollBar)
			exitDropdown = true;
		*/
		if (FlxG.mouse.justPressed && !CoolUtil.mouseOverlapsCamera(dropdown.camera)) {
			exitDropdown = true;
		}

		if (dragging) {
			if (FlxG.mouse.justReleased) {
				dragging = false;

				var selBox = listGrp.members[listSelectedIndex];
				selBox.camera = listCamera;

				if (CoolUtil.mouseOverlapsCamera(listCamera)) {
					var hoverIndex = getHoverIndex2(listSelectedIndex);
					if (hoverIndex != -1)
						shiftSelectedOrder(hoverIndex, true, true);
					else {
						updateListBoxes();
						changeSelected(listSelectedIndex, true);
						listCamera.follow(null);
					}
				}
			}
		}

		if (overlapsScrollBar || !CoolUtil.mouseOverlapsCamera(listCamera)) {
			if (listHoveredIndex != -1)
				changeHovered(-1);
		}else {
			if (FlxG.mouse.wheel != 0) {
				listCamera.follow(null);
				@:privateAccess
				listCamera._scrollInternal.y -= 48 * FlxG.mouse.wheel;
				listCamera.updateScroll(); // apply follow bounds
				cameraMoved = true;
				exitDropdown = true;
			}

			if (!dragging && ((cameraMoved && listHoveredIndex != -1) || FlxG.mouse.deltaScreenX != 0.0 || FlxG.mouse.deltaScreenX != 0.0)) {
				var hoverIndex = getHoverIndex();
				if (hoverIndex != -1)
					changeHovered(hoverIndex);
			}
			
			if (FlxG.mouse.justPressed) {
				var hoverIndex = getHoverIndex();
				if (hoverIndex != -1) {
					var box = listGrp.members[hoverIndex];

					if (CoolUtil.overlapsMouse(box.toggleSprite, listCamera)) {
						toggleEntry(hoverIndex);
					}else {
						changeSelected(hoverIndex, true);				
					}

					if (CoolUtil.overlapsMouse(box.dragSprite, listCamera)) {
						changeSelected(hoverIndex, true);
						dragging = true;
					}
				}
			}
			
			if (FlxG.mouse.justPressedRight) {
				var hoverIndex = getHoverIndex();
				if (hoverIndex != -1) {
					changeSelected(hoverIndex, true);
					openDropdown();
					dropdown.changeSelected(-1, true);
				}
			}
		}

		if (dragging) {
			// nice visual feedback
			changeHovered(getHoverIndex());

			var mousePos = FlxG.mouse.getPositionInCameraView(topCamera);
			var selBox = listGrp.members[listSelectedIndex];

			@:privateAccess
			//topCamera._scrollInternal.set(-listCamera.x, -listCamera.y);

			selBox.y = mousePos.y - selBox.height / 2;
			selBox.camera = topCamera;
			listCamera.follow(null);

			mousePos.putWeak();
		}
		#end

		if (exitDropdown)
			dropdown.exists = false;

		if (dropdown.exists) {
			var box = listGrp.members[listSelectedIndex];
			if (box != null) {
				var camera = listCamera;
				var y = camera.y + box.getScreenPosition(null, camera).y;
				
				dropdown.x = camera.x + camera.width;
				dropdown.y = y;
			}
		}

		if (cameraMoved)
			listScrollBar.progress = CoolMath.scale(listCamera.scroll.y, listCamera.minScrollY, listCamera.maxScrollY - listCamera.viewHeight, 0, 1);

		super.update(elapsed);
	}

	function save() {

	}

	override function startOutro(onOutroComplete:() -> Void) {
		if (FlxG.sound.music?.playing)
			FlxG.sound.music.fadeOut(0.3, 0.0, _ -> FlxG.sound.music.stop());

		super.startOutro(onOutroComplete);
	}

	override function destroy() {
		FlxG.cameras.remove(listCamera);
		super.destroy();

		if (didChanges) {
			FlxG.sound.destroy(true);
			Paths.clearStoredMemory();
			Paths.clearUnusedMemory();
		}
	}
}

typedef ModMenuCapabilities = {
	var canLaunch:Bool;
	var hasOptions:Bool;
	var hasCredits:Bool;
}

@:publicFields
private class PackDisplayData {
	var title:String;
	var description:String;
	var author:Null<String>;
	var bgColor:FlxColor;
	var accentColor:FlxColor;

	var packIsLoaded:Bool;
	var runsGlobally:Bool;

	var bgAsset:FlxGraphic;
	var bannerAsset:FlxGraphic;

	inline function new() {}

	public function toString() {
		final fields = Type.getInstanceFields(Type.getClass(this));
		final arr:Array<String> = [];

		for (fieldName in fields) {
			if (fieldName == 'bgColor') {
				arr.push('bgColor => ${bgColor.toHexString()}');
				continue;
			}

			var value = Reflect.getProperty(this, fieldName);
			
			if (Reflect.isFunction(value))
				continue;

			arr.push('$fieldName => $value');
		}

		return '[\n' + arr.join('\n') + '\n]';
	}
}

private inline function packGraphic(pack:Pack, key:String):Null<FlxGraphic> {
	if (pack == null)
		return null;
	else {
		var path = pack.getPath('$key.png');
		var bmp = openfl.display.BitmapData.fromFile(path);
		return (bmp==null) ? null : FlxG.bitmap.add(bmp, false, path);
	}
}

private enum abstract ModOption(String) from String to String {
	var LAUNCH_MOD;
	var OPEN_PACK_OPTIONS;
	var OPEN_MOD_LOCATION;
	var ADD_FAVORITE;
	var REMOVE_FAVORITE;
}

private class Dropdown extends FlxTypedGroup<DropdownItem> {
	public var x:Float = 0;
	public var y:Float = 0;

	public var hovered:Bool = false;
	public var selectedIndex:Int = 0;
	public var options(default, null):Array<String>;
	public var callback:(name:String, index:Int) -> Void;

	var width = 256;
	var height = 52;
	var spacing = 4;

	public function new(x:Float = 0.0, y:Float = 0.0) {
		super();
		this.x = x;
		this.y = y;

		camera = new FlxCamera(x, y, width, 1);
		camera.bgColor = 0;
		FlxG.cameras.add(camera, false);
	}

	public function setList(options:Array<String>) {
		var totalHeight = options.length * (height + spacing);
		camera.height = totalHeight;

		killMembers();
		for (i => str in options) {
			var item = members[i] ??= {
				var obj = new DropdownItem();
				add(obj);
				obj;
			};
			var y = (height + spacing) * i;
			item.setup(0, y, width, height, str);
			item.revive();
		}

		this.options = options;
		//changeSelected(-1, true);
	}

	public function changeSelected(val:Int, isAbs:Bool = false) {
		var prevSelected = selectedIndex;
		selectedIndex = isAbs ? val : CoolUtil.updateIndex(selectedIndex, val, this.length);
		
		var prevObj = members[prevSelected];
		prevObj?.unSelected();
		
		var curObj = members[selectedIndex];
		curObj?.onSelected();
	}

	public function acceptSelected() {
		if (callback != null)
			callback(options[selectedIndex], selectedIndex);
	}

	override function update(elapsed:Float) {
		camera.setPosition(x, y);
		hovered = CoolUtil.mouseOverlapsCamera(camera);

		var hoverIdx:Int = -1;
		if (hovered) {
			for (i => obj in members) {
				if (CoolUtil.overlapsMouse(obj.bg, camera)) {
					hoverIdx = i;
					break;
				}
			}
		}
		
		if (!hovered && FlxG.mouse.justPressed) {
			this.exists = false;
		}

		if (hoverIdx != -1 && FlxG.mouse.justPressed)
			acceptSelected();

		if (hoverIdx != selectedIndex && FlxG.mouse.deltaScreenX != 0 && FlxG.mouse.deltaScreenY != 0.0)
			changeSelected(hoverIdx, true);

		////
		var change:Int = Controls.firstActive.UI_VERTICAL_P;
		if (change != 0)
			changeSelected(change);

		if (Controls.firstActive.BACK)
			this.exists = false;

		if (Controls.firstActive.ACCEPT)
			acceptSelected();

		////
		super.update(elapsed);
	}

	override function destroy() {
		FlxG.cameras.remove(camera);
		super.destroy();
	}
}

private class DropdownItem extends FlxGroup {
	public var bg:SlicedSprite;
	public var txt:FlxText;

	public function new() {
		super();
		
		bg = new SlicedSprite(
			0,
			0,
			0,
			0,
			"contentmenu/9slice",
			[24, 24, 24, 28]
		);
		bg.useDefaultAntialiasing = true;

		txt = new FlxText(0, 0, 0, "", 18);
		txt.font = Paths.font("quanticob.ttf");
		txt.color = FlxColor.BLACK;
		
		add(bg);
		add(txt);
	}
	
	public function setup(x:Float = 0.0, y:Float = 0.0, width:Float, height:Float, str:String = "") {
		bg.setPosition(x, y);
		bg.setSize(width, height);

		txt.fieldWidth = width - 24 * 2;
		txt.text = str;
		txt.drawFrame();
		SpriteTools.objectCenter(txt, bg);
	}

	public function onSelected() {
		bg.color = FlxColor.YELLOW;
		//txt.color = FlxColor.RED;
	}
	
	public function unSelected() {
		bg.color = FlxColor.WHITE;
		txt.color = FlxColor.BLACK;
	}
}

private class EntryBox extends FlxSpriteGroup {
	public var entry:PackEntry;

	public var bg:FlxSprite;
	public var icon:FlxSprite;
	public var text:FlxText;
	public var dragSprite:FlxSprite;
	public var toggleSprite:FlxSprite;
	public var selectionHighlight:FlxSprite;
	
	public function new(width:Float, height:Float) {
		super();
		
		bg = new FlxSprite();
		bg.color = FlxColor.WHITE;
		bg.makeGraphic(1, 1);
		bg.scale.set(width, height);
		bg.updateHitbox();
		add(bg);

		dragSprite = new FlxSprite();
		dragSprite.loadGraphic("contentmenu/item_draggable");
		dragSprite.x = bg.x;
		#if lime_funkin
		dragSprite.blend = INVERT;
		#else
		dragSprite.color = FlxColor.BLACK;
		#end
		SpriteTools.objectCenter(dragSprite, bg, Y);
		add(dragSprite);

		icon = new FlxSprite(dragSprite.x + dragSprite.width + 8);
		add(icon);

		text = new FlxText(0, 0, 0, "unknown", 18);
		text.setFormat(Paths.font("quanticob.ttf"), 18, 0xFF000000, LEFT);
		text.alignment = LEFT;
		//text.setFormat();
		//text.color = 0xFF000000;
		add(text);
		SpriteTools.objectCenter(text, bg, Y);
		text.y = Math.fround(text.y);

		////
		toggleSprite = new FlxSprite();
		var graphic = Paths.image("contentmenu/active_indicator");
		toggleSprite.loadGraphic(graphic, true, Std.int(graphic.width / 2), graphic.height);
		toggleSprite.animation.add("off", [0]);
		toggleSprite.animation.add("on", [1]);
		add(toggleSprite);
		toggleSprite.x = bg.x + bg.width - toggleSprite.width - 20;
		//toggleSprite.x = draggable.x - toggleSprite.width;
		SpriteTools.objectCenter(toggleSprite, bg, Y);

		selectionHighlight = new FlxSprite();
		selectionHighlight.color = FlxColor.BLACK;
		selectionHighlight.alpha = 0.3;
		selectionHighlight.makeGraphic(1, 1);
		selectionHighlight.setGraphicSize(width, height);
		selectionHighlight.updateHitbox();
		add(selectionHighlight);

		unSelected();
	}

	public function setEntry(entry:PackEntry) {
		this.entry = entry;
		
		updateToggleSprite();
		
		@:privateAccess {
			final pack = PackManager.allPacks.get(entry.id);

			bg.color = pack.loadException.length > 0 ? FlxColor.RED : FlxColor.WHITE;

			var graphic:FlxGraphic = packGraphic(pack, 'packicon');
			graphic ??= Paths.image("contentmenu/pack");
			icon.loadGraphic(graphic);
			icon.checkEmptyFrame(); // flixel icon :o
		}
		
		icon.setGraphicSize(32, 32);
		icon.updateHitbox();
		SpriteTools.objectCenter(icon, bg, Y);

		text.text = entry.id;
		text.x = icon.x + icon.width + 12;
		text.fieldWidth = Std.int(toggleSprite.x - text.x - 20);
	}

	public function updateToggleSprite() {
		toggleSprite.animation.play(entry.enabled ? "on" : "off");
	}

	public function onSelected() {
		selectionHighlight.visible = false;
		bg.alpha = 0.75;
		bg.blend = NORMAL;
		text.alpha = 1.0;
	}
	
	public function unSelected() {
		selectionHighlight.visible = true;
		bg.alpha = 0.67;
		bg.blend = OVERLAY;
		text.alpha = 0.8;
	}
}

/*
abstract MenuIndex(Int) from Int to Int {

}

class AutoScrollingText extends FlxText {
	public var minX:Float = 32;
	public var maxX:Float = FlxG.width - 32;
	public var viewWidth(get, never):Float;

	public var bg:FlxSprite;
	public var bar:FlxSprite;

	override public function new(x:Float, x:Float, fw:Float) {
		bg = new FlxSprite().makeGraphic(1, 1);
		bg.exists = false;

		bar = new FlxSprite().makeGraphic(1, 1);
		bar.scale.x = 12;

		super(x, x, fw);
	}

	override function graphicLoaded() {
		super.graphicLoaded();
	}
	
	override function update(elapsed:Float) {
		bg.update(elapsed);
		super.update(elapsed);
		bar.update(elapsed);
		
		final viewWidth = viewWidth;
		this.x = CoolMath.boundTo(this.x, maxX - this.width, minX);
	}
	
	override function draw() {
		if (bg.exists && bg.visible) {
			bg.setPosition(this.x, minX);
			bg.setGraphicSize(this.width, viewWidth);
			bg.updateHitbox();
			bg.scrollFactor.copyFrom(this.scrollFactor);
			bg.draw();
		}

		{
			var rect = this.clipRect ?? new FlxRect();
			var bottom = this.x + this.width;
			
			rect.set(0, 0, this.width, this.width);
			rect.x = Math.max(0.0, minX - this.x);
			rect.width = this.width - (bottom - maxX) - rect.x;
			
			this.clipRect = rect;
			super.draw();
		}
	}

	override function destroy() {
		super.destroy();
		bg.destroy();
		bar.destroy();
	}

	inline function get_viewWidth() return maxX - minX;
}
*/