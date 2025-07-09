uniform vec2 res;
uniform vec2 dir;


//weights and offsets for a 9-pixel gaussian filter using built-in linear interpolation to sample 2 pixels at once
uniform float offset[3] = float[](0.0, 1.3846153846, 3.2307692308);
uniform float weight[3] = float[](0.2270270270, 0.3162162162, 0.0702702703);

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	vec4 value = Texel(tex, texture_coords) * weight[0];
    //vec4 value = Texel(tex, texture_coords);
    for (int i=1; i<3; i++) {
        value += Texel(tex, texture_coords + dir * offset[i] / res) * weight[i];
		value += Texel(tex, texture_coords - dir * offset[i] / res) * weight[i];
    }
    return value;
}
