#version 120

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

vec3 getWave(vec3 color, vec4 trueWorldPos) {
	// small wave
	float speed1 = float(worldTime) / (noiseTextureResolution * 15);
	vec3 coord1 = trueWorldPos.xyz / noiseTextureResolution;
	coord1.x *= 3;
	coord1.x += speed1;
	coord1.z += speed1 * 0.2;
	float noise1 = texture2D(noisetex, coord1.xz).x;

	// mixed wave
	float speed2 = float(worldTime) / (noiseTextureResolution * 7);
	vec3 coord2 = trueWorldPos.xyz / noiseTextureResolution;
	coord2.x *= 0.5;
	coord2.x -= speed2 * 0.15 + noise1 * 0.05;  // 加入第一个波浪的噪声
	coord2.z -= speed2 * 0.7 - noise1 * 0.05;
	float noise2 = texture2D(noisetex, coord2.xz).x;

	// draw brightness
	color *= noise2 * 0.6 + 0.4;    // 0.4 - 1.0

	return color;
}


/* DRAWBUFFERS:0 */
void main() {
	// if not water, just draw the texture
	if(!isBlockId(blockId, 10091)) {
		vec4 color = texture2D(texture, texcoord) * glcolor;
		color *= texture2D(lightmap, lmcoord);
		gl_FragData[0] = color;
		return;
	}

	vec4 trueWorldPos = gbufferModelViewInverse * viewPosition;
	trueWorldPos.xyz += cameraPosition;

	vec3 wi = normalize(-viewPosition.xyz);
	vec3 n = normalize(viewNormal);
	float ior = 0.08;

	float a = fresnel(wi, n, ior);

	vec4 color = vec4(0.1, 0.2, 0.4, 1.0);
	color *= texture2D(lightmap, lmcoord);
	color.w = a;
	color.xyz = getWave(color.xyz, trueWorldPos);

	gl_FragData[0] = color; //gcolor
}