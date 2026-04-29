#include "optimized.h"

#include <random>

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

    __shared__ particle sharedBin[PARTICLES_PER_BIN];

    // TODO - LOAD EVERYTHING FROM BINNED INTO SHARED MEM ???
    //const particle* currentBin = //bins[binBaseIdx];
    //particle p = currentBin[binOffset];
    if (binOffset >= currentBinCount) return;

    sharedBin[binOffset] = *bins[binBaseIdx + binOffset];
    const particle& p = sharedBin[binOffset];

    __syncthreads();

    if (p.type != PTYPE_WATER) return;

    vector_t Force(0, 0, 0);
    curandState cstate;

    for (int i = 0; i < currentBinCount; i++) {
        const particle neighbor = sharedBin[i]; //currentBin[i];
        const vector_t r = sub_vectors(p.pos,neighbor.pos);
        if (vector_norm(r) < RC) {
            if (neighbor.type != PTYPE_NULL) {
                curand_init(binOffset * i, step, 0, &cstate);
                Force = add_vectors(Force,compute_net_force(p, neighbor, curand_normal(&cstate), dt));
            }
        }
    }
    bins[binBaseIdx + binOffset]->acc = scale_vector(1/p.mass, Force);
}

__device__ void rebinParticles(size_t particleBufferSize, particle* particles, particle** bins, int* bin_counts) {
    int idx = threadIdx.x + blockIdx.x * blockDim.x;

    if (idx >= particleBufferSize) return;

    particle& p = particles[idx];

    const size_t binBaseIdx = position_to_bin_index(p.pos);
    const int ticketNumber = atomicAdd(&bin_counts[binBaseIdx / PARTICLES_PER_BIN], 1);

    /* TODO - ADD OVERFLOW BIN */
    if (ticketNumber >= PARTICLES_PER_BIN) {
        /* TOO BAD SO SAD. Your particle doesn't get binned */
        bin_counts[binBaseIdx / PARTICLES_PER_BIN] = PARTICLES_PER_BIN; // reset the count back to the cap
        return;
    }

    bins[binBaseIdx + ticketNumber] = &particles[idx];
}

__global__ void initialRebin(size_t particleBufferSize, particle_t* particles, particle_t** bins, int* bin_counts) { //
    rebinParticles(particleBufferSize, particles, bins, bin_counts);
}

__global__ void integrateForces(uchar4* d_ptr, size_t particleBufferSize, particle_t* particles, particle_t** bins, int* binCounts, float deltaTime) {
    int idx = threadIdx.x + blockIdx.x * blockDim.x;

    if (idx >= particleBufferSize) return;

    particle_t& p = particles[idx];
    if (p.type == PTYPE_NULL) return;

    p.vel = add_vectors(p.vel, scale_vector(deltaTime, p.acc));
    p.pos = add_vectors(p.pos, scale_vector(deltaTime, p.vel));

    //if (static_cast<int>(roundf(p.pos.x)) >= width || static_cast<int>(roundf(p.pos.x)) < 0 || static_cast<int>(roundf(p.pos.y)) >= height || static_cast<int>(roundf(p.pos.y)) < 0) return;
    if (static_cast<int>(roundf(p.pos.x)) >= SIM_WIDTH) p.pos.x = p.pos.x - static_cast<float>(SIM_WIDTH);
    if (static_cast<int>(roundf(p.pos.x)) < 0) p.pos.x = p.pos.x + static_cast<float>(SIM_WIDTH);
    if (static_cast<int>(roundf(p.pos.y)) >= SIM_HEIGHT) p.pos.y = p.pos.y - static_cast<float>(SIM_HEIGHT);
    if (static_cast<int>(roundf(p.pos.y)) < 0) p.pos.y = p.pos.y + static_cast<float>(SIM_HEIGHT);

    if (static_cast<int>(roundf(p.pos.x)) >= SIM_WIDTH || static_cast<int>(roundf(p.pos.x)) < 0 || static_cast<int>(roundf(p.pos.y)) >= SIM_HEIGHT || static_cast<int>(roundf(p.pos.y)) < 0)  {
        printf("Particle Panic!\n");
        p.pos.x = SIM_WIDTH / 2;
        p.pos.y = SIM_HEIGHT / 2;
        p.vel = vector_t();
    }

    rebinParticles(particleBufferSize, particles, bins, binCounts);

    d_ptr[static_cast<int>(roundf(p.pos.x)) + static_cast<int>(roundf(p.pos.y)) * SIM_WIDTH] = ucharFromParticle(p);
}

//Host Utility

static inline void resetBinCounts() {
    cudaError_t err;
    err = cudaMemset(d_bin_counts, 0, NUM_BINS * NUM_BINS * sizeof(int));
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));
    cudaMemset(d_bins, 0, sizeof(particle*) * NUM_BINS * NUM_BINS * PARTICLES_PER_BIN);
}

void launchGeneratePixelsOptimized(uchar4* d_ptr, float deltaTime) {
    dim3 blockSize(PARTICLES_PER_BIN);
    dim3 gridSize(NUM_BINS, NUM_BINS);

    cudaError_t err;

    computeForces<<<gridSize, blockSize>>>(d_bins, d_bin_counts, deltaTime, step);
    err = cudaGetLastError();
    if (err != cudaSuccess) printf("Error Compute Forces: %s\n", cudaGetErrorString(err));

    resetBinCounts();

    blockSize = dim3(BLOCKSIZE);
    gridSize = dim3((particleBufferSize + BLOCKSIZE - 1 )/ BLOCKSIZE);

    integrateForces<<<gridSize, blockSize>>>(d_ptr, particleBufferSize, d_particles, d_bins, d_bin_counts, deltaTime);
    err = cudaGetLastError();
    if (err != cudaSuccess) printf("Error Integrate Forces: %s\n", cudaGetErrorString(err));

    printf("FPS: %f\n", 1 / (deltaTime * SIMFACTOR));
    step++;
}

void setupKernelOptimized(particle* h_particles) {
    cudaError_t err;
    err = cudaMalloc(&d_particles,  particleBufferSize * sizeof(particle));
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));
    err = cudaMemcpy(d_particles, h_particles,  particleBufferSize * sizeof(particle), cudaMemcpyHostToDevice);
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));

    err = cudaMalloc(&d_bins, NUM_BINS * NUM_BINS * PARTICLES_PER_BIN * sizeof(particle_t*));
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));

    err = cudaMalloc(&d_bin_counts, NUM_BINS * NUM_BINS * sizeof(int));
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));
    cudaMemset(d_bins, 0, sizeof(particle*) * NUM_BINS * NUM_BINS * PARTICLES_PER_BIN);

    dim3 blockSize = dim3(BLOCKSIZE);
    dim3 gridSize = dim3((particleBufferSize + BLOCKSIZE - 1 )/ BLOCKSIZE);

    resetBinCounts();
    initialRebin<<<gridSize, blockSize>>>(particleBufferSize, d_particles, d_bins, d_bin_counts);

    err = cudaGetLastError();
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));
}

void endKernelOPtimized() {
    cudaError_t err;
    err = cudaFree(d_particles);
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));
}
