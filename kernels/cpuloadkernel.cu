#include "cpuloadkernel.h"
#include <cmath>
#include <cstdio>
#include <cuda_runtime.h>
#include <device_launch_parameters.h>

__global__ void generatePixels(uchar4* d_ptr, int width, int height, particle* particles) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x >= width || y >= height) return;

    int index = y * width + x;

    particle ourparticle = particles[index];

    if (static_cast<int>(roundf(ourparticle.pos.x)) >= width || static_cast<int>(roundf(ourparticle.pos.x)) < 0 || static_cast<int>(roundf(ourparticle.pos.y)) >= height || static_cast<int>(roundf(ourparticle.pos.y)) < 0) return;

    unsigned char r = ourparticle.type == PTYPE_WATER ? 0 : 114;
    unsigned char g = ourparticle.type == PTYPE_WATER ? 63 : 114;
    unsigned char b = ourparticle.type == PTYPE_WATER ? 205 : 114;

    d_ptr[static_cast<int>(roundf(ourparticle.pos.x)) + static_cast<int>(roundf(ourparticle.pos.y)) * width] = make_uchar4(r, g, b, 255);
}

void launchGeneratePixelsCPULOAD(uchar4* d_ptr, int width, int height, float deltaTime) {
    dim3 blockSize(16, 16);
    dim3 gridSize((width + blockSize.x - 1) / blockSize.x, (height + blockSize.y - 1) / blockSize.y);

    //Realistically you will want any operations that change the particles array to occur here (or be called from here) - G.O
    //compute forces
    for (int i = 0; i < width * height; ++i) {
        particle &p = h_particles[i];
        if (p.type == PTYPE_WATER) {
            p.vel = vector(0, -0.5, 0);
        }
    }

    // update positions
    bool printed = false;
    for (int i = 0; i < width * height; ++i) {
        particle &p = h_particles[i];
        p.vel = p.vel + p.acc /** deltaTime*/;
        p.pos = p.pos + p.vel /** deltaTime*/;

        if (p.type == PTYPE_WATER && !printed) {
            printf("(%f, %f) | %f | %f | Deltatime: %f \n",p.pos.x, p.pos.y, p.vel.y, p.acc.y, deltaTime);
            printed = true;
        }
    }

    cudaError_t err;

    particle *d_particles;
    size_t size = sizeof(particle) * width * height;

    err = cudaMalloc(&d_particles, size);
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));
    err = cudaMemcpy(d_particles, h_particles, size, cudaMemcpyHostToDevice);
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));

    generatePixels<<<gridSize, blockSize>>>(d_ptr, width, height, d_particles);

    err = cudaGetLastError();
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));

    err = cudaFree(d_particles);
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));
}

