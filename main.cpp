#include <iostream>
#include "util/opengl_interface.h"
#include "kernels/naive.h"

int main(int argc, char** argv) {

    opengl_interface::initWindow(argc, argv);
    opengl_interface::kernel = launchGeneratePixelsNaive;

    //init table of particles for constant image
    particle* h_particles = static_cast<particle*>(malloc(sizeof(particle) * SIM_WIDTH * SIM_HEIGHT));

    for (int x = 0; x < SIM_WIDTH; x++) {
        for (int y = 0; y < SIM_HEIGHT; y++) {
            if (x == 0 || y == 0 || x == SIM_WIDTH - 1 || y == SIM_HEIGHT - 1) {
                //h_particles[x + (y * SIM_WIDTH)] = particle(PTYPE_ROCK, 1, vector(x, y));
            }
            else if (std::rand() % 100 == 0) {
                h_particles[x + (y * SIM_WIDTH)] = particle(PTYPE_WATER, 1, vector(x, y));
            }
            else {
                h_particles[x + (y * SIM_WIDTH)] = particle(PTYPE_NULL, 0, vector());
            }
        }
    }

    setupKernel(h_particles);

    //UPDATING PARTICLES SHOULD BE DONE IN kernels/cpuloadkernel.cu IN THE HOST FUNCTION - G.O

    //loop

    glutMainLoop();

    return 0;
}
