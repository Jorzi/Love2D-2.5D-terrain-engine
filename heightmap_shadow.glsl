uniform vec2 res;
uniform vec3 lightDir;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	float height = Texel(tex, texture_coords).r;
	vec3 light = normalize(lightDir);
	light /= vec3(res, 256/2);
	float maxHeight = height;
	int n = 0;
	for(float i=light.z; i<=1-height; i+=light.z){
		n++;
		height = Texel(tex, texture_coords + n*light.xy).r;
		maxHeight = max(maxHeight, height-i);
	}
	
    return vec4(maxHeight, 0, 0, 1);
}
