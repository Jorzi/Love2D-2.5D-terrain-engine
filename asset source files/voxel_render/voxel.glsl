#pragma language glsl3
uniform VolumeImage volume;
uniform VolumeImage volume_nor;
uniform VolumeImage volume_ao;
uniform float viewAngle;
varying vec3 traverseVector;
varying vec3 lightDir;
ivec3 size = textureSize(volume, 0);


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


vec4 raycast(inout vec3 coords, vec3 dir, float maxLod){
    vec4 texturecolor = vec4(0,0,0,0);
    int lod = 0;
    int N = 0;
    float rNext = 0;

    ivec3 currentRes;
    vec3 pixelCoords;
    vec3 intCoords;
    float xNext;
    float yNext;
    float zNext;
    float r1;
    float r2;
    float r3;
    while(min3(coords) >= 0.0 && max3(coords) <= 1.0 && N < 512){
        texturecolor = textureLod(volume, coords, lod);
        N++;
        if(texturecolor.a == 0){
            if(textureLod(volume, coords, lod+1).a == 0 && lod < maxLod){
                lod++;
            }
            //find next intersection planes in x, y, z
            currentRes = textureSize(volume, lod);
            pixelCoords = coords * currentRes;
            intCoords = floor(pixelCoords);
            xNext = dir.x > 0 ? intCoords.x+1 - pixelCoords.x : intCoords.x - pixelCoords.x;
            yNext = dir.y > 0 ? intCoords.y+1 - pixelCoords.y : intCoords.y - pixelCoords.y;
            zNext = dir.z > 0 ? intCoords.z+1 - pixelCoords.x : intCoords.x - pixelCoords.x;
            //float maxDist = length(size);
            //r1 = dir.x != 0 ? xNext/dir.x : maxDist; //new glsl standard specifies that division by 0 is inf, but old one allows different values depending on the vendor implementation
            //r2 = dir.y != 0 ? yNext/dir.y : maxDist; //this calculation is ~10% slower, but guarantees predictable results on old hardware
            //r3 = dir.z != 0 ? zNext/dir.z : maxDist;
            r1 = xNext/dir.x; 
            r2 = yNext/dir.y;
            r3 = zNext/dir.z;
            rNext = min(min(r1, r2), r3); //choose closest plane
            coords += dir*(rNext/currentRes + 0.01/size); //move to the next intersection
        }else if(lod==0) {
            texturecolor.a = 1;
            return texturecolor;
        }else{
            lod--;
        }
    }
    return texturecolor;
}

#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{

    float maxLod = max(floor(log2(min3(size)))-3, 0);
    vec3 coords = clamp(VaryingTexCoord.xyz, vec3(0), 1-(0.1/size));
    vec3 normal = vec3(0,0,1);
    float AO = 1;
    vec4 texturecolor;
    float lambertFactor = 1;

    texturecolor = raycast(coords, traverseVector, maxLod);
    if (texturecolor.a == 0) discard;
    vec4 tmp = Texel(volume_nor, coords);
    normal = tmp.rgb * 2 - 1;
    AO = tmp.a;
    lambertFactor = max(0, dot(normal, lightDir));
    if(lambertFactor > 0){
        coords += normal.xyz/size + 5*lightDir.xyz/size; //shadow bias
        float shadowRay = raycast(coords, lightDir, maxLod).a == 0 ? 1 : 0;
        lambertFactor = lambertFactor * shadowRay;
    }
    AO = clamp(pow(AO, 0.5)*1.9, 0.1, 1);
    texturecolor.rgb = texturecolor.rgb * (lambertFactor*0.6 + AO*0.4);
    //return mix(texturecolor, VaryingTexCoord, 0.5);

    //return vec4(normal * 0.5 + 0.5, texturecolor.a);
    //return vec4(AO, AO, AO, texturecolor.a);
    return texturecolor;
}
#endif