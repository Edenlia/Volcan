#version 120

attribute vec4 mc_Entity;

uniform mat4 gbufferModelViewInverse;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying float blockId;
varying vec3 viewNormal;
varying vec4 worldPosition;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
	blockId = mc_Entity.x;
	viewNormal = gl_NormalMatrix * gl_Normal;
	worldPosition = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
}