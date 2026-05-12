package funkin.states.options;

import funkin.objects.notes.StrumNote;
import funkin.objects.notes.Note;
import flixel.group.FlxSpriteGroup;
import funkin.objects.huds.BaseHUD;
import funkin.objects.hud.RatingGroup;

import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.math.FlxPoint;

private enum abstract RatingElement(Int) from Int to Int {
	var NONE = -1;
	var JUDGE = 0;
	var COMBO = 1;
	var TIMER = 2;
}

class ComboPositionSubstate extends MusicBeatSubstate
{
	////
	private final fuckingBgColor:FlxColor;
	private final canClose:Bool = true;

	//// Preview	
	var judge:RatingSprite;
	var combo:Array<RatingSprite>;
	var timing:FlxText;

	//// Offset Texts
	var txt_rating:FlxText;
	var txt_combo:FlxText;
	var txt_timing:FlxText;

	///
	var mouseGrabbed:RatingElement = NONE; 
	var keyboardGrabbed:RatingElement = NONE;

	var prevMousePos:FlxPoint = FlxPoint.get();
	var curMousePos:FlxPoint = FlxPoint.get();

	public function new(?bgColor:FlxColor, ?canClose:Bool = true){
		super();

		this.fuckingBgColor = bgColor==null ? 0x00000000 : bgColor;
		this.canClose = canClose != false;
	}

	override public function create()
	{
		camera = new FlxCamera();
		camera.bgColor = fuckingBgColor;
		FlxG.cameras.add(camera, false);
		this.cameras = [camera];

		FlxG.mouse.getScreenPosition(camera, prevMousePos);

		////
		var judgeName:Null<String> = null;
		var judgeColor:Null<FlxColor> = null;

		var hud = PlayState.instance?.hud;
		if (hud != null)
		{
			var highestJudgement = hud.displayedJudges[0];
			
			if (highestJudgement != null){
				judgeName = highestJudgement;
				judgeColor = hud.judgeColours.get(judgeName);
			}
		}   

		if (judgeName == null)
			judgeName = ClientPrefs.useEpics ? "epic" : "sick";

		if (judgeColor == null){
			if (BaseHUD._judgeColours.exists(judgeName))
				judgeColor = BaseHUD._judgeColours.get(judgeName);
			else
				judgeColor = 0xFFFFFFFF;
		}

		var comboColor:FlxColor = ClientPrefs.coloredCombos ? judgeColor : 0xFFFFFFFF;
		
		////////
		var rat = new RatingGroup();
		rat.exists = false;
		add(rat);
		
		////
		judge = rat.displayJudgment(judgeName);
		judge.cameras = cameras;
		add(judge);

		////
		for (num in combo = rat.displayCombo(10 + Std.random(980))){
			num.color = comboColor;
			num.cameras = cameras;
			add(num);
		};

		////
		if (PlayState.instance == null) {
			var totalPlayers:Int = ClientPrefs.centerNotefield ? 1 : 2;
			
			var swagOffset = Note.halfWidth + 45;
			var top = swagOffset;
			var bot = (FlxG.height - swagOffset);
			var y:Float;
			
			#if FUNNY_ALLOWED
			if (ClientPrefs.middleScroll)
				y = (top + bot) * 0.5;
			else #end
				y = (ClientPrefs.downScroll ? bot : top);

			for (player in 0...totalPlayers) {
				var keyCount = 4;
				for (column in 0...keyCount) {
					var x = Note.halfWidth + funkin.modchart.ModManager._getBaseX(totalPlayers, player, column, keyCount);
					var obj = new StrumNote(x, y, column, null);
					obj.postAddedToGroup();
					obj.updateHitbox();
					obj.x -= obj.width / 2;
					obj.y -= obj.height / 2;
					add(obj);
				}
			}
		}

		////
		timing = new FlxText(0, 0, 0, "0ms");
		timing.setFormat(Paths.font("vcr.ttf"), 28, 0xFFFFFFFF, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		timing.color = judgeColor;
		timing.scrollFactor.set();
		timing.borderSize = 1.25;
		timing.cameras = cameras;
		timing.updateHitbox();
		add(timing);

		////
		var textGroup = new FlxSpriteGroup();
		textGroup.cameras = cameras;

		final alignment:FlxTextAlign = {
			// If this substate is opened while on PlayState then the offsets are shown on the opposite side to not cover the real judge counters :P
			final beingShownOutside = (PlayState.instance != null) && (ClientPrefs.judgeCounter != "Off");
			(ClientPrefs.hudPosition == "Left") != (!beingShownOutside) ? RIGHT : LEFT;
		};

		function makeText(i, text:String = ' '){
			var text:FlxText = new FlxText(
				10, 
				(i * 30) + 24 * Math.floor(i / 2), 
				FlxG.width - 10 * 2, 
				text, 
				24
			);
			text.scrollFactor.set();
			text.setFormat(Paths.font("vcr.ttf"), 24, 0xFFFFFFFF, alignment);
			text.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2);
			text.cameras = cameras;
			
			textGroup.add(text);
			return text;
		}

		makeText(0, "Judgement Offset");
		txt_rating = makeText(1);
		makeText(2, "Combo Offset");
		txt_combo = makeText(3);
		makeText(4, "Timing Offset");
		txt_timing = makeText(5);

		textGroup.screenCenter(Y);
		add(textGroup);

		////
		updateJudgePos();
		updateComboPos();
		updateTimingPos();
		
		super.create();
	}

	////
	function updateJudgePos(){
		judge.x = FlxG.width * 0.5 + ClientPrefs.comboOffset[0];
		judge.y = FlxG.height * 0.5 - ClientPrefs.comboOffset[1];
		
		txt_rating.text = '[${ClientPrefs.comboOffset[0]}, ${ClientPrefs.comboOffset[1]}]';
	}

	function updateComboPos(){
		var x = FlxG.width * 0.5 + ClientPrefs.comboOffset[2] - combo[0].width;
		var y = FlxG.height * 0.5 - ClientPrefs.comboOffset[3];

		for (i in 0...combo.length){
			var spr:RatingSprite = combo[i];
			spr.x = x + i *	spr.width;
			spr.y = y;
		}

		txt_combo.text = '[${ClientPrefs.comboOffset[2]}, ${ClientPrefs.comboOffset[3]}]';
	}

	function updateTimingPos() {
		timing.screenCenter();
		timing.x += ClientPrefs.comboOffset[4];
		timing.y -= ClientPrefs.comboOffset[5];

		txt_timing.text = '[${ClientPrefs.comboOffset[4]}, ${ClientPrefs.comboOffset[5]}]';
	}

	////

	// fuck this nonsense
	function sowy(okay:Any){
		final mp = curMousePos;

		if (okay is Array) {
			for (i in (okay:Array<Dynamic>))
				if (sowy(i)) return true;

			return false;
		}
		else if (okay is RatingSprite) {
			var okay = (okay:RatingSprite);
			var hW = okay.width * 0.5;
			var hH = okay.height * 0.5;

			return (Math.abs(okay.x - mp.x) <= hW && Math.abs(okay.y - mp.y) <= hH);
		}
		else if (okay is FlxSprite) {
			return FlxG.mouse.overlaps(okay, camera);
		}
		
		return false;
	}

	override public function update(elapsed)
	{
		//// Update mouse
		FlxG.mouse.getScreenPosition(camera, curMousePos);
		var deltaX:Int = Std.int(curMousePos.x - prevMousePos.x);
		var deltaY:Int = Std.int(curMousePos.y - prevMousePos.y);
		prevMousePos.set(curMousePos.x, curMousePos.y);

		FlxG.mouse.visible = true;

		if (FlxG.mouse.justPressed){
			mouseGrabbed = NONE;

			var toCheck:Array<Dynamic> = [timing, combo, judge];
			for (idx => chk in toCheck){				
				if (sowy(chk)){
					mouseGrabbed = toCheck.length-1-idx;
					break;
				}
			}
		}
		if (FlxG.mouse.justReleased)
			mouseGrabbed = NONE;

		if (deltaX != 0 || deltaY != 0){
			switch(mouseGrabbed){
				default:

				case JUDGE:
					ClientPrefs.comboOffset[0] += deltaX;
					ClientPrefs.comboOffset[1] -= deltaY; // Why the fuck is this inverted!!!!!!!!!!!!!!!!!!!!!!
					updateJudgePos();
				case COMBO:
					ClientPrefs.comboOffset[2] += deltaX;
					ClientPrefs.comboOffset[3] -= deltaY;
					updateComboPos();
				case TIMER:
					ClientPrefs.comboOffset[4] += deltaX;
					ClientPrefs.comboOffset[5] -= deltaY;
					updateTimingPos();			  
			}
		}

		//// Update keyboard
		var addNum:Int = 1;
		if(FlxG.keys.pressed.SHIFT) addNum = 10;

		// bringing back this old ass shit for now JUST because the keybinds are helpful
		var controlArray:Array<Bool> = [
			FlxG.keys.justPressed.LEFT,
			FlxG.keys.justPressed.RIGHT,
			FlxG.keys.justPressed.UP,
			FlxG.keys.justPressed.DOWN,
		
			FlxG.keys.justPressed.A,
			FlxG.keys.justPressed.D,
			FlxG.keys.justPressed.W,
			FlxG.keys.justPressed.S,

			FlxG.keys.justPressed.J,
			FlxG.keys.justPressed.L,
			FlxG.keys.justPressed.I,
			FlxG.keys.justPressed.K
		];

		if(controlArray.contains(true)) {
			for (i in 0...controlArray.length){
				if(controlArray[i]){
					switch(i)
					{
						case 0:
							ClientPrefs.comboOffset[0] -= addNum;
						case 1:
							ClientPrefs.comboOffset[0] += addNum;
						case 2:
							ClientPrefs.comboOffset[1] += addNum;
						case 3:
							ClientPrefs.comboOffset[1] -= addNum;
						
						////
						case 4:
							ClientPrefs.comboOffset[2] -= addNum;
						case 5:
							ClientPrefs.comboOffset[2] += addNum;
						case 6:
							ClientPrefs.comboOffset[3] += addNum;
						case 7:
							ClientPrefs.comboOffset[3] -= addNum;

						////
						case 8:
							ClientPrefs.comboOffset[4] -= addNum;
						case 9:
							ClientPrefs.comboOffset[4] += addNum;
						case 10:
							ClientPrefs.comboOffset[5] += addNum;
						case 11:
							ClientPrefs.comboOffset[5] -= addNum;							
					}
					updateJudgePos();
					updateComboPos();
					updateTimingPos();
				}
			}
		}

		if(controls.RESET) {
			ClientPrefs.comboOffset[0] = -60;
			ClientPrefs.comboOffset[1] = 60;
			ClientPrefs.comboOffset[2] = -260;
			ClientPrefs.comboOffset[3] = -80;
			ClientPrefs.comboOffset[4] = 0;
			ClientPrefs.comboOffset[5] = 0;
			updateJudgePos();
			updateComboPos();
			updateTimingPos();
		}

		////
		super.update(elapsed);

		if (canClose && controls.BACK) {
			FlxG.sound.play(Paths.sound("cancelMenu"));
			close();
		}
		
	}

	override public function close(){
		FlxG.cameras.remove(camera, true);
		super.close();
	}
	
	override public function destroy(){
		super.destroy();
		
		curMousePos.put();
		prevMousePos.put();
	}
}