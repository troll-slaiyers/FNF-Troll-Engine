package funkin.objects.cutscenes;
import flixel.addons.text.FlxTypeText;
import flixel.util.FlxColor;
import funkin.input.Controls;
import flixel.text.FlxText.FlxTextBorderStyle;
import sys.FileSystem;
import haxe.Json;
import sys.io.File;
/*
todo: add in portraits 
add in null checking
sorry if the code is a mess rn, alot is going on rn
*/
typedef DialogueFile = {
	var dialogue:Array<DialogueLine>;
    var dialogueBox:String; //what box the file should use.
}
typedef DialogueLine = {
    var text:String;
	var character:String;
	var characterAnim:String;
	var textSpeed:Float;
	@:optional var soundByte:String; //what soundbyte should be played
}

class DialogueCutscene extends Cutscene{
    var dialogueText:FlxTypeText;
    public var curDialogueCount:Int = 0;
    var box:DialogueBox;
    var dialogueFile:DialogueFile;
    //none of the nulls work rn so fuck it
    public function new(dialoguePath:String){
		super();
        try
        {
		    dialogueFile = Paths.json('$dialoguePath');
        }
        catch(e)
        {
            trace('no dialogue!!!');
            endDialogue();
        }
	}
    public override function createCutscene() {
        trace('created dialogue');
        if(dialogueFile == null) 
        {
            trace('no dialogue!!!');
            endDialogue();
        }
        box = new DialogueBox('pixel');
        add(box);

        dialogueText = new FlxTypeText(170, 420, Std.int(FlxG.width * 0.7), '', 32);
        dialogueText.setFormat(Paths.font('pixel.otf'), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        dialogueText.antialiasing = false;
        dialogueText.borderSize = 1.4;
        dialogueText.start(0.09);
        add(dialogueText);
        createNewLine();
        this.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]]; // this works right? :sob:
    } 

        
    override function update(elapsed:Float)
    {
       	if (FlxG.keys.justPressed.SPACE)
        {
            curDialogueCount++;
            createNewLine();
        }
        
        if (FlxG.keys.justPressed.BACKSPACE)
        {
            curDialogueCount--;
            createNewLine();
        }
        
        super.update(elapsed);
    }
    /**
     * Creates a new line of dialogue.
     */
    public function createNewLine()
    {
        var curDialogueLine:DialogueLine = null;
		curDialogueLine = dialogueFile.dialogue[curDialogueCount];
        if(curDialogueCount == dialogueFile.dialogue.length)
        {
            endDialogue();
            return;
        }

        box.animation.play('pressed');
        dialogueText.resetText(curDialogueLine.text);
        dialogueText.start(curDialogueLine.textSpeed);

    }
    /**
     * Function thats called when Dialogue is ending.
     */
    function endDialogue()
    {
        onEnd.dispatch(false);
        //destroy();
    }
    
	inline public static function parseDialogue(path:String):DialogueFile {
		#if sys
		return Json.parse(File.getContent(path));
		#else
		return Json.parse(Assets.getText(path));
		#end
	}
    override public function restart(){
        curDialogueCount = 0;
		createNewLine();
	}

}
