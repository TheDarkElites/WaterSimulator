/* This file will contain code for various implementations related to the DPD particle simulation */
#include <"include/particle.hpp">
#include <cmath>

/* Conservative Force */
float weight_c(float r) {
  int rc = 10; // cutoff radius 10m (could change)
  return 1- (r/rc);
}

vector compute_force_c(particle& i, particle& j) {
  int a = 25; // hard coded for water
  vector r_ij = j.pos - i.pos;
  float r = std::sqrt(r_ij * r_ij); // yes we don't have a norm function :(
  float w_C = weight_c(r);
  vector r_hat = (1/r) * r_ij; // same as unit vec e
  return a * w_C * r_hat;
}

/* Dissipative Force */
float weight_d(float r) {
  int rc = 10; // cutoff radius 10m (could change)
  return (1- (r/rc)) * (1- (r/rc));
}

vector compute_force_d(particle& i, particle& j) {
  float gamma = 4.5; // hard coded for water
  vector r_ij = j.pos - i.pos;
  vector v_ij = j.vel - i.vel;
  float r = std::sqrt(r_ij * r_ij);
  float w_D = weight_d(r);
  vector r_hat = (1/r) * r_ij; // same as unit vec e
  return -gamma * w_D * (v_ij * r_hat) * r_hat;
}

/* Random Force */
vector compute_force_r(particle& i, particle& j) {
  /* TODO */
  return vector(0.0, 0.0, 0.0);
}

/* Net DPD Force */
vector compute_net_force(particle& i, particle& j) {
  return compute_force_c(i, j)
       + compute_force_d(i, j)
       + compute_force_r(i, j);
}
