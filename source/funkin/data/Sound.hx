package funkin.data;

import haxe.io.Bytes;
import lime.media.AudioBuffer;
import openfl.media.Sound as OpenFLSound;

class Sound {
	public static function fromFile(path:String):Null<OpenFLSound> {
		var bytes:Null<Bytes> = Paths.getBytes(path);
		return (bytes == null) ? null : fromBytes(bytes);
	}

	public static function fromBytes(bytes:Bytes):Null<OpenFLSound> {
		@:privateAccess
		var codec = AudioBuffer.__getCodec(bytes);
		
		var audioBuffer:AudioBuffer = switch(codec) {
			case "audio/ogg": AudioBuffer.fromBytes(bytes);
			#if hxdr_libs
			case "audio/mp3": hxdr_libs.Mp3.fromBytes(bytes);
			case "audio/wav": hxdr_libs.Wav.fromBytes(bytes);
			case "audio/flac": hxdr_libs.Flac.fromBytes(bytes);
			#end
			default: null;
		};

		if (audioBuffer == null)
			return null;

		return OpenFLSound.fromAudioBuffer(audioBuffer);
	}
}