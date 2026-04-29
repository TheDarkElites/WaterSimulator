#include <iostream>
#include "util/opengl_interface.h"
#include "kernels/naive.h"

#define WALL_WIDTH 50
#define WALL_DENSITY 0.125
#define WATER_PERCENTAGE 0.05

int main(int argc, char** argv) {

    opengl_interface::initWindow(argc, argv);
    opengl_interface::kernel = launchGeneratePixelsNaive;

    std::vector<particle> WaterParticles;
    std::vector<particle> StoneParticles;

    //init table of particles for constant image

    //Setup particle start

    for (double x = 0; x < SIM_WIDTH; x+=WALL_DENSITY) {
        for (double y = 0; y < SIM_HEIGHT; y+=WALL_DENSITY) {
            if ( ((x >= SIM_WIDTH / 4 && x <= SIM_WIDTH / 4 + WALL_WIDTH) || (x >= 3 * SIM_WIDTH / 4 && x <= 3 * SIM_WIDTH / 4 + WALL_WIDTH)) && (y >= SIM_HEIGHT / 4 && y <= 3 * SIM_HEIGHT / 4 + WALL_WIDTH) ||
             ((y >= SIM_HEIGHT / 4 && y <= SIM_HEIGHT / 4 + WALL_WIDTH) || (y >= 3 * SIM_HEIGHT / 4 && y <= 3 * SIM_HEIGHT / 4 + WALL_WIDTH)) && (x >= SIM_WIDTH / 4 && x <= 3 * SIM_WIDTH / 4 + WALL_WIDTH) ) {
                        StoneParticles.emplace_back(PTYPE_ROCK, 1, vector_t(x, y));
             }
        }
    }

    for (int i = 0; i < SIM_WIDTH * SIM_HEIGHT * WATER_PERCENTAGE; i++) {
        WaterParticles.emplace_back(PTYPE_WATER, 1, vector(SIM_WIDTH/2 + (std::rand() % 4 - 2), SIM_HEIGHT/2 + (std::rand() % 4 - 2)));
    }

    //Init particle table

    particleBufferSize = (WaterParticles.size() + StoneParticles.size());
    particle* h_particles = static_cast<particle*>(malloc(particleBufferSize * sizeof(particle)));
    memcpy(h_particles, WaterParticles.data(), WaterParticles.size() * sizeof(particle));
    memcpy(h_particles + WaterParticles.size(), StoneParticles.data(), StoneParticles.size() * sizeof(particle));

    //Setup kernel

    setupKernel(h_particles);

    //UPDATING PARTICLES SHOULD BE DONE IN kernels/cpuloadkernel.cu IN THE HOST FUNCTION - G.O

    //loop

    glutMainLoop();

    return 0;
}
