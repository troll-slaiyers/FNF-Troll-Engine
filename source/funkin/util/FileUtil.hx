package funkin.util;

import haxe.io.Path;
import haxe.io.Bytes;
import flixel.util.typeLimit.OneOfTwo;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

#if linc_filedialogs
import filedialogs.FileDialogs;
#else
import lime.ui.FileDialog;
import openfl.net.FileFilter;
#end

using StringTools;

class FileUtil {
	/**
		Normalize a path to be used by the the file system.

		On Windows, slashes `/` are replaced by backslashes `\`
		
		If `path` is `null`, or if the resulting path doesn't exist, the current working directory is returned.

		@param path File path, can be relative or absolute.
		@return An absolute path to be used in system functions.
	**/
	public static inline function getSystemPath(?path:String):String {
		#if sys
		if (path == null || path.length == 0)
			return Sys.getCwd();
		if (!Path.isAbsolute(path))
			path = Path.normalize(Path.addTrailingSlash(Sys.getCwd()) + path);
		
		if (!FileSystem.exists(Path.directory(path)))
			path = Sys.getCwd();
		#if windows else
			path = path.replace('/', '\\');
		#end

		return path;
		#else
		return "";
		#end
	}

	public static function safeSaveFile(path:String, content:OneOfTwo<String, Bytes>):Bool {
		#if sys
		try {
			FileSystem.createDirectory(Path.directory(path));
			if (content is Bytes)
				File.saveBytes(path, content);
			else
				File.saveContent(path, content);
			return true;
		}
		catch(e) {
			final errMsg:String = 'Error while trying to save the file: ${Std.string(e).replace('\n', ' ')}';
			trace(errMsg);
		}
		#end

		return false;
	}
	
	public static function showOpenDialog(title:String = "Open File", ?defaultPath:String, ?filters:Array<String>, ?onOpen:(bytes:Bytes)->Void, ?onSelect:(path:String)->Void, ?onCancel:Void->Void):Void {
		final filters = _filefilters(filters);
		final defaultPath = getSystemPath(defaultPath);
		#if linc_filedialogs
		final files:Array<String> = FileDialogs.open_file(title, cast defaultPath, cast filters, Option.None);
		if (onSelect != null) onSelect(files[0]);
		if (files.length == 0) {
			if (onCancel != null) onCancel();
		}else {
			if (onOpen != null) onOpen(File.getBytes(files[0]));
		}
		#else
		final dialog:FileDialog = new FileDialog();
		if (onOpen != null) dialog.onOpen.add(onOpen);
		if (onCancel != null) dialog.onCancel.add(onCancel);
		if (onSelect != null) dialog.onSelect.add(onSelect);
		dialog.browse(OPEN, filters, defaultPath, title);
		Sys.sleep(0.5); // sleep to prevent dialogs sometimes not opening if opened in quick succession
		#end
	}

	public static function showOpenMultipleDialog(title:String = "Open Files", ?defaultPath:String, ?filters:Array<String>, ?onSelect:(paths:Array<String>)->Void, ?onCancel:Void->Void):Void {
		final filters = _filefilters(filters);
		final defaultPath = getSystemPath(defaultPath);
		#if linc_filedialogs
		final files:Array<String> = FileDialogs.open_file(title, cast defaultPath, cast filters, Option.Multiselect);
		if (files.length == 0) {
			if (onCancel != null) onCancel();
		}else {
			if (onSelect != null) onSelect(files);
		}
		#else
		final dialog:FileDialog = new FileDialog();
		if (onCancel != null) dialog.onCancel.add(onCancel);
		if (onSelect != null) dialog.onSelectMultiple.add(onSelect);
		dialog.browse(OPEN_MULTIPLE, filters, defaultPath, title);
		Sys.sleep(0.5); // sleep to prevent dialogs sometimes not opening if opened in quick succession
		#end
	}

	public static function showSaveDialog(content:OneOfTwo<String, Bytes>, title:String = "Save File", ?defaultPath:String, ?filters:Array<String>, ?onSave:(path:String)->Void, ?onCancel:Void->Void):Void {
		final filters = _filefilters(filters);
		final defaultPath = getSystemPath(defaultPath);
		#if linc_filedialogs
		final savePath:String = FileDialogs.save_file(title, cast defaultPath, cast filters);
		if (savePath.length == 0) {
			if (onCancel != null) onCancel();
		}else {
			var success:Bool = safeSaveFile(savePath, content);
			if (success && onSave != null) onSave(savePath);
		}
		#else
		final dialog:FileDialog = new FileDialog();
		dialog.onSelect.add((f) -> safeSaveFile(f, content));
		if (onCancel != null) dialog.onCancel.add(onCancel);
		if (onSave != null) dialog.onSelect.add(onSave);
		dialog.browse(SAVE, filters, defaultPath, title);
		Sys.sleep(0.5); // sleep to prevent dialogs sometimes not opening if opened in quick succession
		#end
	}

	@:noCompletion
	private static inline function _filefilters(?filters:Array<String>) {
		#if linc_filedialogs
		return filters ?? [];
		#else		
		if (filters == null)
			return null;

		final goodFilters:Array<String> = [];

		for (i in 0...Math.floor(filters.length / 2))
			goodFilters.push(filters[i*2+1].replace("*.", "").replace(";", ","));
		
		return goodFilters.join(";");
		#end
	}

	/** 
		Get the current date as a valid file name  
		Because you can't use : in file names
	**/
	public static inline function getDateFileName():String {
		return DateTools.format(Date.now(), "%Y.%m.%d %H.%M.%S");
	}
	
	/**
		Get the Date of a file name generated by `getDateFileName`
	**/
	public static function getFileNameDate(fn:String):Date {
		var split1 = fn.split(' ');
		var day = split1[0].split('.'); // y m d
		var time = split1[1].split('.'); // h m s
		time.resize(3);
		return Date.fromString(day.join('-') + ' ' + time.join(':'));
	}
}