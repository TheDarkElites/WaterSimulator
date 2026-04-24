#include "include/physics.h"

vector gravityForce(particle p, particle P, float G) {
    vector r = P.pos - p.pos;
    float r_squared = std::max(r * r, std::numeric_limits<float>::min());
    vector F = ((G * 1000 * p.mass)/(r_squared))*(1/(r_squared) * r);
    return F;
}