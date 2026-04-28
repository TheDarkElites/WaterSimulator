#ifndef WATERSIMULATOR_NAIVE_H
#define WATERSIMULATOR_NAIVE_H

#include <cuda_runtime.h>
#include <curand_kernel.h>

#include "../include/particle.h"

#define RC 2
#define WALL_RANGE 10
#define MINABS(A,B) abs(A) < abs(B) ? (A) : (B)
//Conservative Force Constant
constexpr float a = 25;
constexpr float wall_grav = -9999;

constexpr float epsilon = 1e-6;
constexpr float kT = 1;

void launchGeneratePixelsNaive(uchar4* d_ptr, int width, int height, float time);

void setupKernel(particle* h_particles);

void endKernel();

inline particle* d_particles;
inline ulong step = 0;

#endif //WATERSIMULATOR_NAIVE_H
