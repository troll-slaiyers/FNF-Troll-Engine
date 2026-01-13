package funkin.states.options;

@:noScripting
class OptionsState extends MusicBeatState
{
	override function create()
	{
		var bg = new funkin.objects.CoolMenuBG(Paths.image('menuDesat', null, false), 0xff7186fd);
		add(bg);

		persistentUpdate = true;

		var daSubstate = new OptionsSubstate(true);
		daSubstate.goBack = (changedOptions:Array<String>) -> {
			MusicBeatState.switchState(new MainMenuState());
		};
		openSubState(daSubstate);
		super.create();
	}
}