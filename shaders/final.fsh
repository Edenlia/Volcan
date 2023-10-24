#version 120

uniform sampler2D colortex0;
uniform sampler2D colortex1;

uniform int worldTime;

uniform ivec2 eyeBrightness;
uniform ivec2 eyeBrightnessSmooth;

varying vec4 texcoord;

vec3 exposure(vec3 color, float factor) {
    float eyeLight = float(max(eyeBrightnessSmooth.y, eyeBrightnessSmooth.x))/240;
    eyeLight = pow(eyeLight, 6.0) * factor + (1.0f-factor);
    return color / eyeLight;
}

vec3 ACESToneMapping(vec3 color, float adapted_lum) {
    const float A = 2.51f;
    const float B = 0.03f;
    const float C = 2.43f;
    const float D = 0.59f;
    const float E = 0.14f;
    color *= adapted_lum;
    return (color * (A * color + B)) / (color * (C * color + D) + E);
}

void main() {
    vec4 color = texture2D(colortex0, texcoord.st);

    // exposure
    color.rgb = exposure(color.rgb, 0.25);
    // tone mapping
//    color.rgb = ACESToneMapping(color.rgb, 1);
    gl_FragData[0] = color;

//    vec4 testColor = texture2D(colortex1, texcoord.st);
//    testColor.rgb += getScaleInverse(colortex1, texcoord.st, vec2(0.0, 0), 2).rgb * pow(7, 0.25);
//    gl_FragData[0] = testColor;
}