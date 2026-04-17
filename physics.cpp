#include "include/particle.hpp"

vector gravityForce(particle p, particle P, float G=6.67e-11) {
    vector r = P.pos - p.pos;
    vector F = ((G * 1000 * p.mass)/(r*r))*(1/(r*r) * r);
    if (r * r < 1e-6) {
        F = vector(0, 0, 0);
    }
    return F;
}