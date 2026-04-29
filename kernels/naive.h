#ifndef WATERSIMULATOR_NAIVE_H
#define WATERSIMULATOR_NAIVE_H

#include <cuda_runtime.h>
#include <curand_kernel.h>

#include "../include/particle.h"
#include "../util/physics.h"
#include "../util/vector_tools.h"

#define BLOCKSIZE 16

void launchGeneratePixelsNaive(uchar4* d_ptr, float time);

void setupKernelNaive(particle* h_particles);

void endKernelNaive();

inline particle* d_particles;
inline ulong step = 0;

#endif //WATERSIMULATOR_NAIVE_H