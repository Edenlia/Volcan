#version 120

// set color buffer4 to R32F format, only use R channel
const int R32F = 114;
const int colortex4Format = R32F;

const int noiseTextureResolution = 128;
uniform mat4 gbufferModelViewInverse;
uniform sampler2D noisetex;
uniform vec3 cameraPosition;

uniform sampler2D lightmap;
uniform sampler2D texture;

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

// Using Schlick's approximation to Fresnel
// ior is n2/n1
// https://en.wikipedia.org/wiki/Schlick%27s_approximation
float fresnel(vec3 I, vec3 N, float ior) {
	float cos = clamp(dot(I, N), 0.0, 1.0);
	float f0 = pow((1.0 - ior) / (1.0 + ior), 2.0);
	return f0 + (1.0 - f0) * pow(1.0 - cos, 5.0);
}

/* DRAWBUFFERS:024 */
void main() {

	if(isBlockId(blockId, 10091)) {
		vec3 wi = normalize(-viewPosition.xyz);
		vec3 n = normalize(viewNormal);
		float ior = 0.08;

		float a = fresnel(wi, n, ior);

		vec4 color = vec4(0.1, 0.2, 0.4, 1.0);
		color *= texture2D(lightmap, lmcoord);
		color.w = a;
		//		color = vec4(999);
		gl_FragData[0] = color; //gcolor
		gl_FragData[1] = vec4(n * 0.5 + 0.5, 1.0);
		gl_FragData[2] = vec4(blockId); //blockId
	}
	else { // if not water, just draw the texture
		vec4 color = texture2D(texture, texcoord) * glcolor;
		color *= texture2D(lightmap, lmcoord);
		vec3 n = normalize(viewNormal);
		gl_FragData[0] = color;
		gl_FragData[1] = vec4(n * 0.5 + 0.5, 1.0);
		gl_FragData[2] = vec4(0.0); //blockId
	}
}