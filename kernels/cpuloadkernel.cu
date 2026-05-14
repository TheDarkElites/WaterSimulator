#include "cpuloadkernel.h"

static RNG rng;

__global__ void generatePixels(uchar4* d_ptr, particle* particles, size_t particleBufferSize) {
    int id = blockIdx.x * blockDim.x + threadIdx.x;

    if (id >= particleBufferSize) return;

    particle ourparticle = particles[id];

    if (static_cast<int>(roundf(ourparticle.pos.x)) >= SIM_WIDTH || static_cast<int>(roundf(ourparticle.pos.x)) < 0 || static_cast<int>(roundf(ourparticle.pos.y)) >= SIM_HEIGHT || static_cast<int>(roundf(ourparticle.pos.y)) < 0) return;

    unsigned char r = ourparticle.type == PTYPE_WATER ? 0 : 114;
    unsigned char g = ourparticle.type == PTYPE_WATER ? 63 : 114;
    unsigned char b = ourparticle.type == PTYPE_WATER ? 205 : 114;

    d_ptr[static_cast<int>(roundf(ourparticle.pos.x)) + static_cast<int>(roundf(ourparticle.pos.y)) * SIM_WIDTH] = make_uchar4(r, g, b, 255);
}

void launchGeneratePixelsCPU(uchar4* d_ptr, float deltaTime) {
    dim3 blockSize = dim3(BLOCKSIZE);
    dim3 gridSize = dim3((particleBufferSize + BLOCKSIZE - 1 )/ BLOCKSIZE);

    //Realistically you will want any operations that change the particles array to occur here (or be called from here) - G.O
    // generate thetas
    rng.generate_thetas();
    //compute forces
    for (int i = 0; i < particleBufferSize; ++i) {
        particle &p = h_particles[i];
        if (p.type == PTYPE_WATER) {
            vector Force = vector();
            for (int j = 0; j < particleBufferSize; ++j) {
                vector r = p.pos - h_particles[j].pos;
                if (vecnorm(r) < RC) {
                    if (h_particles[j].type == PTYPE_WATER) {
                        Force = Force + compute_net_force(p, h_particles[j], rng.get_theta(i, j), deltaTime);
                    }
                }
            }
            p.acc = Force * (1/p.mass);
        }
    }

    // update positions
    for (int i = 0; i < particleBufferSize; ++i) {
        particle &p = h_particles[i];

        p.vel = p.vel + p.acc * deltaTime;
        p.pos = p.pos + p.acc * deltaTime;

        if (static_cast<int>(roundf(p.pos.x)) >= SIM_WIDTH) p.pos.x = p.pos.x - static_cast<float>(SIM_WIDTH);
        if (static_cast<int>(roundf(p.pos.x)) < 0) p.pos.x = p.pos.x + static_cast<float>(SIM_WIDTH);
        if (static_cast<int>(roundf(p.pos.y)) >= SIM_HEIGHT) p.pos.y = p.pos.y - static_cast<float>(SIM_HEIGHT);
        if (static_cast<int>(roundf(p.pos.y)) < 0) p.pos.y = p.pos.y + static_cast<float>(SIM_HEIGHT);

        if (static_cast<int>(roundf(p.pos.x)) >= SIM_WIDTH || static_cast<int>(roundf(p.pos.x)) < 0 || static_cast<int>(roundf(p.pos.y)) >= SIM_HEIGHT || static_cast<int>(roundf(p.pos.y)) < 0)  {
            printf("Particle Panic!\n");
            p.pos.x = SIM_WIDTH / 2;
            p.pos.y = SIM_HEIGHT / 2;
            p.vel = vector();
        }
    }

    cudaError_t err;

    particle *d_particles;
    size_t size = sizeof(particle) * particleBufferSize;

    err = cudaMalloc(&d_particles, size);
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));
    err = cudaMemcpy(d_particles, h_particles, size, cudaMemcpyHostToDevice);
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));

    generatePixels<<<gridSize, blockSize>>>(d_ptr, d_particles, particleBufferSize);

    err = cudaGetLastError();
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));

    err = cudaFree(d_particles);
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));

    printf("FPS: %f\n", 1 / (deltaTime * SIMFACTOR) );
}

void setupKernelCPU(particle *h_particles_new) {
    h_particles = h_particles_new;
    rng = RNG();
}
