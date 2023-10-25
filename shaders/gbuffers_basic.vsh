#version 120

uniform mat4 gbufferModelViewInverse;

varying vec2 lmcoord;
varying vec4 glcolor;
varying vec3 viewNormal;
varying vec4 worldPosition;

void main() {
	gl_Position = ftransform();
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
	viewNormal = gl_NormalMatrix * gl_Normal;
	worldPosition = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
}