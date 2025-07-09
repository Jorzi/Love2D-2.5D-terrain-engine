uniform Image heightmap;
uniform Image objectShadows;
uniform Image waterDepth;
uniform vec2 cameraSize;
uniform vec2 pos;
uniform vec2 screenSize;
uniform float rot;
uniform float zscale;
//uniform float waterLevel;
varying vec2 flatPos;


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
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
	VaryingTexCoord.xy -= vec2(0.5, 0.5); //center camera pivot
	VaryingTexCoord.xy *= cameraSize;
	vec2 rotatedCamera = vec2(VaryingTexCoord.x * cos(rot) - VaryingTexCoord.y * sin(rot), VaryingTexCoord.x * sin(rot) + VaryingTexCoord.y * cos(rot));
	VaryingTexCoord.xy = rotatedCamera + pos;
	float height = Texel(heightmap, VaryingTexCoord.xy).r;
  float water = Texel(waterDepth, VaryingTexCoord.xy).r;
  water = max(water, 0);
	//height = max(height, waterLevel);
  height = height + water;
	height *=  256 * zscale;

  flatPos = vertex_position.xy;
	vertex_position.y -= height;
	return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	
	float height = Texel(heightmap, texture_coords).r;
  float water = Texel(waterDepth, texture_coords).r;
  water = max(water, 0);
  float shadow = Texel(objectShadows, flatPos/screenSize).r;
	//dynamic water
	height += water;
    return vec4(texture_coords - pos, height, shadow);
}
#endif