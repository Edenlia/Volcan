#version 120

uniform sampler2D colortex0;
uniform sampler2D colortex1;

uniform int worldTime;

uniform ivec2 eyeBrightness;
uniform ivec2 eyeBrightnessSmooth;

varying vec4 texcoord;

vec4 getScaleInverse(sampler2D src, vec2 pos, vec2 anchor, int fact) {
    return texture2D(src, pos/pow(2, fact)+anchor);
}

vec3 exposure(vec3 color, float factor) {
    float skylight = float(eyeBrightnessSmooth.y)/240;
    skylight = pow(skylight, 6.0) * factor + (1.0f-factor);
    return color / skylight;
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

    vec4 bloom = vec4(vec3(0), 1);
    bloom.rgb += getScaleInverse(colortex1, texcoord.st, vec2(0.0, 0), 2).rgb * pow(7, 0.25);
    bloom.rgb += getScaleInverse(colortex1, texcoord.st, vec2(0.3, 0), 3).rgb * pow(6, 0.25);
    bloom.rgb += getScaleInverse(colortex1, texcoord.st, vec2(0.5, 0), 4).rgb * pow(5, 0.25);
    bloom.rgb += getScaleInverse(colortex1, texcoord.st, vec2(0.6, 0), 5).rgb * pow(4, 0.25);
    bloom.rgb += getScaleInverse(colortex1, texcoord.st, vec2(0.7, 0), 6).rgb * pow(3, 0.25);
    bloom.rgb += getScaleInverse(colortex1, texcoord.st, vec2(0.8, 0), 7).rgb * pow(2, 0.25);
    bloom.rgb += getScaleInverse(colortex1, texcoord.st, vec2(0.9, 0), 8).rgb * pow(1, 0.25);
    bloom.rgb = pow(bloom.rgb, vec3(1/2.2));

    // interpolate the night value
    float isNight = 0;  // 0: day, 1: night
    if(12000<worldTime && worldTime<13000) {
        isNight = 1.0 - (13000-worldTime) / 1000.0; // evening
    }
    else if(13000<=worldTime && worldTime<=23000) {
        isNight = 1;    // night
    }
    else if(23000<worldTime) {
        isNight = (24000-worldTime) / 1000.0;   // dawn
    }

    color.rgb += bloom.rgb * ((0.3 * isNight) + 0.2); // 0.2: day, 0.5: night
    // exposure
    color.rgb = exposure(color.rgb, 0.25);
    // tone mapping
//    color.rgb = ACESToneMapping(color.rgb, 1);
    gl_FragData[0] = color;

//    vec4 testColor = texture2D(colortex1, texcoord.st);
//    testColor.rgb += getScaleInverse(colortex1, texcoord.st, vec2(0.0, 0), 2).rgb * pow(7, 0.25);
//    gl_FragData[0] = testColor;
}