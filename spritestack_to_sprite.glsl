uniform float cameraRot;
uniform float objectRot;
uniform float humidity;
uniform Image MainTex;
uniform Image normalMap;

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}



#ifdef VERTEX
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
	float rot = cameraRot - objectRot;
	float height = VertexColor.r * 256;
    vertex_position.xy = vec2(vertex_position.x * cos(-rot) - vertex_position.y * sin(-rot), vertex_position.x * sin(-rot) + vertex_position.y * cos(-rot));
    vertex_position.y *= 0.5;
	vertex_position += vec4(0, -height, 0, 0);
	return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL
void effect()
{
	vec4 texturecolor = Texel(MainTex, VaryingTexCoord.xy);
    vec3 normal = 2*Texel(normalMap, VaryingTexCoord.xy).rgb - 1;
	//dry up leaves
	if(texturecolor.a < 1){
		texturecolor.a = 0.01 + sqrt(rand(VaryingTexCoord.xy)) > (1-humidity) ? texturecolor.a : 0;
		texturecolor.rgb = mix(texturecolor.rgb, vec3(0.6, 0.5, 0.2), 1-humidity);
	}
    normal = vec3(normal.x * cos(objectRot) - normal.y * sin(objectRot), normal.x * sin(objectRot) + normal.y * cos(objectRot), normal.z);
    vec3 lightDir = normalize(vec3(1,1,1));
    float lightFactor = clamp(dot(lightDir, normal), 0, 1);

    love_Canvases[0] = texturecolor;
    love_Canvases[1] = vec4(lightFactor, VaryingColor.r, 0, texturecolor.a);
}
#endif