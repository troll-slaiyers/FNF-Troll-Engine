package funkin.api;

import cpp.ConstCharStar;

@:include("filesystem")
extern class Native {
	#if mac
	inline static function getTempDirectory():ConstCharStar
		return untyped Sys.getEnv("TMPDIR").c_str();
	#else
	@:native("std::filesystem::temp_directory_path().c_str")
    static function getTempDirectory():ConstCharStar;
	#end
}