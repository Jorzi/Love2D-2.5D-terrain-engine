#pragma language glsl3
uniform vec3 size;
uniform VolumeImage volume;
varying vec3 traverseVector;

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
    traverseVector = transpose(mat3(TransformMatrix)) * transpose(mat3(rotView)) * vec3(0, 0, -0.5); //calculate view vector by inverse transforming a top-down vector
	return (vertex_position )*vec4(1, 1, 0.01, 1);
}
#endif


#ifdef PIXEL
void effect()
{
    vec3 coords = VaryingTexCoord.xyz;
    vec3 normal = vec3(0,0,1);
    float lod = 3;
    float maxLod = 5;
    vec4 texturecolor;
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
            break;
        }else{
            lod -=1;
            if(coords != VaryingTexCoord.xyz){
                coords -= pow(2, lod) * traverseVector.xyz/size;
            }
        }
    }
    love_Canvases[1] = vec4(0, 0, texturecolor.a, 1);
}
#endif