package funkin.states.editors;

import funkin.states.base.TransitionableState;

#if DISCORD_ALLOWED
import funkin.api.Discord.DiscordClient;
#end

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using StringTools;

class MasterEditorMenu extends MusicBeatState
{
	var options:Array<String> = [
		'Song Select',
		'Character Editor',
		'Chart Editor',
		'Test Stage',
		'VSlice Converter',
		/*
		'Stage Editor',
		'Stage Builder',
		*/
		/*
		'Week Editor',
		'Menu Character Editor',
		*/
		#if USING_MOONCHART
		'Chart Converter',
		#end
	];
	private var menu:AlphabetMenu;
	private var packs:Array<String> = [null];

	private var selectedPackIndex = 0;
	private var packTxt:FlxText;

	override function create()
	{
		this.persistentUpdate = true;
		super.create();
		FlxG.mouse.visible = false;
		TransitionableState.skipNextTransOut = true;
		FlxG.camera.bgColor = FlxColor.BLACK;

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence({details: "Editors Menu"});
		#end

		var bg:FlxSprite = new FlxSprite(0, 0, Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF353535;
		add(bg);

		menu = new AlphabetMenu();
		menu.controls = controls;
		menu.callbacks.onAccept = function(i, _){
			switch(options[i]) {
				case 'Song Select': MusicBeatState.switchState(new SongSelectState()); return;
				case 'Character Editor': MusicBeatState.switchState(new CharacterEditorState(Character.DEFAULT_CHARACTER, false));
				case 'Chart Editor': LoadingState.loadAndSwitchState(new ChartingState(), false);
				case 'VSlice Converter': MusicBeatState.switchState(new funkin.states.editors.VSliceConverter());
				/*
				case 'Stage Editor': MusicBeatState.switchState(new StageEditorState());
				case 'Stage Builder': MusicBeatState.switchState(new StageBuilderState());
				*/
				case "Test Stage": MusicBeatState.switchState(new TestState());
				#if USING_MOONCHART
				case 'Chart Converter': MusicBeatState.switchState(new ChartConverterState());
				#end
				default: return;
			}
			
			MusicBeatState.stopMenuMusic();
			menu.controls = null;
		}
		for (name in options) menu.addTextOption(name);
		menu.curSelected = 0;
		add(menu);
		
		
		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 42).makeGraphic(FlxG.width, 42, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		packTxt = new FlxText(textBG.x, textBG.y + 4, FlxG.width, '', 32);
		packTxt.setFormat(Paths.font("calibri.ttf"), 32, FlxColor.WHITE, CENTER);
		packTxt.scrollFactor.set();
		add(packTxt);
		
		for (folder in Paths.packList)
		{
			packs.push(folder);
		}

		var found:Int = packs.indexOf(Paths.currentPackId);
		if(found > -1) selectedPackIndex = found;
		changeDirectory();
	}

	override function update(elapsed:Float)
	{
		if(controls.UI_LEFT_P)
			changeDirectory(-1);
		if(controls.UI_RIGHT_P)
			changeDirectory(1);

		if (controls.BACK) {
			menu.controls = null;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}
		
		super.update(elapsed);
	}

	function changeDirectory(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4 );

		selectedPackIndex += change;

		if(selectedPackIndex < 0)
			selectedPackIndex = packs.length - 1;
		if(selectedPackIndex >= packs.length)
			selectedPackIndex = 0;
	
		if (packs[selectedPackIndex] == null || packs[selectedPackIndex].length < 1) {
			Paths.currentPackId = '';
			packTxt.text = '< Main Active Pack: <None> >';
		}
		else
		{
			Paths.currentPackId = packs[selectedPackIndex];
			packTxt.text = '< Main Active Pack: ' + Paths.currentPackId + ' >';
		}
		packTxt.text = packTxt.text.toUpperCase();
	}
}