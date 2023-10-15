#version 120

const int noiseTextureResolution = 128;
uniform sampler2D noisetex;
uniform vec3 cameraPosition;

uniform sampler2D texture;
uniform sampler2D depthtex0; // depth with water
uniform sampler2D depthtex1; // depth without water
uniform sampler2D gcolor;
uniform sampler2D shadow;
uniform sampler2D shadowtex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;
uniform vec3 shadowLightPosition; // shadow light (sun or moon) position in eye space

uniform float viewWidth;    // screen width in pixels
uniform float viewHeight;   // screen height in pixels

uniform float far; // around 225
uniform float near;

uniform int worldTime;

varying vec2 texcoord; // x,y is screen space coords, [0, 1]

#include "/visibility.glsl"

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

float getWave(vec4 trueWorldPos) {
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

    return noise2 * 0.4 + 0.6;    // 0.6 - 1.0
}

vec3 rayTrace(vec3 startPoint, vec3 direction) {
    // A bug causes reflections near the player to mess up. This (for an unknown reason) happens when vieReflection.z is positive
//    if (direction.z > 0) {
//        return vec3(0);
//    }

    vec3 point = startPoint;    // current point

    // 20 iterations
    int iteration = 100;
    for(int i=0; i<iteration; i++) {
        point += direction * 0.2;   // 0.1 is step length

        // view space -> screen space
        vec4 ndcPos = gbufferProjection * vec4(point, 1.0);
        ndcPos.xyz /= ndcPos.w;
        vec2 uv = ndcPos.xy*0.5 + 0.5;

        // beyond screen
        if (uv.x<0 || uv.x>1 ||
            uv.y<0 || uv.y>1) {
            return vec3(0);
        }

        float shadowMapDepth = texture2D(depthtex0, uv).x;
        float hitDepth = (ndcPos.z+1.0)*0.5;

        float depthTolerance = 0.0002;    // 0.01 is a good value

        // hit!
        if(shadowMapDepth < hitDepth && hitDepth > 0.56 && hitDepth < 1 && abs(shadowMapDepth - hitDepth) < depthTolerance) {
            return texture2D(texture, uv).rgb;
        }
    }

    return vec3(0);
}

vec3 drawWater(vec3 color, vec4 trueWorldPos, vec4 viewPos0, vec4 viewPos1, vec3 viewNormal, vec2 uv) {
    float wave = getWave(trueWorldPos);

    vec3 finalColor = color;
    finalColor *= wave;

    vec3 n = viewNormal;
    n.z += 0.05 * (((wave-0.4)/0.6) * 2 - 1);
    n = normalize(n);
    vec3 wi = normalize(-viewPos0.xyz);
    float cos = clamp(dot(wi, n), 0.0, 1.0);
    vec3 wo = 2 * cos * n - wi;

    vec3 reflectColor = rayTrace(viewPos0.xyz, wo);
        if(length(reflectColor)>0) {
            float fadeFactor = 1 - clamp(pow(abs(uv.x-0.5)*2, 2), 0, 1);
            finalColor = mix(finalColor, reflectColor, fadeFactor);
        }

    return finalColor;
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
        float viewDepth0 = calViewSpaceDepth(depth0 * 2 - 1, far, near);
        float viewDepth1 = calViewSpaceDepth(depth1 * 2 - 1, far, near);

        vec3 wi = normalize(-viewPos1.xyz);
        vec3 n = normalize(normal);
        float cos = clamp(dot(wi, n), 0.0, 1.0);
        vec3 wo = 2 * cos * n - wi;

        color.xyz = drawWater(color.xyz, trueWorldPos, viewPos0, viewPos1, normal, texcoord);

        float shadowBrightness = clamp((viewDepth1 - viewDepth0) * cos, 0.75, 1);

        color.xyz *= visibility(worldPos1, shadowtex1, shadowLightPosition, shadowModelView,
                    shadowProjection, shadowProjectionInverse, normal, far, near, shadowBrightness);
    }


    gl_FragData[0] = color;
    gl_FragData[1] = bloom;
}