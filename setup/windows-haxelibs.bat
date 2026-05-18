@echo off
color 0a
cd ..
echo Install Haxe libraries?
pause
cls
@echo on
haxelib --always --quiet git lime https://github.com/FunkinCrew/lime 6c2fd14ca30f688723d760581b720567bb4ee70c
haxelib --always --quiet git openfl https://github.com/FunkinCrew/openfl 9313f0689748966e4647f3f7e31cbd6176456210
haxelib --always --quiet git flixel https://github.com/troll-slaiyers/flixel dev
haxelib --always --quiet install flixel-ui 2.6.1
haxelib --always --quiet install flixel-addons 3.2.3
haxelib --always --quiet git hxcpp https://github.com/moxie-coder/hxcpp-funkin troll-engine
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