package funkin.objects.cutscenes;
import flixel.addons.text.FlxTypeText;
import flixel.util.FlxColor;
import funkin.input.Controls;
import flixel.text.FlxText.FlxTextBorderStyle;
import haxe.Json;
import flixel.util.FlxTimer;

typedef DialogueFile = {
	var dialogue:Array<DialogueLine>;
    var box_style:String; //what box the file should use.
}
typedef DialogueLine = {
    var text:String;
	var character:String;
	var character_anim:String;
	var text_speed:Float;
    var text_size:Int;//custom font size
	var sound_byte:String; 
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
    var characters:Array<DialogueCharacter> = [];
    public var keepAllCharactersOnScreen:Bool = false;
    
    public function new(dialoguePath:String)
    {
		super();
        onEnd.addOnce(endDialogue);
		dialogueFile = Paths.json('$dialoguePath');
	}

    public override function createCutscene() 
    {
        loadCharacters();

        box = new DialogueBox(dialogueFile.box_style);
        box.visible = false;
        add(box);

		box.script?.call("onCreatePost");
        
        dialogueText = new FlxTypeText(box.textOffsets[0], box.textOffsets[1], box.textWidth, '', 32);
        dialogueText.setFormat(Paths.font(box.font), 32, FlxColor.fromString(box.textColor), LEFT, SHADOW, FlxColor.fromString(box.shadowTextColor), false);
        dialogueText.antialiasing = box.antialiasing;
        dialogueText.borderSize = box.shadowWidth;
        add(dialogueText);

        dialogueText.completeCallback = function()
        {
            box.finishLine();
        }
        new FlxTimer().start(introDelay, function(tmr:FlxTimer)
		{
            canProgressDialogue = true;
            box.visible = true;
            createNewLine();
		});

        this.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
    } 
    function loadCharacters()
    {
        //alot of this function is kind of ripped from psych
        var charsMap:Map<String, Bool> = new Map<String>();
        //Does a loop through the entire dialogue file and checks for characters
		for (i in 0...dialogueFile.dialogue.length) {
			if(dialogueFile.dialogue[i] != null && dialogueFile.dialogue[i].character != null) {
				var newChar:String = dialogueFile.dialogue[i].character;
                if(!charsMap.exists(newChar) || !charsMap.get(newChar)) 
					charsMap.set(newChar);//adds to the map only if the new character doesnt already exist
			}
		}

        for (curCharacter in charsMap.keys()) {
		    var char:DialogueCharacter = new DialogueCharacter(curCharacter); //new character thats invisible and barely drawn.
			char.updateHitbox();
			char.scrollFactor.set();
			char.alpha = 0.00001;
			add(char);
			characters.push(char);
		}

    }
    override function update(elapsed:Float)
    {
       	if (FlxG.keys.justPressed.SPACE && canProgressDialogue)
        {
            curLine++;
            createNewLine();
        }
        //maybe have a proper log book for dialogue.
        
        super.update(elapsed);
    }
    /**
     * Creates a new line of dialogue.
     */
    public function createNewLine()
    {
        FlxG.sound.play(Paths.sound(box.dialoguePressedSound), 0.7);
        box.newLine();
        if(curLine >= dialogueFile.dialogue.length)
        {
            onEnd.dispatch(false);
            return;
        }
        var curDialogueLine:DialogueLine = null;
		curDialogueLine = dialogueFile.dialogue[curLine];
        var curCharcter:Int = 0;
        for (i in 0...characters.length) {
			if(characters[i].curChar == curDialogueLine.character) {
				curCharcter = i;
				break;
			}
		}
        if(!keepAllCharactersOnScreen)
        for (i in 0...characters.length) {
            characters[i].alpha = 0;
		    if(characters[i] ==  characters[curCharcter]) {
				characters[curCharcter].alpha = 1;
			}
		}
        characters[curCharcter].animation.play(curDialogueLine.character_anim);
        getTextSound();
        dialogueText.size = getTextSize(curDialogueLine.text_size);
               
        dialogueText.resetText(curDialogueLine.text);
        dialogueText.start(curDialogueLine.text_speed);
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
