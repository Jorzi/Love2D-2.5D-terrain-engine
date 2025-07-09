uniform Image terrain;
uniform Image fluidBuffer;
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
    vec4 texturecolor = Texel(tex, screen_coords/res);
    vec4 ground = Texel(terrain, screen_coords/res);
    vec4 fluid = Texel(fluidBuffer, screen_coords/res);
    float target = max(color.r - ground.r, 0);
    //if (target <= 0) discard;
    //fluid.r = target;
    return vec4(target, fluid.g, fluid.b, 1);
}
#endif