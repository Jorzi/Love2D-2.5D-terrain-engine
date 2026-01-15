#pragma language glsl3
uniform VolumeImage volume;
uniform float zcoord;
uniform float maxLOD;
uniform vec3 size;


#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    // The order of operations matters when doing matrix multiplication.
    return transform_projection * vertex_position;
}
#endif

float max3 (vec3 v) {
  return max (max (v.x, v.y), v.z);
}
float min3 (vec3 v) {
  return min (min (v.x, v.y), v.z);
}

#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	
	vec3 coords = vec3(texture_coords, zcoord);
    if(Texel(volume, coords).a == 0)discard; //don't calculate normals for empty voxels

    float illumination = 0;
    float limit = 1;
    float stepSize = 1;
    for(float x = -limit; x <= limit; x += stepSize){
        for(float y = -limit; y <= limit; y += stepSize){
            for(float z = -limit; z <= limit; z += stepSize){
                vec3 offset = vec3(x, y, z);
                if(offset != vec3(0,0,0)){
                    float alpha = textureLod(volume, coords+offset/size, 0).a;
                    float light = 1 - alpha;
                    for(float i = 1; i <= maxLOD; i++){
                        vec3 offsetCoords = coords+offset/size*pow(2, i);
                        if(min3(offsetCoords) < 0.0 || max3(offsetCoords) > 1.0 ) break;
                        alpha = textureLod(volume, offsetCoords, i).a;
                        light *= 1 - alpha;
                        if(light < 0.01) break;
                    }
                    illumination += light/26;
                }
            }
        }
    }

    return vec4(illumination, illumination, illumination, 1);
}
#endif