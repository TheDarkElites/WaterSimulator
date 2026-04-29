#ifndef WATERSIMULATOR_PHYSICS_H
#define WATERSIMULATOR_PHYSICS_H

#include "../include/particle.h"
#include "vector_tools.h"

#define RC 2
//Conservative Force Constant
constexpr float a = 25;
constexpr float a_rock_water = 600;

constexpr float epsilon = 1e-6;
constexpr float kT = 1;

__device__ vector_t compute_net_force(const particle& i, const particle& j, float theta, float dt);

#endif //WATERSIMULATOR_PHYSICS_H