#include "overflow.h"

#include <random>

#ifdef DEBUG
#include "debugkernel.h"
#endif

__device__ size_t position_to_bin_index_overflow(const vector_t& pos) {
    size_t binX = static_cast<size_t>(floor(pos.x / BIN_WIDTH));
    size_t binY = static_cast<size_t>(floor(pos.y / BIN_HEIGHT));
    return (binX * NUM_BINS + binY) * PARTICLES_PER_BIN;
}

//Kernel Mains
__global__ void computeForcesOverflow(particle** bins, const int* binCounts, float dt, ulong step) {
    const unsigned int binCountIdx = blockIdx.x * NUM_BINS + blockIdx.y;
    const int currentBinCount = binCounts[binCountIdx];
    const unsigned int binBaseIdx = binCountIdx * PARTICLES_PER_BIN;
    const unsigned int binOffset = threadIdx.x;

    __shared__ particle sharedBin[PARTICLES_PER_BIN];

    if (binOffset >= currentBinCount) return;

    sharedBin[binOffset] = *bins[binBaseIdx + binOffset];
    const particle& p = sharedBin[binOffset];

    __syncthreads();

#ifdef DEBUG
    bins[binBaseIdx + binOffset]->dirty = true; //Track that we modified this particle
#endif

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

__global__ void handleOverflowParticles(particle* particles, size_t n, float dt, ulong step) {
    const int idx = threadIdx.x + blockIdx.x * blockDim.x;
    curandState cstate;

    particle_t& p = particles[idx];
    if (p.binned) return; // binned particles already handled

    for (size_t i = 0; i < n; i++) {
        particle_t& other = particles[i];
        const vector_t r = sub_vectors(p.pos, other.pos);
        if (vector_norm(r) < RC && other.type != PTYPE_NULL) {
            curand_init(idx * i, step, 0, &cstate);
            const vector_t F = compute_net_force(p, particles[i], curand_normal(&cstate), dt);
            p.acc = add_vectors(p.acc, scale_vector(p.mass, F));
            // if the other particle is binned also account for the missing interaction going the other way (negative F)
            if (other.binned) {
                // 1. Calculate the opposite force vector first
                vector_t opposite_force = scale_vector(-other.mass, F);

                // 2. Safely apply the force component-by-component using atomics
                atomicAdd(&other.acc.x, opposite_force.x);
                atomicAdd(&other.acc.y, opposite_force.y);
            }
        }
    }
#ifdef DEBUG
    particles[idx].dirty = true; //Track that we modified this particle
#endif
}

__device__ void rebinParticlesOverflow(size_t particleBufferSize, particle* particles, particle** bins, int* bin_counts) {
    int idx = threadIdx.x + blockIdx.x * blockDim.x;

    if (idx >= particleBufferSize) return;

    particle& p = particles[idx];
    p.binned = true; // mark p as binned to begin with (undone if it doesn't get a spot)

    const size_t binBaseIdx = position_to_bin_index_overflow(p.pos);
    const int ticketNumber = atomicAdd(&bin_counts[binBaseIdx / PARTICLES_PER_BIN], 1);
    
    if (ticketNumber >= PARTICLES_PER_BIN) {
        /* TOO BAD SO SAD. Your particle doesn't get binned */
        p.binned = false; // but we still account for it in thhe overflow kernel
        bin_counts[binBaseIdx / PARTICLES_PER_BIN] = PARTICLES_PER_BIN; // reset the count back to the cap
        return;
    }

    bins[binBaseIdx + ticketNumber] = &particles[idx];
}

__global__ void initialRebinOverflow(size_t particleBufferSize, particle_t* particles, particle_t** bins, int* bin_counts) { //
    rebinParticlesOverflow(particleBufferSize, particles, bins, bin_counts);
}

__global__ void integrateForcesOverflow(uchar4* d_ptr, size_t particleBufferSize, particle_t* particles, particle_t** bins, int* binCounts, float deltaTime) {
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

    rebinParticlesOverflow(particleBufferSize, particles, bins, binCounts);

    d_ptr[static_cast<int>(roundf(p.pos.x)) + static_cast<int>(roundf(p.pos.y)) * SIM_WIDTH] = ucharFromParticle(p);
}

//Host Utility

static inline void resetBinCounts() {
    cudaError_t err;
    err = cudaMemset(d_bin_counts, 0, NUM_BINS * NUM_BINS * sizeof(int));
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));
    cudaMemset(d_bins, 0, sizeof(particle*) * NUM_BINS * NUM_BINS * PARTICLES_PER_BIN);
}

void launchGeneratePixelsOverflow(uchar4* d_ptr, float deltaTime) {
    dim3 blockSize(PARTICLES_PER_BIN);
    dim3 gridSize(NUM_BINS, NUM_BINS);

    cudaError_t err;

    computeForcesOverflow<<<gridSize, blockSize>>>(d_bins, d_bin_counts, deltaTime, step);
    err = cudaGetLastError();
    if (err != cudaSuccess) printf("Error Compute Forces: %s\n", cudaGetErrorString(err));

    blockSize = dim3(BLOCKSIZE);
    gridSize = dim3((particleBufferSize + BLOCKSIZE - 1 )/ BLOCKSIZE);

    handleOverflowParticles<<<gridSize, blockSize>>>(d_particles, particleBufferSize, deltaTime, step);
    if (err != cudaSuccess) printf("Error Overflow Particles: %s\n", cudaGetErrorString(err));

    resetBinCounts();

    integrateForcesOverflow<<<gridSize, blockSize>>>(d_ptr, particleBufferSize, d_particles, d_bins, d_bin_counts, deltaTime);
    err = cudaGetLastError();
    if (err != cudaSuccess) printf("Error Integrate Forces: %s\n", cudaGetErrorString(err));

#ifdef DEBUG
    if (!verifyParticleSimulation()) printf("Failed to verify simulation for all particles\n");
#endif
    step++;
}

void setupKernelOverflow(particle* h_particles) {
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
    initialRebinOverflow<<<gridSize, blockSize>>>(particleBufferSize, d_particles, d_bins, d_bin_counts);

    err = cudaGetLastError();
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));
}

void endKernelOverflow() {
    cudaError_t err;
    err = cudaFree(d_particles);
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));
}
