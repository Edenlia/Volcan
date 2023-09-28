#version 120

uniform sampler2D texture;
uniform sampler2D depthtex0;

uniform float far;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

varying vec4 texcoord;

/* DRAWBUFFERS: 0 */
void main() {
    vec4 color = texture2D(texture, texcoord.st);

    // 获取当前像素深度
    float depth = texture2D(depthtex0, texcoord.st).x;

    // 利用深度缓冲建立带深度的ndc坐标
    vec4 positionInNdcCoord = vec4(texcoord.st*2-1, depth*2-1, 1);

    // 逆投影变换 -- ndc坐标转到裁剪坐标
    vec4 positionInClipCoord = gbufferProjectionInverse * positionInNdcCoord;

    // 透视除法 -- 裁剪坐标转到眼坐标
    vec4 positionInViewCoord = vec4(positionInClipCoord.xyz/positionInClipCoord.w, 1.0);

    // 逆 “视图模型” 变换 -- 眼坐标转 “我的世界坐标”
    vec4 positionInWorldCoord = gbufferModelViewInverse * positionInViewCoord;

    color.rgb *= positionInNdcCoord.x;

    gl_FragData[0] = color;
}