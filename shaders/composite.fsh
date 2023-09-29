#version 120

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

vec2 getFishEyeCoord(vec2 positionInNdcCoord) {
    return positionInNdcCoord / (0.15 + 0.85*length(positionInNdcCoord.xy));
}

bool visible(vec4 worldPos) {
    vec4 shadowPos = shadowProjection * shadowModelView * worldPos;
    shadowPos /= shadowPos.w; // NDC

    shadowPos = shadowPos * 0.5 + 0.5; // Screen space

    float realDepth = shadowPos.z;

//    shadowPos.xy = getFishEyeCoord(shadowPos.xy);

    float shadowDepth = texture2D(shadow, shadowPos.xy).r;

//    // too far away,
//    if (shadowDepth > 0.999) {
//        return false;
//    }

    if (realDepth - shadowDepth > EPSILON) {
        return false;
    } else {
        return true;
    }
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

    if (screenSpaceDepth < 1.0 && !visible(worldPos)) {
        color *= 0.5;
    }

//    vec4 sh = texture2D(shadow, texcoord.st);

    gl_FragData[0] = color;
}