package funkin.data;

import funkin.data.CharacterData;

@:publicFields
class AndromedaCharacterData {
	static function isAndromedaFormat(data:Dynamic):Bool {
		return Reflect.field(data, "format") == "andromeda";
	}

	static function toPsychData(data:AndromedaCharJson):CharacterFile return {
		animations: [for (anim in data.anims) toPsychAnim(anim)],
		image: 'characters/'+data.spritesheet,
		scale: data.scale,
		sing_duration: data.singDur,
		
		position: data.charOffset,
		camera_position: data.camOffset,

		flip_x: data.flipX,
		no_antialiasing: data.antialiasing==false,

		healthicon: data.iconName,
		healthbar_colors: funkin.scripts.Wrappers.SowyColor.toRGBArray(CoolUtil.colorFromString(data.healthColor))
	}

	static function toPsychAnim(anim:AndromedaAnimShit):AnimArray return {
		anim: anim.name,
		name: anim.prefix,
		fps: anim.fps,
		indices: anim.indices,
		loop: anim.looped,
		offsets: [Std.int(anim.offsets[0]), Std.int(anim.offsets[1])]
	}
}

typedef AndromedaAnimShit = {
	var prefix:String;
	var name:String;
	var fps:Int;
	var looped:Bool;
	var offsets:Array<Float>;
	@:optional var indices:Array<Int>;
}

typedef AndromedaCharJson = {
	var anims:Array<AndromedaAnimShit>;
	var spritesheet:String;
	var singDur:Float; // dadVar
	var iconName:String;
	var healthColor:String;
	var charOffset:Array<Float>;
	var beatDancer:Bool; // dances every beat like gf and spooky kids
	var flipX:Bool;

	@:optional var format:String;
	@:optional var camMovement:Float;
	@:optional var camOffset:Array<Float>;
	@:optional var scale:Float;
	@:optional var antialiasing:Bool;
}