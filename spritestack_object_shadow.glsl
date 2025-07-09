uniform float cameraRot;
uniform float objectRot;
uniform float humidity;

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}


#ifdef VERTEX
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
	vec3 lightDir = normalize(vec3(1,1,1));
    float rot = cameraRot - objectRot;
	float height = VertexColor.r * 256;
    lightDir = vec3(lightDir.x * cos(-cameraRot) - lightDir.y * sin(-cameraRot), lightDir.x * sin(-cameraRot) + lightDir.y * cos(-cameraRot), lightDir.z);
    vertex_position.xy = vec2(vertex_position.x * cos(-rot) - vertex_position.y * sin(-rot), vertex_position.x * sin(-rot) + vertex_position.y * cos(-rot));
    vertex_position.y *= 0.5;
	vertex_position -= vec4(lightDir.xy * height / lightDir.z * vec2(1, 0.5), 0, 0);
	return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	float opacity = Texel(tex, texture_coords).a;
    //dry up leaves
	if(opacity < 1){
		opacity = 0.01 + sqrt(rand(texture_coords)) > (1-humidity) ? opacity : 0;
	}
    return vec4(0,0,0, opacity);
}
#endif