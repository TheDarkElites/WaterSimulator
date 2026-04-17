#ifndef WATERSIMULATOR_PARTICLE_H
#define WATERSIMULATOR_PARTICLE_H

#endif //WATERSIMULATOR_PARTICLE_H

struct vector {
    float x; /* vector i-hat component */
    float y; /* vector j-hat component */
    /* including this for future 3d implementation */
    float z; /* vector k-hat component */

    /* constructors */

    /* default constructor - zero vector */
    vector() : x(0), y(0), z(0) {}
    /* 2D constructor - k-hat = 0 */
    vector(const float x_, const float y_) : x(x_), y(y_), z(0) {}
    /* general constructor - initializes all values */
    vector(const float x_, const float y_, const float z_) : x(x_), y(y_), z(z_) {}

    /* vector operations */

    /* vector component-wise addition */
    vector operator+(const vector& b) const {
        const vector& a = *this;
        return {a.x+b.x, a.y+b.y, a.z+b.z};
    }

    /* vector component-wise subtraction */
    vector operator-(const vector& b) const {
        const vector& a = *this;
        return {a.x-b.x, a.y-b.y, a.z-b.z};
    }

    /* vector inner product */
    float operator*(const vector& b) const {
        const vector& a = *this;
        return a.x*b.x + a.y*b.y + a.z*b.z;
    }

    /* vector norm squared */
    [[nodiscard]] float norm_squared() const {return *this * *this;}
};

/* vector scalar multiplication */
inline vector operator*(const float c, const vector& v) {
    return {c*v.x, c*v.y, c*v.z};
}

inline vector operator*(const vector& v, const float c) {
    return c * v;
}

enum particle_type {
    PTYPE_AIR, /* vacuum particle */
    PTYPE_WATER, /* fluid particle */
    PTYPE_ROCK /* solid particle */
};

struct particle {
    particle_type type; /* particle type */
    float mass; /* particle mass */
    vector pos; /* particle position vector */
    vector vel; /* particle velocity vector */
    vector acc; /* particle acceleration vector */

    /* constructors */

    /* free inertial particle at the origin */
    particle(const particle_type type_, const float mass_) :
        type(type_), mass(mass_), pos(), vel(), acc() {}
    /* free inertial particle at a position */
    particle(const particle_type type_, const float mass_, const vector& pos_) :
        type(type_), mass(mass_), pos(pos_), vel(), acc() {}
    particle(const particle_type type_, const float mass_, const float x, const float y, const float z) :
        type(type_), mass(mass_), pos(x, y, z), vel(), acc() {}
};
