uniform vec2 res;
uniform Image waterDepth;


vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	float depth = Texel(waterDepth, texture_coords).r;
	//float mask = clamp(1000*depth, 0, 1);
	float mask = float(depth > 0);

    return vec4(1-mask, 0, 0, 1);
}
