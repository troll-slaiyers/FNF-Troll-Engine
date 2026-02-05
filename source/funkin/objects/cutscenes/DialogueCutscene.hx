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
    var boxStyle:String; //what box the file should use.
}
typedef DialogueLine = {
    var text:String;
	var character:String;
	var characterAnim:String;
	var textSpeed:Float;
	var soundByte:String; //what soundbyte should be played
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
        box = new DialogueBox(dialogueFile.boxStyle);
        add(box);

        dialogueText = new FlxTypeText(170, 420, Std.int(FlxG.width * 0.7), '', 32);
        dialogueText.setFormat(Paths.font(box.font), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        dialogueText.antialiasing = box.antialiasing;
        dialogueText.borderSize = 1.4;
        add(dialogueText);
        

        createNewLine();

        this.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
    } 

    override function update(elapsed:Float)
    {
       	if (FlxG.keys.justPressed.SPACE)
        {
            curDialogueCount++;
            createNewLine();
        }
        /*
        maybe have a proper log book for dialogue.
        if (FlxG.keys.justPressed.BACKSPACE)
        {
            curDialogueCount--;
            createNewLine();
        }
        */
        super.update(elapsed);
    }
    /**
     * Creates a new line of dialogue.
     */
    public function createNewLine()
    {
        getTextSound();
        FlxG.sound.play(Paths.sound(box.dialoguePressedSound), 0.7);
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

    override public function restart(){
        curDialogueCount = 0;
		createNewLine();
	}
    /**
     * Function thats called whenever
     */
    public function getTextSound()
    {
        var dialogueTalkSound:String = box.dialogueTalkSound;
        if(box.dialogueTalkSound != null)
        dialogueText.sounds = [FlxG.sound.load(Paths.sound(dialogueTalkSound), 0.6)];
    }

}
