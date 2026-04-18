//
// Created by George on 4/17/26.
//

#ifndef WATERSIMULATOR_DPD_H
#define WATERSIMULATOR_DPD_H
#include "particle.hpp"
#include <random>
#include <algorithm>
#include <vector>

#define RC 2

/* Conservative Force */
vector compute_force_c(particle& i, particle& j);

/* Dissipative Force */
vector compute_force_d(particle& i, particle& j);

/* Random Force */
vector compute_force_r(particle& i, particle& j, float theta, float dt);

/* Net DPD Force */
vector compute_net_force(particle& i, particle& j, float theta, float dt);

/* Random Force */
class RNG {
private:
    std::mt19937 rng{12345};
    std::normal_distribution<float> normal{0.0, 1.0};  // mean=0, std=1
    std::vector<float> thetas;
public:
    RNG(int width, int height);
    RNG(int width, int height, int seed): RNG(width, height) { // random number engine (seeded)
        rng = std::mt19937(seed);
    }
    void generate_thetas();
    float get_theta(int i, int j);
};

#endif //WATERSIMULATOR_DPD_H
