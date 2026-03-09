


#ifdef VERTEX
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
	vertex_position.y *= .5;
	return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	float opacity = Texel(tex, texture_coords).b;
    return vec4(0,0,0, opacity);
}
#endif