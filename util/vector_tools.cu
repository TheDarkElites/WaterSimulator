#include "vector_tools.h"

// Utility
__device__ uchar4 ucharFromParticle(const particle& p) {
    return make_uchar4(p.type == PTYPE_WATER ? 0 : 114, p.type == PTYPE_WATER ? 63 : 114, p.type == PTYPE_WATER ? 205 : 114, 255);
}

// Vector API

__device__ vector_t add_vectors(const vector_t v1, const vector_t v2) {
    return vector_t(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z);
}

__device__ vector_t scale_vector(const float c, const vector_t v) {
    return vector_t(c*v.x, c*v.y, c*v.z);
}

__device__ vector_t sub_vectors(const vector_t v1, const vector_t v2) {
    return add_vectors(v1, scale_vector(-1, v2));
}

__device__ float dot_product(const vector_t v1, const vector_t v2) {
    return v1.x*v2.x + v1.y*v2.y + v1.z*v2.z;
}

__device__ float vector_norm(const vector_t v) {
    return sqrt(dot_product(v, v));
}

__device__ vector_t normalize(const vector_t v) {
    return scale_vector(1/vector_norm(v), v);
}