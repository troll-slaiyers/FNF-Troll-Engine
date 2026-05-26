import haxe.CallStack;
import openfl.events.UncaughtErrorEvent;
import flixel.FlxG;
import funkin.util.FileUtil;

using StringTools;

#if (windows && cpp)
import funkin.api.Windows;
#end

#if linc_filedialogs
// class name is a bit misleading for the function used
// but it does also handle file dialogs, soooo
import filedialogs.FileDialogs;
#end

private enum abstract HandlerChoice(Int) {
	var NO;
	var YES;
	var CANCEL;
}

class CrashHandler {
	public static function init() {
		openfl.Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onFlashCrash);

		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onHxcppCrash);
		#end
	}

	private static function onFlashCrash(event:UncaughtErrorEvent) {
		onCrash(event.error);
		// one of these oughta do it
		event.stopImmediatePropagation();
		event.stopPropagation();
		event.preventDefault();
	}

	private static function onHxcppCrash(errorName:String) {
		onCrash(errorName);
	}

	inline private static function getLogFilePath():String {
		return 'logs/' + FileUtil.getDateFileName() + '.txt';
	}

	private static function onCrash(errorName:String):Void {
		print("\nCall stack starts below");

		final callstack:String = callstackToString(CallStack.exceptionStack(true));
		final versionLine:String = 'Version: ${Main.Version.displayedVersion}';
		print('\n$callstack\n$errorName');

		////
		var boxMessage:String = callstack;
		boxMessage += '\n$errorName';
		boxMessage += '\n$versionLine';

		#if SAVE_CRASH_LOGS
		var logContent = '$versionLine\nException: $errorName\n$callstack';

		final logPath:String = getLogFilePath();
		boxMessage += '\nLog file was saved at $logPath';
		FileUtil.safeSaveFile(logPath, logContent);
		#end

		final boxRet = showCrashBox(errorName, boxMessage);
		switch(boxRet) {
			// Go back to the main menu
			case YES: return toMainMenu();
					
			// Continue with a possibly unstable state
			case CANCEL: return;
				
			// Close the game
			case NO:
		}

		#if sys
		lime.system.System.exit(1);
		#end
	}

	inline private static function showCrashBox(errorName:String, boxMessage:String):HandlerChoice {
		#if WINDOWS_CRASH_HANDLER
		boxMessage += "\nWould you like to go to the main menu?";
		final ret:MessageBoxReturnValue = Windows.msgBox(boxMessage, errorName, MessageBoxIcon.ERROR | MessageBoxOptions.YESNOCANCEL | MessageBoxDefaultButton.BUTTON3);
		return switch(ret) {
			case YES: YES;
			case CANCEL: CANCEL;
			default: NO;
		}
		#elseif (UNIX_CRASH_HANDLER && linc_filedialogs)
		boxMessage += "\nWould you like to go to the main menu?";
		final btn:Button = FileDialogs.message(errorName, boxMessage, Choice.Yes_No_Cancel, Icon.Error);
		return switch(btn) {
			case Yes: YES;
			case Cancel: CANCEL;
			default: NO;
		}
		#else
		application.window.alert(callstack, errorName); // this shit barely works on linux!
		return NO;
		#end
	}

	#if (WINDOWS_CRASH_HANDLER || UNIX_CRASH_HANDLER)
	@:unreflective static inline function toMainMenu() @:privateAccess {
		try{
			if (FlxG.game._state != null) {
				FlxG.game._state.destroy();
				FlxG.game._state = null;
			}
		}catch(e){
			print("Error destroying state: ", e);
		}	
		
		FlxG.game._nextState = new funkin.states.MainMenuState();
		FlxG.game.switchState();
	}
	#end

	public static function callstackToString(callstack:Array<StackItem>):String {
		var buf = new StringBuf();
		for (stackItem in callstack) {
			switch (stackItem) {
				case FilePos(s, file, line, column):
					buf.add(switch(s) {
						case Method(className, methodName):
							'$file:$line [$methodName]';
						case LocalFunction(name):
							'$file:$line [$name]';
						default: '$s';
					});
					buf.add('\n');
				default:
					buf.add(stackItem);
					buf.add('\n');
			}
		}
		return buf.toString();
	}
}