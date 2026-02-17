package funkin.states.base;

#if (VIDEOS_ALLOWED && hxvlc)
import hxvlc.flixel.FlxVideo;
import hxvlc.util.Location;
#else
typedef Location = String;
#end

#if (VIDEOS_ALLOWED && hxvlc)
class VideoPlayerState extends BaseVideoPlayerState<FlxVideo>
{
	override function createVideo() {
		if (!Paths.exists(videoPath)){
			onComplete();
			
		}else{
			trace('Loading video: $videoPath');

			video = new FlxVideo();
			video.onEndReached.add(endVideo);
			FlxG.addChildBelowMouse(video);
			
			var loaded = video.load(videoPath);
			if (loaded)
				video.play();
			else {
				trace('Error loading video: $videoPath');
				endVideo();
			}
		}
	}

	override function pauseVideo() {
		video.pause();
	}

	override function destroyVideo() {
		video.stop();
		video.dispose();
		FlxG.removeChild(video);
	}
}
#else
class VideoPlayerState extends BaseVideoPlayerState<Dynamic> {}
#end

class BaseVideoPlayerState<VideoHandler> extends MusicBeatState
{  
	var videoPath:Location;
	var onComplete:Void -> Void;
	var isSkippable:Bool;

	public var ended:Bool = false;
	public var autoDestroy:Bool = true;
	public var video:VideoHandler;

	public function new(videoPath:Location, onComplete:Void -> Void, isSkippable:Bool = true)
	{
		super();

		this.videoPath = videoPath;
		this.isSkippable = isSkippable==true;
		this.onComplete = onComplete;
	}

	override public function create() {
		FlxG.camera.bgColor = 0xFF000000;
		super.create();
		createVideo();
	}

	private function createVideo() {
		trace("Video playback is unavailable");
		onComplete();
	}

	public function pauseVideo() {
	
	}

	public function destroyVideo() {
		
	}

	/**
		Destroys the VideoHandler if `autoDestroy` is `true` and calls the `onComplete` callback
	**/
	private function endVideo() {
		if (ended)
			return;
		
		ended = true;
		pauseVideo();
		
		if (autoDestroy) destroyVideo();
		if (onComplete != null) onComplete();
	}

	override public function update(e) {
		if (isSkippable && FlxG.keys.justPressed.ENTER) {
			endVideo();
		}

		super.update(e);
	}
}