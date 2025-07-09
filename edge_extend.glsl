uniform vec2 res;
uniform Image terrain;

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

    vec2 step = 1.0/res;
    vec2[8] sample_points =  vec2[8](vec2(0,1), vec2(0,-1), vec2(1,0), vec2(-1,0), vec2(-1,-1), vec2(-1,1), vec2(1,1), vec2(1,-1));
    vec4 data = Texel(tex, texture_coords);
    if(data.r > 0) return data;
    float height = Texel(terrain, texture_coords).r;
    data.r += height;
    vec4 blur = vec4(0,0,0,0);
    int count = 0;
    for (int i = 0; i < 8; i++){
        vec4 data1 = Texel(tex, texture_coords + sample_points[i]*step);
        if(data1.r > 0){
            data1.r += Texel(terrain, texture_coords + sample_points[i]*step).r;
            blur +=data1;
            count += 1;
        }
    }
    if (count > 0){
        blur /= count;
        data.r = blur.r;
        //data.g = 1;
    }else{
        data.r -= height;
        return data;
    }
    data.r -= height;

    return data;
}
#endif