uniform vec2 res;
uniform Image heightmap;

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
    float height = Texel(heightmap, texture_coords).r;
    vec4 data_out = data; //depth, flow x, flow y, ground moisture

    //water absorption
    if(data.r > 0) {
        data_out.a = 1;
        float diff = 1-data.a;
        data_out.r = max(data.r - diff/4096, 0);
    }

    //diffusion
    float sumWeight = 1;
    for (int i = 0; i < 4; i++){
        vec4 data1 = Texel(tex, texture_coords + sample_points[i]*step);
        float height1 = Texel(heightmap, texture_coords + sample_points[i]*step).r;
        //float weight = 0.2+(8*(height1 - height));
        float weight = 0.2;
        weight = clamp(weight, 0, 2);
        data_out.a += data1.a*weight;
        sumWeight += weight;
    }
    data_out.a /= sumWeight;

    //evaporation
    data_out.a = data_out.a*0.9995 - 0.000005;
    data_out.a = max(data_out.a, 0);

    return data_out;
}
#endif