#version 120

uniform mat4 gbufferModelViewInverse;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying vec3 viewNormal;
varying vec4 worldPosition;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
	viewNormal = gl_NormalMatrix * gl_Normal;
	// TODO: Understand the space of gl_Vertex and gbufferModelViewSpace
	// The space of gl_Vertex is strange,
	// if multiply gl_ModelViewMatrix, it can be changed to view space.
	// But if multiply gbufferModelViewMatrix that will be wrong.
	// Should know the difference between gl_ModelViewMatrix and gbufferModelViewMatrix.
	worldPosition = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
}