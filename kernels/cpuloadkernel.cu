#include "cpuloadkernel.h"

__global__ void generatePixels(uchar4* d_ptr, particle* particles) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x >= SIM_WIDTH || y >= SIM_HEIGHT) return;

    int index = y * SIM_WIDTH + x;

    particle p = particles[index];

    if (static_cast<int>(roundf(p.pos.x)) >= SIM_WIDTH) p.pos.x = p.pos.x - static_cast<float>(SIM_WIDTH);
    if (static_cast<int>(roundf(p.pos.x)) < 0) p.pos.x = p.pos.x + static_cast<float>(SIM_WIDTH);
    if (static_cast<int>(roundf(p.pos.y)) >= SIM_HEIGHT) p.pos.y = p.pos.y - static_cast<float>(SIM_HEIGHT);
    if (static_cast<int>(roundf(p.pos.y)) < 0) p.pos.y = p.pos.y + static_cast<float>(SIM_HEIGHT);

    if (static_cast<int>(roundf(p.pos.x)) >= SIM_WIDTH || static_cast<int>(roundf(p.pos.x)) < 0 || static_cast<int>(roundf(p.pos.y)) >= SIM_HEIGHT || static_cast<int>(roundf(p.pos.y)) < 0)  {
        printf("Particle Panic!\n");
        p.pos.x = SIM_WIDTH / 2;
        p.pos.y = SIM_HEIGHT / 2;
        p.vel.x = 0;
        p.vel.y = 0;
    }

    unsigned char r = p.type == PTYPE_WATER ? 0 : 114;
    unsigned char g = p.type == PTYPE_WATER ? 63 : 114;
    unsigned char b = p.type == PTYPE_WATER ? 205 : 114;

    d_ptr[static_cast<int>(roundf(p.pos.x)) + static_cast<int>(roundf(p.pos.y)) * SIM_WIDTH] = make_uchar4(r, g, b, 255);
}

void launchGeneratePixelsCPULOAD(uchar4* d_ptr, float deltaTime) {
    dim3 blockSize(16, 16);
    dim3 gridSize((SIM_WIDTH + blockSize.x - 1) / blockSize.x, (SIM_HEIGHT + blockSize.y - 1) / blockSize.y);

    //Realistically you will want any operations that change the particles array to occur here (or be called from here) - G.O
    //compute forces
    for (int i = 0; i < particleBufferSize; ++i) {
        particle &p = h_particles[i];
        if (p.type == PTYPE_WATER) {

        }
    }

    // update positions
    for (int i = 0; i < particleBufferSize; ++i) {
        particle &p = h_particles[i];
        p.vel = p.vel + p.acc * deltaTime;
        p.pos = p.pos + p.vel * deltaTime;
    }

    cudaError_t err;

    particle *d_particles;
    size_t size = sizeof(particle) * particleBufferSize;

    err = cudaMalloc(&d_particles, size);
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));
    err = cudaMemcpy(d_particles, h_particles, size, cudaMemcpyHostToDevice);
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));

    generatePixels<<<gridSize, blockSize>>>(d_ptr, d_particles);

    err = cudaGetLastError();
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));

    err = cudaFree(d_particles);
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));
}

void setupKernelCPU(particle* new_h_particles) {
    h_particles = new_h_particles;
}

