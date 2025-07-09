uniform vec2 res;

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
    vec2[4] sample_points =  vec2[4](vec2(0,1), vec2(0,-1), vec2(1,0), vec2(-1,0));
    vec4 data = Texel(tex, texture_coords);
    if(data.r == 0) return data;
    vec4 blur = vec4(0,0,0,0);
    for (int i = 0; i < 4; i++){
        vec4 data1 = Texel(tex, texture_coords + sample_points[i]*step);
        blur +=data1;
    }
    blur /= 4;
    blur.r = data.r;

    return 0.95 * data + 0.05 * blur;
}
#endif