#version 120

uniform sampler2D colortex0;
uniform sampler2D colortex1;

uniform float viewWidth;
uniform float viewHeight;

varying vec4 texcoord;

/* DRAWBUFFERS: 01 */
void main() {
    vec4 color = texture2D(colortex0, texcoord.st);
    gl_FragData[0] = color;

    vec4 bloom = texture2D(colortex1, texcoord.xy);
    gl_FragData[1] = bloom;
}