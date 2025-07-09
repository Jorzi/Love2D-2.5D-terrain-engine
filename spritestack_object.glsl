uniform float cameraRot;
uniform float objectRot;
uniform vec3 objectWorldPos;
uniform vec2 screenSize;
uniform Image shadowmap;
uniform Image geomBuffer;
uniform Image normalMap;
varying vec2 localXY;
uniform float humidity;

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}



#ifdef VERTEX
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
	float rot = cameraRot - objectRot;
	float height = VertexColor.r * 256;
	localXY =  vec2(vertex_position.x * cos(objectRot) - vertex_position.y * sin(objectRot), vertex_position.x * sin(objectRot) + vertex_position.y * cos(objectRot));
    vertex_position.xy = vec2(vertex_position.x * cos(-rot) - vertex_position.y * sin(-rot), vertex_position.x * sin(-rot) + vertex_position.y * cos(-rot));
    vertex_position.y *= 0.5;
	vertex_position += vec4(0, -height, 0, 0);
	return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	float height = objectWorldPos.z + 0.4*color.r;
	vec3 groundCoords = Texel(geomBuffer, screen_coords/screenSize).rgb;
	if (height <= groundCoords.z) discard;
	vec4 texturecolor = Texel(tex, texture_coords);
	//dry up leaves
	if(texturecolor.a < 1){
		texturecolor.a = 0.01 + sqrt(rand(texture_coords)) > (1-humidity) ? texturecolor.a : 0;
		texturecolor.rgb = mix(texturecolor.rgb, vec3(0.6, 0.5, 0.2), 1-humidity);
	}
	float shadowHeight = Texel(shadowmap, objectWorldPos.xy + 1.0/8000 * localXY).r;

	vec3 nor = 2 * Texel(normalMap, texture_coords).rgb - 1;
	nor = normalize(nor);

	vec3 lightDir = normalize(vec3(1,1,1));
	lightDir = vec3(lightDir.x * cos(-objectRot) - lightDir.y * sin(-objectRot), lightDir.x * sin(-objectRot) + lightDir.y * cos(-objectRot), lightDir.z);
	float lightFactor = clamp(0.8 * dot(lightDir, nor)+0.2, 0, 1);
	lightFactor *= (1 - clamp((shadowHeight - height + 0.001)*80, 0, 1));
	lightFactor = 0.7 * lightFactor + 0.3;
    return vec4(texturecolor.rgb * lightFactor, texturecolor.a);
}
#endif