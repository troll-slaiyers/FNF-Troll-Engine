@echo off
color 0a
cd ..
echo Install Haxe libraries?
pause
cls
@echo on
haxelib --always --quiet git lime https://github.com/FunkinCrew/lime 8d5555df83e208c0bab3877ed89cff6cf8906227
haxelib --always --quiet git https://github.com/FunkinCrew/openfl 9.3.4 a85b45f21c7e1a4c19663a193bf4ea961faf0dfa
haxelib --always --quiet git https://github.com/FunkinCrew/flixel 5.6.2 f7b94eebf7dbb452a929d0c67ab31a9cbd71d3a0
haxelib --always --quiet git https://github.com/FunkinCrew/flixel-addons 3.2.3 187f93b34f93c6a405d634a42913c745e443463a
haxelib --always --quiet install flixel-ui 2.6.4
haxelib --always --quiet git hxcpp https://github.com/moxie-coder/hxcpp-funkin
haxelib --always --quiet git hscript https://github.com/troll-slaiyers/t-hscript
haxelib --always --quiet install no-spoon 0.2.0
haxelib --always --quiet  --skip-dependencies install hxvlc 2.2.6
haxelib --always --quiet install hxdiscord_rpc 1.3.0
haxelib --always --quiet install moonchart 0.5.1
haxelib --always --quiet install flixel-animate 1.3.1
haxelib --always --quiet git funkin.vis https://github.com/FunkinCrew/funkVis
haxelib --always --quiet git grig.audio https://github.com/FunkinCrew/grig.audio refactor/fft-cam-version
haxelib --always --quiet git linc_filedialogs https://github.com/dazKind/linc_filedialogs
@echo off
echo ---------
echo Finished!
pause