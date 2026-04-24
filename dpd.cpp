/* This file will contain code for various implementations related to the DPD particle simulation */
#include <cmath>
#include "include/dpd.h"

/* Conservative Force */
float weight_c(float r) {
  return 1- (r/RC);
}

vector compute_force_c(particle& i, particle& j) {
  int a = 25; // hard coded for water
  vector r_ij = j.pos - i.pos;
  float r = std::sqrt(r_ij * r_ij); // yes we don't have a norm function :(
  if (r < epsilon) {return {};}
  float w_C = weight_c(r);
  vector r_hat = (1/r) * r_ij; // same as unit vec e
  return a * w_C * r_hat;
}

/* Dissipative Force */
float weight_d(float r) {
  return (1- (r/RC)) * (1- (r/RC));
}

vector compute_force_d(particle& i, particle& j) {
  float gamma = 4.5; // hard coded for water
  vector r_ij = j.pos - i.pos;
  vector v_ij = j.vel - i.vel;
  float r = std::sqrt(r_ij * r_ij);
  if (r < epsilon) {return {};}
  float w_D = weight_d(r);
  vector r_hat = (1/r) * r_ij; // same as unit vec e
  return -gamma * w_D * (v_ij * r_hat) * r_hat;
}

/* Random Force */
RNG::RNG(int width, int height) { // random number engine (use default seed)
  size_t N = static_cast<size_t>(width) * height;
  thetas.resize(N*(N-1)/2);
}

void RNG::generate_thetas() {
  for (size_t i = 0; i < thetas.size(); ++i)
    thetas[i] = normal(rng);
}

float RNG::get_theta(int i, int j) {
  if (i == j) return 0.0; // this shouldn't even happen
  if (i < j) std::swap(i, j);
  // assume i > j
  // then row i starts at (i-1)th triangular number
  size_t base = (i-1)*i/2;
  return thetas[base+j];
}


float weight_r(float r) {
  return 1- (r/RC);
}

vector compute_force_r(particle& i, particle& j, float theta, float dt) {
  float sigma = std::sqrt(2*4.5); // hard code for water sqrt(2*gamma)
  vector r_ij = j.pos - i.pos;
  float r = std::sqrt(r_ij * r_ij); // yes we don't have a norm function :(
  if (r < epsilon) {return {};}
  float w_R = weight_r(r);
  vector r_hat = (1/r) * r_ij; // same as unit vec e
  return sigma * w_R * (theta/std::sqrt(dt)) * r_hat;
}

/* Net DPD Force */
vector compute_net_force(particle& i, particle& j, float theta, float dt) {
  return compute_force_c(i, j)
       + compute_force_d(i, j)
       + compute_force_r(i, j, theta, dt);
}
