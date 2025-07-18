#define M_PI 3.1415926535897932384626433832795
uniform float objectRot;
uniform float cameraRot;
uniform vec3 objectWorldPos;
uniform vec2 screenSize;
uniform Image shadowmap;
uniform Image geomBuffer;
uniform Image normalMap;
varying vec2 localXY;
uniform float humidity;
uniform float Nmoisture;
uniform float Nangles;

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}



#ifdef VERTEX
vec4 position( mat4 transform_projection, vec4 vertex_position )
{

	localXY =  vertex_position.xy;
    float xShift = floor(objectRot/(2*M_PI)*Nangles) / Nangles;
    VaryingTexCoord.x += xShift;
    float yShift = floor(humidity*Nmoisture) / Nmoisture;
    VaryingTexCoord.y += yShift;
	return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	float height = objectWorldPos.z - (localXY.y - 5)/(255*5);
	vec3 groundCoords = Texel(geomBuffer, screen_coords/screenSize).rgb;
	if (height <= groundCoords.z) discard;
	vec4 texturecolor = Texel(tex, texture_coords);
	//dry up leaves
	/* if(texturecolor.a < 1){
		texturecolor.a = 0.01 + sqrt(rand(texture_coords)) > (1-humidity) ? texturecolor.a : 0;
		texturecolor.rgb = mix(texturecolor.rgb, vec3(0.6, 0.5, 0.2), 1-humidity);
	} */
	float shadowHeight = Texel(shadowmap, objectWorldPos.xy + 1.0/8000 * vec2(localXY.x * cos(cameraRot) , localXY.x * sin(cameraRot) )).r;

	vec3 nor = 2 * Texel(normalMap, texture_coords).rgb - 1;
    nor.y *=-1;
	nor = normalize(nor);

	vec3 lightDir = normalize(vec3(1,1,1));
	lightDir = vec3(lightDir.x * cos(cameraRot) - lightDir.y * sin(cameraRot), lightDir.x * sin(cameraRot) + lightDir.y * cos(cameraRot), lightDir.z);
	float lightFactor = clamp(0.8 * dot(lightDir, nor)+0.2, 0, 1);
	lightFactor *= (1 - clamp((shadowHeight - height + 0.001)*80, 0, 1));
	lightFactor = 0.7 * lightFactor + 0.3;
    return vec4(texturecolor.rgb * lightFactor, texturecolor.a);
}
#endif