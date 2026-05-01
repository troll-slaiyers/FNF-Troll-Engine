package funkin.api;

import cpp.ConstCharStar;

@:include("filesystem")
extern class Native {
    @:native("std::filesystem::temp_directory_path().c_str")
    static function getTempDirectory():ConstCharStar;
}