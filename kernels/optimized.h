#ifndef WATERSIMULATOR_OPTIMIZED_H
#define WATERSIMULATOR_OPTIMIZED_H

#include <cuda_runtime.h>
#include <curand_kernel.h>

#include "../include/particle.h"
#include "../util/physics.h"
#include "../util/opengl_interface.h"

/* number of bins per dimension */
// use 320 for 4k, use larger number when using lower resolution
#define NUM_BINS 320
/* number of particles per bin 8 */
#define PARTICLES_PER_BIN (SIM_WIDTH * SIM_HEIGHT / (NUM_BINS * NUM_BINS))
#define BIN_WIDTH (SIM_WIDTH / NUM_BINS)
#define BIN_HEIGHT (SIM_HEIGHT / NUM_BINS)

#define BLOCKSIZE 256 * 2

void launchGeneratePixelsOptimized(uchar4* d_ptr, float time);

void setupKernelOptimized(particle* h_particles);

void endKernelOptimized();

inline particle* d_particles;
inline particle** d_bins;
inline int* d_bin_counts;
inline ulong step = 0;

#endif //WATERSIMULATOR_OPTIMIZED_H
