package funkin.objects.playfields;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxSort;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import lime.app.Event;
import funkin.modchart.ModManager;
import funkin.data.JudgmentManager;
import funkin.objects.notes.*;
import funkin.states.PlayState;
import funkin.states.PlayState.instance as game;
import funkin.Conductor.curDecBeat;

using StringTools;

/*
The system is seperated into 3 classes:

- PlayField
	- This is the gameplay component.
	- This keeps track of notes and updates them
	- This is typically per-player, and can control multiple characters, can be locked up, etc.
	- You can also swap which PlayField a player is actually controlling n all that

- NoteField
	- This is the rendering component.
	- This can be created seperately from a PlayField to duplicate the notes multiple times, for example.
	- Needs to be linked to a PlayField though, so it can keep track of what notes exist, when notes get hit (to update receptors), etc.

- ProxyField
	- Clones a NoteField
	- This cannot have its own modifiers, etc applied. All this does is render whatever's in the NoteField
	- If you need to duplicate one PlayField a bunch, you should be using ProxyFields as they are far more optimized it only calls the mod manager for the initial notefield, and not any ProxyFields
	- One use case is if you wanna include an infinite NoteField effect (i.e the end of The Government Knows by FMS_Cat, or get f**ked from UKSRT8)
*/

/*
	If you use this code, please credit me (Nebula) and 4mbr0s3 2
	Or ATLEAST credit 4mbr0s3 2 since he did the cool stuff of this system (hold note manipulation)

	Note that if you want to use this in other mods, you'll have to do some pretty drastic changes to a bunch of classes (PlayState, Note, Conductor, etc)
	If you can make it work in other engines then epic but its best to just use this engine tbh
 */

typedef NoteCallback = (Note, PlayField) -> Void;

class PlayField extends FlxTypedGroup<FlxBasic>
{
	/** tracks managed by this field **/
	public var tracks:Array<FlxSound> = [];
	/** used to calculate the base position of the strums **/
	public var playerId(default, set):Int = 0;

	/** spawn time for notes **/
	public var spawnTime:Float = 1750;
	/** spawned notes **/
	public var spawnedNotes:Array<Note> = [];
	
	/** spawned notes by data. Used for input **/
	public var spawnedByData:Array<Array<Note>> = [[], [], [], []];
	/** spawned tap notes (with requiresTap) per column. Used for input but can't change spawnedByData cus of holds n shit lol! **/
	public var tapsByData:Array<Array<Note>> = [[], [], [], []];
	/** spawned tap notes (without requiresTap) per column. Used for input but can't change spawnedByData cus of holds n shit lol! **/
	public var noTapsByData:Array<Array<Note>> = [[], [], [], []];
	/** unspawned notes **/
	public var noteQueue:Array<Array<Note>> = [[], [], [], []];
	
	/** receptors **/
	public var strumNotes:Array<StrumNote> = [];
	/** characters that sing when field is hit **/
	public var characters:Array<Character> = [];
	/** default character animations to play for each column **/
	public var singAnimations:Array<Array<String>> = [
		["singUP"],
		["singLEFT", "singRIGHT"],
		["singLEFT", "singUP", "singRIGHT"],
		["singLEFT", "singDOWN", "singUP", "singRIGHT"],
		["singLEFT", "singDOWN", "singUP", "singUP", "singRIGHT"],
		["singLEFT", "singUP", "singRIGHT", "singLEFT", "singDOWN", "singRIGHT"],
		["singLEFT", "singUP", "singRIGHT", "singUP", "singLEFT", "singDOWN", "singRIGHT"],
		[
			"singLEFT",
			"singDOWN",
			"singUP",
			"singRIGHT",
			"singLEFT",
			"singDOWN",
			"singUP",
			"singRIGHT"
		],
		[
			"singLEFT",
			"singDOWN",
			"singUP",
			"singRIGHT",
			"singUP",
			"singLEFT",
			"singDOWN",
			"singUP",
			"singRIGHT"
		],
		[
			"singLEFT",
			"singDOWN",
			"singUP",
			"singRIGHT",
			"singDOWN",
			"singUP",
			"singLEFT",
			"singDOWN",
			"singUP",
			"singRIGHT"
		]
	];
	
	/** note renderer **/
	public var noteField:NoteField;
	/** for deriving judgements for input reasons **/
	public var judgeManager:JudgmentManager;
	/** the mod manager. will be set automatically by playstate so dw bout this **/
	public var modManager:ModManager;
	/** used for the mod manager. can be set to a different number to give it a different set of modifiers. can be set to 0 to sync the modifiers w/ bf's, and 1 to sync w/ the opponent's **/
	public var modNumber:Int = 0;
	/** if this playfield takes input from the player **/
	public var isPlayer:Bool = false;
	/** if this playfield will take input at all **/
	public var inControl:Bool = true;
	/** How many lanes are in this field **/
	public var keyCount(default, set):Int = 4;
	/** if this playfield should be played automatically (botplay, opponent, etc) **/
	public var autoPlayed(default, set):Bool = false;

	public var x:Float = 0;
	public var y:Float = 0;
	
	/** function that gets called when the note is hit. goodNoteHit and opponentNoteHit in playstate for eg **/
	public var noteHitCallback:NoteCallback;
	/** function that gets called when a hold is stepped on. Only really used for calling script events. Return 'false' to not do hold logic **/
	public var holdPressCallback:NoteCallback;
	/** function that gets called when a hold is released. Only really used for calling script events. **/
	public var holdReleaseCallback:NoteCallback;
	/** function that gets called for every 'step' that a hold is pressed for. **/
	public var holdStepCallback:NoteCallback;

	/** notesplashes **/
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	/** things that get "attached" to the receptors. custom splashes, etc. **/
	public var strumAttachments:FlxTypedGroup<NoteObject>;

 	/** Event that gets called every time you miss a note. **/
	public var noteMissed = new Event<NoteCallback>();
	/** Event that gets called every time a note is removed. **/
	public var noteRemoved = new Event<NoteCallback>(); 
	/** Event that gets called every time a note is spawned. **/
	public var noteSpawned = new Event<NoteCallback>();
	/** Event that gets called every time a hold is dropped **/
	public var holdDropped = new Event<NoteCallback>();
	/** Event that gets called every time a hold is finished **/
	public var holdFinished = new Event<NoteCallback>();
	/** Event that gets called every time a hold is updated **/
	public var holdUpdated = new Event<(Note, PlayField, Float) -> Void>();
	
	/** what keys are pressed rn **/
	public var keysPressed:Array<Bool> = [false,false,false,false];
	public var isHolding:Array<Bool> = [false,false,false,false];

	public var baseXPositions:Array<Float> = [];

	private var garbage:Array<Note> = [];

	public function new(?keyCount:Int){
		super();
		this.modManager = game?.modManager;
		this.judgeManager = game?.judgeManager;
		this.keyCount = keyCount ?? PlayState.keyCount;

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		grpNoteSplashes.visible = false; // so they dont get drawn
		add(grpNoteSplashes);

		strumAttachments = new FlxTypedGroup<NoteObject>();
		strumAttachments.visible = false;
		add(strumAttachments);

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		splash.handleRendering = false;
		splash.alpha = 0.0;
		grpNoteSplashes.add(splash);

		////
		noteField = new NoteField(this);
	}

	/** queues a note to be spawned **/
	public function queue(note:Note){
		if (noteQueue[note.column] == null)
			noteQueue[note.column] = [note];
		else{
			noteQueue[note.column].push(note);
			noteQueue[note.column].sort(sortNotesAscend);
		}
	}

	/** unqueues a note **/
	public function unqueue(note:Note)
	{
		if (noteQueue[note.column] != null) {
			noteQueue[note.column].remove(note);
			noteQueue[note.column].sort(sortNotesAscend);
		}
	}

	/** destroys a note **/
	public function removeNote(daNote:Note){
		daNote.active = false;
		daNote.visible = false;
		daNote.kill();

		noteRemoved.dispatch(daNote, this);

		daNote.kill();
		spawnedNotes.remove(daNote);
		if (spawnedByData[daNote.column] != null)
			spawnedByData[daNote.column].remove(daNote);

		if (tapsByData[daNote.column] != null)
			tapsByData[daNote.column].remove(daNote);

		if (noTapsByData[daNote.column] != null)
			noTapsByData[daNote.column].remove(daNote);

		if (noteQueue[daNote.column] != null)
			noteQueue[daNote.column].remove(daNote);

		if (daNote.unhitTail.length > 0)
			while (daNote.unhitTail.length > 0)
				removeNote(daNote.unhitTail.shift());
		

		if (daNote.parent != null && daNote.parent.tail.contains(daNote))
			daNote.parent.tail.remove(daNote);

 		if (daNote.parent != null && daNote.parent.unhitTail.contains(daNote))
			daNote.parent.unhitTail.remove(daNote); 

		if (noteQueue[daNote.column] != null)
			noteQueue[daNote.column].sort(sortNotesAscend);
		remove(daNote);
		daNote.destroy();
	}

	/** spawns a note **/
	public function spawnNote(note:Note){
		if(note.spawned)
			return;
		
		if (noteQueue[note.column]!=null){
			noteQueue[note.column].remove(note);
			noteQueue[note.column].sort(sortNotesAscend);
		}

		if (spawnedByData[note.column] != null)
			spawnedByData[note.column].push(note);
		else
			return;
		

		if(note.holdType == HEAD || note.holdType == TAP){
			if(note.requiresTap){
				if (tapsByData[note.column] != null)
					tapsByData[note.column].push(note);
			}else{
				if (noTapsByData[note.column] != null)
					noTapsByData[note.column].push(note);
			}

		}

		noteSpawned.dispatch(note, this);
		spawnedNotes.push(note);
		note.handleRendering = false;
		note.spawned = true;

		insert(0, note);
	}

	/** gets all notes in the playfield, spawned or otherwise. **/
	public function getAllNotes(?column:Int){
		var arr:Array<Note> = [];
		if (column == null) {
			for (queue in noteQueue) {
				for (note in queue)
					arr.push(note);
			}
		}else {
			for (note in noteQueue[column])
				arr.push(note);
		}
		for (note in spawnedNotes)
			arr.push(note);
		return arr;
	}
	
	/** Returns true if this PlayField has the note, false otherwise. **/
	public function hasNote(note:Note)
		return spawnedNotes.contains(note) || noteQueue[note.column]!=null && noteQueue[note.column].contains(note);
	
	/** Sends an input to the PlayField **/
	public function input(column:Int, ?hitTime:Float):Null<Note> {
		if (column < 0 || column > keyCount) 
			return null;

		hitTime ??= Conductor.getAccPosition();

		var noteList = getTapNotes(column, (note:Note) -> !note.tooLate);
		noteList.sort(sortNotesDescend); // so lowPriority actually works (even though i hate it lol!)

		var recentHold:Null<Note> = null;

		while (noteList.length > 0)
		{
			var note:Note = noteList.pop();
			if (note.wasGoodHit && note.holdType == HEAD && note.holdingTime < note.sustainLength)
				recentHold = note; // for the sake of ghost-tapping shit.
				// returned lower so that holds dont interrupt hitting other notes as, even though that'd make sense, it also feels like shit to play on some songs i.e Bopeebo
			else{
				if (note.wasGoodHit)
					continue;
				var judge:Judgment = judgeManager.judgeNote(note, hitTime);
				if (judge != UNJUDGED){
					note.hitResult.judgment = judge;
					note.hitResult.hitDiff = hitTime - note.strumTime;
					noteHitCallback(note, this);
					return note;
				}
			}
		}

		return recentHold;
	}

	/** generates the receptors **/
	public function generateStrums(){
		for(i in 0...keyCount){
			var strum:StrumNote = new StrumNote(0, 0, i, this, (FlxG.state == game) ? game.hudSkin : 'default');
			strum.downScroll = ClientPrefs.downScroll;
			strum.alpha = 0;
			insert(0, strum);
			strum.x = getBaseX(i);
			strum.y = 50;
			strum.handleRendering = false; // NoteField handles rendering
			strum.cameras = cameras;
			strumNotes.push(strum);
			strum.postAddedToGroup();
		}
	}

	/** 
		Does the fade & slide animation for the receptors.  
		OYT uses this when mario comes in.
		@param skip If true, the receptors will immediately appear without any animation.
	**/
	public function fadeIn(skip:Bool = false)
	{
		if (skip) {
			for (column => strum in strumNotes)
				strum.alpha = 1;
		}else {	
			for (column => strum in strumNotes) {
				FlxTween.tween(strum, {offsetY: strum.offsetY, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: ((0.5 * 4) / keyCount) + Conductor.beatLength * ((column * 4) / keyCount)});
				strum.offsetY -= strum.downScroll ? -10 : 10;
				strum.alpha = 0;
			}
		}
	}

	/** 
		Spawns a notesplash w/ specified skin. 
		@param note Optional note to derive the skin and colours from. 
	**/
	public function spawnSplash(note:Null<Note>, splashSkin:String){
		var skin:String;
		var hue:Float;
		var sat:Float;
		var brt:Float;

		if (note != null) {
			skin = note.noteSplashTexture;
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}else{
			skin = splashSkin;
			hue = sat = brt = 0.0;
			
			/*var hsb = ClientPrefs.arrowHSV[note.column % 4]; 
			hue = hsb[0] / 360;
			sat = hsb[1] / 100;
			brt = hsb[2] / 100;*/
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(0, 0, note.column, skin, hue, sat, brt, note);
		splash.handleRendering = false;
		grpNoteSplashes.add(splash);
		return splash;
	}

	/** Spawns notes, deals w/ hold inputs, etc. **/
	override public function update(elapsed:Float){
		noteField.modManager = modManager;
		noteField.modNumber = modNumber;
		noteField.cameras = cameras;

		for (char in characters)
			char.controlled = isPlayer;
		
		// note spawning
		for (column => queue in noteQueue) {
			if (queue[0] == null)
				continue;

			var modifier = modManager.get("noteSpawnTime" + column); 
			if (modifier == null || modifier.getValue(modNumber) <= 0) 
				modifier = modManager.get("noteSpawnTime");
			
			var spawnTime:Float;
			if (modifier == null || (spawnTime = modifier.getValue(modNumber)) <= 0)
				spawnTime = this.spawnTime;
			else
				spawnTime = modifier.getValue(modNumber);
			
			while (queue.length > 0 && queue[0].strumTime - Conductor.songPosition < spawnTime)
				spawnNote(queue[0]);
		}

		super.update(elapsed);

		for(obj in strumNotes)
			modManager.updateObject(curDecBeat, obj, modNumber);

		for (daNote in spawnedNotes)
		{
			if(!daNote.alive){
				spawnedNotes.remove(daNote);
				continue;
			}
			modManager.updateObject(curDecBeat, daNote, modNumber);

			// check for hold inputs
			if(!daNote.isSustainNote){
				if(daNote.column >= keyCount){
					garbage.push(daNote);
					continue;
				}
				if(daNote.holdingTime < daNote.sustainLength && inControl && !daNote.blockHit){
					if(!daNote.tooLate && daNote.wasGoodHit){
						var isHeld:Bool = autoPlayed || keysPressed[daNote.column];
						var wasHeld:Bool = daNote.isHeld;
						daNote.isHeld = isHeld;
						isHolding[daNote.column] = true;
						if(wasHeld != isHeld){
							if(isHeld){
								if(holdPressCallback != null)
									holdPressCallback(daNote, this);
							}else if(holdReleaseCallback!=null)
								holdReleaseCallback(daNote, this);
						}

						var receptor = strumNotes[daNote.column];
						var oldSteps:Int = Math.floor(daNote.holdingTime / Conductor.stepCrotchet);
						var lastTime:Float = daNote.holdingTime;
						daNote.holdingTime = Conductor.songPosition - daNote.strumTime;
						if (daNote.holdingTime > daNote.sustainLength)
							daNote.holdingTime = daNote.sustainLength;
						var currentSteps:Int = Math.floor(daNote.holdingTime / Conductor.stepCrotchet);
						if(oldSteps < currentSteps)
							if(holdStepCallback != null)
								holdStepCallback(daNote, this);
						holdUpdated.dispatch(daNote, this, daNote.holdingTime - lastTime);

						if(isHeld && !daNote.isRoll){
							if(daNote.unhitTail.length > 0)
								if (receptor.animation.finished || receptor.animation.name != "confirm") 
									receptor.playAnim("confirm", true, daNote);
							
							daNote.tripProgress = 1.0;
						}else
							daNote.tripProgress -= elapsed / (daNote.maxReleaseTime * judgeManager.judgeTimescale);

						if(daNote.isRoll && autoPlayed && daNote.tripProgress <= 0.5)
							holdPressCallback(daNote, this); // would set tripProgress back to 1 but idk maybe the roll script wants to do its own shit

						if(daNote.tripProgress <= 0){
							holdDropped.dispatch(daNote, this);
							daNote.tripProgress = 0;
							daNote.tooLate=true;
							daNote.wasGoodHit=false;
							for(tail in daNote.unhitTail){
								tail.tooLate = true;
								tail.blockHit = true;
								tail.ignoreNote = true;
							}
							isHolding[daNote.column] = false;
							if (!isHeld)
								receptor.playAnim("static", true);

						}else{
							for (tail in daNote.unhitTail)
							{
								if ((tail.strumTime - 25) <= Conductor.songPosition && !tail.wasGoodHit && !tail.tooLate){
									noteHitCallback(tail, this);
								}
							}

							if (daNote.holdingTime >= daNote.sustainLength)
							{
								//trace("finished hold");
								holdFinished.dispatch(daNote, this);
								daNote.holdingTime = daNote.sustainLength;
								isHolding[daNote.column] = false;
								if (!isHeld)
									receptor.playAnim("static", true);
							}

						}
					}
				}
			}
			// check for note deletion
			if (daNote.garbage)
				garbage.push(daNote);
			else
			{

				if (daNote.tooLate && daNote.active && !daNote.causedMiss && !daNote.isSustainNote)
				{
					daNote.causedMiss = true;
					if (!daNote.ignoreNote && (daNote.tooLate || !daNote.wasGoodHit))
						noteMissed.dispatch(daNote, this);
				} 

				if((
					(daNote.holdingTime>=daNote.sustainLength) && daNote.sustainLength>0 ||
					daNote.isSustainNote && daNote.strumTime - Conductor.songPosition < -350 ||
					!daNote.isSustainNote
					&& (daNote.sustainLength == 0 || daNote.tooLate)
					&& daNote.strumTime - Conductor.songPosition < -(200 + judgeManager.getWindow(TIER1) + daNote.sustainLength)) && (daNote.tooLate || daNote.wasGoodHit))
				{
					daNote.garbage = true;
					garbage.push(daNote);
				}
				
			}
		}

		while (garbage.length > 0) 
			removeNote(garbage.pop());

		if (inControl && autoPlayed)
		{
			for(i in 0...keyCount){
				for (daNote in getTapNotes(i, (note:Note) -> !note.tooLate && !note.wasGoodHit && !note.ignoreNote && !note.hitCausesMiss)){
					var hitDiff = Conductor.songPosition - daNote.strumTime;
					if (isPlayer && (hitDiff + ClientPrefs.ratingOffset) >= (-5 * (Wife3.timeScale>1 ? 1 : Wife3.timeScale)) || hitDiff >= 0){
						daNote.hitResult.judgment = judgeManager.useEpics ? TIER5 : TIER4;
						daNote.hitResult.hitDiff = (hitDiff > -5) ? -5 : hitDiff; 
						if (noteHitCallback!=null) noteHitCallback(daNote, this);
					}
					
				}
			}
		}else{
			for(column in 0...keyCount){
				if (keysPressed[column]){
					var noteList = getTapNotesWithEnd(column, Conductor.songPosition + ClientPrefs.hitWindow, (note:Note) -> !note.isSustainNote, false);
					
					noteList.sort(sortNotesDescend);
					
					while (noteList.length > 0)
					{
						var note:Note = noteList.pop();
						var judge:Judgment = judgeManager.judgeNote(note, Conductor.songPosition);
						if (judge != UNJUDGED)
						{
							note.hitResult.judgment = judge;
							note.hitResult.hitDiff = Conductor.songPosition - note.strumTime;
							noteHitCallback(note, this);
						}
						
					}
				}
			}
		}
	}
	
	/** Gets all living notes w/ optional filter **/
	public function getNotes(column:Int, ?filter:Note->Bool):Array<Note>
	{
		if (spawnedByData[column]==null)
			return [];

		var collected:Array<Note> = [];
		for (note in spawnedByData[column])
		{
			if (note.alive && note.column == column)
			{
				if (filter == null || filter(note))
					collected.push(note);
			}
		}
		return collected;
	}
 
	/** get all living TAP notes **/
	public function getTapNotes(column:Int, ?filter:Note->Bool, requiresTap:Bool = true):Array<Note> {
		var array = requiresTap ? tapsByData[column] : noTapsByData[column];

		if (array == null)
			return [];

		var collected:Array<Note> = [];
		for (note in array) {
			if (note.alive && note.column == column) {
				if (filter == null || filter(note))
					collected.push(note);
			}
		}
		return collected;
	}

	/** gets all living TAP notes before a certain time w/ optional filter **/
	public function getTapNotesWithEnd(column:Int, end:Float, ?filter:Note->Bool, requiresTap:Bool = true):Array<Note> {
		var array = requiresTap ? tapsByData[column] : noTapsByData[column];

		if (array == null)
			return [];

		var collected:Array<Note> = [];
		for (note in array) {
			if (note.strumTime > end)
				break;
			if (note.alive && note.column == column && !note.wasGoodHit && !note.tooLate) {
				if (filter == null || filter(note))
					collected.push(note);
			}
		}
		return collected;
	}

	/** gets all living notes before a certain time w/ optional filter **/
	public function getNotesWithEnd(column:Int, end:Float, ?filter:Note->Bool):Array<Note>
	{
		if (spawnedByData[column] == null)
			return [];
		var collected:Array<Note> = [];
		for (note in spawnedByData[column])
		{
			if (note.strumTime>end)break;
			if (note.alive && note.column == column && !note.wasGoodHit && !note.tooLate)
			{
				if (filter == null || filter(note))
					collected.push(note);
			}
		}
		return collected;
	}

	/** go through every queued note and call a func on it **/
	public function forEachQueuedNote(callback:Note->Void)
	{
		for(column in noteQueue){
			var i:Int = 0;
			var note:Note = null;

			while (i < column.length)
			{
				note = column[i++];

				if (note != null && note.exists && note.alive)
					callback(note);
			}
		}
	}

	/** kills all notes which are stacked **/
	public function clearStackedNotes(){

		var goobaeg:Array<Note> = [];
		for (column in noteQueue)
		{
			if (column.length >= 2)
			{
				for (nIdx in 1...column.length)
				{
					var last = column[nIdx - 1];
					var current = column[nIdx];
					if (last == null || current == null)
						continue;
					if (last.isSustainNote || current.isSustainNote)
						continue; // holds only get fukt if their parents get fukt
					if (!last.alive || !current.alive)
						continue; // just incase
					if (Math.abs(last.strumTime - current.strumTime) <= Conductor.jackLimit)
					{
						if (last.sustainLength < current.sustainLength) // keep the longer hold
							removeNote(last);
						else
						{
							current.kill();
							goobaeg.push(current); // mark to delete after, cant delete here because otherwise it'd fuck w/ stuff
						}
					}
				}
			}
		}
		for (note in goobaeg)
			removeNote(note);
	}

	/** as is in the name, removes all dead notes **/
	public function clearDeadNotes(){
		var dead:Array<Note> = [];
		for(note in spawnedNotes){
			if(!note.alive)
				dead.push(note);
		}
		for(column in noteQueue){
			for(note in column){
				if(!note.alive)
					dead.push(note);
			}
		}

		for(note in dead)
			removeNote(note);
	}

	public function setDefaultBaseXPositions() {
		for (i in 0...keyCount)
			baseXPositions[i] = getDefaultBaseX(i);
	}

	public inline function getBaseX(direction:Int)
		return baseXPositions[direction];

	public inline function getDefaultBaseX(direction:Int)
		return modManager.getBaseX(direction, this.playerId, keyCount);

	private static inline function sortNotesAscend(a:Note, b:Note):Int
		return Std.int(a.strumTime - b.strumTime);

	private static inline function sortNotesDescend(a:Note, b:Note):Int
		return Std.int(b.strumTime - a.strumTime);

	override function destroy(){
		noteSpawned.removeAll();
		noteSpawned.cancel();
		noteMissed.removeAll();
		noteMissed.cancel();
		noteRemoved.removeAll();
		noteRemoved.cancel();

		return super.destroy();
	}

	#if true
	function set_playerId(v) {
		playerId = v;
		setDefaultBaseXPositions();
		return playerId;
	}

	function set_keyCount(cnt:Int){
		if (cnt < 0)
			cnt=0;

		if (spawnedByData.length < cnt) {
			for (_ in (spawnedByData.length)...cnt)
				spawnedByData.push([]);
		} else if(spawnedByData.length > cnt){
			spawnedByData.resize(cnt);
		}

		if (tapsByData.length < cnt) {
			for (_ in (tapsByData.length)...cnt)
				tapsByData.push([]);
		} else if (tapsByData.length > cnt) {
			tapsByData.resize(cnt);
		} 

		if (noTapsByData.length < cnt) {
			for (_ in (noTapsByData.length)...cnt)
				noTapsByData.push([]);
		} else if (noTapsByData.length > cnt) {
			noTapsByData.resize(cnt);
		} 

		if (noteQueue.length < cnt) {
			for (_ in (noteQueue.length)...cnt)
				noteQueue.push([]);
		} else if (noteQueue.length > cnt) {
			noteQueue.resize(cnt);
		}

		if (keysPressed.length < cnt) {
			for (_ in (keysPressed.length)...cnt)
				keysPressed.push(false);
		}

		if (baseXPositions.length < cnt) {
			for (_ in (baseXPositions.length)...cnt)
				baseXPositions.push(getDefaultBaseX(baseXPositions.length));
		} else if (baseXPositions.length > cnt) {
			baseXPositions.resize(cnt);
		}

		return keyCount = cnt;
	}

	function set_autoPlayed(aP:Bool){
		if(aP == autoPlayed)return aP;
		
		for (idx in 0...keysPressed.length)
			keysPressed[idx] = false;
		
		for(obj in strumNotes){
			obj.playAnim("static");
			obj.resetAnim = 0;
		}
		return autoPlayed = aP;
	}

	override function set_camera(to){
		for (strumLine in strumNotes)
			strumLine.camera = to;
		
		noteField.camera = to;

		return super.set_camera(to);
	}

	override function set_cameras(to){
		for (strumLine in strumNotes)
			strumLine.cameras = to;
		
		noteField.cameras = to;

		return super.set_cameras(to);
	}

	#end
}