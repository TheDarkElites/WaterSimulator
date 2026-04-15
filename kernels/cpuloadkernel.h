//
// Created by George on 4/15/26.
//

#ifndef WATERSIMULATOR_CPULOADKERNEL_H
#define WATERSIMULATOR_CPULOADKERNEL_H

#include <cuda_runtime.h>
#include "../include/particle.hpp"

void launchGeneratePixelsCPULOAD(uchar4* d_ptr, int width, int height, float time);

inline particle* h_particles;

#endif //WATERSIMULATOR_CPULOADKERNEL_H
