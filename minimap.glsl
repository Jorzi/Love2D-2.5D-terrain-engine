uniform Image fluidsim;

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

    vec3 nor = 2 * Texel(tex, texture_coords).xyz - 1;
    vec4 water = Texel(fluidsim, texture_coords);
    float waterMask = clamp(water.r * 256, 0, 1);
    nor = mix(nor, vec3(0,0,1), waterMask);
    vec3 lightDir = normalize(vec3(1,1,1));
	float lightFactor = clamp(dot(lightDir, nor), 0, 1);
	lightFactor = 0.5 * lightFactor + 0.5;
    float cliffmask = clamp(1.1*pow(nor.y, 2)+1.1*pow(nor.x, 2)-0.2, 0, 1);
    vec4 diffuse = vec4(0.8, 0.6, 0.4, 1);
    diffuse = mix(diffuse, vec4(0.2, 0.3, 0.1, 1), clamp(pow(water.a, 0.3)*1.2, 0, 1));
    diffuse = mix(diffuse, vec4(0.4, 0.3, 0.2, 1), cliffmask);
    diffuse = mix(diffuse, vec4(0.6, 0.4, 0.7, 1), waterMask);
    float waterDepth = water.r*50;
    if(waterDepth > 0) {
        waterDepth += 0.15;
    }
    waterDepth = clamp(waterDepth, 0, 1);
    diffuse = mix(diffuse, vec4(0.1, 0.3, 0.5, 1), waterDepth);
    return vec4(diffuse.rgb * lightFactor, 1);
}
#endif