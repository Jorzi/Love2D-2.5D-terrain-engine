uniform Image heightmap;
uniform Image normalmap;
uniform Image shadowmap;
uniform Image geomBuffer;
uniform vec2 cameraSize;
uniform vec2 pos;
uniform vec2 screenSize;
uniform float rot;
uniform float spriteRot;
uniform float zscale;
varying float height;

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}



#ifdef VERTEX
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
    vertex_position.xy = vec2(vertex_position.x * cos(-rot+spriteRot) - vertex_position.y * sin(-rot+spriteRot), vertex_position.x * sin(-rot+spriteRot) + vertex_position.y * cos(-rot+spriteRot));
    vertex_position.y *= 0.5;
    vec2 vertex_screen_coords = vec2(TransformMatrix * vertex_position).xy / vec2(screenSize.x, screenSize.y + 256 * zscale); //normalized screen space vertex
    vertex_screen_coords -= vec2(0.5, 0.5); //center camera pivot
    vertex_screen_coords *= cameraSize;  
    vec2 rotatedCamera = vec2(vertex_screen_coords.x * cos(rot) - vertex_screen_coords.y * sin(rot), vertex_screen_coords.x * sin(rot) + vertex_screen_coords.y * cos(rot));
    vertex_screen_coords = rotatedCamera + pos;
    height = Texel(heightmap, vertex_screen_coords).r;

    vertex_position.y -= height * 256 * zscale;
    return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	vec4 groundCoords = Texel(geomBuffer, screen_coords/screenSize);
    float bias = 1.0/256;
	if (height + bias < groundCoords.z) discard;
	vec4 texturecolor = Texel(tex, texture_coords);
	float shadowHeight = Texel(shadowmap, groundCoords.xy+pos).r;

	//precomputed normal map
	vec3 nor = 2 * Texel(normalmap, groundCoords.xy+pos).rgb - 1;
	nor = normalize(nor);

    vec3 lightDir = normalize(vec3(1,1,1));
	float lightFactor = clamp(dot(lightDir, nor), 0, 1);
	lightFactor *= (1 - clamp((shadowHeight - height + 0.001)*100, 0, 1));
    lightFactor *= groundCoords.a;
	lightFactor = 0.7 * lightFactor + 0.3;

    return color * vec4(texturecolor.rgb * lightFactor, texturecolor.a);
}
#endif