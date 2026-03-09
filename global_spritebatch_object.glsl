#define M_PI 3.1415926535897932384626433832795
uniform float cameraRot;
//uniform vec3 objectWorldPos;
uniform vec2 screenSize;
uniform Image shadowmap;
uniform Image geomBuffer;
uniform Image normalMap;
varying vec2 localXY;




#ifdef VERTEX
vec4 position( mat4 transform_projection, vec4 vertex_position )
{

	localXY =  vertex_position.xy;
	return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	vec2 sunlight = Texel(normalMap, texture_coords).rg;
	vec3 objectWorldPos = color.xyz;
    float height = objectWorldPos.z + sunlight.g/5;
	vec3 groundCoords = Texel(geomBuffer, screen_coords/screenSize).rgb;
	if (height <= groundCoords.z) discard;
	vec4 texturecolor = Texel(tex, texture_coords);

	//float shadowHeight = Texel(shadowmap, objectWorldPos.xy + 1.0/8000 * vec2(localXY.x * cos(cameraRot) , localXY.x * sin(cameraRot) )).r;
	float shadowHeight = Texel(shadowmap, objectWorldPos.xy).r;

    
	float lightFactor = sunlight.r;
	lightFactor *= (1 - clamp((shadowHeight - height + 0.001)*80, 0, 1));
	lightFactor = 0.7 * lightFactor + 0.3;
    return vec4(texturecolor.rgb * lightFactor, texturecolor.a);
}
#endif