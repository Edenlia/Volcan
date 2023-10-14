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

// View space's z is negative, need to get abs(viewPos.z)
// and scale it to [0, 1]
float calViewSpaceDepth(float ndcDepth, mat4 projectionInverse, float far, float near) {
    vec4 ndcPos = vec4(0.0, 0.0, ndcDepth, 1.0);
    vec4 viewPos = projectionInverse * ndcPos;
    viewPos /= viewPos.w;
    float viewSpaceDepth = abs(viewPos.z);
    return (viewSpaceDepth - near) / (far - near);
}

// Params are in view space, linear depth
float calPenumbraSize(float objDepth, float blockerDepth) {
    return (objDepth - blockerDepth) / blockerDepth;
}

float useShadowMap(sampler2D shadowMap, vec4 ndcPos, float objDepth, vec3 lightDir, vec3 normal, float shadowStrength) {
    // The fish eye function applied in ndc space, so we need to
    // change the ndcPos to fish eye coord first and then change
    // the range from [-1, 1] to [0, 1]
    vec2 uv = shadowDistort(ndcPos.xy) * 0.5 + 0.5;
    float shadowMapDepth = texture2D(shadowMap, uv).r;

    vec2 distortedNDCXY = shadowDistort(ndcPos.xy);
    float bias = computeBias(distortedNDCXY, lightDir, normal);

    // compute cos between light direction and vertex normal in eye space
    // shadowLightPosition is in eye space, gl_Normal is vertex normal in
    // model space, so we need to transform it to eye space by gl_NormalMatrix
    // When cos decrease, means more perpendicular, so the bias should be smaller
    //    float diff = dot(normalize(shadowLightPosition), normalize(gl_NormalMatrix * gl_Normal));
    //    bias /= diff;

    if (objDepth - shadowMapDepth <= bias) {
        return 1.0;
    } else {
        return shadowStrength;
    }
}

float PCF(sampler2D shadowMap, vec4 ndcPos, float objDepth, vec3 lightDir, vec3 normal, float shadowStrength) {
    // Set random seed
    vec2 uv = shadowDistort(ndcPos.xy) * 0.5 + 0.5;
    poissonDiskSamples(uv);
    
    float visible = 0.0;
    float numSample = NUM_SAMPLES;
    
    for (int i = 0; i < NUM_SAMPLES; i++) {
        vec2 offset = poissonDisk[i] * PCF_FILTER_RADIUS;
        vec4 sampledPos = ndcPos + vec4(offset, 0, 0);

        // If the sampled position is out of the screen, then exclude it
        if (sampledPos.x < -1.0 || sampledPos.x > 1.0 || sampledPos.y < -1.0 || sampledPos.y > 1.0) {
            numSample--;
            continue;
        }

        vec2 distortedNDCXY = shadowDistort(sampledPos.xy);

        vec2 sampledUV = distortedNDCXY * 0.5 + 0.5;

        float bias = computeBias(distortedNDCXY, lightDir, normal);
        
        float shadowMapDepth = texture2D(shadowMap, sampledUV).r;
        
        if (objDepth - shadowMapDepth <= bias) {
            visible += 1.0;
        }
    }

    visible /= numSample;

    return (1 - shadowStrength) * visible + shadowStrength; // visibility is [shadowStrength, 1]
}

float findBlocker(
        sampler2D shadowMap,
        vec4 ndcPos,
        float viewSpaceDepth,
        mat4 shadowProjectionInverseMatrix,
        float far,
        float near,
        vec3 lightDir,
        vec3 normal) {
    // find the blocker, using view space depth because the
    // ndc space depth is not linear
    int blockerNum = 0;
    float blockerDepthSum = 0.0;

    float numSample = NUM_SAMPLES;
    float blockSearchRadius = 2.0 / 1024.0;

    for (int i = 0; i < NUM_SAMPLES; i++) {
        vec2 offset = poissonDisk[i] * blockSearchRadius;
        vec4 sampledPos = ndcPos + vec4(offset, 0, 0);

        // If the sampled position is out of the screen, then exclude it
        if (sampledPos.x < -1.0 || sampledPos.x > 1.0 || sampledPos.y < -1.0 || sampledPos.y > 1.0) {
            numSample--;
            continue;
        }

        vec2 distortedNDCXY = shadowDistort(sampledPos.xy);

        vec2 sampledUV = distortedNDCXY * 0.5 + 0.5;

        float bias = computeBias(distortedNDCXY, lightDir, normal);

        float shadowMapDepth = texture2D(shadowMap, sampledUV).r;
        float shadowMapNDCDepth = shadowMapDepth * 2.0 - 1.0;
        float shadowMapViewSpaceDepth = calViewSpaceDepth(shadowMapNDCDepth, shadowProjectionInverseMatrix, far, near);

        if (shadowMapViewSpaceDepth - viewSpaceDepth < 0.0) {
            blockerNum++;
            blockerDepthSum += shadowMapViewSpaceDepth;
        }
    }

    if (blockerNum == 0) {
        return -1.0;
    }

    return blockerDepthSum / blockerNum;
}


float PCSS(
        sampler2D shadowMap,
        vec4 ndcPos,
        float objDepth,
        mat4 shadowProjectionInverseMatrix,
        float far,
        float near,
        vec3 lightDir,
        vec3 normal,
        float shadowStrength) {
    // Set random seed
    vec2 uv = shadowDistort(ndcPos.xy) * 0.5 + 0.5;
    poissonDiskSamples(uv);

    // STEP 1: blocker search
    // TODO: use light's frustum to determine the block search radius
    float viewSpaceDepth = calViewSpaceDepth(ndcPos.z, shadowProjectionInverseMatrix, far, near);
    float blockerDepth = findBlocker(shadowMap, ndcPos, viewSpaceDepth, shadowProjectionInverseMatrix, far, near, lightDir, normal);
    if (blockerDepth == -1) {
        return 1.0;
    }

    // STEP 2: penumbra size
    float penumbraRatio = calPenumbraSize(viewSpaceDepth, blockerDepth);
    float radius = LIGHT_RADIUS * penumbraRatio;

//    if (blockerDepth < viewSpaceDepth) {
//        return 1.0;
//    } else {
//        return 0.0;
//    }

    // STEP 3: PCF filtering
    float visible = 0.0;
    float numSample = NUM_SAMPLES;

    for (int i = 0; i < NUM_SAMPLES; i++) {
        vec2 offset = poissonDisk[i] * radius;
        vec4 sampledPos = ndcPos + vec4(offset, 0, 0);

        // If the sampled position is out of the screen, then exclude it
        if (sampledPos.x < -1.0 || sampledPos.x > 1.0 || sampledPos.y < -1.0 || sampledPos.y > 1.0) {
            numSample--;
            continue;
        }

        vec2 distortedNDCXY = shadowDistort(sampledPos.xy);

        vec2 sampledUV = distortedNDCXY * 0.5 + 0.5;

        float bias = computeBias(distortedNDCXY, lightDir, normal);

        float shadowMapDepth = texture2D(shadowMap, sampledUV).r;

        if (objDepth - shadowMapDepth <= bias) {
            visible += 1.0;
        }
    }

    visible /= numSample;

//    if (visible != 1.0 && visible != 0.0) {
//        return 1.0;
//    } else {
//        return 0.0;
//    }

    return (1 - shadowStrength) * visible + shadowStrength; // visibility is [shadowStrength, 1]
}


// find the visibility of pos, ranged in [shadowStrength, 1]
// using shadow map.
float visibility(vec4 worldPos,
sampler2D shadowMap,
vec3 shadowLightPos,
mat4 shadowModelViewMatrix,
mat4 shadowProjectionMatrix,
mat4 shadowProjectionInverseMatrix,
vec3 viewSpaceNormal,
float far,
float near,
float shadowStrength
) {
    // compute cos between light direction and vertex normal in eye space
    // shadowLightPosition is in eye space, gl_Normal is vertex normal in
    // model space, so we need to transform it to eye space by gl_NormalMatrix
    // If cosLN is less than 0.0, then the vertex is facing away from the light
    // so we don't need to do shadow test
    vec3 lightDir = normalize(shadowLightPos);
    vec3 normal = normalize(viewSpaceNormal);
    float cosLN = dot(lightDir, normal);
    if (cosLN < 0.0) {
        return shadowStrength;
    }

    // from world space to light's clip space
    vec4 viewPos = shadowModelViewMatrix * worldPos;
    vec4 ndcPos = shadowProjectionMatrix * viewPos;
    ndcPos /= ndcPos.w;

    float objDepth = ndcPos.z * 0.5 + 0.5;

//    return useShadowMap(shadowMap, ndcPos, objDepth, lightDir, normal, shadowStrength);
//    return PCF(shadowMap, ndcPos, objDepth, lightDir, normal, shadowStrength);
    return PCSS(shadowMap, ndcPos, objDepth, shadowProjectionInverseMatrix, far, near, lightDir, normal, shadowStrength);
}
