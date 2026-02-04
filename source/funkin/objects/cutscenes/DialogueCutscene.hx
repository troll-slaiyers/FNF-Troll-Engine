package funkin.objects.cutscenes;
import flixel.addons.text.FlxTypeText;
import flixel.util.FlxColor;
import funkin.input.Controls;
import flixel.text.FlxText.FlxTextBorderStyle;
/*
todo: add in portraits 
unhardcode the dialogue
*/
class DialogueCutscene extends Cutscene{
    //THIS WILL BE CHANGED OBV
    var text:Array<String> = 
    [   
    'blah blah',
    'bleh bleh bleh',
    'blu blu blu'
    ];
    var dialogueText:FlxTypeText;
    public var curDialogue:Int = 0;
    var box:DialogueBox;
    public override function createCutscene() {
        trace('created dialogue');

        box = new DialogueBox('pixel');
        add(box);

        dialogueText = new FlxTypeText(170, 420, Std.int(FlxG.width * 0.9), '', 32);
        dialogueText.setFormat(Paths.font('pixel.otf'), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        dialogueText.antialiasing = false;
        dialogueText.borderSize = 1.4;
        dialogueText.start(0.09);
        add(dialogueText);
        
        this.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]]; // this works right? :sob:
    } 

        
    override function update(elapsed:Float)
    {
       	if (FlxG.keys.justPressed.SPACE)
        {
            curDialogue++;
            createNewLine();
        }
        
        if (FlxG.keys.justPressed.BACKSPACE)
        {
            curDialogue--;
            createNewLine();
        }
        
        super.update(elapsed);
    }
    /**
     * Creates a new line of dialogue.
     */
    public function createNewLine()
    {
        if(curDialogue == text.length)
        {
            endDialogue();
            return;
        } 
        box.animation.play('pressed');
        dialogueText.resetText(text[curDialogue]);
        dialogueText.start(0.09);

    }
    /**
     * Function thats called when Dialogue is ending.
     */
    function endDialogue()
    {
        onEnd.dispatch(false);
        //destroy();
    }
    override public function restart(){
        curDialogue = 0;
		createNewLine();
	}
}
