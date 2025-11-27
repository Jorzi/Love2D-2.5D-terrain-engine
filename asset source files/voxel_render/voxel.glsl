#ifdef VERTEX
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
    vertex_position = TransformMatrix * vertex_position;
    vertex_position.y *= 0.5;
	vertex_position.y -= vertex_position.z;
	return ProjectionMatrix * vertex_position;
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	vec4 texturecolor = Texel(tex, texture_coords);
    return vec4(texturecolor.rgb, texturecolor.a);
}
#endif