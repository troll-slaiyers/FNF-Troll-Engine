package funkin.objects;
import flixel.text.FlxText;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import flixel.FlxSprite;

class ChartingTipText extends FlxGroup
{
    final text =
		"W/S or Mouse Wheel - Change strum time
		\nA/D - Go to the previous/next section
		\nUp/Down - Change strum Time with snapping
		\nLeft/Right - Change Snap
		\nHold Shift to move 4x faster
		\nHold Control and click on an arrow to select it
		\nZ/X - Zoom in/out
		\n
		\nEnter - Play your chart
		\nQ/E - Decrease/Increase Note Sustain Length
		\nSpace - Stop/Resume song
        \nM - Change Camera Section focus
        \nR - Go to start of section
        \nTAB - Change UI Section
        \n
        \nCTRL + O - Open Song Select
        \nCTRL + Z/Y - Undo/Redo last placed notes
        \nCTRL + S - Save Chart
        \n
        \nHave fun Charting!
	";
    public function new(x:Int, y:Int)
    {
        super();
        var bg:FlxSprite = new FlxSprite(x, y).makeGraphic(1, 1);
		bg.scale.set(440, FlxG.height);
		bg.updateHitbox();
		bg.color = 0xFF000000;
        bg.alpha = 0.7;
		bg.scrollFactor.set();
		add(bg);

		var tipTextArray:Array<String> = text.split('\n');
		for (i in 0...tipTextArray.length) {
			var tipText:FlxText = new FlxText(0, y + (i * 13) + 45, bg.width, tipTextArray[i], 16);
			tipText.setFormat(null, 14, FlxColor.WHITE, CENTER);
			tipText.antialiasing = false;
			tipText.borderSize = 1.25;
			tipText.scrollFactor.set();
			add(tipText);
		}

    }
}
