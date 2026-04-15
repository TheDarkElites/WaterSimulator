#include "cpuloadkernel.h"
#include <cmath>
#include <cuda_runtime.h>
#include <device_launch_parameters.h>

__global__ void generatePixels(uchar4* d_ptr, int width, int height, particle* particles) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x >= width || y >= height) return;

    int index = y * width + x;

    particle ourparticle = particles[index];

    unsigned char r = ourparticle.type == PTYPE_AIR ? 0 : ourparticle.type == PTYPE_WATER ? 0 : 114;
    unsigned char g = ourparticle.type == PTYPE_AIR ? 0 : ourparticle.type == PTYPE_WATER ? 63 : 114;
    unsigned char b = ourparticle.type == PTYPE_AIR ? 0 : ourparticle.type == PTYPE_WATER ? 205 : 114;

    d_ptr[static_cast<int>(roundf(ourparticle.pos.x)) + static_cast<int>(roundf(ourparticle.pos.y)) * width] = make_uchar4(r, g, b, 255);
}

void launchGeneratePixelsCPULOAD(uchar4* d_ptr, int width, int height, float time) {
    dim3 blockSize(16, 16);
    dim3 gridSize((width + blockSize.x - 1) / blockSize.x, (height + blockSize.y - 1) / blockSize.y);

    //Realistically you will want any operations that change the particles array to occur here (or be called from here) - G.O

    particle* d_particles;
    cudaMalloc(&d_particles, sizeof(particle) * width * height);
    cudaMemcpy(d_particles, h_particles, sizeof(particle) * width * height, cudaMemcpyHostToDevice);

    generatePixels<<<gridSize, blockSize>>>(d_ptr, width, height, d_particles);

    cudaFree(d_particles);
}

