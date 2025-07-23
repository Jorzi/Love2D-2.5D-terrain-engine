#define M_PI 3.1415926535897932384626433832795
uniform float cameraRot;
uniform float objectRot;
uniform float humidity;
uniform float Nmoisture;
uniform float Nangles;

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}


#ifdef VERTEX
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
    float lightDir = radians(-45.0);
    float rot = objectRot+lightDir;
    float xShift = (floor(rot/(2*M_PI)*Nangles+0.5)+1) / Nangles;
    VaryingTexCoord.x += xShift;
    float yShift = floor(humidity*Nmoisture+0.5) / Nmoisture;
    VaryingTexCoord.y += yShift;
    lightDir = lightDir - cameraRot;
    vertex_position.xy = vec2(vertex_position.x * cos(lightDir) - vertex_position.y * sin(lightDir), vertex_position.x * sin(lightDir) + vertex_position.y * cos(lightDir));
    vertex_position.y *= 0.5;
	return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	float opacity = Texel(tex, texture_coords).a;
    return vec4(0,0,0, opacity);
}
#endif