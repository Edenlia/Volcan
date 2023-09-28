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


bool visible(vec4 worldPos) {
    vec4 shadowPos = shadowProjection * shadowModelView * worldPos;
    shadowPos /= shadowPos.w; // NDC

    shadowPos = shadowPos * 0.5 + 0.5; // Screen space

    float realDepth = shadowPos.z;
    float shadowDepth = texture2D(shadow, shadowPos.xy).r;

    if (realDepth - shadowDepth > 0.001) {
        return false;
    } else {
        return true;
    }
}


void main() {
    vec4 color = texture2D(texture, texcoord.st);
    float screenSpaceDepth = texture2D(depthtex0, texcoord.st).r; // [0, 1]

    vec4 screenSpaceCoord = vec4(texcoord.xy, screenSpaceDepth, 1.0);
    vec4 ndcCoord = screenSpaceCoord * 2.0 - 1.0;
    vec4 worldPos = gbufferModelViewInverse * gbufferProjectionInverse * ndcCoord;

    worldPos /= worldPos.w;

    if (!visible(worldPos)) {
        color *= 0.5;
    }

    gl_FragData[0] = color;
}