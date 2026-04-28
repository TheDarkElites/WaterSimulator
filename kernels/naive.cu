#include "naive.h"

#include <random>

#include "../util/opengl_interface.h"

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

__device__ vector_t min_vector(const vector_t minv, const vector_t target) {
    return vector_t(MINABS(minv.x,target.x),MINABS(minv.y,target.y),MINABS(minv.z,target.z));
}

// Physics Forces

/* Conservative Force */
__device__ float weight_c(float r) {
    return 1- (r/RC);
}

__device__ vector_t compute_force_c(const particle_t& i, const particle_t& j) {
    vector_t r_ij = sub_vectors(j.pos, i.pos);
    float r = vector_norm(r_ij);
    if (r < epsilon) return vector_t(0, 0, 0);
    float w_C = weight_c(r);
    vector_t r_hat = normalize(r_ij); // same as unit vec e
    return scale_vector(a * w_C, r_hat);
}

/* Dissipative Force */
__device__ float weight_d(float r) {
    return (1- (r/RC)) * (1- (r/RC));
}

__device__ vector_t compute_force_d(const particle_t& i, const particle_t& j) {
    float gamma = 4.5; // hard coded for water
    vector_t r_ij = sub_vectors(j.pos, i.pos);
    vector_t v_ij = sub_vectors(j.vel, i.vel);
    float r = vector_norm(r_ij);
    if (r < epsilon) return vector_t(0, 0, 0);
    float w_D = weight_d(r);
    vector_t r_hat = normalize(r_ij); // same as unit vec e
    return scale_vector(-gamma * w_D * dot_product(v_ij, r_hat), r_hat);
}

/* Gravity Force */

__device__ vector_t gravityForce(const particle_t& p, const particle_t& P, float G) {
    vector_t r = sub_vectors(P.pos,p.pos);
    float r_squared = max(dot_product(r, r), epsilon);
    vector_t F = scale_vector((G * P.mass * p.mass)/(r_squared), normalize(r));
    return F;
}

/* Random Force */

__device__ float weight_r(float r) {
    return 1- (r/RC);
}

__device__ vector_t compute_force_r(const particle_t& i, const particle_t& j, float theta, float dt) {
    float sigma = sqrt(2*4.5*kT); // hard code for water sqrt(2*gamma*kT)
    vector_t r_ij = sub_vectors(j.pos, i.pos);
    float r = vector_norm(r_ij);
    if (r < epsilon) return vector_t(0, 0, 0);
    float w_R = weight_r(r);
    vector_t r_hat = normalize(r_ij); // same as unit vec e
    return scale_vector(sigma * w_R * (theta/sqrt(dt)), r_hat);
}

/* final force */

__device__ vector_t compute_net_force(const particle& i, const particle& j, float theta, float dt) {
    return add_vectors(
        compute_force_c(i, j), add_vectors(
        compute_force_d(i, j),
        compute_force_r(i, j, theta, dt)
    ));
}

__device__ size_t position_to_bin_index(const vector_t& pos) {
    size_t binX = static_cast<size_t>(floor(pos.x / BIN_WIDTH));
    size_t binY = static_cast<size_t>(floor(pos.y / BIN_HEIGHT));
    return (binX * NUM_BINS + binY) * PARTICLES_PER_BIN;
}

//Kernel Mains
__global__ void computeForces(particle** bins, const int* binCounts, float dt, ulong step) {
    const unsigned int binCountIdx = blockIdx.x * NUM_BINS + blockIdx.y;
    const int currentBinCount = binCounts[binCountIdx];
    const unsigned int binBaseIdx = binCountIdx * PARTICLES_PER_BIN;
    const unsigned int binOffset = threadIdx.x;

    // TODO - LOAD EVERYTHING FROM BINNED INTO SHARED MEM ???
    //const particle* currentBin = //bins[binBaseIdx];
    //particle p = currentBin[binOffset];
    if (binOffset >= currentBinCount) return;

    const particle p = *bins[binBaseIdx + binOffset];

    if (p.type != PTYPE_WATER) return;

    vector_t Force(0, 0, 0);
    curandState cstate;

    for (int i = 0; i < currentBinCount; i++) {
        const particle neighbor = *bins[binBaseIdx + i]; //currentBin[i];
        const vector_t r = sub_vectors(p.pos,neighbor.pos);
        if (vector_norm(r) < RC) {
            if (neighbor.type == PTYPE_WATER) {
                curand_init(binOffset * i, step, 0, &cstate);
                Force = add_vectors(Force,compute_net_force(p, neighbor, curand_normal(&cstate), dt));
            }
        }
        if (neighbor.type == PTYPE_ROCK && vector_norm(r) < WALL_RANGE) {
            Force = add_vectors(Force, gravityForce(p, neighbor, wall_grav));
        }
    }
    bins[binBaseIdx + binOffset]->acc = scale_vector(1/p.mass, Force);
}

__device__ void rebinParticles(int width, int height, particle* particles, particle** bins, int* bin_counts) {
    int idx = threadIdx.x + blockIdx.x * blockDim.x;
    int idy = threadIdx.y + blockIdx.y * blockDim.y;

    if (idx >= width || idy >= height) return;

    particle& p = particles[idx + idy * width];

    const size_t binBaseIdx = position_to_bin_index(p.pos);
    const int ticketNumber = atomicAdd(&bin_counts[binBaseIdx / PARTICLES_PER_BIN], 1);

    /* TODO - ADD OVERFLOW BIN */
    if (ticketNumber >= PARTICLES_PER_BIN) {
        /* TOO BAD SO SAD. Your particle doesn't get binned */
        bin_counts[binBaseIdx / PARTICLES_PER_BIN] = PARTICLES_PER_BIN; // reset the count back to the cap
        return;
    }

    bins[binBaseIdx + ticketNumber] = &particles[idx + idy * width];
}

__global__ void initialRebin(int width, int height, particle_t* particles, particle_t** bins, int* bin_counts) { //
    rebinParticles(width, height, particles, bins, bin_counts);
}

__global__ void integrateForces(uchar4* d_ptr, int width, int height, particle_t* particles, particle_t** bins, int* binCounts, float deltaTime) {
    int idx = threadIdx.x + blockIdx.x * blockDim.x;
    int idy = threadIdx.y + blockIdx.y * blockDim.y;

    if (idx >= width || idy >= height) return;

    particle_t& p = particles[idx + idy * width];
    if (p.type == PTYPE_NULL) return;

    p.vel = add_vectors(p.vel, scale_vector(deltaTime, p.acc));
    p.pos = add_vectors(p.pos, scale_vector(deltaTime, p.vel));

    //if (static_cast<int>(roundf(p.pos.x)) >= width || static_cast<int>(roundf(p.pos.x)) < 0 || static_cast<int>(roundf(p.pos.y)) >= height || static_cast<int>(roundf(p.pos.y)) < 0) return;
    if (static_cast<int>(roundf(p.pos.x)) >= width) p.pos.x = p.pos.x - static_cast<float>(width);
    if (static_cast<int>(roundf(p.pos.x)) < 0) p.pos.x = p.pos.x + static_cast<float>(width);
    if (static_cast<int>(roundf(p.pos.y)) >= height) p.pos.y = p.pos.y - static_cast<float>(height);
    if (static_cast<int>(roundf(p.pos.y)) < 0) p.pos.y = p.pos.y + static_cast<float>(height);

    if (static_cast<int>(roundf(p.pos.x)) >= width || static_cast<int>(roundf(p.pos.x)) < 0 || static_cast<int>(roundf(p.pos.y)) >= height || static_cast<int>(roundf(p.pos.y)) < 0)  {
        printf("Particle Panic!\n");
        p.pos.x = SIM_WIDTH / 2;
        p.pos.y = SIM_HEIGHT / 2;
        p.vel = vector_t();
    }

    rebinParticles(width, height, particles, bins, binCounts);

    d_ptr[static_cast<int>(roundf(p.pos.x)) + static_cast<int>(roundf(p.pos.y)) * width] = ucharFromParticle(p);
}

//Host Utility

static inline void resetBinCounts() {
    cudaError_t err;
    err = cudaMemset(d_bin_counts, 0, NUM_BINS * NUM_BINS * sizeof(int));
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));
    cudaMemset(d_bins, 0, sizeof(particle*) * NUM_BINS * NUM_BINS * PARTICLES_PER_BIN);
}

void launchGeneratePixelsNaive(uchar4* d_ptr, int width, int height, float deltaTime) {
    dim3 blockSize(PARTICLES_PER_BIN);
    dim3 gridSize(NUM_BINS, NUM_BINS);

    cudaError_t err;

    computeForces<<<gridSize, blockSize>>>(d_bins, d_bin_counts, deltaTime, step);
    err = cudaGetLastError();
    if (err != cudaSuccess) printf("Error Compute Forces: %s\n", cudaGetErrorString(err));

    resetBinCounts();

    blockSize = dim3(16, 16);
    gridSize = dim3((width + blockSize.x - 1) / blockSize.x, (height + blockSize.y - 1) / blockSize.y);

    integrateForces<<<gridSize, blockSize>>>(d_ptr, width, height, d_particles, d_bins, d_bin_counts, deltaTime);
    err = cudaGetLastError();
    if (err != cudaSuccess) printf("Error Integrate Forces: %s\n", cudaGetErrorString(err));

    printf("FPS: %f\n", 1 / (deltaTime * SIMFACTOR));
    step++;
}

void setupKernel(particle* h_particles) {
    size_t size = sizeof(particle) * SIM_WIDTH * SIM_HEIGHT;

    cudaError_t err;
    err = cudaMalloc(&d_particles, size);
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));
    err = cudaMemcpy(d_particles, h_particles, size, cudaMemcpyHostToDevice);
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));

    err = cudaMalloc(&d_bins, NUM_BINS * NUM_BINS * PARTICLES_PER_BIN * sizeof(particle_t*));
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));

    err = cudaMalloc(&d_bin_counts, NUM_BINS * NUM_BINS * sizeof(int));
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));
    cudaMemset(d_bins, 0, sizeof(particle*) * NUM_BINS * NUM_BINS * PARTICLES_PER_BIN);


    dim3 blockSize(PARTICLES_PER_BIN);
    dim3 gridSize(NUM_BINS, NUM_BINS);

    blockSize = dim3(16, 16);
    gridSize = dim3((SIM_WIDTH + blockSize.x - 1) / blockSize.x, (SIM_HEIGHT + blockSize.y - 1) / blockSize.y);

    resetBinCounts();
    initialRebin<<<gridSize, blockSize>>>(SIM_WIDTH, SIM_HEIGHT, d_particles, d_bins, d_bin_counts);

    // int* counts_test = (int*) malloc(NUM_BINS * NUM_BINS * sizeof(int));
    // cudaMemcpy(counts_test, d_bin_counts, NUM_BINS * NUM_BINS * sizeof(int), cudaMemcpyDeviceToHost);
    // int t = 0;

    err = cudaGetLastError();
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));
}

void endKernel() {
    cudaError_t err;
    err = cudaFree(d_particles);
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));
}
