uniform vec3 size;
uniform VolumeImage volume;
varying vec3 traverseVector; 

float max3 (vec3 v) {
  return max (max (v.x, v.y), v.z);
}
float min3 (vec3 v) {
  return min (min (v.x, v.y), v.z);
}

#ifdef VERTEX
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
    traverseVector = transpose(mat3(TransformMatrix)) * transpose(mat3(rot60)) * vec3(0, 0, -1);
	return (rot60 * ProjectionMatrix * vertex_position)*vec4(1, 1, 0.01, 1);
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	//vec4 texturecolor = Texel(tex, texture_coords);
    float N = 0.5;
    vec3 coords = VaryingTexCoord.xyz + N*traverseVector.xyz/size;
    vec4 texturecolor = Texel(volume, coords);
    while(min3(coords) >= 0.0 && max3(coords) <= 1.0 ){
        if(texturecolor.a > 0.5){
            texturecolor.a = 1;
            break;
        }
        N+=1;
        coords = VaryingTexCoord.xyz + N*traverseVector.xyz/size;
        texturecolor = Texel(volume, coords);
    }
    return texturecolor;
}
#endif