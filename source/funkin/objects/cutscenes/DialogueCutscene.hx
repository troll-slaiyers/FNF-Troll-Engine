package funkin.objects.cutscenes;

import flixel.addons.text.FlxTypeText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

typedef DialogueFile = {
	var dialogue:Array<DialogueLine>;
	var box_style:String;
}
typedef DialogueLine = {
	var text:String;
	var character:String;
	var character_anim:String;
	var text_speed:Float;
	var text_size:Int; // custom font size
	var line_sound:Array<String>; 
	var box_animation:String;
}

class DialogueCutscene extends Cutscene
{
	/**
	 * How long it should take until the dialogue first starts
	 * Set to 0 for instant start time.
	*/
	public var introDelay:Float = 2;
	
	/** Whether the player is able to progress the dialogue. **/
	public var canProgressDialogue:Bool = false;
	
	/** Variable that allows you to keep all characters on screen if you want too. **/
	public var keepAllCharactersOnScreen:Bool = false;

	/** Array that will be filled with all the dialogue characters. **/
	var characters:Array<DialogueCharacter> = [];

	public var curLine:Int = 0;
	
	var dialogueFile:DialogueFile;
	var dialogueText:FlxTypeText;
	var box:DialogueBox;
	var curCharacter:DialogueCharacter;

	var finishedLine:Bool = false;
	
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
		dialogueText.completeCallback = finishLine;

		new FlxTimer().start(introDelay, function(tmr:FlxTimer) {
			canProgressDialogue = true;
			box.visible = true;
			createNewLine();
		});

		this.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	public function finishLine()
	{
		finishedLine = true;
		box.script?.call("onFinishLineDialogue");
	}

	function loadCharacters()		
	{
		var characterMap:Map<String, Bool> = new Map<String, Bool>();
		//Does a loop through the entire dialogue file and checks for characters
		for (i in 0...dialogueFile.dialogue.length) {
			if(dialogueFile.dialogue[i] != null && dialogueFile.dialogue[i].character != null) {
				var newCharacter:String = dialogueFile.dialogue[i].character;
				if(!characterMap.exists(newCharacter) || !characterMap.get(newCharacter)) 
					characterMap.set(newCharacter, true);//adds to the map only if the character doesnt already exist
			}
		}

		for (curCharacter in characterMap.keys()) {
			var char:DialogueCharacter = new DialogueCharacter(curCharacter);
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
			if(finishedLine)
			{
				curLine++;
				createNewLine();
			}
			else
			{
				skipCurLine();
			}

		}
		//todo: maybe have a proper log book for dialogue.
		
		super.update(elapsed);
	}

	/**
	 * Function thats called when a line of dialogue is skipped mid sentence.
	 */
	private function skipCurLine()
	{
		box?.script?.call("onSkipLine");
		dialogueText.skip();
	}

	/**
	 * Creates a new line of dialogue.
	 */
	public function createNewLine()
	{
		FlxG.sound.play(Paths.sound(box.dialoguePressedSound), 0.7);
		box?.script?.call("onNewLine");
		
		if(curLine >= dialogueFile.dialogue.length)
		{
			onEnd.dispatch(false);
			return;
		}
		finishedLine = false;
		var curDialogueLine:DialogueLine;
		curDialogueLine = dialogueFile.dialogue[curLine];

		playBoxAnimation(curDialogueLine.box_animation);

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
		curCharacter = characters[curCharcter];
		curCharacter.animation.play(curDialogueLine.character_anim);
		getTextSound();
		dialogueText.size = getTextSize(curDialogueLine.text_size);
			   
		dialogueText.resetText(curDialogueLine.text);
		dialogueText.start(curDialogueLine.text_speed);
	}

	/**
	 * Function that's only called when dialogue is ending.
	 * @param wasSkipped 
	 */
	function endDialogue(wasSkipped:Bool)
	{
		box?.script?.call("onDialogueEnded");

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
	 * Function thats called to retrieve text sound.
	 * Leaving all fields empty, will not play a sound.
	 */
	private function getTextSound()
	{
		var dialogueTalkSound:Array<String> = null;
		if(dialogueFile.dialogue[curLine].line_sound != null)
			dialogueTalkSound = dialogueFile.dialogue[curLine].line_sound;
		else if(curCharacter.talkSound != null)
			dialogueTalkSound = curCharacter.talkSound;
		else if(box.dialogueTalkSound != null)
			dialogueTalkSound = box.dialogueTalkSound;

		if(dialogueTalkSound != null)
		dialogueText.sounds = [for (dialogueSound in dialogueTalkSound) FlxG.sound.load(Paths.sound(dialogueSound), 0.6)];
	}

	/**
	 * Play dialogue box animation
	 * @param _anim 
	 */
	function playBoxAnimation(_anim:String)
	{
		if(_anim == null) return;
		box?.animation.play(_anim);
	}
}
