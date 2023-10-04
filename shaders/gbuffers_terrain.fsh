#version 120

uniform sampler2D lightmap;
uniform sampler2D texture;
uniform sampler2D shadow;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;
uniform vec3 shadowLightPosition; // shadow light (sun or moon) position in eye space

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying vec3 viewNormal;
varying vec4 worldPosition;

#include "/visibility.glsl"

void main() {
	vec4 color = texture2D(texture, texcoord) * glcolor;
	vec4 worldPos = worldPosition;
	vec2 lm = lmcoord;

	lm.y *= visibility(worldPos, shadow, shadowLightPosition, shadowModelView, shadowProjection, viewNormal);

	color *= texture2D(lightmap, lm);

/* DRAWBUFFERS:0 */
	gl_FragData[0] = color; //gcolor
}