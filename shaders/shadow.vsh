#version 120

varying vec4 texcoord;

#include "/shadow_util.glsl"

void main() {
    gl_Position = ftransform();
    gl_Position.xy = shadowDistort(gl_Position.xy);
    texcoord = gl_TextureMatrix[0] * gl_MultiTexCoord0;
}