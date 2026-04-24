#include "cpuloadkernel.h"
#include "../include/dpd.h"
#include "../include/physics.h"
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cuda_runtime.h>
#include <device_launch_parameters.h>

#include "../util/opengl_interface.h"

static RNG rng = RNG(SIM_WIDTH, SIM_HEIGHT);

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
    // generate thetas
    rng.generate_thetas();
    //compute forces
    for (int i = 0; i < width * height; ++i) {
        particle &p = h_particles[i];
        if (p.type == PTYPE_WATER) {
            vector Force = vector();
            for (int j = 0; j < width * height; ++j) {
                vector r = p.pos - h_particles[j].pos;
                if (vecnorm(r) < RC) {
                    if (h_particles[j].type == PTYPE_WATER) {
                        Force = Force + compute_net_force(p, h_particles[j], rng.get_theta(i, j), deltaTime);
                    }
                }
                if (h_particles[j].type == PTYPE_ROCK) {
                    //Force = Force + gravityForce(p, h_particles[j], -5);
                }
            }
            p.acc = Force * (1/p.mass);
        }
    }

    // update positions
    for (int i = 0; i < width * height; ++i) {
        particle &p = h_particles[i];

        // if (p.pos.x < 0) {
        //     p.pos.x = SIM_WIDTH/2;
        //     p.vel.x = 0;
        //     p.acc.x = 0;
        // }
        // if (p.pos.x > SIM_WIDTH - 1) {
        //     p.pos.x = SIM_WIDTH/2;
        //     p.vel.x = 0;
        //     p.acc.x = 0;
        // }
        // if (p.pos.y < 0) {
        //     p.pos.y = SIM_HEIGHT/2;
        //     p.vel.y = 0;
        //     p.acc.y = 0;
        // }
        // if (p.pos.y > SIM_HEIGHT - 1) {
        //     p.pos.y = SIM_HEIGHT/2;
        //     p.vel.y = 0;
        //     p.acc.y = 0;
        // }

        p.vel = p.vel + p.acc * deltaTime;

        bool inBounds = (p.pos.x >= 0 && p.pos.x < width) && (p.pos.y >= 0 && p.pos.y < height);
        vector nextPos = p.pos + p.vel * deltaTime;
        // clamp the x
        if (nextPos.x < 0) {
            float clampedX = 0 + (0 - nextPos.x);
            nextPos.x = clampedX;
            p.vel.x *= -1; // flip the velocity
        }
        else if (nextPos.x >= width) {
            float clampedX = width - (nextPos.x - width);
            nextPos.x = clampedX;
            p.vel.x *= -1; // flip the velocity
        }
        // clamp the y
        if (nextPos.y < 0) {
            float clampedY = 0 + (0 - nextPos.y);
            nextPos.y = clampedY;
            p.vel.y *= -1; // flip the velocity
        }
        else if (nextPos.y >= height) {
            float clampedY = width - (nextPos.y - width);
            nextPos.y = clampedY;
            p.vel.y *= -1; // flip the velocity
        }

        p.pos = nextPos;

        bool tunneled = inBounds && !(p.pos.x >= 0 && p.pos.x < width && (p.pos.y >= 0 && p.pos.y < height));

        if (tunneled) printf("Tunneled\n");
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

    printf("FPS: %f\n", 1 / (deltaTime * SIMFACTOR) );
}

