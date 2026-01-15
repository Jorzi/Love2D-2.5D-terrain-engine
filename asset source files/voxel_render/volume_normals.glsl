uniform VolumeImage volume;
uniform float zcoord;
uniform vec3 size;


#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    // The order of operations matters when doing matrix multiplication.
    return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	
	vec3 coords = vec3(texture_coords, zcoord);
    if(Texel(volume, coords).a == 0)discard; //don't calculate normals for empty voxels

    vec3 normal = vec3(0,0,0);
    float limit = 2;
    float stepSize = 1;
    for(float x = -limit; x <= limit; x += stepSize){
        for(float y = -limit; y <= limit; y += stepSize){
            for(float z = -limit; z <= limit; z += stepSize){
                vec3 offset = vec3(x, y, z);
                if(offset != vec3(0,0,0)){
                    float alpha = Texel(volume, coords + offset/size).a;
                    normal -= alpha * normalize(offset)/pow(length(offset), 3);
                }
            }
        }
    }
    if (length(normal) < 1.0/256){
        normal = vec3(0,0,1);
    }
    return vec4(normalize(normal) * 0.5 + 0.5, 1);
}
#endif