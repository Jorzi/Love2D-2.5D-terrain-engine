#pragma language glsl3
uniform vec3 size;
uniform VolumeImage volume;
uniform VolumeImage volume_nor;
varying vec3 traverseVector;
uniform float cameraRot;
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
    mat4 rotCamera = mat4(
        cos(-cameraRot), sin(-cameraRot), 0, 0,
        -sin(-cameraRot), cos(-cameraRot), 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    );
    vertex_position = rotCamera * vertex_position;
    float viewAngle = radians(60.0);
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
    traverseVector = transpose(mat3(TransformMatrix)) * transpose(mat3(rotCamera)) * transpose(mat3(rotView)) * vec3(0, 0, -0.5); //calculate view vector by inverse transforming a top-down vector
    lightDir = transpose(mat3(scaleRotMat)) * normalize(vec3(1,1,1)); //inverse transform light according to camera
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
void effect()
{
	//vec4 texturecolor = Texel(tex, texture_coords);
    //vec3 coords = VaryingTexCoord.xyz + traverseVector.xyz/size;
    vec3 coords = VaryingTexCoord.xyz;
    vec3 normal = vec3(0,0,1);
    float AO = 1;
    float lod = 3;
    float maxLod = 5;
    vec4 texturecolor = vec4(0,0,0,0);
    float lambertFactor = 1;
    float height = 0;
    vec4 tmp;
    while(min3(coords) >= 0.0 && max3(coords) <= 1.0 ){
        texturecolor  = textureLod(volume, coords, lod);
        if(texturecolor.a == 0){
            lod = min(lod+1, maxLod);
            coords += pow(2, lod) * traverseVector.xyz/size;
            while(lod > 0 && (min3(coords) < 0.0 || max3(coords) > 1.0 )){
                lod -=1;
                coords -= pow(2, lod) * traverseVector.xyz/size;
            }
        } else if(lod==0){
            texturecolor.a = 1;
            tmp = Texel(volume_nor, coords);
            normal = tmp.rgb * 2 - 1;
            normal = normalize(normal);
            AO = tmp.a;
            lambertFactor = max(0, dot(normal, lightDir));
            height = coords.z * size.z / 256;
            if(lambertFactor > 0){
                coords += normal.xyz/size + 5*lightDir.xyz/size; //shadow bias
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
    AO = clamp(pow(AO, 0.5)*1.9, 0.1, 1);
    texturecolor.rgb = texturecolor.rgb * AO;

    love_Canvases[0] = texturecolor;
    //love_Canvases[0] = vec4(tmp.rgb, texturecolor.a);
    love_Canvases[1] = vec4(lambertFactor, height, 0, texturecolor.a);
}
#endif