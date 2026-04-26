#if (display || macro)
import no.Spoon;
import no.spoon.Bender;
import no.spoon.BuildFields;
import haxe.macro.Compiler;

/**
	@see https://github.com/back2dos/no-spoon/
**/
class Spork {
	public static function stuff() {
		#if display
		Spoon.bend("flixel.FlxGame", macro class {
			var _elapsedMS:Float = 0;
		});

		#else
		final DEFINES = haxe.macro.Context.getDefines();

		// FlxColor pisses it's stupid little pants if I don't do this
		// ...for some reason??? only started happening after linc_filedialogs was added?? tf?? -swordcube the fifth
		if (DEFINES.exists("cpp") && DEFINES.exists("windows")) {
			Compiler.addGlobalMetadata("flixel.util.FlxColor", "@:headerCode('#undef TRANSPARENT')");
		}
		
		Spoon.bend("flixel.tweens.FlxEase", macro class {
			public static function expoInOut(t:Float):Float
			{
				return t == 0 ? 0 : (t == 1 ? 1 : (t < .5 ? Math.pow(2, 10 * (t * 2 - 1)) / 2 : (-Math.pow(2, -10 * (t * 2 - 1)) + 2) / 2));
			}
		});

		Spoon.bend("flixel.group.FlxSpriteGroup", macro class {
			override public function draw():Void
			{
				// Bit jank, but should preserve alpha alot better than the default flixel way
				if (!directAlpha){
					for(obj in group.members)
						if(obj != null && obj.colorTransform != null)
							obj.colorTransform.alphaMultiplier = obj.alpha * alpha; // set alpha to object alpha mult by group alpha
				}

				group.draw();

				if (!directAlpha)
					for (obj in group.members)
						if(obj != null && obj.colorTransform != null)
							obj.updateColorTransform(); // reset back to default
				

				#if FLX_DEBUG
				if (FlxG.debugger.drawDebug)
					drawDebug();
				#end
			}

			override function set_alpha(Value:Float):Float
			{
				Value = FlxMath.bound(Value, 0, 1);

				if (exists && alpha != Value)
				{
					if (directAlpha)
						transformChildren(directAlphaTransform, Value);
				}
				return alpha = Value;
			}
		});

		// catch shader errors and point to the error line in the shader code
		Spoon.bend("openfl.display.Shader", macro class {
			@:noCompletion private function __createGLProgram(vertexSource:String, fragmentSource:String):GLProgram
			{
				var gl = __context.gl;
				var program = gl.createProgram();
				try {
					var vertexShader = __createGLShader(vertexSource, gl.VERTEX_SHADER);
					var fragmentShader = __createGLShader(fragmentSource, gl.FRAGMENT_SHADER);

					// Fix support for drivers that don't draw if attribute 0 is disabled
					for (param in __paramFloat)
					{
						if (param.name.indexOf("Position") > -1 && StringTools.startsWith(param.name, "openfl_"))
						{
							gl.bindAttribLocation(program, 0, param.name);
							break;
						}
					}

					gl.attachShader(program, vertexShader);
					gl.attachShader(program, fragmentShader);
					gl.linkProgram(program);

					if (gl.getProgramParameter(program, gl.LINK_STATUS) == 0)
					{
						var message = "Unable to initialize the shader program";
						message += "\n" + gl.getProgramInfoLog(program);
						Log.error(message);
					}
				}catch(e:Dynamic){
					#if traceShaderLineNumbers 
					if (e is String){
						// sowy

						var split:Array<String> = e.split('\n');

						var errorLog:Array<String> = [];
						var errorLines:Map<Int, Bool> = [];

						for (_ in 0...split.indexOf('')){
							var str = split.shift();
							errorLog.push(str);

							var parS = str.indexOf('(');
							if (parS == -1) continue;

							var parE = str.indexOf(')', parS);
							var line:String = str.substr(parS + 1, parE - parS);
							var lineVal = Std.parseInt(line);

							if (lineVal != null)
								errorLines.set(lineVal, true);
						}

						for (n in 1...split.length)
							split[n] = (errorLines.exists(n) ? 'Error here ->' : '($n)') + split[n];

						e =	split.join('\n') + '\n\n' + errorLog.join('\n');
					}
					#end
					
					trace(e);
				}

				return program;
			}
		});
		#end
	}
}
#end