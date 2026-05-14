#include "debugkernel.h"
#include <assert.h>
#include <cuda_runtime.h>

__global__ void verifySimulation(particle_t* p, size_t n, debugreturn* r) {
    extern __shared__ unsigned long long s[];
    int tid = threadIdx.x, idx = tid + blockIdx.x * blockDim.x;
    unsigned long long *sc = s, *sf = s + blockDim.x;
    sc[tid] = sf[tid] = 0;

#ifndef DEBUG
    assert(false);
#else
    if (idx < n) {
        if (p[idx].dirty) { sc[tid] = 1; p[idx].dirty = false; }
        else sf[tid] = 1;
    }
    __syncthreads();

    for (int i = blockDim.x / 2; i > 0; i >>= 1) {
        if (tid < i) {
            sc[tid] += sc[tid + i];
            sf[tid] += sf[tid + i];
        }
        __syncthreads();
    }

    if (tid == 0) {
        if (sc[0]) atomicAdd((unsigned long long*)&r->particlesCalc, sc[0]);
        if (sf[0]) atomicAdd((unsigned long long*)&r->particlesFail, sf[0]);
    }
#endif
}

bool verifyParticleSimulation() {
    dim3 blockSize = dim3(BLOCKSIZE);
    dim3 gridSize = dim3((particleBufferSize + BLOCKSIZE - 1 )/ BLOCKSIZE);

    debugreturn_t* ret_d;

    cudaMalloc((void**)&ret_d, sizeof(debugreturn));
    cudaMemset(ret_d, 0, sizeof(debugreturn));
    size_t sharedMem = 2 * BLOCKSIZE * sizeof(unsigned long long);

    verifySimulation<<<gridSize, blockSize,sharedMem>>>(d_particles, particleBufferSize, ret_d);

    cudaError_t err = cudaGetLastError();
    if (err != cudaSuccess) printf("Error Debug Kernel: %s\n", cudaGetErrorString(err));

    debugreturn_t* ret = (debugreturn*)malloc(sizeof(debugreturn));
    cudaMemcpy(ret, ret_d, sizeof(debugreturn), cudaMemcpyDeviceToHost);

    printf("Sim Summary:\n   ParticlesSimulated: %llu\n   ParticlesFailedToSimulate: %llu\n", ret->particlesCalc, ret->particlesFail);
    bool success = ret->particlesFail == 0;
    cudaFree(ret_d);
    free(ret);
    return success;
}