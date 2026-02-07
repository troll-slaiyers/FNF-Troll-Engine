package funkin.objects.cutscenes;
import flixel.addons.text.FlxTypeText;
import flixel.util.FlxColor;
import funkin.input.Controls;
import flixel.text.FlxText.FlxTextBorderStyle;
import sys.FileSystem;
import haxe.Json;
import sys.io.File;
import flixel.util.FlxTimer;
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
    var text_size:Int;//custom font size
	var soundByte:String; //what soundbyte should be played //should have this based on character i think
}

class DialogueCutscene extends Cutscene{
    var dialogueText:FlxTypeText;
    public var curLine:Int = 0;
    var box:DialogueBox;
    var dialogueFile:DialogueFile;
    /**
     * How long it should take until the dialogue first starts
     * Set to 0 for instant start time.
     */
    public var introDelay:Float = 2;
    /**
     * Whether the player is able to progress the dialogue.
     * Starts of at 0.
     */
    public var canProgressDialogue:Bool = false;
    public function new(dialoguePath:String){
		super();
        onEnd.addOnce(endDialogue);
		dialogueFile = Paths.json('$dialoguePath');

	}
    public override function createCutscene() {
        trace('created dialogue');

        box = new DialogueBox(dialogueFile.boxStyle);
        box.visible = false;
        add(box);

        dialogueText = new FlxTypeText(170, 450, Std.int(FlxG.width * 0.75), '', 12);
        dialogueText.setFormat(Paths.font(box.font), 12, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        dialogueText.antialiasing = box.antialiasing;
        dialogueText.borderSize = 1.4;
        add(dialogueText);
       
        new FlxTimer().start(introDelay, function(tmr:FlxTimer)
		{
            canProgressDialogue = true;
            box.visible = true;
            createNewLine();
		});

        this.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
    } 

    override function update(elapsed:Float)
    {
       	if (FlxG.keys.justPressed.SPACE && canProgressDialogue)
        {
            curLine++;
            createNewLine();
        }
        /*
        maybe have a proper log book for dialogue.
        if (FlxG.keys.justPressed.BACKSPACE)
        {
            curLine--;
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
        if(curLine >= dialogueFile.dialogue.length)
        {
            onEnd.dispatch(false);
            return;
        }
        var curDialogueLine:DialogueLine = null;
		curDialogueLine = dialogueFile.dialogue[curLine];
        getTextSound();
        dialogueText.size = getTextSize(curDialogueLine.text_size);
        FlxG.sound.play(Paths.sound(box.dialoguePressedSound), 0.7);
      
       
        box.animation.play('pressed');
        dialogueText.resetText(curDialogueLine.text);
        dialogueText.start(curDialogueLine.textSpeed);

    }
    /**
     * Function that's only called when the current dialogue is ending.
     * @param wasSkipped 
     */
    function endDialogue(wasSkipped:Bool)
    {
        box.onDialogueEnded();
        new FlxTimer().start(1, function(tmr:FlxTimer)
		{
            destroy();
		});
    }
    /**
     * Returns Text Size for the current line.
     * This is done so we can use custom text sizes for each line.
     * @param _lineTextSize 
     * @return Int
     */
    inline function getTextSize(_lineTextSize:Int):Int 
        return _lineTextSize > 0 ? _lineTextSize : box.textSize;
    

    override public function restart(){
        curLine = 0;
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
