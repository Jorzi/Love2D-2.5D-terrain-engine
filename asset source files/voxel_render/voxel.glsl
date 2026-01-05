uniform vec3 size;
uniform VolumeImage volume;
uniform VolumeImage volume_nor;
uniform float viewAngle;
varying vec3 traverseVector;
varying vec3 lightDir;

float max3 (vec3 v) {
  return max (max (v.x, v.y), v.z);
}
float min3 (vec3 v) {
  return min (min (v.x, v.y), v.z);
}

#ifdef VERTEX
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
    mat4 scaleRotMat = mat4(mat3(TransformMatrix)); //separate out translation from matrix
    vec4 translateVec = TransformMatrix[3];
    vertex_position = scaleRotMat * vertex_position; //apply scale & rotation

    float cosTheta = cos(viewAngle);
    float sinTheta = sin(viewAngle);
    mat4 rotView = mat4(
        1, 0, 0, 0,
        0, cosTheta, sinTheta, 0,
        0, -sinTheta, cosTheta, 0,
        0, 0, 0, 1
    );
    vertex_position = rotView * vertex_position; //additional rotation for "isometric" perspective
    vertex_position.xyz += translateVec.xyz; //apply translation
    vertex_position = ProjectionMatrix * vertex_position; //apply projection
    traverseVector = transpose(mat3(TransformMatrix)) * transpose(mat3(rotView)) * vec3(0, 0, -1); //calculate view vector by inverse transforming a top-down vector
    lightDir = transpose(mat3(TransformMatrix)) * normalize(vec3(1,1,1)); //inverse transform light
	return (vertex_position )*vec4(1, 1, 0.01, 1);
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	//vec4 texturecolor = Texel(tex, texture_coords);
    float N = 0.5;
    //vec3 coords = VaryingTexCoord.xyz + N*traverseVector.xyz/size;
    vec3 coords = VaryingTexCoord.xyz;
    vec3 normal = vec3(0,0,1);
    vec4 texturecolor = Texel(volume, coords);
    float lambertFactor = 1;
    while(min3(coords) >= 0.0 && max3(coords) <= 1.0 ){
        if(texturecolor.a > 0.5){
            texturecolor.a = 1;
            normal = Texel(volume_nor, coords).rgb * 2 - 1;
            lambertFactor = max(0, dot(normal, lightDir));
            if(lambertFactor > 0){
                float alpha = 0;
                coords += -traverseVector.xyz/size + lightDir.xyz/size;
                while(min3(coords) >= 0.0 && max3(coords) <= 1.0 ){
                    coords += lightDir.xyz/size;
                    alpha = Texel(volume, coords).a;
                    if(alpha > 0.5){
                        lambertFactor = 0;
                        break;
                    }
                }
            }
            break;
        }
        N+=1;
        coords += traverseVector.xyz/size;
        texturecolor = Texel(volume, coords);
    }
    texturecolor.rgb = texturecolor.rgb * (lambertFactor*0.7 + 0.3);
    return mix(texturecolor, VaryingTexCoord, 0.2) ;
}
#endif