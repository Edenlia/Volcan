const float PHI     = 1.6180339887498948482045868343656381177203091798058;
const float PHI_INV = 0.6180339887498948482045868343656381177203091798058;
const float PHI2    = 1.32471795724474602596;

const vec3 vogel_sphere_8[8] = vec3[8](
vec3(0.4841229182759271, 0, 0.875),
vec3(-0.5756083959600474, 0.5273044419500952, 0.625),
vec3(0.08104581592239497, -0.923475270768781, 0.375),
vec3(0.603666717801552, 0.7873763355719433, 0.12500000000000006),
vec3(-0.9769901230486042, -0.17281579634244423, -0.12499999999999994),
vec3(0.7821820926083319, -0.497560221483642, -0.375),
vec3(-0.20265354556067547, 0.7538610883124871, -0.6249999999999999),
vec3(-0.22313565385811115, -0.42963412338560025, -0.875)
);

float sq(float x) { // Square
    return x * x;
}
vec2 sq(vec2 x) {
    return x * x;
}
vec3 sq(vec3 x) {
    return x * x;
}
vec4 sq(vec4 x) {
    return x * x;
}

float ssq(float x) { // Signed Square
    return x * abs(x);
}
vec2 ssq(vec2 x) {
    return x * abs(x);
}
vec3 ssq(vec3 x) {
    return x * abs(x);
}
vec4 ssq(vec4 x) {
    return x * abs(x);
}

float cb(float x) { // Cube
    return x * x * x;
}
vec2 cb(vec2 x) {
    return x * x * x;
}
vec3 cb(vec3 x) {
    return x * x * x;
}
vec4 cb(vec4 x) {
    return x * x * x;
}

float sqsq(float x) { // Cube
    return sq(sq(x));
}
vec2 sqsq(vec2 x) {
    return sq(sq(x));
}
vec3 sqsq(vec3 x) {
    return sq(sq(x));
}
vec4 sqsq(vec4 x) {
    return sq(sq(x));
}

float Bayer2(vec2 a) {
    a = floor(a);
    return fract(a.x * .5 + a.y * a.y * .75);
}

#define Bayer4(a)   (Bayer2 (0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer8(a)   (Bayer4 (0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer16(a)  (Bayer8 (0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer32(a)  (Bayer16(0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer64(a)  (Bayer32(0.5 * (a)) * 0.25 + Bayer2(a))