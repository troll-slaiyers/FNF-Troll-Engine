package funkin.states;

import funkin.api.Native;
import flixel.group.FlxGroup;
import math.CoolMath;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.addons.display.FlxBackdrop;
import lime.system.System;
import haxe.io.Path;
import sys.io.File;
import sys.io.FileOutput;
import sys.FileSystem;
import openfl.utils.ByteArray;
import openfl.events.Event;
import openfl.events.ProgressEvent;
import openfl.net.URLRequest;
import openfl.net.URLLoader;
import flixel.ui.FlxBar;
import flixel.text.FlxText;
import flixel.util.FlxColor;

import funkin.api.Github;
import Main.Version;

using StringTools;

typedef DownloadData = {
	var fileName:String;
	var fileSize:Int;
	var link:String;
}

typedef FileData = {
	var fileName:String;
	var path:String;
}

typedef DLProgress = {
	var bytesFinished:Float;
	var bytesTotal:Float;
	var files:Array<DownloadData>;
	var downloadedFiles:Array<FileData>;
	var finishedFiles:Array<FileData>;
	var currentFile:Int;
	var totalFiles:Int;
	var done:Bool;
}

private function formatDecimal(Number:Float, Precision = 2):String {
	var mult:Float = 1;
	for (_ in 0...Precision)
		mult *= 10;
	
	var formatted = Std.string(Math.fround(Number * mult) / mult);
	var sowy = formatted.lastIndexOf('.');

	if (sowy == -1) {
		formatted += '.';
		sowy = 0;
	}else
		sowy = formatted.length - sowy - 1;

	for (_ in sowy...Precision)
		formatted += '0';

	return formatted;
}

private function formatBytes(Bytes:Float, Precision = 2):String {
	var units:Int = 0;
	while (Bytes >= 1024) {
		Bytes /= 1024;
		units++;
	}

	return formatDecimal(Bytes, Precision) + switch(units) {
		case 0: " Bytes";
		case 1: "kB";
		case 2: "MB";
		default: "GB";
	};
}

@:noScripting
class UpdaterState extends MusicBeatState {
	var busy:Bool = false;
	var updateText:FlxText;
	var controlsText:FlxText;
	var fileBar:FlxBar;

	static final path = Path.join([Native.getTempDirectory(), "TrollEngineUpdate"]);
	static final OS:String = Sys.systemName().toLowerCase();

	var release:Release;
	var stream:URLLoader;
	var prog:DLProgress = {
		bytesFinished: 0,
		bytesTotal: 0,
		files: [],
		downloadedFiles: [],
		finishedFiles: [],
		currentFile: 0,
		totalFiles: 0,
		done: false
	}
	
	public function new(r:Release){
		super();
		release=r;
	}

	override function create(){
		var tuff = new FlxSprite();
		tuff.loadGraphic(Paths.image("week54prototype"));
		tuff.screenCenter();
		tuff.alpha = 0.6;
		add(tuff);

		var ac = new funkin.objects.shaders.AdjustColor();
		ac.brightness = -32 / 100;
		ac.contrast = 64 / 100;
		tuff.shader = ac.shader;

		/*
		var tile = new FlxBackdrop(Paths.image("trollface"), 16, 16);
		tile.antialiasing = false;
		tile.setGraphicSize(0, FlxG.height / 4 - tile.spacing.y);
		tile.updateHitbox();
		tile.blend = ADD;
		tile.alpha = 0.01;
		tile.velocity.x = tile.velocity.y = 10 * (FlxG.height / 720);
		tile.screenCenter(X);
		add(tile);
		*/

		////
		updateText = new FlxText(0, 0, FlxG.width);
		updateText.setFormat(Paths.font("calibrib.ttf"), 32, FlxColor.WHITE, CENTER);
		updateText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 4);
		add(updateText);

		controlsText = new FlxText(0, 0, FlxG.width);
		controlsText.setFormat(Paths.font("calibrib.ttf"), 32, FlxColor.WHITE, CENTER);
		controlsText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 4);
		add(controlsText);

		fileBar = new FlxBar(0, 0, LEFT_TO_RIGHT, Std.int(FlxG.width/2), 10, null, null, 0, 100, false);
		fileBar.screenCenter(XY);
		fileBar.numDivisions = 200;
		fileBar.y += 100;
		fileBar.createFilledBar(FlxColor.GRAY, FlxColor.GREEN);
		fileBar.visible = false;
		add(fileBar);
		super.create();

		////
		/*
		if (true) {
			release = cast {
				name: "MD Test",
				body: sys.io.File.getContent('cl.md'),
				assets: [],
			}
			checkoutRelease();
			return;
		}
		*/

		if (release == null) {
			updateText.text = "grievous error";
			updateText.drawFrame();
			updateText.screenCenter();
			
			yesSelected = gotoMenus;
			noSelected = gotoMenus;
			ignoreSelected = gotoMenus;
			return;
		}

		var beta = release.prerelease ? " (PRE-RELEASE)" : "";
		var currentBeta = Version.isBeta ? " (PRE-RELEASE)" : "";

		updateText.text = 'You are on Troll Engine v${Version.semanticVersion}${currentBeta}, but the most recent is v${release.tag_name}${beta}!';
		updateText.drawFrame();
		
		controlsText.text = '[Y] Check out release • [N] Remind me later • [I] Skip this update';
		controlsText.drawFrame();
		
		updateText.screenCenter(Y);
		updateText.y -= controlsText.height / 2;
		controlsText.y = updateText.y + updateText.height + updateText.size;

		yesSelected = checkoutRelease;
		noSelected = function() {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			gotoMenus();
		}
		ignoreSelected = function() {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			ignoreThisRelease();
		}
	}

	override function update(elapsed:Float){
		super.update(elapsed);
		
		if (!busy) {	
			if (FlxG.keys.justPressed.N)
				noSelected();
			else if(FlxG.keys.justPressed.I)
				ignoreSelected();
			else if(FlxG.keys.justPressed.Y)
				yesSelected();
		}
	}

	override function draw() {
		controlsText.exists = !busy;
		super.draw();
	}

	function noop() {}

	dynamic function noSelected() {}
	dynamic function yesSelected() {}
	dynamic function ignoreSelected() {}

	dynamic function gotoMenus() {
		MusicBeatState.switchState(new TitleState());
	}

	////
	function ignoreThisRelease(playSound:Bool = true) {
		Main.outOfDate = false;
		
		FlxG.save.data.ignoredUpdates ??= [];
		FlxG.save.data.ignoredUpdates.push(release.tag_name);
		FlxG.save.flush();

		gotoMenus();
	}

	function checkoutRelease() {
		//// get every asset. there should probably only be 1 but y'know!!
		var downloadList:Array<DownloadData> = [];

		for (asset in release.assets){
			if (asset.name.toLowerCase().contains(OS.toLowerCase())){
				downloadList.push({
					fileName: asset.name,
					link: asset.browser_download_url,
					fileSize: asset.size
				});
			}
		}

		/*
		// If no platform-specific release then get every asset
		for (asset in release.assets) {
			downloadList.push({
				fileName: asset.name,
				link: asset.browser_download_url,
				fileSize: asset.size
			});
		}
		*/

		#if UPDATES_ALLOWED
		final canUpdate = downloadList.length > 0;
		#else
		final canUpdate = false;
		#end

		////
		FlxG.mouse.visible = true;
		
		updateText.exists = false;		
		controlsText.text = '[Y] ${canUpdate ? 'Install update' : 'Visit release page'} • [N] Remind me later • [I] Skip this update';

		var group = new FlxGroup();
		add(group);

		////
		var width = Std.int(FlxG.height * 4/3);

		var titleText = new FlxText(0, 0, width);
		titleText.setFormat(Paths.font("calibrib.ttf"), 32, FlxColor.WHITE, LEFT);
		titleText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 4);
		titleText.text = release.name;
		group.add(titleText);
		
		var releaseText = new ScrollingText(0, 0, width);
		releaseText.setFormat(Paths.font("calibri.ttf"), 24, FlxColor.WHITE, LEFT);
		//releaseText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 4);
		group.add(releaseText);

		applyMDStyle(releaseText, release.body);

		////
		controlsText.drawFrame();
		controlsText.y = FlxG.height - controlsText.height - 16;

		titleText.drawFrame();
		titleText.screenCenter(X);
		titleText.y = 16;
		
		releaseText.drawFrame();
		releaseText.x = titleText.x;
		releaseText.y = titleText.y + titleText.height + 24;
		releaseText.minY = releaseText.y;
		releaseText.maxY = controlsText.y - 24;

		//
		yesSelected = function() {
			if (canUpdate) {
				remove(group);
				group.destroy();
				updateText.exists = true;
				startDownload(downloadList);
			}else {
				FlxG.autoPause = true;
				FlxG.openURL(Main.recentRelease.html_url);
			}
		}
		noSelected = function() {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			gotoMenus();
		}
		ignoreSelected = function() {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			ignoreThisRelease();
		}
	}

	// Removes SPACES only, not tabs
	static inline function ltrim(str:String) {
		for (i in 0...str.length) {
			if (str.fastCodeAt(i) != ' '.code) {
				str = str.substring(i);
				break;
			}
		}
		return str;
	}

	static function applyMDStyle(text:FlxText, content:String) {
		/*
		Normally in real markdown it works like this:
		1 (_ / *) for italic
		2 (__ / **) for bold
		3 (___ / ***) for bold and italic
		4 (____ / ****) bold again

		(From this point onward shit will crash)

		5 (_____ / *****) bold and italic again
		6 (______ / ******) just bold again
		7 (_______ / *******) bold and italic again
		8 (________ / ********) bold again you get it
		*/

		////
		var render:String = content;
		render = render.replace('\\\\', '<backslash>');
		render = render.replace('\\*', '<asterisk>');
		render = render.replace('\\_', '<underscore>');
		
		render = replaceMarker(render, '****', '<bold>');
		render = replaceMarker(render, '***', '<bold><italic>');
		render = replaceMarker(render, '**', '<bold>');
		render = replaceMarker(render, '*', '<italic>');
		
		render = replaceMarker(render, '____', '<bold>');
		render = replaceMarker(render, '___', '<bold><italic>');
		render = replaceMarker(render, '__', '<bold>');
		render = replaceMarker(render, '_', '<italic>');
		
		render = render.replace('<asterisk>', '*');
		render = render.replace('<underscore>', '_');
		render = render.replace('<backslash>', '\\');
				
		var boldFormat = new FlxTextFormat(null, true);
		var italicFormat = new FlxTextFormat(null, null, true);
		var boldMarker = new FlxTextFormatMarkerPair(boldFormat, "<bold>");
		var italicMarker = new FlxTextFormatMarkerPair(italicFormat, "<italic>");

		try {
			text.applyMarkup(render, [boldMarker, italicMarker]);
			text.drawFrame();
		}catch(e) {
			print(e);
			text.clearFormats();
			text.text = content;
		}
	}
	
	static function replaceMarker(str:String, ogMarker:String, newMarker:String) {
		var split:Array<String> = [];
		var i = 0;
		while (i < str.length) {
			var nli = str.indexOf('\n', i);
			if (nli == -1) {
				split.push(str.substring(i));
				break;
			}else {
				split.push(str.substring(i, nli));
				i = nli + 1;
			}
		}
		
		var buf = new StringBuf();
		for (lineIdx => lineStr in split) {
			//print('line ${lineIdx+1}: ${lineStr.replace('\r', '\\r').replace('\f', '\\b').replace('\n', '\\n')}');
			var i = 0;
			while (i < lineStr.length) {
				var startIndex = lineStr.indexOf(ogMarker, i);
				if (startIndex == -1) {
					// no marker was found, add the rest of the line
					//trace('line (${lineIdx+1}:$i): No start marker, add rest of the line');
					buf.addSub(lineStr, i);
					break;
				}
				startIndex += ogMarker.length;
				
				var endIndex = lineStr.indexOf(ogMarker, startIndex);
				if (endIndex == -1) {
					//trace('line (${lineIdx+1}:$i): No ending marker, add rest of the line');
					// no marker was found, add the rest of the line
					buf.addSub(lineStr, i);
					break;
				}
				//trace('line (${lineIdx+1}:$i): Found marked content [$startIndex - $endIndex]');
				i = endIndex + ogMarker.length;

				buf.add(newMarker);
				buf.add(lineStr.substring(startIndex, endIndex));
				//buf.addSub(lineStr, startIndex, endIndex); // this is fucked
				buf.add(newMarker);
			}
			buf.add('\n');
		}
		return buf.toString();
	}
	
	/*
	function warning() {
		new FlxTimer().start(0.08, tmr -> {
			updateText.alpha = (tmr.elapsedLoops % 2 == 0) ? 1.0 : 0.6;
		}, 4);
		
		FlxG.sound.play(Paths.sound('scrollMenu')).pitch = 2;
		new FlxTimer().start(0.16, _ -> {
			FlxG.sound.play(Paths.sound('scrollMenu')).pitch = 2;
		}, 2);
	}
	*/

	function startDownload(downloadList) {	
		//// setup folder to download to
		updateText.text = "Preparing";

		clearFiles(path);
		FileSystem.createDirectory(path);

		////
		updateText.text = "Starting download";

		prog.files = downloadList;
		prog.totalFiles += downloadList.length;

		busy = true;
		fileBar.visible = true;

		FlxG.autoPause = false;
		download(function(){
			fileBar.visible = false;
			updateText.text = "Finished downloading! Preparing extraction";
			sys.thread.Thread.create(() ->
			{ 
				installShit();
				updateText.text = "Finished extraction! Installing to the game folder..";

				var progPath = Path.normalize(Sys.programPath());
				var exeFile = Path.withoutDirectory(progPath);
				var programFolder = Path.directory(progPath);
				var finishedFolder = Path.join([path, 'Finished']);

				copy(finishedFolder, '', FileSystem.absolutePath(programFolder));
				updateText.text = "Done copying!";

				FileSystem.rename(progPath, Path.withExtension(progPath, 'tempcopy'));
				File.copy(Path.join([finishedFolder, exeFile]), progPath);
				prog.done = true; 
				
				clearFiles(path);

				var ret:Int = -1;

				#if windows
				ret = Sys.command('start', ['/B', exeFile]);
				#end
				
				if (ret == 0) {
					System.exit(0);
				}

				updateText.text = "It is now safe to close\nthis program";
				updateText.color = FlxColor.ORANGE;
			});
		});
	}

	function download(onFinish:Void->Void){
		var file = prog.files.shift();
		if(file==null){
			onFinish();
			return;
		}
		updateText.text = 'Beginning to download ${file.fileName} (${prog.currentFile} / ${prog.totalFiles})';
		// wanted to use a while loop to download everything, but can't cus of it being async so L
		downloadFile(file, download.bind(onFinish));
	}

	function downloadFile(file:DownloadData, onFinish:Void->Void){	  
		prog.bytesTotal = 1; // so no 0 / 0 bullshit
		prog.bytesFinished = 0; 
		fileBar.setRange(0, file.fileSize);
		stream = new URLLoader();
		stream.dataFormat = BINARY;
		stream.addEventListener(ProgressEvent.PROGRESS, function(e:ProgressEvent){
			prog.bytesFinished = e.bytesLoaded;
			prog.bytesTotal = e.bytesTotal;

			fileBar.setRange(0, prog.bytesTotal);
			fileBar.value = prog.bytesFinished;
			
			var finished = formatBytes(prog.bytesFinished);
			var total = formatBytes(prog.bytesTotal);
			updateText.text = 'Downloading ${file.fileName} ($finished / $total) (${prog.currentFile} / ${prog.totalFiles})';
		});
		stream.addEventListener(Event.COMPLETE, function(e:Event) {
			fileBar.percent = 100;
			prog.bytesFinished = prog.bytesTotal;
			var path = '$path\\${file.fileName}';
			var output:FileOutput = File.write(path);
			try{
				var writingData:ByteArray = new ByteArray();
				var downloadedData:ByteArray = stream.data;
				downloadedData.readBytes(writingData); // should read all bytes? if needed i'll stream it into the file output instead tho
				output.write(writingData); // should write all bytes? same as above if needed ill stream it
				prog.downloadedFiles.push({
					fileName: file.fileName,
					path: path
				});
			}catch(e:Dynamic){
				trace(file.fileName + " failed to write, RIP!! " + e);
			}
			output.flush();
			output.close();
			onFinish();

			prog.currentFile++;
		});

		stream.load(new URLRequest(file.link));
	}

	function installShit(){
		var extractionPath = '${path}\\Finished';
		clearFiles(extractionPath);
		FileSystem.createDirectory(extractionPath);

		prog.currentFile = 0;
		prog.totalFiles = prog.downloadedFiles.length;
		prog.bytesFinished = 0;
		prog.bytesTotal = 0;
		fileBar.setRange(0, prog.totalFiles);

		for (file in prog.downloadedFiles) {
			fileBar.value = prog.currentFile;

			if (!file.fileName.endsWith(".zip")) {
				prog.currentFile++;
				prog.finishedFiles.push(file);
				continue;
			}

			updateText.text = 'Reading file ${file.fileName} (${prog.currentFile} / ${prog.totalFiles})\nPlease wait';

			var toRead = File.read(file.path);
			var entries = haxe.zip.Reader.readZip(toRead);
			toRead.close();

			var extractedFiles:Int = 0;
			var totalFiles:Int = entries.length;
			updateText.text = 'Extracting (${prog.currentFile} / ${prog.totalFiles}) (${extractedFiles} / ${totalFiles})';

			for (zippedFile in entries) {
				updateText.text = 'Extracting (${prog.currentFile} / ${prog.totalFiles}) (${extractedFiles} / ${totalFiles})';
				extractedFiles++;

				var name = zippedFile.fileName;
				var fullPath = Path.join([extractionPath, name]);
				
				trace(name);
				
				if (name.endsWith("/")) {
					// dir
					if (!FileSystem.exists(fullPath))
						FileSystem.createDirectory(fullPath);
					else
						clearFiles(fullPath);
				}else{
					var directory = [for (w in name.split("/")) w.trim()];
					directory.pop();
					FileSystem.createDirectory(Path.join([extractionPath, directory.join("/")]));
					var data = haxe.zip.Reader.unzip(zippedFile);
					File.saveBytes(fullPath, data);
				}
			}

			prog.currentFile++;
		}
	}

	function copy(base:String, dir:String, dest:String){
		trace("copying from " + Path.join([base, dir]));
		for (file in FileSystem.readDirectory(Path.join([base, dir])))
		{
			var finFile = Path.join([base, dir, file]);
			var myFile = Path.join([dest, dir, file]);
			if (file.endsWith(".dll") || file.endsWith(".ndll"))
			{
				var temp = '${Path.withoutExtension(myFile)}.tempcopy';
				if(FileSystem.exists(temp))
					FileSystem.deleteFile(temp);
				FileSystem.rename(myFile, temp); // anything with the .temp ext will be removed after the game restarts
			}
			if (file == Path.withoutDirectory(Sys.programPath()))
			{
				trace("Ignoring copying the executable");
				continue;
			}
			if(file == 'content'){
				trace("Ignoring copying the content folder");
				// Maybe add a way to ask the user "Wanna replace the fuckin folders???"
				// And show a list of what content would be replaced with new content
				// This ensures that people who edit base game folder will be abl eto say no and keep their changes
				// rn tho, just skip content so we dont remove anyone's content folders

				/*
				no content should be distributed alongside the build!!!
				TODO: mods menu!!!!
				*/

				continue;
			}
			if (FileSystem.isDirectory(finFile)){
				if (FileSystem.exists(myFile) && !FileSystem.isDirectory(myFile)){
					FileSystem.deleteFile(myFile);
					trace("deletin da file " + myFile);
				}
				if (!FileSystem.exists(myFile)){
					trace("makin da directory " + myFile);
					FileSystem.createDirectory(myFile);
				}
				
				copy(base, Path.join([dir, file]), dest);
			}else{
				trace('Copying $finFile to $myFile');
				File.copy(finFile, myFile); 
			}
			
		}
	}

	function clearFiles(path:String){
		if (FileSystem.exists(path))
		{
			for (file in FileSystem.readDirectory(path))
			{
				var fp = Path.join([path, file]);
				if (FileSystem.isDirectory(fp)){
					clearFiles(fp);
					FileSystem.deleteDirectory(fp);
				}else
					FileSystem.deleteFile(fp);
			}
		}
	}

	#if(CHECK_FOR_UPDATES || display)
	// gets the most recent release and returns it
	// if you dont have download betas on, then it'll exclude prereleases
	public static function getRecentGithubRelease():Release
	{
		var recentRelease:Release;

		if (ClientPrefs.checkForUpdates)
		{
			var github:Github = new Github(); // leaving the user and repo blank means it'll derive it from the repo the mod is compiled from
			// if it cant find the repo you compiled in, it'll just default to troll engine's repo
			var releases = github.getReleases((release:Release) -> (Main.downloadBetas || !release.prerelease));
			recentRelease = releases[0];

			if (recentRelease != null && FlxG.save.data.ignoredUpdates?.contains(recentRelease.tag_name) == true)
				recentRelease = null;
		}else{
			recentRelease = null;
		}

		return Main.recentRelease = recentRelease;
	}

	public static function checkOutOfDate():Bool{
		var outOfDate = false;

		if (!ClientPrefs.checkForUpdates) {
			trace('Update checking is disabled by the user');
		}
		else if (Main.recentRelease == null) {
			trace('No recent release found');
		}
		else {
			var recentRelease = Main.recentRelease;
			var tagName:funkin.data.SemanticVersion = recentRelease.tag_name;

			trace('Newest version: $tagName | Current: ${Version.semanticVersion}');
			
			// hoping this works lol
			if (tagName > Version.semanticVersion){
				outOfDate = true;
				trace('New version found!');
			}
		}

		return Main.outOfDate = outOfDate;
	}

	public static function clearTemps(dir:String)
	{
		#if desktop
		for (file in FileSystem.readDirectory(dir)){
			var file = './$dir/$file';
			if (FileSystem.isDirectory(file))
				clearTemps(file);
			else if (file.endsWith(".tempcopy"))
				FileSystem.deleteFile(file);
		}
		#end
	}
	#else
	public static function getRecentGithubRelease():Release
		return Main.recentRelease = null;

	public static function checkOutOfDate():Bool
		return Main.outOfDate = false;
	#end
}

// Making a new camera would've been a trillion times easier but oh well
class ScrollingText extends FlxText {
	public var minY:Float = 32;
	public var maxY:Float = FlxG.height - 32;
	public var viewHeight(get, never):Float;

	public var bg:FlxSprite;
	public var bar:FlxSprite;

	override public function new(x:Float, y:Float, fw:Float) {
		bg = new FlxSprite().makeGraphic(1, 1);
		bg.exists = false;

		bar = new FlxSprite().makeGraphic(1, 1);
		bar.scale.x = 12;

		super(x, y, fw);
	}

	override function graphicLoaded() {
		super.graphicLoaded();
	}
	
	override function update(elapsed:Float) {
		bg.update(elapsed);
		super.update(elapsed);
		bar.update(elapsed);
		
		final viewHeight = viewHeight;
		final canScroll = viewHeight < (this.frameHeight * this.scale.y);

		if (canScroll && FlxG.mouse.wheel != 0) {
			this.y += FlxG.mouse.wheel * this.size;
		}
		
		bar.exists = canScroll;
		if (bar.exists) {
			bar.scale.y = viewHeight * (viewHeight / this.height);
			bar.updateHitbox();
			
			var hovering = FlxG.mouse.overlaps(bar);
			if (hovering && FlxG.mouse.justPressed)
				bar.active = true;

			bar.color = (hovering || bar.active) ? 0xFFFFFFFF : 0xFF999999;
			
			if (bar.active) {
				if (FlxG.mouse.pressed) {
					#if false
					this.y -= FlxG.mouse.deltaY;
					#else
					bar.y += FlxG.mouse.deltaY;
					final maxSprY = maxY - this.height;
					final minSprY = minY;		
					final minBarY = minY;
					final maxBarY = maxY - bar.height;
					this.y = CoolMath.scale(bar.y, minBarY, maxBarY, minSprY, maxSprY);
					#end
				}else {
					bar.active = false;
				}
			}
		}
		
		if (canScroll)
			this.y = CoolMath.boundTo(this.y, maxY - this.height, minY);
		else
			this.y = minY;
	}
	
	override function draw() {
		if (bg.exists && bg.visible) {
			bg.setPosition(this.x, minY);
			bg.setGraphicSize(this.width, viewHeight);
			bg.updateHitbox();
			bg.scrollFactor.copyFrom(this.scrollFactor);
			bg.draw();
		}

		{
			var rect = this.clipRect ?? new FlxRect();
			var bottom = this.y + this.height;
			
			rect.set(0, 0, this.width, this.height);
			rect.y = Math.max(0.0, minY - this.y);
			rect.height = this.height - (bottom - maxY) - rect.y;
			
			this.clipRect = rect;
			super.draw();
		}
		
		if (bar.exists && bar.visible) {
			// this.y when you reach the bottom
			final maxSprY = maxY - this.height;
			// this.y when you're at the beggining
			final minSprY = minY;
		
			// bar.y when you're at the beggining
			final minBarY = minY;
			// bar.y when you reach the bottom
			final maxBarY = maxY - bar.height;
		
			bar.x = this.x + this.width + 2;
			bar.y = CoolMath.scale(this.y, minSprY, maxSprY, minBarY, maxBarY);
			bar.y = CoolMath.boundTo(bar.y, minBarY, maxBarY);
			bar.draw();
		}
	}

	override function destroy() {
		super.destroy();
		bg.destroy();
		bar.destroy();
	}

	inline function get_viewHeight() return maxY - minY;
}