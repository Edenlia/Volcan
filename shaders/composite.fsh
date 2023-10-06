#version 120

#define DRAW_SHADOW_MAP gcolor //Configures which buffer to draw to the screen [gcolor shadowcolor0 shadowtex0 shadowtex1]

uniform sampler2D texture;
uniform sampler2D depthtex0;
uniform sampler2D shadow;
uniform sampler2D gcolor;

uniform float viewWidth;    // screen width in pixels
uniform float viewHeight;   // screen height in pixels

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

void main() {
    vec4 color = texture2D(texture, texcoord);

    gl_FragData[0] = color;
    // write bright color to channel 1, for blooming
    gl_FragData[1] = getBloomOriginColor(color);
}