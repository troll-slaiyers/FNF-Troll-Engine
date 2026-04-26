package funkin.objects.shaders;

class CoolBGShader extends FlxShader {
	@:glFragmentSource('
#pragma header

uniform float iTime;

const vec4 gridColor1 = vec4(vec3(1.0), 1.0);
const vec4 gridColor2 = vec4(vec3(0.75), 1.0);

const vec4 colorTransformMult = vec4(-vec3(1.0), 1.0);

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
		
		return vec4 (color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
	}
	
	return color * openfl_Alphav;
}

vec4 getGridColor(vec2 uv) {
    vec2 RESOLUTION_RESCALE = vec2(openfl_TextureSize.x / openfl_TextureSize.y, 1.0);
    
    vec2 gridScale = vec2(3.0, 3.0);
    gridScale *= RESOLUTION_RESCALE;
    
    uv -= vec2(iTime * 0.02) * vec2(1.0, -1.0);
    
    vec2 um = mod(uv * gridScale, vec2(1.0));
    float sowy = mix(um.x, 1.0 - um.x, um.y);
    
    return mix(gridColor1, gridColor2, sowy);
}

void main()
{
    vec2 uv = openfl_TextureCoordv;
	vec4 color = flixel_color();
	vec4 colorTransformAdd = vec4(vec3(1.0) + color.xyz / 3.0, 0.0);

    vec4 texColor = texture2D(bitmap, uv);
    vec4 grad = vec4(vec3(uv.y), 1.0);
    texColor = (texColor * colorTransformMult) + colorTransformAdd;
    
    gl_FragColor = (grad + getGridColor(uv) * 0.5 * color) * texColor;
}
	')
	public function new() {
		super();
	}
}