package funkin.states.options;

import flixel.util.FlxColor;
import funkin.data.FlxTextFormatData;

class MenuStyle {
	public static final WINDOW_COLOR1 = FlxColor.fromRGB(58, 58, 58);
	public static final WINDOW_COLOR2 = FlxColor.fromRGB(52, 52, 52);

	/** Normal tab color **/
	public static final TAB_COLOR1 = FlxColor.fromRGB(58, 58, 58);
	/** Selected tab color **/
	public static final TAB_COLOR2 = FlxColor.fromRGB(58, 58, 58) + FlxColor.fromRGB(60, 60, 60);

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