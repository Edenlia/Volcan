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

vec3 blooming(vec2 texcoord, int radius) {
    vec3 sum = vec3(0);

    for(int i=-radius; i<=radius; i++) {
        for(int j=-radius; j<=radius; j++) {
            vec2 offset = vec2(i/viewWidth, j/viewHeight);
            sum += getBloomOriginColor(texture2D(texture, texcoord.st+offset)).rgb;
        }
    }

    sum /= pow(radius+1, 2);
    return sum*0.3;
}

void main() {
    vec4 color = texture2D(texture, texcoord);

    color.rgb += blooming(texcoord, 15);

    gl_FragData[0] = color;
}