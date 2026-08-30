package funkin.states;

import funkin.states.options.OptionsSubstate;
import funkin.states.base.TransitionableState;
import flixel.text.FlxText;
import funkin.data.Song;
import funkin.data.Highscore;
import funkin.states.options.OptionsState;
import funkin.states.editors.MasterEditorMenu;

#if DISCORD_ALLOWED
import funkin.api.Discord.DiscordClient;
#end

using StringTools;

/**
	Barebones menu that shows a list of every available song and chart
	Not meant to be a Freeplay menu!!! Just here as a placeholder and song select menu for quick testing
**/
class SongSelectState extends funkin.states.base.DebugListState
{	
	public var songs:Array<Song> = null;

	public static function getEverySong():Array<Song>
	{
		var songList:Array<Song> = [];

		for (contentId in Paths.packList){
			var folder = Paths.packMap.get(contentId);
			for (song in folder.getSongs())
				songList.push(song);
		}

		return songList;
	}

	public function new() {
		super(null);
	}

	override public function create() 
	{
		TransitionableState.skipNextTransIn = true;
		TransitionableState.skipNextTransOut = true;
		this.persistentDraw = false;
		this.persistentUpdate = false;

		////
		if (_parentState == null) {
			if (!MusicBeatState.isPlayingMusic()){
				MusicBeatState.playMenuMusic(true);
			}else{
				FlxG.sound.music.fadeIn(1.0, FlxG.sound.music.volume);
			}
		}

		songs ??= getEverySong();
		this.textStrings = [for (song in songs) song.songId];
		this.textStrings2 = [for (song in songs) song.packId];

		super.create();

		var versionTxt = new FlxText(0, 0, 0, Main.Version.displayedVersion, 12);
		versionTxt.setPosition(FlxG.width - 2 - versionTxt.width, FlxG.height - 2 - versionTxt.height);
		versionTxt.alpha = 0.6;
		versionTxt.antialiasing = false;
		add(versionTxt);
	} 

	override public function update(e)
	{
		if (FlxG.keys.pressed.CONTROL)
		{
			var ss = new GameplayChangersSubstate();
			ss.cameras = cameras;
			openSubState(ss);
			return;
		}

		if (FlxG.keys.justPressed.SIX)
		{
			var ss = new OptionsSubstate();
			openSubState(ss);
			return;
		}

		super.update(e);
	}
	
	dynamic public function onSelectChart(song:Song, chart:String) {
		PlayState.loadPlaylist([song], chart);
		PlayState.isStoryMode = false;

		if (FlxG.keys.pressed.SHIFT)
			LoadingState.loadAndSwitchState(new funkin.states.editors.ChartingState());
		else
			LoadingState.loadAndSwitchState(new PlayState());
	}

	override public function onSelect(i:Int) {
		var charts = songs[i].getCharts();
		if (charts.length > 0) {
			trace(charts);
			var ss = new ChartSelectSubstate(songs[i], charts, onSelectChart);
			ss.cameras = cameras;
			openSubState(ss);
		}else {
			trace("no charts!");
			textObjects[curTextIdx].color = 0xFFFF0000;
		}
	}

	override dynamic public function goBack() {
		if (_parentState == null)
			MusicBeatState.switchState(new MasterEditorMenu());
		else
			close();
	}

	override function destroy() {
		super.destroy();
		if (cam != null)
			FlxG.cameras.remove(cam);
	}
}

class ChartSelectSubstate extends MusicBeatSubstate
{
	var song:Song;
	var charts:Array<String>;

	var curSelected:Int = 0;

	var chartTxts:Array<FlxText> = [];
	var scoreTxts:Array<FlxText> = [];

	public var onSelect:(Song, String) -> Void;

	public function new(song:Song, ?charts:Array<String>, ?onSelect:(Song, String) -> Void)
	{
		super();
		this.song = song;
		this.charts = charts ?? song.getCharts();
		this.onSelect = onSelect ?? (_, _) -> close();
	}

	override function create()
	{
		var songTxt = new FlxText(0, 5, FlxG.width, song.songId);
		songTxt.setFormat(null, 20, 0xFFFFFFFF, CENTER);
		add(songTxt);

		var y = songTxt.y + songTxt.height + 20;
		var spacing = 20;
		
		for (idx => chartId in charts) {
			var y = y + idx * spacing;
			var w2 = FlxG.width / 2;

			var text = new FlxText(-10, y, w2, chartId, 16);
			text.alignment = RIGHT;
			chartTxts[idx] = text;
			add(text);

			var scoreTxt = new FlxText(w2 + 10, text.y, w2, Std.string(Highscore.getScore(song.songId, chartId)), 16);
			scoreTxt.alignment = LEFT;
			scoreTxts[idx] = scoreTxt;
			add(scoreTxt);
		}

		changeSel();
	}

	function changeSel(diff:Int = 0)
	{
		chartTxts[curSelected].color = 0xFFFFFFFF;
		curSelected = CoolUtil.updateIndex(curSelected, diff, chartTxts.length);
		chartTxts[curSelected].color = 0xFFFFFF00;
	}

	override public function update(e){
		if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W)
			changeSel(-1);
		if (FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.S)
			changeSel(1);

		if (FlxG.keys.justPressed.R) {
			openSubState(new ResetScoreSubState(
				song.songId,
				charts[curSelected],
				false
			));
			this.subStateClosed.addOnce((_) -> {
				scoreTxts[curSelected].text = Std.string(Highscore.getScore(song.songId, charts[curSelected]));
			});
		}
		else if (FlxG.keys.justPressed.BACKSPACE || FlxG.keys.justPressed.ESCAPE)
			this.close();
		else if (FlxG.keys.justPressed.ENTER) {
			onSelect(song, charts[curSelected]);
		}

		super.update(e);
	} 
}