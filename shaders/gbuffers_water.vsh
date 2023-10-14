#version 120

attribute vec2 mc_Entity;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

uniform vec3 cameraPosition;

uniform int worldTime;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying float blockId;
varying vec3 viewNormal;
varying vec4 viewPosition;

bool isBlockId(float entityId, int blockId) {
	return abs(entityId - float(blockId)) < 0.03; // rounding error
}

vec4 getBump(vec4 viewPos) {
	vec4 worldPos = gbufferModelViewInverse * viewPos;
	worldPos.xyz += cameraPosition;

	worldPos.y += sin(float(worldTime*0.3) + worldPos.z + 2) * 0.05;

	worldPos.xyz -= cameraPosition;
	return gbufferModelView * worldPos;
}

void main() {
	viewNormal = gl_NormalMatrix * gl_Normal;
	viewPosition = gl_ModelViewMatrix * gl_Vertex;
	viewPosition /= viewPosition.w;

	if(mc_Entity.x == 10091) {
		gl_Position = gbufferProjection * getBump(viewPosition);
	}
	else {
		gl_Position = gbufferProjection * viewPosition;
	}

	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;

	blockId = mc_Entity.x;
}