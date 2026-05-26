@echo off
color 0a
cd ..
echo Install Haxe libraries?
pause
cls
@echo on
haxelib --always --quiet install lime 8.1.3
haxelib --always --quiet install openfl 9.3.4
haxelib --always --quiet install flixel 5.6.2
haxelib --always --quiet install flixel-ui 2.6.1
haxelib --always --quiet install flixel-addons 3.2.3
haxelib --always --quiet git hxcpp https://github.com/moxie-coder/hxcpp-funkin
haxelib --always --quiet git hscript https://github.com/troll-slaiyers/t-hscript
haxelib --always --quiet install no-spoon 0.2.0
haxelib --always --quiet  --skip-dependencies install hxvlc 2.2.6
haxelib --always --quiet install hxdiscord_rpc 1.3.0
haxelib --always --quiet install moonchart 0.5.1
haxelib --always --quiet install flixel-animate 1.5.0
haxelib --always --quiet git funkin.vis https://github.com/FunkinCrew/funkVis
haxelib --always --quiet git grig.audio https://github.com/FunkinCrew/grig.audio refactor/fft-cam-version
haxelib --always --quiet git linc_filedialogs https://github.com/dazKind/linc_filedialogs
@echo off
echo ---------
echo Finished!
pause