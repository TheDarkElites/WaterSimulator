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

//Kernel Mains
__global__ void computeForces(int width, int height, particle* particles, float dt, ulong step) {
    int idx = threadIdx.x + blockIdx.x * blockDim.x;
    int idy = threadIdx.y + blockIdx.y * blockDim.y;

    particle& p = particles[idx + idy * width];
    if (p.type != PTYPE_WATER) return;

    vector_t Force = vector_t(0, 0, 0);
    curandState cstate;

    for (int i = 0; i < width * height; i++) {
        vector_t r = sub_vectors(p.pos,particles[i].pos);
        if (vector_norm(r) < RC) {
            if (particles[i].type == PTYPE_WATER) {
                curand_init((idx + idy * width) * i, step, 0, &cstate);
                Force = add_vectors(Force,compute_net_force(p, particles[i], curand_normal(&cstate), dt));
            }
        }
        if (particles[i].type == PTYPE_ROCK) {
            Force = add_vectors(Force, gravityForce(p, particles[i], wall_grav));
        }
    }
    p.acc = scale_vector(1/p.mass, Force);
}

__global__ void integrateForces(uchar4* d_ptr, int width, int height, particle* particles, float deltaTime) {
    int idx = threadIdx.x + blockIdx.x * blockDim.x;
    int idy = threadIdx.y + blockIdx.y * blockDim.y;

    particle& p = particles[idx + idy * width];
    if (p.type == PTYPE_NULL) return;

    p.vel = add_vectors(p.vel, scale_vector(deltaTime, p.acc));
    p.pos = add_vectors(p.pos, scale_vector(deltaTime, p.vel));

    if (static_cast<int>(roundf(p.pos.x)) >= width || static_cast<int>(roundf(p.pos.x)) < 0 || static_cast<int>(roundf(p.pos.y)) >= height || static_cast<int>(roundf(p.pos.y)) < 0) return;

    d_ptr[static_cast<int>(roundf(p.pos.x)) + static_cast<int>(roundf(p.pos.y)) * width] = ucharFromParticle(p);
}

//Host Utility

void launchGeneratePixelsNaive(uchar4* d_ptr, int width, int height, float deltaTime) {
    dim3 blockSize(16, 16);
    dim3 gridSize((width + blockSize.x - 1) / blockSize.x, (height + blockSize.y - 1) / blockSize.y);

    cudaError_t err;

    computeForces<<<gridSize, blockSize>>>(width, height, d_particles, deltaTime, step);
    err = cudaGetLastError();
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));

    integrateForces<<<gridSize, blockSize>>>(d_ptr, width, height, d_particles, deltaTime);
    err = cudaGetLastError();
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));

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
}

void endKernel() {
    cudaError_t err;
    err = cudaFree(d_particles);
    if (err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(err));
}
