package funkin.objects.shaders;

class WarmBGShader extends FlxShader {
	@:glFragmentSource("
#pragma header

vec4 flixel_color()
{
	vec4 color = vec4(1.0);
	if (!(hasTransform || openfl_HasColorTransform))
		return color;
	
	if (openfl_HasColorTransform || hasColorTransform)
	{
		color = vec4 (color.rgb / color.a, color.a);
		vec4 mult = vec4 (openfl_ColorMultiplierv.rgb, 1.0);
		color = clamp (openfl_ColorOffsetv + (color * mult), 0.0, 1.0);
		
		if (color.a == 0.0)
			return vec4 (0.0, 0.0, 0.0, 0.0);
		
		return vec4 (color.rgb * color.a, color.a);
	}
	
	return color;
}

void main() {
	// Background image
	gl_FragColor = texture2D(bitmap, openfl_TextureCoordv);
	
	// 14% alpha image over a white background // Actually changing it to 60% cuz it's barely visible lol
	gl_FragColor = mix(vec4(1.0, 1.0, 1.0, 1.0), gl_FragColor, 0.60);
	
	// Gradient, colored at the top, fades to vec4(1.0, 1.0, 1.0, 0.0) towards the bottom
	// Color is grabbed from the sprite.color property
	vec4 gradientColor = mix(flixel_color(), vec4(1.0, 1.0, 1.0, 0.0), openfl_TextureCoordv.y);
	
	// Multiply image color by gradient
	gl_FragColor = mix(gl_FragColor, gl_FragColor * vec4(gradientColor.rgb, 1.0), gradientColor.a);
	
	// Apply sprite.alpha
	gl_FragColor *= openfl_Alphav;
}
	")
	public function new() {
		super();
	}
}