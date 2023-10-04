#include "/shadow_util.glsl"

#define PCF_FILTER_RADIUS (1.0 / 1024.0)
#define NUM_SAMPLES 16
#define NUM_RINGS 10

highp float rand_1to1(highp float x) {
    // -1 -1
    return fract(sin(x) * 10000.0);
}

highp float rand_2to1(vec2 uv) {
    // 0 - 1
    const highp float a = 12.9898, b = 78.233, c = 43758.5453;
    highp float dt = dot(uv.xy, vec2(a, b)), sn = mod(dt, PI);
    return fract(sin(sn) * c);
}

vec2 poissonDisk[NUM_SAMPLES];

void poissonDiskSamples(const in vec2 randomSeed) {

    float ANGLE_STEP = PI2 * float(NUM_RINGS) / float(NUM_SAMPLES);
    float INV_NUM_SAMPLES = 1.0 / float(NUM_SAMPLES);

    float angle = rand_2to1(randomSeed) * PI2;
    float radius = INV_NUM_SAMPLES;
    float radiusStep = radius;

    for (int i = 0; i < NUM_SAMPLES; i++) {
        poissonDisk[i] = vec2(cos(angle), sin(angle)) * pow(radius, 0.75);
        radius += radiusStep;
        angle += ANGLE_STEP;
    }
}

void uniformDiskSamples(const in vec2 randomSeed) {

    float randNum = rand_2to1(randomSeed);
    float sampleX = rand_1to1(randNum);
    float sampleY = rand_1to1(sampleX);

    float angle = sampleX * PI2;
    float radius = sqrt(sampleY);

    for (int i = 0; i < NUM_SAMPLES; i++) {
        poissonDisk[i] = vec2(radius * cos(angle), radius * sin(angle));

        sampleX = rand_1to1(sampleY);
        sampleY = rand_1to1(sampleX);

        angle = sampleX * PI2;
        radius = sqrt(sampleY);
    }
}

float calViewSpaceDepth(float ndcDepth, mat4 projectionInverse) {
    vec4 depth = vec4(0.0, 0.0, ndcDepth, 1.0);
    vec4 viewDepth = projectionInverse * depth;
    viewDepth /= viewDepth.w;
    return viewDepth.z;
}

// Params are in view space
float calPenumbraSize(float objDepth, float blockerDepth) {
    return (objDepth - blockerDepth) / blockerDepth;
}

float useShadowMap(sampler2D shadowMap, vec4 ndcPos, float viewObjDepth) {
    // The fish eye function applied in ndc space, so we need to
    // change the ndcPos to fish eye coord first and then change
    // the range from [-1, 1] to [0, 1]
    vec2 uv = shadowDistort(ndcPos.xy) * 0.5 + 0.5;
    float shadowMapDepth = texture2D(shadowMap, uv).r;

    vec2 distortedNDCXY = shadowDistort(ndcPos.xy);
    float bias = computeBias(distortedNDCXY);

    // compute cos between light direction and vertex normal in eye space
    // shadowLightPosition is in eye space, gl_Normal is vertex normal in
    // model space, so we need to transform it to eye space by gl_NormalMatrix
    // When cos decrease, means more perpendicular, so the bias should be smaller
    //    float diff = dot(normalize(shadowLightPosition), normalize(gl_NormalMatrix * gl_Normal));
    //    bias /= diff;

    if (viewObjDepth - shadowMapDepth <= bias) {
        return 1.0;
    } else {
        return SHADOW_BRIGHTNESS;
    }
}

float PCF(sampler2D shadowMap, vec4 ndcPos, float viewObjDepth) {
    // Set random seed
    vec2 uv = shadowDistort(ndcPos.xy) * 0.5 + 0.5;
    poissonDiskSamples(uv);
    
    float visible = 0.0;
    float numSample = NUM_SAMPLES;
    
    for (int i = 0; i < NUM_SAMPLES; i++) {
        vec2 offset = poissonDisk[i] * PCF_FILTER_RADIUS;
        vec4 sampledPos = ndcPos + vec4(offset, 0, 0);

//        // If the sampled position is out of the screen, then exclude it
//        if (sampledPos.x < -1.0 || sampledPos.x > 1.0 || sampledPos.y < -1.0 || sampledPos.y > 1.0) {
//            numSample--;
//            continue;
//        }

        vec2 distortedNDCXY = shadowDistort(sampledPos.xy);

        // If the sampled position is out of the screen, then exclude it
        if (distortedNDCXY.x < -1.0 || distortedNDCXY.x > 1.0 || distortedNDCXY.y < -1.0 || distortedNDCXY.y > 1.0) {
            numSample--;
            continue;
        }

        vec2 sampledUV = distortedNDCXY * 0.5 + 0.5;

        float bias = computeBias(distortedNDCXY);
        
        float shadowMapDepth = texture2D(shadowMap, sampledUV).r;
        
        if (viewObjDepth - shadowMapDepth <= bias) {
            visible += 1.0;
        }
    }

    visible /= numSample;

    return (1 - SHADOW_BRIGHTNESS) * visible + SHADOW_BRIGHTNESS; // visibility is [SHAODW_STRENGTH, 1]
}

float findBlocker(sampler2D shadowMap, vec4 ndcPos, float objDepth, mat4 shadowProjectionInverseMatrix) {
    // find the blocker, using view space depth because the
    // ndc space depth is not linear
    float viewSpaceDepth = calViewSpaceDepth(ndcPos.z, shadowProjectionInverseMatrix);

    float pixelOffset = 0.5 / shadowMapResolution;
    int blockerNum = 0;
    float blockerDepthSum = 0.0;

    int radius = 5;

    for (int i = -radius; i <= radius; i++) {
        for (int j = -radius; j <= radius; j++) {
            vec4 offset = vec4(i, j, 0, 0) * pixelOffset;
            vec4 sampledPos = ndcPos + offset;
            vec2 sampledUV = shadowDistort(sampledPos.xy) * 0.5 + 0.5;

            float shadowMapDepth = texture2D(shadowMap, sampledUV).r;
            float shadowMapViewSpaceDepth = calViewSpaceDepth(shadowMapDepth, shadowProjectionInverseMatrix);

            if (shadowMapViewSpaceDepth < viewSpaceDepth) {
                blockerNum++;
                blockerDepthSum += shadowMapViewSpaceDepth;
            }
        }
    }

    if (blockerNum == 0) {
        return -1.0;
    }

    return blockerDepthSum / blockerNum;
}


float PCSS(sampler2D shadowMap, vec4 ndcPos, float objDepth, mat4 shadowProjectionInverseMatrix) {
    // STEP 1: blocker search
    float blockerDepth = findBlocker(shadowMap, ndcPos, objDepth, shadowProjectionInverseMatrix);
    if (blockerDepth == -1) {
        return 1.0;
    }

    // STEP 2: penumbra size
    float viewSpaceDepth = calViewSpaceDepth(ndcPos.z, shadowProjectionInverseMatrix);
    float penumbraRatio = calPenumbraSize(viewSpaceDepth, blockerDepth);
    float radius = LIGHT_RADIUS * penumbraRatio;

    // STEP 3: PCF filtering
    float visible = 0.0;
    int sampleNum = 1;
    float pixelOffset = 0.5 / shadowMapResolution;
    for (int i = -sampleNum; i <= sampleNum; i++) {
        for (int j = -sampleNum; j <= sampleNum; j++) {
            vec4 offset = vec4(i, j, 0, 0) * pixelOffset * radius;
            vec4 sampledPos = ndcPos + offset;
            vec2 sampledUV = shadowDistort(sampledPos.xy) * 0.5 + 0.5;

            float shadowMapDepth = texture2D(shadowMap, sampledUV).r;

            if (objDepth - shadowMapDepth <= 5e-5) {
                visible += 1.0;
            }
        }
    }

    visible /= pow(sampleNum * 2 + 1, 2);

    return (1 - SHADOW_BRIGHTNESS) * visible + SHADOW_BRIGHTNESS; // visibility is [SHAODW_STRENGTH, 1]
}


// find the visibility of pos, ranged in [SHADOW_BRIGHTNESS, 1]
// using shadow map.
float visibility(vec4 worldPos,
sampler2D shadowMap,
vec3 shadowLightPos,
mat4 shadowModelViewMatrix,
mat4 shadowProjectionMatrix,
mat4 shadowProjectionInverseMatrix,
vec3 viewSpaceNormal
) {
    // compute cos between light direction and vertex normal in eye space
    // shadowLightPosition is in eye space, gl_Normal is vertex normal in
    // model space, so we need to transform it to eye space by gl_NormalMatrix
    // If cosLN is less than 0.0, then the vertex is facing away from the light
    // so we don't need to do shadow test
        float cosLN = dot(normalize(shadowLightPos), normalize(viewSpaceNormal));
        if (cosLN < 0.0) {
            return SHADOW_BRIGHTNESS;
        }

    // from world space to light's clip space
    vec4 ndcPos = shadowProjectionMatrix * shadowModelViewMatrix * worldPos;
    ndcPos /= ndcPos.w;

    float viewObjDepth = ndcPos.z * 0.5 + 0.5;

    return useShadowMap(shadowMap, ndcPos, viewObjDepth);
//    return PCF(shadowMap, ndcPos, viewObjDepth);
//    return PCSS(shadowMap, ndcPos, viewObjDepth, shadowProjectionInverseMatrix);
}
