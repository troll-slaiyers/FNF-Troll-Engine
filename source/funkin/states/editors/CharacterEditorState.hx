package funkin.states.editors;

import funkin.objects.ui.ColorPicker;
import flixel.group.FlxGroup;
import haxe.io.Path;
import funkin.objects.hud.HealthIcon;
import funkin.objects.Character;
import funkin.data.CharacterData;
import funkin.objects.ui.CustomFlxUI;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.animation.FlxAnimation;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import haxe.Json;

using StringTools;

#if DISCORD_ALLOWED
import funkin.api.Discord.DiscordClient;
#end

final TemplateCharacter:String = '{
	"animations": [
		{
			"loop": false,
			"offsets": [
				0,
				0
			],
			"fps": 24,
			"anim": "idle",
			"indices": [],
			"name": "Dad idle dance"
		},
		{
			"offsets": [
				0,
				0
			],
			"indices": [],
			"fps": 24,
			"anim": "singLEFT",
			"loop": false,
			"name": "Dad Sing Note LEFT"
		},
		{
			"offsets": [
				0,
				0
			],
			"indices": [],
			"fps": 24,
			"anim": "singDOWN",
			"loop": false,
			"name": "Dad Sing Note DOWN"
		},
		{
			"offsets": [
				0,
				0
			],
			"indices": [],
			"fps": 24,
			"anim": "singUP",
			"loop": false,
			"name": "Dad Sing Note UP"
		},
		{
			"offsets": [
				0,
				0
			],
			"indices": [],
			"fps": 24,
			"anim": "singRIGHT",
			"loop": false,
			"name": "Dad Sing Note RIGHT"
		}
	],
	"no_antialiasing": false,
	"image": "characters/DADDY_DEAREST",
	"position": [
		0,
		0
	],
	"healthicon": "face",
	"flip_x": false,
	"healthbar_colors": [
		161,
		161,
		161
	],
	"camera_position": [
		0,
		0
	],
	"sing_duration": 6.1,
	"scale": 1
}';

class CharacterEditorState extends funkin.states.base.CustomFlxUIState {
	static function getAnimOrder(name:String):Int {
		var points = 0;

		for (i => aaa in ['idle', 'singLEFT', 'singDOWN', 'singUP', 'singRIGHT']) {
			if (name.startsWith(aaa))
				points += (-272727) + i * 10;
		}
		for (i => aaa in ['miss', 'alt', 'loop']) {
			if (name.endsWith(aaa))
				points += (2727) + i;
		}

		return points;
	}

	static function animSortFunc(a:AnimArray, b:AnimArray)
		return getAnimOrder(a.anim) - getAnimOrder(b.anim);

	////
	var goToPlayState:Bool = true;

	var originMarker:FlxSprite;
	var char:Character;
	var ghostChar:Null<Character>;
	var bgLayer:FlxTypedGroup<FlxSprite>;
	var charLayer:FlxTypedGroup<Character>;
	var animTexts:FlxTypedGroup<FlxText>;
	// var animList:Array<String> = [];
	var curAnim:Int = 0;
	var charName:String = 'pico';
	var camFollow:FlxObject;

	public function new(charName:String = 'pico', goToPlayState:Bool = true) {
		super();
		this.charName = charName;
		this.goToPlayState = goToPlayState;
	}

	var UI_box:FlxUITabMenu;
	var UI_characterbox:FlxUITabMenu;

	var tipTexts:FlxTypedGroup<FlxText>;
	var testModeTipTexts:FlxTypedGroup<FlxText>;

	private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;
	private var camMenu:FlxCamera;

	var testModeButton:FlxButton;
	var leHealthIcon:HealthIcon;
	var characterList:Array<String> = [];

	var cameraFollowPointer:FlxSprite;
	var healthBarBG:FlxSprite;

	var ghostCamPointer:FlxSprite;

	override function create() {
		// FlxG.sound.playMusic(Paths.music('breakfast'), 0.5);

		camEditor = new FlxCamera();
		camEditor.bgColor = 0xFF999999;
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camMenu = new FlxCamera();
		camMenu.bgColor.alpha = 0;

		FlxG.cameras.reset(camEditor);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camMenu, false);
		FlxG.cameras.setDefaultDrawTarget(camEditor, true);

		bgLayer = new FlxTypedGroup<FlxSprite>();
		add(bgLayer);
		charLayer = new FlxTypedGroup<Character>();
		add(charLayer);

		var pointer:FlxGraphic = FlxGraphic.fromClass(GraphicCursorCross);

		ghostCamPointer = new FlxSprite().loadGraphic(pointer);
		ghostCamPointer.setGraphicSize(40, 40);
		ghostCamPointer.updateHitbox();
		ghostCamPointer.color = FlxColor.BLUE;
		ghostCamPointer.alpha = 0;
		ghostCamPointer.visible = false;
		ghostCamPointer.antialiasing = false;
		add(ghostCamPointer);

		cameraFollowPointer = new FlxSprite().loadGraphic(pointer);
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();
		cameraFollowPointer.color = FlxColor.RED;
		cameraFollowPointer.antialiasing = false;
		add(cameraFollowPointer);

		originMarker = new FlxSprite(0, 0, Paths.image("stageeditor/originMarker"));
		originMarker.offset.set(originMarker.width / 2, originMarker.height / 2);
		add(originMarker);

		animTexts = new FlxTypedGroup<FlxText>();
		animTexts.camera = camHUD;
		add(animTexts);

		var healthbarGraphic = Paths.image('healthBar');
		if (healthbarGraphic == null)
			healthbarGraphic = CoolUtil.makeOutlinedGraphic(600, 18, 0xFFFFFFFF, 5, 0xFF000000);

		healthBarBG = new FlxSprite(30, FlxG.height - 75, healthbarGraphic);
		healthBarBG.scrollFactor.set();
		healthBarBG.camera = camHUD;
		add(healthBarBG);

		leHealthIcon = new HealthIcon();
		leHealthIcon.y = FlxG.height - 150;
		leHealthIcon.camera = camHUD;
		add(leHealthIcon);

		camFollow = new FlxObject();
		add(camFollow);
		FlxG.camera.follow(camFollow);

		loadChar(charName.startsWith('bf'));
		resetCam();
		
		inline function makeTipTexts(texts:String) {
			var group = new FlxTypedGroup<FlxText>();
			group.camera = camHUD;
			add(group);
			
			var tipTextArray = texts.split('\n');
			for (i => str in tipTextArray) {
				var tipText:FlxText = new FlxText(FlxG.width - 320, FlxG.height - 15 - 16 * (tipTextArray.length - i), 300, str, 12);
				tipText.setFormat(null, 12, FlxColor.WHITE, RIGHT);
				tipText.setBorderStyle(FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK, 1);
				tipText.scrollFactor.set();
				group.add(tipText);
			}
			return group;
		}

		tipTexts = makeTipTexts(
			"E/Q - Camera Zoom In/Out
			\nR - Reset Camera Zoom
			\nIJKL - Move Camera
			\nW/S - Previous/Next Animation
			\nSpace - Play Animation
			\nArrow Keys - Move Character Offset
			\nT - Reset Current Offset
			\nHold SHIFT to Move 10x faster\n"
		);

		testModeTipTexts = makeTipTexts(
			"-- Test Mode --
			\nSPACE - Play Idle Animation
			\nDFJK - Play Note Animations
			\nERUI - Play Miss Animations
			\nHold SHIFT to play Alt Animations\n"
		);
		testModeTipTexts.exists = false;

		var tabs = [
			{name: 'Editor', label: 'Editor'},
			{name: 'Ghost', label: 'Ghost'},
		];
		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.cameras = [camMenu];

		UI_box.resize(360, 160);
		UI_box.x = FlxG.width - UI_box.width - 25;
		UI_box.y = 25;
		UI_box.scrollFactor.set();

		var tabs = [
			{name: 'Character', label: 'Character'},
			{name: 'Animations', label: 'Animations'},
		];
		UI_characterbox = new FlxUITabMenu(null, tabs, true);
		UI_characterbox.cameras = [camMenu];

		UI_characterbox.resize(360, 250);
		UI_characterbox.x = UI_box.x + UI_box.width - UI_characterbox.width;
		UI_characterbox.y = UI_box.y + UI_box.height;
		UI_characterbox.scrollFactor.set();
		add(UI_characterbox);
		add(UI_box);

		addEditorUI();
		addGhostUI();

		addCharacterUI();
		addAnimationsUI();

		reloadCharacterOptions();
		UI_characterbox.selected_tab_id = 'Character';

		FlxG.mouse.visible = true;

		super.create();
	}

	function resetCam() {
		var camPos = char.getCamera();
		camFollow.x = camPos[0];
		camFollow.y = camPos[1];

		FlxG.camera.zoom = 1;
	}

	override function onFocus() {
		FlxG.mouse.visible = true;
	}

	var testMode:Bool = false;

	var charDropDown:FlxUIDropDownMenu;

	function addEditorUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Editor";

		var check_player = new FlxUICheckBox(15, 60, null, null, "Playable Character", 100);
		check_player.checked = char.isPlayer;
		check_player.callback = function() {
			char.isPlayer = !char.isPlayer;
			char.flipX = !char.flipX;
			char.xFacing = char.isPlayer ? -1 : 1;
			updatePointerPos();
		};

		testModeButton = new FlxButton(15, 90, "Test: OFF", function() {
			testModeButton.text = (testMode = !testMode) ? "Test: ON" : "Test: OFF";
			testModeTipTexts.exists = testMode;
			tipTexts.exists = !testMode;
		});

		charDropDown = new FlxUIDropDownMenu(15, 30, FlxUIDropDownMenu.makeStrIdLabelArray([''], true), function(character:String) {
			charName = characterList[Std.parseInt(character)];

			loadChar(check_player.checked);
			updateDiscordPresence();
			reloadCharacterDropDown();
		});

		var saveCharacterButton = new FlxButton(360 - 80 - 15, 30, "Save File", saveCharacter);

		var templateCharacter:FlxButton = new FlxButton(360 - 80 - 15, 90, "Load Template", function() {
			var parsedJson:CharacterFile = cast Json.parse(TemplateCharacter);

			inline function loadTemplate(char:Character){
				char.animOffsets.clear();
				char.animationsArray = parsedJson.animations;
				for (anim in char.animationsArray) {
					char.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
				}
				if (char.animationsArray[0] != null) {
					char.playAnim(char.animationsArray[0].anim, true);
				}

				char.singDuration = parsedJson.sing_duration;
				char.positionArray = parsedJson.position;
				char.cameraPosition = parsedJson.camera_position;

				char.imageFile = parsedJson.image;
				char.baseScale = parsedJson.scale;
				char.noAntialiasing = parsedJson.no_antialiasing;
				char.originalFlipX = parsedJson.flip_x;
				char.healthIcon = parsedJson.healthicon;
				char.healthColorArray = parsedJson.healthbar_colors;
				char.setPosition(char.positionArray[0], char.positionArray[1]);

				reloadCharacterImage(char);
			}
			loadTemplate(char);
			if(ghostMirrorsCharacter){
				loadTemplate(ghostChar);
				updateGhostAnimationsList();
				ghostCharName = "Current Character";
			}
			reloadCharacterDropDown();
			reloadCharacterOptions();
			resetHealthBarColor();
			updatePointerPos();
			updateAnimList();
		});
		templateCharacter.color = FlxColor.RED;
		templateCharacter.label.color = FlxColor.WHITE;

		tab_group.add(new FlxText(charDropDown.x, charDropDown.y - 15, 0, 'Character:'));
		tab_group.add(check_player);
		tab_group.add(testModeButton);
		tab_group.add(charDropDown);
		tab_group.add(saveCharacterButton);
		tab_group.add(templateCharacter);
		UI_box.addGroup(tab_group);

		charDropDown.selectedLabel = charName;
		reloadCharacterDropDown();
	}

	var imageInputText:FlxUIInputText;
	var healthIconInputText:FlxUIInputText;

	var singDurationStepper:FlxUINumericStepper;
	var scaleStepper:FlxUINumericStepper;
	var positionXStepper:FlxUINumericStepper;
	var positionYStepper:FlxUINumericStepper;
	var positionCameraXStepper:FlxUINumericStepper;
	var positionCameraYStepper:FlxUINumericStepper;

	var flipXCheckBox:FlxUICheckBox;
	var noAntialiasingCheckBox:FlxUICheckBox;

	var healthColorPicker:ColorPicker;

	function addCharacterUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Character";

		imageInputText = new FlxUIInputText(15, 30, 200, 'characters/BOYFRIEND', 8);
		imageInputText.name = "char_imageFile";

		var reloadImage = new FlxButton(imageInputText.x + 210, imageInputText.y - 3, "Reload Image", function() {

			inline function _reloadImage(char:Character){
				char.imageFile = imageInputText.text;
				reloadCharacterImage(char);
				if (char.animation.curAnim != null) {
					char.playAnim(char.animation.curAnim.name, true);
				}
			}

			_reloadImage(char);
			if (ghostMirrorsCharacter)
				_reloadImage(ghostChar);
		});
		
		singDurationStepper = new CustomFlxUINumericStepper(15, imageInputText.y + 35, 0.1, 4, 0, 999, 1);
		singDurationStepper.name = 'char_singDuration';

		scaleStepper = new CustomFlxUINumericStepper(15, singDurationStepper.y + 40, 0.1, 1, 0.05, 10, 1);
		scaleStepper.name = "char_scale";

		flipXCheckBox = new FlxUICheckBox(singDurationStepper.x + 80, singDurationStepper.y, null, null, "Flip X", 50);
		flipXCheckBox.checked = char.isPlayer ? !char.flipX : char.flipX;
		flipXCheckBox.callback = function() {
			char.originalFlipX = !char.originalFlipX;
			char.flipX = char.originalFlipX;
			if (char.isPlayer)
				char.flipX = !char.flipX;
		};

		noAntialiasingCheckBox = new FlxUICheckBox(flipXCheckBox.x, flipXCheckBox.y + 40, null, null, "No Antialiasing", 80);
		noAntialiasingCheckBox.name = 'char_noAntialiasing';
		noAntialiasingCheckBox.checked = char.noAntialiasing;

		positionXStepper = new CustomFlxUINumericStepper(flipXCheckBox.x + 110, flipXCheckBox.y, 10, char.positionArray[0], -9000, 9000, 0);
		positionXStepper.name = "char_position_x";

		positionYStepper = new CustomFlxUINumericStepper(positionXStepper.x + 60, positionXStepper.y, 10, char.positionArray[1], -9000, 9000, 0);
		positionYStepper.name = "char_position_y";

		positionCameraXStepper = new CustomFlxUINumericStepper(positionXStepper.x, positionXStepper.y + 40, 10, char.cameraPosition[0], -9000, 9000, 0);
		positionCameraXStepper.name = 'char_cameraPosition_x';

		positionCameraYStepper = new CustomFlxUINumericStepper(positionYStepper.x, positionYStepper.y + 40, 10, char.cameraPosition[1], -9000, 9000, 0);
		positionCameraYStepper.name = 'char_cameraPosition_y';

		var y = noAntialiasingCheckBox.y + 45;

		healthIconInputText = new FlxUIInputText(15, y, 75, leHealthIcon.getCharacter(), 8);
		healthIconInputText.name = 'char_healthIcon';

		healthColorPicker = new ColorPicker(15, y + 25, "Health bar color", setHealthBarColor);
	
		var decideIconColor = new FlxButton(15, y + 50, "Get Icon Color", function() {
			try {
				setHealthBarColor(CoolUtil.dominantColor(leHealthIcon));
			} catch (e) {
				if (Main.showDebugTraces) {
					trace(e.details());
				}
			}
		});

		tab_group.add(new FlxText(15, imageInputText.y - 15, 0, 'Image file name:'));
		tab_group.add(new FlxText(15, healthIconInputText.y - 15, 0, 'Health icon name:'));
		tab_group.add(new FlxText(15, singDurationStepper.y - 15, 0, 'Sing duration:'));
		tab_group.add(new FlxText(15, scaleStepper.y - 15, 0, 'Scale:'));
		tab_group.add(new FlxText(positionXStepper.x, positionXStepper.y - 15, 0, 'Character X/Y:'));
		tab_group.add(new FlxText(positionCameraXStepper.x, positionCameraXStepper.y - 15, 0, 'Camera X/Y:'));
		tab_group.add(imageInputText);
		tab_group.add(reloadImage);
		tab_group.add(decideIconColor);
		tab_group.add(healthIconInputText);
		tab_group.add(singDurationStepper);
		tab_group.add(scaleStepper);
		tab_group.add(flipXCheckBox);
		tab_group.add(noAntialiasingCheckBox);
		tab_group.add(positionXStepper);
		tab_group.add(positionYStepper);
		tab_group.add(positionCameraXStepper);
		tab_group.add(positionCameraYStepper);
		tab_group.add(healthColorPicker);
		UI_characterbox.addGroup(tab_group);
	}

	var animationDropDown:FlxUIDropDownMenu;
	var animationInputText:FlxUIInputText;
	var animationXCam:FlxUINumericStepper;
	var animationYCam:FlxUINumericStepper;
	var animationNameInputText:FlxUIInputText;
	var animationIndicesInputText:FlxUIInputText;
	var animationNameFramerate:FlxUINumericStepper;
	var animationLoopCheckBox:FlxUICheckBox;

	function addAnimationsUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Animations";

		animationInputText = new FlxUIInputText(15, 85, 80, '', 8);
		animationNameInputText = new FlxUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		animationIndicesInputText = new FlxUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
		animationNameFramerate = new CustomFlxUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
		animationLoopCheckBox = new FlxUICheckBox(animationNameFramerate.x + 75, animationNameFramerate.y, null, null, "Loop", 100);

		animationXCam = new CustomFlxUINumericStepper(animationNameInputText.x + 170, animationNameInputText.y, 10, 0, -9000, 9000, 0);
		animationXCam.name = 'animation_cam_x';
		
		animationYCam = new CustomFlxUINumericStepper(animationXCam.x + 60, animationXCam.y, 10, 0, -9000, 9000, 0);
		animationYCam.name = 'animation_cam_y';

		animationDropDown = new FlxUIDropDownMenu(15, animationInputText.y - 55, FlxUIDropDownMenu.makeStrIdLabelArray([''], true), function(pressed:String) {
			var selectedAnimation:Int = Std.parseInt(pressed);
			var anim:AnimArray = char.animationsArray[selectedAnimation];

			if (anim == null)
				return;

			animationInputText.text = anim.anim;
			animationNameInputText.text = anim.name;
			animationLoopCheckBox.checked = anim.loop;
			animationNameFramerate.value = anim.fps;

			animationIndicesInputText.text = (anim.indices == null) ? '' : anim.indices.join(',');

			var cameraOffset:Array<Float> = anim.cameraOffset ?? CharacterData.getDefaultAnimCamOffset(anim.anim);
			animationXCam.value = cameraOffset[0];
			animationYCam.value = cameraOffset[1];
			updatePointerPos();
		});

		var addUpdateButton:FlxButton = new FlxButton(70, animationIndicesInputText.y + 30, "Add/Update", function() {
			inline function updateAnimation(char:Character){
				var indicesInput = animationIndicesInputText.text.trim();
				var indices:Array<Int> = indicesInput.length == 0 ? null : CharacterData.parseIndices(indicesInput.split(','));

				var lastAnim:String = char.animationsArray[curAnim] != null ? char.animationsArray[curAnim].anim : '';

				var lastOffsets:Array<Float> = [0, 0];
				for (anim in char.animationsArray) {
					if (animationInputText.text == anim.anim) {
						lastOffsets = anim.offsets;
						if (char.animation.exists(animationInputText.text))
							char.animation.remove(animationInputText.text);

						char.animationsArray.remove(anim);
					}
				}

				var newAnim:AnimArray = {
					anim: animationInputText.text,
					name: animationNameInputText.text,
					fps: Math.round(animationNameFramerate.value),
					loop: animationLoopCheckBox.checked,
					indices: indices,
					offsets: lastOffsets,
					cameraOffset: [animationXCam.value, animationYCam.value]
				};

				if (indices != null && indices.length > 0) {
					char.animation.addByIndices(newAnim.anim, newAnim.name, newAnim.indices, "", newAnim.fps, newAnim.loop);
				} else {
					char.animation.addByPrefix(newAnim.anim, newAnim.name, newAnim.fps, newAnim.loop);
				}

				if (!char.animOffsets.exists(newAnim.anim))
					char.addOffset(newAnim.anim, 0, 0);

				char.animationsArray.push(newAnim);
				char.animationsArray.sort(animSortFunc);

				if (lastAnim == animationInputText.text) {
					var leAnim:FlxAnimation = char.animation.getByName(lastAnim);
					if (leAnim != null && leAnim.frames.length > 0) {
						char.playAnim(lastAnim, true);
					} else {
						for (i in 0...char.animationsArray.length) {
							if (char.animationsArray[i] != null) {
								leAnim = char.animation.getByName(char.animationsArray[i].anim);
								if (leAnim != null && leAnim.frames.length > 0) {
									char.playAnim(char.animationsArray[i].anim, true);
									curAnim = i;
									break;
								}
							}
						}
					}
				}
			}

			updateAnimation(char);
			if(ghostMirrorsCharacter){
				updateAnimation(ghostChar);
				updateGhostAnimationsList();
			}

			reloadAnimationDropDown();
			updateAnimList();
			trace('Added/Updated animation: ' + animationInputText.text);
		});

		var removeButton:FlxButton = new FlxButton(180, animationIndicesInputText.y + 30, "Remove", function() {
			inline function removeAnim(char:Character){
				for (anim in char.animationsArray) {
					if (animationInputText.text == anim.anim) {
						var resetAnim:Bool = (anim.anim == char.animation.name);

						if (resetAnim)
							char.animation.curAnim = null;

						if (char.animation.exists(anim.anim))
							char.animation.remove(anim.anim);

						if (char.animOffsets.exists(anim.anim))
							char.animOffsets.remove(anim.anim);

						char.animationsArray.remove(anim);

						if (resetAnim && char.animationsArray.length > 0)
							char.playAnim(char.animationsArray[0].anim, true);

						reloadAnimationDropDown();
						updateAnimList();
						trace('Removed animation: ' + animationInputText.text);
						break;
					}
				}
			}
			removeAnim(char);
			if(ghostMirrorsCharacter){
				removeAnim(ghostChar);
			}
		});

		tab_group.add(new FlxText(animationXCam.x, animationXCam.y - 15, 0, 'Camera X/Y Offset:'));
		// tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 0, 'Animations:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 15, 0, 'Animation name:'));
		tab_group.add(new FlxText(animationNameFramerate.x, animationNameFramerate.y - 15, 0, 'Framerate:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 15, 0, 'Animation on .XML/.TXT file:'));
		tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 15, 0, 'ADVANCED - Animation Indices:'));

		tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationNameFramerate);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(animationXCam);
		tab_group.add(animationYCam);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);

		tab_group.add(animationDropDown);

		updatePointerPos();
		UI_characterbox.addGroup(tab_group);
	}

	var ghostCharDropDown:FlxUIDropDownMenu;
	var ghostAnimDropDown:FlxUIDropDownMenu;
	var ghostAnimTxt:FlxText;
	var ghostPlayableCheckbox:FlxUICheckBox;

	var ghostList:Array<String>;

	function updateGhostCharList() {
		ghostList = CharacterData.getAllCharacters();
		ghostList.sort(CoolUtil.alphabeticalSort);
		ghostList.insert(0, "");
		ghostList.insert(1, "Current Character");
		ghostCharDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(ghostList, true));
	}

	function addGhostUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Ghost";

		ghostCharDropDown = new FlxUIDropDownMenu(15, 30, FlxUIDropDownMenu.makeStrIdLabelArray([''], true), function(pressed:String) {
			var idx:Int = Std.parseInt(pressed);
			var charName = ghostList[idx];
			if(ghostCharName == charName){
				return;
			}

			updateGhostCharList();
			ghostCharDropDown.selectedLabel = charName;

			if (ghostChar != null) {
				charLayer.remove(ghostChar);
				ghostChar.destroy();
				ghostChar = null;
			}

			if (charName != "") {
				reloadGhost(charName);
				char.alpha = 0.85;
				cameraFollowPointer.alpha = 0.85;
			} else {
				ghostAnimDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray([''], true));
				ghostAnimTxt.text = "";

				char.alpha = 1;
				cameraFollowPointer.alpha = 1;
			}

			updateGhostPointerPos();
		});
		updateGhostCharList();

		ghostAnimDropDown = new FlxUIDropDownMenu(15, ghostCharDropDown.y + 40, FlxUIDropDownMenu.makeStrIdLabelArray([''], true), function(pressed:String) {
			if (ghostChar == null)
				return;

			var curAnimData = ghostChar.animationsArray[Std.parseInt(pressed)];
			var offsets = curAnimData.offsets;

			ghostChar.playAnim(curAnimData.anim, true);
			ghostAnimTxt.text = 'Offset [${offsets[0]}, ${offsets[1]}]';
		});

		ghostPlayableCheckbox = new FlxUICheckBox(15, ghostAnimDropDown.y + 30, null, null, "Playable Character", 100);
		ghostPlayableCheckbox.callback = () -> {
			if (ghostChar != null) {
				ghostChar.isPlayer = !ghostChar.isPlayer;
				ghostChar.flipX = !ghostChar.flipX;
				ghostChar.xFacing = ghostChar.isPlayer ? -1 : 1;
			}

			updateGhostPointerPos();
		}

		var copyGhostCamera = new FlxButton(360 - 80 - 15, ghostCharDropDown.y, "Copy Camera", function() {
			if (ghostChar == null)
				return;

			var diff = ghostCamPointer.x - cameraFollowPointer.x;
			trace(diff);
			char.cameraPosition[0] += diff * char.xFacing;
			char.cameraPosition[1] += ghostCamPointer.y - cameraFollowPointer.y;

			updatePointerPos();
		});

		var copyGhostOffsets = new FlxButton(360 - 80 - 15, ghostAnimDropDown.y, "Copy Offset", function() {
			if (ghostChar == null)
				return;

			var curAnimData = char.animationsArray[curAnim];
			var animName = curAnimData.anim;
			var offsets = curAnimData.offsets;

			char.addOffset(animName, offsets[0], offsets[1]);
			char.playAnim(animName, true);
		});

		ghostAnimTxt = new FlxText(ghostAnimDropDown.x + 100, ghostAnimDropDown.y, 0, '');
		ghostAnimTxt.fieldWidth = copyGhostOffsets.x - ghostAnimTxt.x;
		ghostAnimTxt.alignment = CENTER;

		var ghostShowCamPointer = new FlxUICheckBox(ghostCharDropDown.x + 140, ghostCharDropDown.y, null, null, "Show Camera Pointer");
		ghostShowCamPointer.checked = ghostCamPointer.visible;
		ghostShowCamPointer.callback = () -> {
			ghostCamPointer.visible = ghostShowCamPointer.checked;
		};

		////
		tab_group.add(new FlxText(ghostCharDropDown.x, ghostCharDropDown.y - 15, 0, 'Character:'));
		tab_group.add(new FlxText(ghostAnimDropDown.x, ghostAnimDropDown.y - 15, 0, 'Animation:'));
		tab_group.add(ghostPlayableCheckbox);
		tab_group.add(ghostAnimDropDown);
		tab_group.add(ghostCharDropDown);

		tab_group.add(ghostShowCamPointer);
		tab_group.add(ghostAnimTxt);

		tab_group.add(copyGhostOffsets);
		tab_group.add(copyGhostCamera);

		UI_box.addGroup(tab_group);
	}

	var ghostMirrorsCharacter:Bool = false;
	var ghostCharName:String = "";

	function reloadGhost(charName:String) {
		if(ghostCharName == charName){
			return;
		}
		ghostCharName = charName;
		ghostChar = new Character(0, 0, charName == "Current Character" ? char.characterId : charName, ghostPlayableCheckbox.checked);
		ghostChar.debugMode = true;
		ghostChar.setupCharacter();
		ghostChar.alpha = 0.6;
		ghostChar.color = 0xFF666688;

		ghostChar.setPosition(ghostChar.positionArray[0], ghostChar.positionArray[1]);

		charLayer.insert(0, ghostChar);

		////

		updateGhostAnimationsList();

		ghostMirrorsCharacter = (charName == "Current Character");
	}

	function updateGhostAnimationsList(){
		if(ghostChar == null){
			return;
		}
		var animList:Array<String> = [
			for (anim in ghostChar.animationsArray)
				anim.anim
		];
		if (animList.length < 1)
			animList.push('NO ANIMATIONS'); // Prevents crash

		var firstAnim = animList.indexOf("idle");
		firstAnim = firstAnim != -1 ? firstAnim : 0;

		ghostAnimDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(animList, true));
		ghostAnimDropDown.selectedId = Std.string(firstAnim);

		var curAnimData = ghostChar.animationsArray[firstAnim];
		var offsets = curAnimData.offsets;

		ghostAnimTxt.text = 'Offset [${offsets[0]}, ${offsets[1]}]';

		ghostChar.playAnim(curAnimData.anim, true);
	}

	function updateGhostPointerPos() {
		if (ghostChar == null) {
			ghostCamPointer.alpha = 0;
			return;
		} else {
			ghostCamPointer.alpha = 0.6;
		}

		var cam = ghostChar.getCamera();

		ghostCamPointer.setPosition(cam[0] - ghostCamPointer.width * 0.5, cam[1] - ghostCamPointer.height * 0.5);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if (id == FlxUIInputText.CHANGE_EVENT)
		{
			var sender:FlxUIInputText = cast sender;
			switch (sender.name) {
				case 'char_healthIcon':
					leHealthIcon.changeIcon(sender.text);
					char.healthIcon = sender.text;
					updateDiscordPresence();
				case 'char_imageFile':
					char.imageFile = sender.text;
			}
		}
		else if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var sender:FlxUICheckBox = cast sender;
			switch (sender.name) {
				case 'char_noAntialiasing':
					char.antialiasing = !sender.checked;
					char.noAntialiasing = sender.checked;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT)
		{
			var sender:FlxUINumericStepper = cast sender;
			switch (sender.name) {
				case 'char_scale':
					char.baseScale = sender.value;
					char.scale.set(sender.value, sender.value);
	
					if (ghostMirrorsCharacter) {
						ghostChar.baseScale = sender.value;
						ghostChar.scale.set(sender.value, sender.value);
						if (ghostChar.animation.curAnim != null) {
							ghostChar.playAnim(ghostChar.animation.curAnim.name, true);
						} else {
							ghostChar.updateHitbox();
						}
					}
	
					updatePointerPos();
	
					if (char.animation.curAnim != null) {
						char.playAnim(char.animation.curAnim.name, true);
					} else {
						char.updateHitbox();
					}
				
				case 'char_position_x':
					char.positionArray[0] = sender.value;
					char.x = char.positionArray[0];
					updatePointerPos();
				case 'char_position_y':
					char.positionArray[1] = sender.value;
					char.y = char.positionArray[1];
					updatePointerPos();
				
				case 'char_cameraPosition_x':
					char.cameraPosition[0] = sender.value;
					updatePointerPos();
				case 'char_cameraPosition_y':
					char.cameraPosition[1] = sender.value;
					updatePointerPos();
				
				case 'animation_cam_x' | 'animation_cam_y':
					updatePointerPos();

				case 'char_singDuration':
					char.singDuration = sender.value; // ermm you forgot this??

			}
		}
	}

	function reloadCharacterImage(char:Character) {
		var lastAnim = char.animation.name;

		try {
			Paths.removeBitmap(char.frames.parent.key); // is null SOMETIMES idk WHY
		} catch (e) {
			if (Main.showDebugTraces) {
				trace(e.details());
			}
		}

		if (Paths.fileExists('images/' + char.imageFile + '/Animation.json', TEXT)) {
			char.frames = Paths.animateAtlas(char.imageFile);
		} else if (Paths.fileExists('images/' + char.imageFile + '.txt', TEXT)) {
			char.frames = Paths.packerAtlas(char.imageFile);
		} else {
			char.frames = Paths.sparrowAtlas(char.imageFile);
		}

		if (char.animationsArray != null && char.animationsArray.length > 0) {
			for (anim in char.animationsArray) {
				var name:String = '' + anim.anim;
				var prefix:String = '' + anim.name;
				var framerate:Int = anim.fps;
				var looped:Bool = !!anim.loop; // Bruh
				var indices:Array<Int> = anim.indices;

				if (indices != null && indices.length > 0)
					char.animation.addByIndices(name, prefix, indices, "", framerate, looped);
				else
					char.animation.addByPrefix(name, prefix, framerate, looped);
			}
		} else {
			char.quickAnimAdd('idle', 'BF idle dance');
		}

		if (lastAnim != null && char.animation.exists(lastAnim)) {
			char.playAnim(lastAnim, true);
		} else {
			char.dance();
		}

		ghostAnimDropDown.selectedLabel = '';
	}

	function updateAnimList():Void {
		animTexts.killMembers();

		inline function makeText(i:Int, label:String, color:FlxColor = 0xFFFFFFFF) {
			var text:FlxText = animTexts.recycle(FlxText, () -> return new FlxText());
			text.text = label;
			text.setPosition(10, 20 + (18 * i));
			text.setFormat(null, 16, color, CENTER);
			text.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1);
			text.scrollFactor.set();
			animTexts.add(text);
			return text;
		}

		if (char.animationsArray.length < 1) {
			makeText(0, 'NO ANIMATIONS AVAILABLE.', 0xFFFF0000);
			return;
		}

		char.animationsArray.sort(animSortFunc);
		for (i => anim in char.animationsArray) {
			var name = anim.anim;
			var offsets = char.animOffsets.get(name);
			var isSelected = i == curAnim;

			if (isSelected)
				makeText(i, '> $name: $offsets', 0xFF00FF00).x += 6;
			else
				makeText(i, '$name: $offsets',0xFFFFFFFF);
		}
	}

	function loadChar(isPlayer:Bool) {
		if (char != null) {
			charLayer.remove(char);
			char.destroy();
		}

		char = new Character(0, 0, charName, isPlayer);
		char.debugMode = true;
		char.startScripts();
		char.setupCharacter();
		if (char.animationsArray[0] != null)
			char.playAnim(char.animationsArray[0].anim, true);

		char.setPosition(char.positionArray[0], char.positionArray[1]);
		charLayer.add(char);

		updateAnimList();
		reloadCharacterOptions();
		updatePointerPos();

		if (ghostMirrorsCharacter) {
			updateGhostCharList();

			if (ghostChar != null) {
				charLayer.remove(ghostChar);
				ghostChar.destroy();
				ghostChar = null;
			}

			reloadGhost("Current Character");
			char.alpha = 0.85;
			cameraFollowPointer.alpha = 0.85;

			updateGhostPointerPos();
			ghostCharDropDown.selectedLabel = "Current Character";
		}
	}

	function updatePointerPos() {
		var cam = char.getCamera();
		var x:Float = cam[0];
		var y:Float = cam[1];

		if (animationXCam != null)
			x += animationXCam.value;
		if (animationYCam != null)
			y += animationYCam.value;

		x -= cameraFollowPointer.width * 0.5;
		y -= cameraFollowPointer.height * 0.5;
		cameraFollowPointer.setPosition(x, y);
	}

	function findAnimationByName(name:String):AnimArray {
		for (anim in char.animationsArray) {
			if (anim.anim == name) {
				return anim;
			}
		}
		return null;
	}

	function reloadCharacterOptions() {
		if (UI_characterbox != null) {
			imageInputText.text = char.imageFile;
			healthIconInputText.text = char.healthIcon;
			singDurationStepper.value = char.singDuration;
			scaleStepper.value = char.baseScale;
			flipXCheckBox.checked = char.originalFlipX;
			noAntialiasingCheckBox.checked = char.noAntialiasing;
			resetHealthBarColor();
			leHealthIcon.changeIcon(healthIconInputText.text);
			positionXStepper.value = char.positionArray[0];
			positionYStepper.value = char.positionArray[1];
			positionCameraXStepper.value = char.cameraPosition[0];
			positionCameraYStepper.value = char.cameraPosition[1];
			reloadAnimationDropDown();
			updateDiscordPresence();
		}
	}

	function reloadAnimationDropDown() {
		var anims:Array<String> = [];

		char.animationsArray.sort(animSortFunc);
		for (anim in char.animationsArray)
			anims.push(anim.anim);

		if (anims.length < 1)
			anims.push('NO ANIMATIONS'); // Prevents crash

		animationDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(anims, true));
	}

	function reloadCharacterDropDown() {
		characterList = CharacterData.getAllCharacters();
		characterList.sort(CoolUtil.alphabeticalSort);

		charDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(characterList, true));
		charDropDown.selectedLabel = charName;
	}

	function resetHealthBarColor() {
		setHealthBarColor(FlxColor.fromRGB(
			char.healthColorArray[0],
			char.healthColorArray[1],
			char.healthColorArray[2]
		));
	}

	function setHealthBarColor(color:FlxColor) {
		healthColorPicker.color = color;
		char.healthColorArray[0] = color.red;
		char.healthColorArray[1] = color.green;
		char.healthColorArray[2] = color.blue;
		updateHealthBarColor();
	}

	function updateHealthBarColor() {
		healthBarBG.color = FlxColor.fromRGB(
			char.healthColorArray[0], 
			char.healthColorArray[1], 
			char.healthColorArray[2]
		);
	}

	function changeCurOffset(x:Int, y:Int, isAbs:Bool = false) {
		var curAnimData = char.animationsArray[curAnim];

		if (isAbs) {
			curAnimData.offsets[0] = x;
			curAnimData.offsets[1] = y;
		} else {
			curAnimData.offsets[0] += x;
			curAnimData.offsets[1] += y;
		}

		char.addOffset(curAnimData.anim, curAnimData.offsets[0], curAnimData.offsets[1]);
		char.playAnim(curAnimData.anim, true);

		if (ghostMirrorsCharacter) {
			ghostChar.addOffset(curAnimData.anim, curAnimData.offsets[0], curAnimData.offsets[1]);
			if (ghostChar.animation.curAnim.name == char.animation.curAnim.name) {
				ghostChar.playAnim(curAnimData.anim, true);
			}
		}

		updateAnimList();
	}

	function updateDiscordPresence() {
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence({details: "Character Editor", state: 'Character: $charName', smallImageKey: leHealthIcon.getCharacter()});
		#end
	}

	override function draw() {
		var unscaleFactor = (1 / FlxG.camera.zoom);
		originMarker.scale.set(unscaleFactor, unscaleFactor);
		originMarker.centerOrigin();

		super.draw();
	}

	function close() {
		if (goToPlayState) {
			MusicBeatState.switchState(new PlayState());
		} else {
			MusicBeatState.switchState(new MasterEditorMenu());
			MusicBeatState.playMenuMusic(true);
		}
		FlxG.mouse.visible = false;
	}

	override function update(elapsed:Float) {
		var inputTexts:Array<FlxUIInputText> = [
			animationInputText,
			imageInputText,
			healthIconInputText,
			animationNameInputText,
			animationIndicesInputText
		];
		for (i in 0...inputTexts.length) {
			if (inputTexts[i].hasFocus) {
				FNFGame.specialKeysEnabled = false;
				super.update(elapsed);
				return;
			}
		}
		FNFGame.specialKeysEnabled = true;

		if (testMode) {
			var alt = FlxG.keys.pressed.SHIFT ? "-alt" : '';
			// who cares anymore
			if (FlxG.keys.justPressed.SPACE) {
				char.playAnim("idle", true);
			}
			if (FlxG.keys.justPressed.D) {
				char.playAnim("singLEFT" + alt, true);
			}
			if (FlxG.keys.justPressed.F) {
				char.playAnim("singDOWN" + alt, true);
			}
			if (FlxG.keys.justPressed.J) {
				char.playAnim("singUP" + alt, true);
			}
			if (FlxG.keys.justPressed.K) {
				char.playAnim("singRIGHT" + alt, true);
			}
			if (FlxG.keys.justPressed.E) {
				char.playAnim("singLEFTmiss", true);
			}
			if (FlxG.keys.justPressed.R) {
				char.playAnim("singDOWNmiss", true);
			}
			if (FlxG.keys.justPressed.U) {
				char.playAnim("singUPmiss", true);
			}
			if (FlxG.keys.justPressed.I) {
				char.playAnim("singRIGHTmiss", true);
			}
		} else if (!charDropDown.dropPanel.visible) {
			if (FlxG.keys.justPressed.ESCAPE) {
				close();
				return;
			}

			if (FlxG.keys.justPressed.R) {
				resetCam();
			}

			if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3) {
				FlxG.camera.zoom += elapsed * FlxG.camera.zoom;
				if (FlxG.camera.zoom > 3)
					FlxG.camera.zoom = 3;
			}
			if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1) {
				FlxG.camera.zoom -= elapsed * FlxG.camera.zoom;
				if (FlxG.camera.zoom < 0.1)
					FlxG.camera.zoom = 0.1;
			}

			if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L) {
				var addToCam:Float = 500 * elapsed;
				if (FlxG.keys.pressed.SHIFT)
					addToCam *= 4;

				if (FlxG.keys.pressed.I)
					camFollow.y -= addToCam;
				else if (FlxG.keys.pressed.K)
					camFollow.y += addToCam;

				if (FlxG.keys.pressed.J)
					camFollow.x -= addToCam;
				else if (FlxG.keys.pressed.L)
					camFollow.x += addToCam;
			}

			if (char.animationsArray.length > 0) {
				var replayAnim = FlxG.keys.justPressed.SPACE;

				if (FlxG.keys.justPressed.W) {
					curAnim -= 1;
					replayAnim = true;
				}

				if (FlxG.keys.justPressed.S) {
					curAnim += 1;
					replayAnim = true;
				}

				if (curAnim < 0)
					curAnim = char.animationsArray.length - 1;

				if (curAnim >= char.animationsArray.length)
					curAnim = 0;

				if (replayAnim) {
					char.playAnim(char.animationsArray[curAnim].anim, true);
					updateAnimList();
				}

				var multiplier:Int = FlxG.keys.pressed.SHIFT ? 10 : 1;

				if (FlxG.keys.justPressed.LEFT)
					changeCurOffset(multiplier, 0);

				if (FlxG.keys.justPressed.RIGHT)
					changeCurOffset(-multiplier, 0);

				if (FlxG.keys.justPressed.DOWN)
					changeCurOffset(0, -multiplier);

				if (FlxG.keys.justPressed.UP)
					changeCurOffset(0, multiplier);

				if (FlxG.keys.justPressed.T)
					changeCurOffset(0, 0, true);
			}
		}

		super.update(elapsed);
	}

	function onSaveComplete(_):Void {
		FlxG.log.notice("Successfully saved file.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel():Void {
		FlxG.log.notice("Save file dialog cancelled.");
	}

	function saveCharacter() {
		var json = {
			"animations": char.animationsArray,
			"image": char.imageFile,
			"scale": char.baseScale,
			"sing_duration": char.singDuration,
			"healthicon": char.healthIcon,

			"position": char.positionArray,
			"camera_position": char.cameraPosition,

			"flip_x": char.originalFlipX,
			"no_antialiasing": char.noAntialiasing,
			"healthbar_colors": char.healthColorArray
		};

		var data:String = Json.stringify(json, "\t");

		if (data.length > 0) {
			CoolUtil.showSaveDialog(data, "Save Character", '$charName.json', ["JSON file", "*.json"], onSaveComplete, onSaveCancel);
		}
	}
}
