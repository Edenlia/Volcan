#version 120

#include "/lib/math.glsl"

#define SSAO_STRENGTH 1.00              // SSAO Strength                                [0.00  0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]

uniform sampler2D colortex0; // Color Buffer
uniform sampler2D colortex2; // normal
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D gcolor;

uniform float near;
uniform float far;

uniform int frameCounter;

uniform mat4 gbufferModelView, gbufferModelViewInverse, gbufferPreviousModelView;
uniform mat4 gbufferProjection, gbufferProjectionInverse, gbufferPreviousProjection;

uniform vec2 screenSize;

varying vec2 texcoord;

float calViewSpaceDepth(float ndcDepth, float far, float near) {
	return 2 * near * far / ((far + near) - ndcDepth * (far - near));
}

float linearAttenuation(float depthDiff, float cutoff, float slope) {
	return clamp((cutoff - depthDiff) * slope, 0.0, 1.0);
}

//////////////////////////////////////////////////////////////////////////////
//                     SCREEN SPACE AMBIENT OCCLUSION
//////////////////////////////////////////////////////////////////////////////

float SSAO(vec3 screenPos, vec3 viewNormal, float filterSize) {
	vec4 ndcPos = vec4(screenPos * 2.0 - 1.0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * ndcPos;
	viewPos /= viewPos.w;
	float viewDepth = calViewSpaceDepth(ndcPos.z, far, near); // [near, far]
	float linearDepth = viewDepth / (far - near); // [0, 1]

	float hits = 0;

	float bayer = Bayer4(screenPos.xy * screenSize);
	float ditherTimesSize  = (fract(bayer + (float(frameCounter) * 0.136)) * 0.85 + 0.15) * filterSize;

//	float depthTolerance   = 0.075/-viewPos.z;

	for (int i = 0; i < 8; i++) {
		vec3 offset = vogel_sphere_8[i] * ditherTimesSize;
		offset *= sign(dot(viewNormal, offset));                        // Inverts the sample position if its pointing towards the surface (thus being within it). Much more efficient than using a tbn
		offset += viewNormal * 0.05;                                    // Adding a small offset away from the surface to avoid self-occlusion and SSAO acne

		vec4 sampling = viewPos + vec4(offset, 0.0); // view space
		sampling = gbufferProjection * sampling;
		sampling /= sampling.w; // Clip space
		sampling = sampling * 0.5 + 0.5; 					  // screen space

		float SMDepth = texture2D(depthtex0, sampling.xy).r;
		float sampleDepth = sampling.z;

		float depthDiff = clamp(sampleDepth - SMDepth, 0.0, 1.0) * linearDepth;
		hits += linearAttenuation(depthDiff, filterSize * 0.6, 3) * float(sampleDepth > SMDepth);
//		if (SMDepth < sampleDepth) {
//			hits++;
//		}
	}

	hits  = clamp(-hits * 0.125 + 1.125, 0, 1);

//	return 1 - float(hits) / 8.0;
	return sqsq(hits);
}

/* DRAWBUFFERS:0 */
void main() {
	vec3 color = texture2D(colortex0, texcoord).rgb;
	float depth = texture2D(depthtex0, texcoord).r;

	vec3 viewNormal = texture2D(colortex2, texcoord).rgb;
	viewNormal = viewNormal * 2.0 - 1.0;
	viewNormal = normalize(viewNormal);

	vec3 screenPos = vec3(texcoord, depth);
	float filterSize = 0.375;

	color *= SSAO(screenPos, viewNormal, filterSize) * SSAO_STRENGTH + (1 - SSAO_STRENGTH);

	gl_FragData[0] = vec4(color, 1.0); //gcolor
}