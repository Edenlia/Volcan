#version 120

const int noiseTextureResolution = 128;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform sampler2D noisetex;
uniform vec3 cameraPosition;

uniform sampler2D texture;
uniform sampler2D depthtex0; // depth with water
uniform sampler2D depthtex1; // depth without water
uniform sampler2D shadow;
uniform sampler2D gcolor;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;

uniform float viewWidth;    // screen width in pixels
uniform float viewHeight;   // screen height in pixels

uniform int worldTime;

varying vec2 texcoord; // x,y is screen space coords, [0, 1]

vec4 getBloomOriginColor(vec4 color) {
    // grey value
    float brightness = 0.299*color.r + 0.587*color.g + 0.114*color.b;
    if(brightness < 0.5) {
        color.rgb = vec3(0);
    }
    return color;
}

bool isBlockId(float entityId, int blockId) {
    return abs(entityId - float(blockId)) < 0.03; // rounding error
}

vec3 getWave(vec3 color, vec4 trueWorldPos) {
    // small wave
    float speed1 = float(worldTime) / (noiseTextureResolution * 15);
    vec3 coord1 = trueWorldPos.xyz / noiseTextureResolution;
    coord1.x *= 3;
    coord1.x += speed1;
    coord1.z += speed1 * 0.2;
    float noise1 = texture2D(noisetex, coord1.xz).x;

    // mixed wave
    float speed2 = float(worldTime) / (noiseTextureResolution * 7);
    vec3 coord2 = trueWorldPos.xyz / noiseTextureResolution;
    coord2.x *= 0.5;
    coord2.x -= speed2 * 0.15 + noise1 * 0.05;  // add noise1 to make it more random
    coord2.z -= speed2 * 0.7 - noise1 * 0.05;
    float noise2 = texture2D(noisetex, coord2.xz).x;

    // draw brightness
    color *= noise2 * 0.4 + 0.6;    // 0.6 - 1.0

    return color;
}

vec3 drawWaterWave(vec3 color, vec4 trueWorldPos, vec4 viewPos, vec3 viewNormal) {
//    trueWorldPos.xyz += cameraPosition;
    color.xyz = getWave(color.xyz, trueWorldPos);

    return color;
}

/* DRAWBUFFERS: 01 */
void main() {
    vec4 color = texture2D(texture, texcoord);
    vec4 bloom = color;

    float id = texture2D(colortex2, texcoord).x;

    // emissive objects
    if(isBlockId(id, 10089)) {
        bloom.rgb *= vec3(0.7, 0.4, 0.2);
    }
    // torch
    else if(isBlockId(id, 10090)) {

        float brightness = dot(bloom.rgb, vec3(0.2, 0.7, 0.1));
        if(brightness < 0.5) {
            bloom.rgb = vec3(0);
        }
        bloom.rgb *= (brightness-0.5)*2;
    }
    // other
    else {
        bloom.rgb *= 0.0;
    }

    // water
    // depth with water
    float depth0 = texture2D(depthtex0, texcoord).x;
    vec4 ndcPos0 = vec4(texcoord*2-1, depth0*2-1, 1);
    vec4 viewPos0 = gbufferProjectionInverse * ndcPos0;
    viewPos0 /= viewPos0.w;
    vec4 worldPos0 = gbufferModelViewInverse * viewPos0;

    // depth without water
    float depth1 = texture2D(depthtex1, texcoord).x;
    vec4 ndcPos1 = vec4(texcoord*2-1, depth1*2-1, 1);
    vec4 viewPos1 = gbufferProjectionInverse * ndcPos1;
    viewPos1 /= viewPos1.w;
    vec4 worldPos1 = gbufferModelViewInverse * viewPos1;

    vec4 temp = texture2D(colortex4, texcoord);
    vec3 normal = temp.xyz * 2 - 1;
    float isWater = temp.w;
    vec4 trueWorldPos = worldPos0 + vec4(cameraPosition, 0);
    if(isWater == 1.0) {
        color.xyz = drawWaterWave(color.xyz, trueWorldPos, viewPos0, normal);
//        color = vec4(1.0);
    }


    gl_FragData[0] = color;
    gl_FragData[1] = bloom;
}