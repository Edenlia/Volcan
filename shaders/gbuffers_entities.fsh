#version 120

uniform sampler2D lightmap;
uniform sampler2D texture;
uniform vec4 entityColor;
uniform sampler2D shadow;
uniform sampler2D shadowtex1;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;
uniform vec3 shadowLightPosition; // shadow light (sun or moon) position in eye space

uniform float far; // around 225
uniform float near;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying vec3 viewNormal;
varying vec4 worldPosition;

#include "/visibility.glsl"

void main() {
	vec4 color = texture2D(texture, texcoord) * glcolor;
	color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);
	vec4 worldPos = worldPosition;
	vec2 lm = lmcoord;

	lm.y *= visibility(worldPos, shadowtex1, shadowLightPosition, shadowModelView, shadowProjection,
					shadowProjectionInverse, viewNormal, far, near, DEFAULT_SHADOW_BRIGHTNESS);

	color *= texture2D(lightmap, lm);

/* DRAWBUFFERS:0 */
	gl_FragData[0] = color; //gcolor
}