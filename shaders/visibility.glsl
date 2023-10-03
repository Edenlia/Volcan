#include "/shadow_util.glsl"


float useShadowMap(sampler2D shadowMap, vec4 ndcPos, float viewObjDepth) {
    // The fish eye function applied in ndc space, so we need to
    // change the ndcPos to fish eye coord first and then change
    // the range from [-1, 1] to [0, 1]
    vec2 uv = shadowDistort(ndcPos.xy) * 0.5 + 0.5;
    float shadowMapDepth = texture2D(shadowMap, uv).r;

    vec2 distortedUV = shadowDistort(ndcPos.xy);
    float bias = computeBias(distortedUV);

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
    // PCF, because the shadow map is using fish eye coord,
    // so we need to sample in clip space, a pixel distance
    // in screen space is 1.0 / shadowMapResolution, so in
    // clip space, it is 2.0 / shadowMapResolution, we use
    // 1/4 a pixel distance
    float pixelOffset = 0.5 / shadowMapResolution;
    float visible = 0.0;
    int radius = 1;

    for (int i = -radius; i <= radius; i++) {
        for (int j = -radius; j <= radius; j++) {
            vec4 offset = vec4(i, j, 0, 0) * pixelOffset;
            vec4 sampledPos = ndcPos + offset;
            vec2 sampledUV = shadowDistort(sampledPos.xy) * 0.5 + 0.5;

            vec2 distortedUV = shadowDistort(sampledPos.xy);
            float bias = computeBias(distortedUV);

            float shadowMapDepth = texture2D(shadowMap, sampledUV).r;

            if (viewObjDepth - shadowMapDepth <= bias) {
                visible += 1.0;
            }
        }
    }
    visible /= pow(radius * 2 + 1, 2);

    return (1 - SHADOW_BRIGHTNESS) * visible + SHADOW_BRIGHTNESS; // visibility is [SHAODW_STRENGTH, 1]
}

float PCSS() {
    return 0.0;
}


// find the visibility of pos, ranged in [SHADOW_BRIGHTNESS, 1]
// using shadow map.
float visibility(vec4 worldPos,
sampler2D shadowMap,
vec3 shadowLightPos,
mat4 shadowModelViewMatrix,
mat4 shadowProjectionMatrix
) {
    // compute cos between light direction and vertex normal in eye space
    // shadowLightPosition is in eye space, gl_Normal is vertex normal in
    // model space, so we need to transform it to eye space by gl_NormalMatrix
    // If cosLN is less than 0.0, then the vertex is facing away from the light
    // so we don't need to do shadow test
    //    float cosLN = dot(normalize(shadowLightPosition), normalize(gl_NormalMatrix * gl_Normal));
    //    if (cosLN < 0.0) {
    //        return SHADOW_BRIGHTNESS;
    //    }

    // from world space to light's clip space
    vec4 ndcPos = shadowProjectionMatrix * shadowModelViewMatrix * worldPos;
    ndcPos /= ndcPos.w;

    float viewObjDepth = ndcPos.z * 0.5 + 0.5;

    return useShadowMap(shadowMap, ndcPos, viewObjDepth);
    //    return PCF(shadowMap, ndcPos, viewObjDepth);
}