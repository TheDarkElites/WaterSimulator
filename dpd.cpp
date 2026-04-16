/* This file will contain code for various implementations related to the DPD particle simulation */
#include <"include/particle.hpp">
#include <cmath>
#include <random>
#include <algorithm>
#include <vector>

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
class RNG {
  private:
    std::mt19937 rng{12345};  
    std::normal_distribution<float> normal{0.0, 1.0};  // mean=0, std=1
    std::vector<float> thetas;

  public:
    RNG(int width, int height) { // random number engine (use default seed)
      size_t N = static_cast<size_t>(width) * height;
      thetas.resize(N*(N-1)/2);
    }

    RNG(int width, int height, int seed): RNG(width, height) { // random number engine (seeded)
      rng = std::mt19937(seed);
    }

    void generate_thetas() {
      for (size_t i = 0; i < thetas.size(); ++i)
        thetas[i] = normal(rng);
    }

    float get_theta(int i, int j) {
      if (i == j) return 0.0; // this shouldn't even happen
      if (i < j) std::swap(i, j);
      // assume i > j
      // then row i starts at (i-1)th triangular number
      size_t base = (i-1)*i/2;
      return thetas[base+j];
    }
}

vector compute_force_r(particle& i, particle& j, float theta) {
  /* TODO */
  return vector(0.0, 0.0, 0.0);
}

/* Net DPD Force */
vector compute_net_force(particle& i, particle& j) {
  return compute_force_c(i, j)
       + compute_force_d(i, j)
       + compute_force_r(i, j);
}
