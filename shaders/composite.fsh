#version 120

#define DRAW_SHADOW_MAP gcolor //Configures which buffer to draw to the screen [gcolor shadowcolor0 shadowtex0 shadowtex1]

uniform sampler2D texture;
uniform sampler2D depthtex0;
uniform sampler2D shadow;
uniform sampler2D gcolor;

uniform float far;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;

uniform vec3 shadowLightPosition; // shadow light (sun or moon) position in eye space

varying vec2 texcoord; // x,y is screen space coords, [0, 1]

#include "/visibility.glsl"

#define EPSILON 5e-5

void main() {
    vec4 color = texture2D(texture, texcoord);
//    float screenSpaceDepth = texture2D(depthtex0, texcoord).r; // [0, 1]
//
//    vec4 screenSpaceCoord = vec4(texcoord, screenSpaceDepth, 1.0);
//    vec4 ndcPos = screenSpaceCoord * 2.0 - 1.0;
//    vec4 viewPos = gbufferProjectionInverse * ndcPos;
//    viewPos /= viewPos.w;
//    vec4 worldPos = gbufferModelViewInverse * viewPos;
//
//    worldPos /= worldPos.w;

    // if the fragment is in front of the far plane, that means
    // it is the sky, so we don't need to do shadow test
//    if (screenSpaceDepth < 1.0) {
//        color *= visibility(worldPos, shadow, shadowLightPosition, shadowModelView, shadowProjection);
//    }

//    float k = SHADOW_DISTORT_FACTOR;
//    vec4 debugColor = vec4(k, k, k, 1.0);

    gl_FragData[0] = color;
}