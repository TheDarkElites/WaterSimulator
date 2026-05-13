//
// Created by George on 4/15/26.
//

#ifndef WATERSIMULATOR_CPULOADKERNEL_H
#define WATERSIMULATOR_CPULOADKERNEL_H

#include <cuda_runtime.h>
#include "../include/particle.hpp"
#include "../util/dpd.h"
#include <chrono>
#include <cmath>
#include <cstdio>
#include <device_launch_parameters.h>
#include "../util/opengl_interface.h"

#define BLOCKSIZE 16

void launchGeneratePixelsCPU(uchar4* d_ptr, float time);

void setupKernelCPU(particle* h_particles);

inline particle* h_particles;

#endif //WATERSIMULATOR_CPULOADKERNEL_H