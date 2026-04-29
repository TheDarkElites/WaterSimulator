#include "physics.h"

// Physics Forces

/* Conservative Force */
__device__ float weight_c(float r) {
    return 1- (r/RC);
}

__device__ vector_t compute_force_c(const particle_t& i, const particle_t& j) {
    vector_t r_ij = sub_vectors(i.pos, j.pos);
    float r = vector_norm(r_ij);
    if (r < epsilon) return vector_t(0, 0, 0);
    float w_C = weight_c(r);
    vector_t r_hat = normalize(r_ij); // same as unit vec e
    return scale_vector(i.type == PTYPE_WATER && j.type == PTYPE_WATER ? a : a_rock_water * w_C, r_hat);
}

/* Dissipative Force */
__device__ float weight_d(float r) {
    return (1- (r/RC)) * (1- (r/RC));
}

__device__ vector_t compute_force_d(const particle_t& i, const particle_t& j) {
    float gamma = 4.5; // hard coded for water
    vector_t r_ij = sub_vectors(i.pos, j.pos);
    vector_t v_ij = sub_vectors(i.vel, j.vel);
    float r = vector_norm(r_ij);
    if (r < epsilon) return vector_t(0, 0, 0);
    float w_D = weight_d(r);
    vector_t r_hat = normalize(r_ij); // same as unit vec e
    return scale_vector(-gamma * w_D * dot_product(v_ij, r_hat), r_hat);
}

/* Random Force */

__device__ float weight_r(float r) {
    return 1- (r/RC);
}

__device__ vector_t compute_force_r(const particle_t& i, const particle_t& j, float theta, float dt) {
    float sigma = sqrt(2*4.5*kT); // hard code for water sqrt(2*gamma*kT)
    vector_t r_ij = sub_vectors(i.pos, j.pos);
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