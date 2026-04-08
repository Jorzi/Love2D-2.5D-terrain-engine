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

float max3 (vec3 v) {
  return max (max (v.x, v.y), v.z);
}
float min3 (vec3 v) {
  return min (min (v.x, v.y), v.z);
}

float raycast(vec3 coords, vec3 dir)
{
    float light = 1;
    for(float i = 2.5; i < length(size); i++){
        vec3 offsetCoords = coords+i*dir/size;
        if(min3(offsetCoords) < 0.0 || max3(offsetCoords) > 1.0 ) break;
        light *= 1 - Texel(volume, offsetCoords).a;
        if(light < 0.01) break;
    }
    return light;
}
#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	
	vec3 coords = vec3(texture_coords, zcoord);
    if(Texel(volume, coords).a == 0)discard; //don't calculate anything for empty voxels

    vec3 normal = vec3(0,0,0);
    float occlusionSum = 0;
    for(float x = -1; x <= 1; x += 1){
        for(float y = -1; y <= 1; y += 1){
            for(float z = -1; z <= 1; z += 1){
                vec3 offset = vec3(x, y, z);
                if(offset != vec3(0,0,0)){
                    float alpha = Texel(volume, coords + offset/size).a;
                    occlusionSum += alpha;
                    normal -= alpha * normalize(offset);
                }
            }
        }
    }
    normal = normalize(normal); //first normal is only used for AO calculation
    vec3 normal2 = normal;
    //coords += normal*occlusionSum/25/size;
    //coords += 0.2*normal/size;

    float illumination = 0;
    float limit = 4;
    //create ray directions according to a cube shell
    float N = 2*limit + 1;
    float numberOfRays = 6*N*N -12*N + 8;
    //top and bottom faces
    for(float x = -limit; x <= limit; x += 1){
        for(float y = -limit; y <= limit; y += 1){
            for(float z = limit; z <= limit; z += 2*limit){
                vec3 dir = normalize(vec3(x, y, z));
                illumination += raycast(coords, dir);
            }
        }
    }
    //left and right faces
    for(float x = -limit; x <= limit; x += 1){
        for(float y = -limit; y <= limit; y += 2*limit){
            for(float z = -floor(limit/2)+1; z <= limit-1; z += 1){
                vec3 dir = normalize(vec3(x, y, z));
                illumination += raycast(coords, dir);
            }
        }
    }
    //front and back faces
    for(float x = -limit; x <= limit; x += 2*limit){
        for(float y = -limit+1; y <= limit-1; y += 1){
            for(float z = -floor(limit/2)+1; z <= limit-1; z += 1){
                vec3 dir = normalize(vec3(x, y, z));
                illumination += raycast(coords, dir);
            }
        }
    }
    illumination /= numberOfRays;

    //reset coords and normal
    coords = vec3(texture_coords, zcoord);
    normal = vec3(0,0,0);
    limit = 2;
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
    return vec4(normalize(normal) * 0.5 + 0.5, illumination);
}
#endif