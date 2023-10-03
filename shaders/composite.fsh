#version 120

const int shadowMapResolution = 1024;

uniform sampler2D texture;
uniform sampler2D depthtex0;
uniform sampler2D shadow;

uniform float far;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;

varying vec4 texcoord; // x,y is screen space coords, [0, 1]

#define EPSILON 5e-5
#define SHADOW_STRENGTH 0.5

vec2 getFishEyeCoord(vec2 positionInNdcCoord) {
    return positionInNdcCoord / (0.1 + length(positionInNdcCoord.xy));
}

float useShadowMap(sampler2D shadowMap, vec4 ndcPos, float viewObjDepth) {
    // The fish eye function applied in ndc space, so we need to
    // change the ndcPos to fish eye coord first and then change
    // the range from [-1, 1] to [0, 1]
    vec2 uv = getFishEyeCoord(ndcPos.xy) * 0.5 + 0.5;

    float shadowMapDepth = texture2D(shadowMap, uv).r;

    if (viewObjDepth - shadowMapDepth <= EPSILON) {
        return 1.0;
    } else {
        return SHADOW_STRENGTH;
    }
}

float PCF(sampler2D shadowMap, vec4 ndcPos, float viewObjDepth) {
    // PCF, because the shadow map is using fish eye coord,
    // so we need to sample in clip space, a pixel distance
    // in screen space is 1.0 / shadowMapResolution, so in
    // clip space, it is 2.0 / shadowMapResolution, we use
    // 1/4 a pixel distance
    float pixelOffset = 0.5 / shadowMapResolution;
    float visible = 0.0;
    int radius = 1;

    for (int i = -radius; i <= radius; i++) {
        for (int j = -radius; j <= radius; j++) {
            vec4 offset = vec4(i, j, 0, 0) * pixelOffset;
            vec4 sampledPos = ndcPos + offset;
            vec2 sampledUV = getFishEyeCoord(sampledPos.xy) * 0.5 + 0.5;

            float shadowMapDepth = texture2D(shadowMap, sampledUV).r;

            if (viewObjDepth - shadowMapDepth <= EPSILON) {
                visible += 1.0;
            }
        }
    }
    visible /= pow(radius * 2 + 1, 2);

    return (1 - SHADOW_STRENGTH) * visible + SHADOW_STRENGTH; // visibility is [SHAODW_STRENGTH, 1]
}

float PCSS() {
    return 0.0;
}


// find the visibility of pos, ranged in [SHADOW_STRENGTH, 1]
// using shadow map.
float visibility(vec4 worldPos, sampler2D shadowMap) {
    // from world space to light's clip space
    vec4 ndcPos = shadowProjection * shadowModelView * worldPos;
    ndcPos /= ndcPos.w;

    float viewObjDepth = ndcPos.z * 0.5 + 0.5;

//    return useShadowMap(shadowMap, ndcPos, viewObjDepth);
    return PCF(shadowMap, ndcPos, viewObjDepth);
}


void main() {
    vec4 color = texture2D(texture, texcoord.st);
    float screenSpaceDepth = texture2D(depthtex0, texcoord.st).r; // [0, 1]

    vec4 screenSpaceCoord = vec4(texcoord.xy, screenSpaceDepth, 1.0);
    vec4 ndcPos = screenSpaceCoord * 2.0 - 1.0;
    vec4 viewPos = gbufferProjectionInverse * ndcPos;
    viewPos /= viewPos.w;
    vec4 worldPos = gbufferModelViewInverse * viewPos;

    worldPos /= worldPos.w;

    // if the fragment is in front of the far plane, that means
    // it is the sky, so we don't need to do shadow test
    if (screenSpaceDepth < 1.0) {
        color *= visibility(worldPos, shadow);
    }

    gl_FragData[0] = color;
}