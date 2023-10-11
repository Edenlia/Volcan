#version 120

uniform sampler2D colortex0;
uniform sampler2D colortex1;

varying vec4 texcoord;

vec4 getScaleInverse(sampler2D src, vec2 pos, vec2 anchor, int fact) {
    return texture2D(src, pos/pow(2, fact)+anchor);
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

    color.rgb += bloom.rgb * 0.5;
    gl_FragData[0] = color;

//    vec4 testColor = texture2D(colortex1, texcoord.st);
//    testColor.rgb += getScaleInverse(colortex1, texcoord.st, vec2(0.0, 0), 2).rgb * pow(7, 0.25);
//    gl_FragData[0] = testColor;
}