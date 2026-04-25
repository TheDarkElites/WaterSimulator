#ifndef WATERSIMULATOR_PARTICLE_H
#define WATERSIMULATOR_PARTICLE_H

#endif //WATERSIMULATOR_PARTICLE_H

typedef struct vector {
    float x; /* vector i-hat component */
    float y; /* vector j-hat component */
    /* including this for future 3d implementation */
    float z; /* vector k-hat component */
} vector_t;

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
