#ifndef WATERSIMULATOR_VECTOR_H
#define WATERSIMULATOR_VECTOR_H

typedef struct vector {
    float x; /* vector i-hat component */
    float y; /* vector j-hat component */
    /* including this for future 3d implementation */
    float z; /* vector k-hat component */
} vector_t;

#endif //WATERSIMULATOR_VECTOR_H
