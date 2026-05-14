#ifndef WATERSIMULATOR_DEBUGKERNEL_H
#define WATERSIMULATOR_DEBUGKERNEL_H

#include <cuda_runtime.h>
#include "../include/particle.h"
#include <chrono>
#include <cmath>
#include <cstdio>
#include <device_launch_parameters.h>
#include "../util/opengl_interface.h"

#ifdef WATERSIMULATOR_OPTIMIZED_H
    #include "optimized.h"
#else
    #include "overflow.h"
#endif

typedef struct debugreturn {
    unsigned long long particlesCalc;
    unsigned long long particlesFail;
} debugreturn_t;

bool verifyParticleSimulation();

#endif //WATERSIMULATOR_DEBUGKERNEL_H