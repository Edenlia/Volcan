#define SHADOW_DISTORT_ENABLED //Toggles shadow map distortion
#define SHADOW_DISTORT_FACTOR 0.15 //Distortion factor for the shadow map. Has no effect when shadow distortion is disabled.
#define SHADOW_BIAS 0.80 //Increase this if you get shadow acne. Decrease this if you get peter panning.
#define SHADOW_BRIGHTNESS .75 // the visibility range [SHADOW_BRIGHTNESS, 1.0]
#define LIGHT_RADIUS .015
#define PI 3.141592653589793
#define PI2 6.283185307179586

const int shadowMapResolution = 2048; //Resolution of the shadow map. Higher numbers mean more accurate shadows. [128 256 512 1024 2048 4096 8192]
const float	sunPathRotation	= 30.0;

#ifdef SHADOW_DISTORT_ENABLED
// distorts the shadow map, like fish eye lens.
// this can increase the shadow map resolution in the center
// of the screen, and decrease it at the edges.
vec2 shadowDistort(vec2 positionInNdcCoord) {
    float factor = SHADOW_DISTORT_FACTOR + length(positionInNdcCoord);
    return positionInNdcCoord / factor;
}

// returns the reciprocal of the derivative of our
// distort function's factor, and multiplies it by a fixed bias depend on resolution.
// if a texel in the shadow map contains a bigger area,
// then we need more bias. therefore, we need to know how much
// bigger or smaller a pixel gets as a result of applying distortion.
// param is the distorted from ndc coord, range [-1, 1]
// TODO: change bias to erase center artifacts
float computeBias(vec2 distortedUV) {
    //square(length(pos.xy) + SHADOW_DISTORT_FACTOR)
    float numerator = length(distortedUV) + SHADOW_DISTORT_FACTOR;
    numerator *= numerator;
    return SHADOW_BIAS / shadowMapResolution * numerator / SHADOW_DISTORT_FACTOR;
}
#else
vec2 shadowDistort(vec2 positionInNdcCoord) {
    return positionInNdcCoord;
}

float computeBias(vec2 distortedUV) {
    return SHADOW_BIAS / shadowMapResolution;
}

#endif

