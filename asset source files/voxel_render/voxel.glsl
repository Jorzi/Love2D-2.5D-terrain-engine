#pragma language glsl3
uniform vec3 size;
uniform VolumeImage volume;
uniform VolumeImage volume_nor;
uniform VolumeImage volume_ao;
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

float shadowRay(vec3 coords, vec3 lightDir, float maxLod){
    float alpha = 0;
    float lod = 0;
    while(min3(coords) >= 0.0 && max3(coords) <= 1.0 ){
        
        alpha = textureLod(volume, coords, lod).a;
        if(alpha == 0){
            lod = min(lod+1, maxLod);
            coords += pow(2, lod) * lightDir.xyz/size;
        }else if(lod==0){
            return 0;
        }else{
            lod -= 1;
            coords -= pow(2, lod) * lightDir.xyz/size;
        }
    }
    return 1;
}

#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	//vec4 texturecolor = Texel(tex, texture_coords);
    //vec3 coords = VaryingTexCoord.xyz + N*traverseVector.xyz/size;
    vec3 coords = VaryingTexCoord.xyz;
    vec3 normal = vec3(0,0,1);
    float AO = 1;
    float lod = 3;
    float maxLod = 5;
    vec4 texturecolor;
    float lambertFactor = 1;
    while(min3(coords) >= 0.0 && max3(coords) <= 1.0 ){
        texturecolor  = textureLod(volume, coords, lod);
        if(texturecolor.a == 0){
            lod = min(lod+1, maxLod);
            coords += pow(2, lod) * traverseVector.xyz/size;
        } else if(lod==0){
            texturecolor.a = 1;
            normal = Texel(volume_nor, coords).rgb * 2 - 1;
            AO = Texel(volume_ao, coords).r;
            lambertFactor = max(0, dot(normal, lightDir));
            if(lambertFactor > 0){
                coords += -traverseVector.xyz/size + lightDir.xyz/size;
                lambertFactor = lambertFactor * shadowRay(coords, lightDir, maxLod);
            }
            
            break;
        }else{
            lod -=1;
            if(coords != VaryingTexCoord.xyz){
                coords -= pow(2, lod) * traverseVector.xyz/size;
            }
        }
    }
    AO = clamp(AO*2, 0, 1);
    texturecolor.rgb = texturecolor.rgb * (lambertFactor*0.5 + AO*0.5);
    //return mix(texturecolor, VaryingTexCoord, 0.2);
    return texturecolor;
}
#endif