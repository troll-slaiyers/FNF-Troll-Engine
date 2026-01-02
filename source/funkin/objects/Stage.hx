package funkin.objects;

import funkin.scripts.ScriptedClassShit.InstanceInterp;
import flixel.group.FlxGroup;
import flixel.FlxBasic;
import funkin.Paths;
import funkin.data.StageData;
import funkin.scripts.*;

using StringTools;

class Stage extends FlxGroup
{
	public var stageId(default, null):String;
	public var stageData(default, null):StageFile;
	
	public var foreground = new FlxGroup();

	public var props:Map<String, FlxBasic> = [];

	public var stageScript:FunkinHScript;

	public var stageBuilt:Bool = false;

	public function new(stageId:String, runScript:Bool = true)
	{
		super();

		this.stageId = stageId;
		this.stageData = StageData.getStageFile(stageId) ?? {
			directory: "",
			defaultZoom: 0.8,
			boyfriend: [500, 100],
			girlfriend: [0, 100],
			opponent: [-500, 100],
			hide_girlfriend: false,
			camera_boyfriend: [0, 0],
			camera_opponent: [0, 0],
			camera_girlfriend: [0, 0],
			camera_speed: 1
		};

		if (runScript)
			startScript();
	}

	public function startScript()
	{
		if (stageScript != null) {
			trace("Stage script already started!");
			return;
		}   

		var file = Paths.getHScriptPath('stages/$stageId');
		if (file == null) {
			stageScript = null;
			return;
		}
	
		stageScript = FunkinHScript.fromFile(file, null, null, true, new InstanceInterp(this));
	}

	public function buildStage()
	{
		if (stageBuilt)
			return this;

		stageBuilt = true;
		if (stageScript != null && stageScript.exists("buildStage"))
			stageScript.call("buildStage", null, ["super" => _buildStage]);
		else
			_buildStage();

		return this;
	}

	private function _buildStage()
	{
		if (stageData.props != null) {
			for (propData in stageData.props) {
				var prop:StageProp = StageProp.buildFromData(propData);
				if (propData.id != null)
					props.set(propData.id, prop);

				if (propData.foreground)
					foreground.insert(propData?.index ?? foreground.members.length, prop);
				else
					insert(propData?.index ?? members.length, prop);
			}
		}

		#if ALLOW_DEPRECATION
		if (stageScript != null)
			stageScript.call("onLoad", [this, foreground]);
		#end

		return this;
	}

	override function destroy()
	{
		if (stageScript != null){
			stageScript.call("onDestroy");
			stageScript.stop();
			stageScript = null;
		}
		
		super.destroy();
	}

	override function toString(){
		return 'Stage($stageId)';
	}

	#if ALLOW_DEPRECATION
	@:deprecated("spriteMap is deprecated. Use props instead.")
	public var spriteMap(get, null):Map<String, FlxBasic>;
	function get_spriteMap()return props;

	@:deprecated("curStage is deprecated. Use stageId instead.")
	public var curStage(get, never):String;
	inline function get_curStage() return stageId;
	
	@:deprecated("Stage.getTitleStages is deprecated. Use StageData.getTitleStages instead.")
	inline public static function getTitleStages(modsOnly = false):Array<String>
		return StageData.getTitleStages(modsOnly);

	@:deprecated("Stage.getAllStages is deprecated. Use StageData.getAllStages instead.")
	inline public static function getAllStages(modsOnly = false):Array<String>
		return StageData.getAllStages(modsOnly);
	#end
}