#ifndef WATERSIMULATOR_PARTICLE_H
#define WATERSIMULATOR_PARTICLE_H

#include "vector.h"

typedef enum {
    PTYPE_NULL, /* vacuum particle */
    PTYPE_WATER, /* fluid particle */
    PTYPE_ROCK /* solid particle */
} ptype_t;

typedef struct particle {
    ptype_t type; /* particle type */
    float mass; /* particle mass */
    vector_t pos; /* particle position vector */
    vector_t  vel; /* particle velocity vector */
    vector_t acc; /* particle acceleration vector */
} particle_t;

#endif //WATERSIMULATOR_PARTICLE_H
