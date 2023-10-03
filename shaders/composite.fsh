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
    return positionInNdcCoord / (0.15 + 0.85*length(positionInNdcCoord.xy));
}

float visibility(vec4 worldPos) {
    // from world space to light's clip space
    vec4 shadowPos = shadowProjection * shadowModelView * worldPos;
    shadowPos /= shadowPos.w;

    float realDepth = shadowPos.z * 0.5 + 0.5;

    // PCF, because the shadow map is using fish eye coord,
    // so we need to sample in clip space, a pixel distance
    // in screen space is 1.0 / shadowMapResolution, so in
    // clip space, it is 2.0 / shadowMapResolution, we use
    // half of a pixel distance
    float pixelOffset = 1.0 / shadowMapResolution;
    float visible = 0.0;
    int radius = 1;

    for (int i = -radius; i <= radius; i++) {
        for (int j = -radius; j <= radius; j++) {
                vec4 offset = vec4(i, j, 0, 0) * pixelOffset;
                vec4 shadowPosOffset = shadowPos + offset;
                shadowPosOffset.xy = getFishEyeCoord(shadowPosOffset.xy); // change to fish eye coord when in NDC
                shadowPosOffset = shadowPosOffset * 0.5 + 0.5; // Clip space to Screen space

                //debug
//                shadowPosOffset = shadowPosOffset + offset;

                float sDepth = texture2D(shadow, shadowPosOffset.xy).r;

                if (realDepth - sDepth <= EPSILON) {
                    visible += 1.0;
                }
        }
    }
    visible /= pow(radius * 2 + 1, 2);

//    shadowPos.xy = getFishEyeCoord(shadowPos.xy); // change to fish eye coord when in NDC
//    shadowPos = shadowPos * 0.5 + 0.5; // Clip space to Screen space
//    float realDepth = shadowPos.z;
//
//    float shadowDepth = texture2D(shadow, shadowPos.xy).r;

    return  (1 - SHADOW_STRENGTH) * visible + SHADOW_STRENGTH; // visibility is [SHAODW_STRENGTH, 1]
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

    if (screenSpaceDepth < 1.0) {
        color *= visibility(worldPos);
    }

    gl_FragData[0] = color;
}