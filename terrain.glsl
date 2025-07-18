uniform Image normalmap;
uniform Image shadowmap;
uniform Image cliffTex;
uniform Image terrainMasks;
uniform Image grassTex;
uniform Image sandTex;
uniform Image soilTex;
uniform Image soilmap;
uniform Image waterDepth;
uniform vec2 worldSize;
uniform vec2 cameraPos;


uniform float time;

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

// Simplex 2D noise
//
vec3 permute(vec3 x) { return mod(((x*34.0)+1.0)*x, 289.0); }

float snoise(vec2 v){
  const vec4 C = vec4(0.211324865405187, 0.366025403784439,
           -0.577350269189626, 0.024390243902439);
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);
  vec2 i1;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;
  i = mod(i, 289.0);
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
  + i.x + vec3(0.0, i1.x, 1.0 ));
  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy),
    dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;
  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}

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
	
	vec4 pos = Texel(tex, texture_coords); //object shadows in alpha channel
  pos.xy += cameraPos;
	float shadowHeight = Texel(shadowmap, pos.xy).r;

	//precomputed normal map
	vec3 nor = 2 * Texel(normalmap, pos.xy).rgb - 1;
	nor = normalize(nor);

  vec4 water = Texel(waterDepth, pos.xy);
  water.r = max(0, water.r);
  float waterLevel = water.r + pos.z;

	//dynamic water
  float waterMask = clamp(water.r * 256, 0, 1);
  vec3 waterNor = vec3(0,0,1);
  if(waterMask > 0){
    vec4 pos1 = Texel(tex, texture_coords + vec2(-0.5, -0.5)/worldSize);
    vec4 pos2 = Texel(tex, texture_coords + vec2(0.5, -0.5)/worldSize);
    vec4 pos3 = Texel(tex, texture_coords + vec2(-0.5, 0.5)/worldSize);
    vec3 tanX = vec3(0.01, 0, pos2.z-pos1.z);
	  vec3 tanY = vec3(0, 0.01, pos3.z-pos1.z);
	  waterNor = cross(tanX, tanY);
    waterNor = normalize(waterNor);
    nor = mix(nor, waterNor, waterMask);
  }
	//nor = mix(nor, waterNor, waterMask);
	
	vec3 lightDir = normalize(vec3(1,1,1));
	float lightFactor = clamp(dot(lightDir, nor), 0, 1);
	lightFactor *= (1 - clamp((shadowHeight - pos.z + 0.001)*100, 0, 1));
  lightFactor *= pos.a;
	lightFactor = 0.7 * lightFactor + 0.3;
	vec4 texturecolor = Texel(sandTex, pos.xy * worldSize/16);
	float waterEdge = Texel(terrainMasks, pos.xy).r * 4;
	float phaseOffset = snoise(pos.xy * worldSize/25) * 6;
	float wave = ((sin(8*waterEdge + 4*time + phaseOffset))*0.5 + 0.5)*clamp(waterEdge - 0.4, 0, 1);
	//vec4 waterColor = mix(vec4(100* water.g + 0.5, 100* water.b + 0.5, 1, 1), vec4(1, 1, 1, 1), wave); //debug colors
  float waterVelocity = clamp(80*length(water.gb), 0, 1);
  float waterTime = time*200;
  float repeatTime = 500;
  float blendFactor = abs(2*(mod(waterTime,repeatTime)/repeatTime)-1);
  float waterNoise = 0.5*mix(snoise(pos.xy * worldSize + 0.5 - water.gb*mod(waterTime,repeatTime)), snoise(pos.xy * worldSize - water.gb*mod(waterTime + repeatTime/2,repeatTime)), blendFactor)+0.5;
	vec4 waterColor = mix(mix(vec4(0.4 , 0.5, 0.9, 1), vec4(1, 1, 1, 1), waterVelocity*waterNoise), vec4(1, 1, 1, 1), wave);

	texturecolor = mix(texturecolor, Texel(grassTex, pos.xy * worldSize/20), clamp(clamp(2* water.a, 0, 1) - 30*(pos.z-waterLevel), 0, 1) );
  float soilMask = Texel(soilmap, pos.xy).r;
  texturecolor = mix(texturecolor, Texel(soilTex, pos.xy * worldSize/48), soilMask );
	vec4 cliff1 = Texel(cliffTex, vec2(pos.x * worldSize.x/16, pos.z*6));
	float mask = clamp(1.1*pow(nor.y, 2)-0.1, 0, 1);
	texturecolor = cliff1*mask + texturecolor*(1-mask);
	vec4 cliff2 = Texel(cliffTex, vec2(pos.y * worldSize.y/16, pos.z*6));
	mask = clamp(1.1*pow(nor.x, 2)-0.1, 0, 1);
	texturecolor = cliff2*mask + texturecolor*(1-mask);
	if(waterMask > 0) waterMask = clamp(waterMask + 0.3, 0, 1);
	texturecolor = mix(texturecolor, waterColor, waterMask);
	texturecolor.rgb = texturecolor.rgb * lightFactor;
	
    return texturecolor * color;
}
#endif