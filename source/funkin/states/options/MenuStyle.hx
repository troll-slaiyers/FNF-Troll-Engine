package funkin.states.options;

import flixel.util.FlxColor;
import funkin.data.FlxTextFormatData;

class MenuStyle {
	public static final WINDOW_COLOR1 = 0xFF353B3E;
	public static final WINDOW_COLOR2 = 0xFF2F3538;

	/** Normal tab color **/
	public static final TAB_COLOR1 = 0xFF353B3E;
	/** Selected tab color **/
	public static final TAB_COLOR2 = 0xFF353B3E + FlxColor.fromRGB(60, 60, 60);

	/** Normal name color **/
	public static final OPT_NAME_COLOR1 = 0xFFFFFFFF;
	/** Selected name color **/
	public static final OPT_NAME_COLOR2 = 0xFFFFFF00;

	public static final TAB_NAME:FlxTextFormatData = {
		font: "vcr.ttf",
		pixelPerfectRender: true,	
		size: 18,
		color: 0xFFFFFFFF,
		alignment: CENTER,
	
		borderStyle: OUTLINE,
		borderColor: 0xFF000000
	};
	
	public static final OPT_CAT_LABEL:FlxTextFormatData = {
		font: "vcr.ttf",
		size: 28,
		color: 0xFFFFFFFF,
		alignment: LEFT
	};
	
	public static final OPT_NAME:FlxTextFormatData = {
		font: "quantico.ttf",	
		size: 22,
		color: OPT_NAME_COLOR1,
		alignment: LEFT
	};

	public static final OPT_VALUE_TEXT:FlxTextFormatData = {
		font: "quantico.ttf",
		size: 18,
		color: 0xFFFFFFFF,
		alignment: LEFT
	};
	
	public static final OPT_DROPDOWN_OPTION_TEXT:FlxTextFormatData = {
		font: "quantico.ttf",
		size: 18,
		color: 0xFFFFFFFF,
	};

	public static final OPT_DESC:FlxTextFormatData = {
		font: "vcr.ttf",
		pixelPerfectRender: true,	
		size: 16,
		color: 0xFFFFFFFF,
		alignment: CENTER,
	
		borderStyle: OUTLINE,
		borderColor: 0xFF000000
	};
}