#ifndef WATERSIMULATOR_OVERFLOW_H
#define WATERSIMULATOR_OVERFLOW_H

#include <cuda_runtime.h>
#include <curand_kernel.h>

#include "../include/particle.h"
#include "../util/physics.h"
#include "../util/opengl_interface.h"

/* number of bins per dimension */
// use 320 for 4k, use larger number when using lower resolution
#define NUM_BINS (320 / 16)
/* number of particles per bin 8 */
#define PARTICLES_PER_BIN (SIM_WIDTH * SIM_HEIGHT / (NUM_BINS * NUM_BINS))
#define BIN_WIDTH (SIM_WIDTH / NUM_BINS)
#define BIN_HEIGHT (SIM_HEIGHT / NUM_BINS)

#define BLOCKSIZE PARTICLES_PER_BIN

void launchGeneratePixelsOverflow(uchar4* d_ptr, float time);

void setupKernelOverflow(particle* h_particles);

void endKernelOverflow();

inline particle* d_particles;
inline particle** d_bins;
inline int* d_bin_counts;
inline ulong step = 0;

#endif //WATERSIMULATOR_OVERFLOW_H
