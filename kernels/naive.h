#ifndef WATERSIMULATOR_NAIVE_H
#define WATERSIMULATOR_NAIVE_H

#include <cuda_runtime.h>
#include <curand_kernel.h>

#include "../include/particle.h"

/* number of bins per dimension */
#define NUM_BINS 640
/* number of particles per bin 8 */
#define PARTICLES_PER_BIN (SIM_WIDTH * SIM_HEIGHT / (NUM_BINS * NUM_BINS))
#define BIN_WIDTH (SIM_WIDTH / NUM_BINS)
#define BIN_HEIGHT (SIM_HEIGHT / NUM_BINS)

#define BLOCKSIZE 256

#define RC 2
#define MINABS(A,B) abs(A) < abs(B) ? (A) : (B)
//Conservative Force Constant
constexpr float a = 25;
constexpr float a_rock_water = 300;
constexpr float wall_grav = -10;

constexpr float epsilon = 1e-6;
constexpr float kT = 1;

void launchGeneratePixelsNaive(uchar4* d_ptr, int width, int height, float time);

void setupKernel(particle* h_particles);

void endKernel();

inline particle* d_particles;
inline particle** d_bins;
inline int* d_bin_counts;
inline ulong step = 0;

#endif //WATERSIMULATOR_NAIVE_H
