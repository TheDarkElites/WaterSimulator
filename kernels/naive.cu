#include "naive.h"

#include <random>

#include "../util/opengl_interface.h"

//Kernel Mains
__global__ void computeForces(particle* particles, float dt, ulong step, size_t particleBufferSize) {
    int idx = threadIdx.x + blockIdx.x * blockDim.x;

    particle& p = particles[idx];
    if (p.type != PTYPE_WATER) return;

    vector_t Force = vector_t(0, 0, 0);
    curandState cstate;

    for (int i = 0; i < particleBufferSize; i++) {
        vector_t r = sub_vectors(p.pos,particles[i].pos);
        if (vector_norm(r) < RC) {
            if (particles[i].type != PTYPE_NULL) {
                curand_init(idx * i, step, 0, &cstate);
                Force = add_vectors(Force,compute_net_force(p, particles[i], curand_normal(&cstate), dt));
            }
        }
    }
    p.acc = scale_vector(1/p.mass, Force);
}

__global__ void integrateForces(uchar4* d_ptr, particle* particles, float deltaTime) {
    int idx = threadIdx.x + blockIdx.x * blockDim.x;

    particle& p = particles[idx];
    if (p.type == PTYPE_NULL) return;

    p.vel = add_vectors(p.vel, scale_vector(deltaTime, p.acc));
    p.pos = add_vectors(p.pos, scale_vector(deltaTime, p.vel));

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

    d_ptr[static_cast<int>(roundf(p.pos.x)) + static_cast<int>(roundf(p.pos.y)) * SIM_WIDTH] = ucharFromParticle(p);
}

//Host Utility

void launchGeneratePixelsNaive(uchar4* d_ptr, float deltaTime) {
    dim3 blockSize = dim3(BLOCKSIZE);
    dim3 gridSize = dim3((particleBufferSize + BLOCKSIZE - 1 )/ BLOCKSIZE);

    cudaError_t err;

    computeForces<<<gridSize, blockSize>>>(d_particles, deltaTime, step, particleBufferSize);
    err = cudaGetLastError();
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));

    integrateForces<<<gridSize, blockSize>>>(d_ptr, d_particles, deltaTime);
    err = cudaGetLastError();
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));

    printf("FPS: %f\n", 1 / (deltaTime * SIMFACTOR));
    step++;
}

void setupKernelNaive(particle* h_particles) {
    size_t size = sizeof(particle) * particleBufferSize;

    cudaError_t err;
    err = cudaMalloc(&d_particles, size);
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));
    err = cudaMemcpy(d_particles, h_particles, size, cudaMemcpyHostToDevice);
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));
}

void endKernelNaive() {
    cudaError_t err;
    err = cudaFree(d_particles);
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));
}