#version 120

uniform sampler2D texture;
uniform sampler2D depthtex0;
uniform sampler2D shadow;
uniform sampler2D gcolor;
uniform sampler2D colortex2;

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

bool isBlockId(float entityId, int blockId) {
    return abs(entityId - float(blockId)) < 0.03; // rounding error
}

/* DRAWBUFFERS: 01 */
void main() {
    vec4 color = texture2D(texture, texcoord);
    vec4 bloom = color;

    float id = texture2D(colortex2, texcoord.st).x;

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

    gl_FragData[0] = color;
    gl_FragData[1] = bloom;
}