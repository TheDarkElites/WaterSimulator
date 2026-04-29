#ifndef WATERSIMULATOR_VECTOR_TOOLS_H
#define WATERSIMULATOR_VECTOR_TOOLS_H

#include <vector_types.h>
#include <cuda_runtime.h>

#include "../include/particle.h"

__device__ uchar4 ucharFromParticle(const particle& p);

__device__ vector_t add_vectors(const vector_t v1, const vector_t v2);

__device__ vector_t scale_vector(const float c, const vector_t v);

__device__ vector_t sub_vectors(const vector_t v1, const vector_t v2);

__device__ float dot_product(const vector_t v1, const vector_t v2);

__device__ float vector_norm(const vector_t v);

__device__ vector_t normalize(const vector_t v);

#endif //WATERSIMULATOR_VECTOR_TOOLS_H