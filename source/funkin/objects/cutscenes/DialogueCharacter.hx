package funkin.objects.cutscenes;
#if USING_FLXANIMATE
import animate.FlxAnimate;
import animate.FlxAnimateFrames;
import animate.FlxAnimateController;
#end

#if USING_FLXANIMATE
class DialogueCharacter extends FlxAnimate
#else
class DialogueCharacter extends FlxSprite
#end
{

}