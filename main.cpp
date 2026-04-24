#include <iostream>
#include "util/opengl_interface.h"
#include "kernels/cpuloadkernel.h"

int main(int argc, char** argv) {

    opengl_interface::initWindow(argc, argv);
    opengl_interface::kernel = launchGeneratePixelsCPULOAD;

    //init table of particles for constant image
    h_particles = static_cast<particle*>(malloc(sizeof(particle) * SIM_WIDTH * SIM_HEIGHT));

    for (int x = 0; x < SIM_WIDTH; x++) {
        for (int y = 0; y < SIM_HEIGHT; y++) {
            if (std::rand() % 2 == 0) {
                h_particles[x + (y * SIM_WIDTH)] = particle(PTYPE_WATER, 1, vector(x, y));
            }
            if (x == 0 || y == 0 || x == SIM_WIDTH - 1 || y == SIM_HEIGHT - 1) {
                h_particles[x + (y * SIM_WIDTH)] = particle(PTYPE_ROCK, 1, vector(x, y));
            }
        }
    }

    //UPDATING PARTICLES SHOULD BE DONE IN kernels/cpuloadkernel.cu IN THE HOST FUNCTION - G.O

    //loop

    glutMainLoop();

    return 0;
}
