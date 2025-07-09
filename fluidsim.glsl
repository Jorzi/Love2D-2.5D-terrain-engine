uniform vec2 res;
uniform float dt;
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
	//shallow water heightfield navier stokes (buggy)
	/* vec4 data = Texel(tex, texture_coords); //r = height, g = v_x, b = v_y
    vec2 step = 1.0/res;
    vec4 data1 = Texel(tex, texture_coords + vec2(step.x, 0));
    vec4 data2 = Texel(tex, texture_coords + vec2(0, step.y));
    float d1 = data1.g>0 ? data.r:data1.r;
    float d2 = data.g>0 ? data.r:data1.r;
    float d3 = data2.b>0 ? data.r:data2.r;
    float d4 = data.b>0 ? data.r:data2.r;

	float delta_height = (d1*data1.g - d2*data.g + d3*data2.b - d4*data.b) * dt;
    float delta_vx = data.r*(data1.r-data.r)*dt;
    float delta_vy = data.r*(data2.r-data.r)*dt;
    data.r += delta_height;
    data.g += delta_vx;
    data.b += delta_vy;
    data.gb *= 0.999; */

    //pipe method
    vec4 data = Texel(tex, texture_coords); //r = height, g = flow_x, b = flow_y
    float ground = Texel(terrain, texture_coords).r;
    vec2 step = 1.0/res;
    vec4 data1 = Texel(tex, texture_coords + vec2(step.x, 0));
    float ground1 = Texel(terrain, texture_coords + vec2(step.x, 0)).r;
    vec4 data2 = Texel(tex, texture_coords + vec2(0, step.y));
    float ground2 = Texel(terrain, texture_coords + vec2(0, step.y)).r;
    vec4 data3 = Texel(tex, texture_coords + vec2(-step.x, 0));
    vec4 data4 = Texel(tex, texture_coords + vec2(0, -step.y));
    //Assuming dx, A = 1
    //float delta_flow_x = max(data.r, data1.r)*(data.r-data1.r)*dt;
    float delta_flow_x = (data.r + ground - data1.r - ground1)*dt;

    //float delta_flow_y = max(data.r, data2.r)*(data.r-data2.r)*dt;
    float delta_flow_y = (data.r + ground - data2.r - ground2)*dt;

    float delta_height = (data3.g + data4.b - data.b - data.g) * dt;
    data.r += delta_height;
    data.r = max(0, data.r);
    
    data.g += delta_flow_x;
    data.g = clamp(data.g, -data1.r, data.r);
    data.b += delta_flow_y;
    data.b = clamp(data.b, -data2.r, data.r);
    data.gb *= pow(0.95, dt);
    //data.a = 1;
    return data;
}
#endif