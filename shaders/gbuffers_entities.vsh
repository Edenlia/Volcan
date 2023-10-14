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
	// When a view pos multiply a gbufferModelViewInverse, it won't be changed to
	// world space, but a world space that set camera at origin.
	// Each worldPosition calculate in shadow map is in that space.
	worldPosition = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
}