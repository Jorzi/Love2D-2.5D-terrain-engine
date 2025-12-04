#ifdef VERTEX
varying vec4 traverseVector; 
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
    vertex_position.z *= (1.0/32); // looks like Love2d handles the z coordinate a bit differently
    vertex_position = TransformMatrix * vertex_position;
    //vertex_position.y *= 0.5;
	//vertex_position.y -= vertex_position.z*5;
    float cosTheta = cos(radians(60.0));
    float sinTheta = sin(radians(60.0));
    mat4 rot60 = mat4(
        1, 0, 0, 0,
        0, cosTheta, sinTheta, 0,
        0, -sinTheta, cosTheta, 0,
        0, 0, 0, 1
    );
    traverseVector = rot60 * TransformMatrix * vec4(0, 0, -1, 0);
	return (rot60 * ProjectionMatrix * vertex_position)*vec4(1, 1, 0.01, 1);
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	//vec4 texturecolor = Texel(tex, texture_coords);
    vec4 texturecolor = VaryingTexCoord;
    return vec4(texturecolor.rgb, texturecolor.a);
}
#endif