package funkin.states.options;

@:noScripting
class OptionsState extends MusicBeatState
{
	override function create()
	{
		add(new funkin.objects.CoolMenuBG('menuDesat', 0xff7F94FF));
		persistentUpdate = true;

		var daSubstate = new OptionsSubstate();
		daSubstate.goBack = (changedOptions:Array<String>) -> {
			MusicBeatState.switchState(new MainMenuState());
		};
		openSubState(daSubstate);
		super.create();
	}
}