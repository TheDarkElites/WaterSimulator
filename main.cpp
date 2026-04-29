#include <iostream>
#include "util/opengl_interface.h"
#include "kernels/optimized.h"

#define WALL_WIDTH 50
#define WALL_DENSITY 0.125
#define WATER_PERCENTAGE 0.01

void makeWall(vector_t posA, vector_t posB, std::vector<particle>& StoneParticles) {
    int iteration = 0;
    for (double y = posA.y; y < posB.y; y+=WALL_DENSITY) {
        double xoffset = iteration & 1 ? 0 : WALL_DENSITY / 2;
        double yoffset = iteration & 1 ? 0 : WALL_DENSITY / 2;
        for (double x = posA.x; x < posB.x; x+=WALL_DENSITY) {
            StoneParticles.emplace_back(PTYPE_ROCK, 1, vector_t(x+xoffset, y+yoffset));
        }
        iteration++;
    }
}

int main(int argc, char** argv) {

    opengl_interface::initWindow(argc, argv);
    opengl_interface::kernel = launchGeneratePixelsOptimized;

    std::vector<particle> WaterParticles;
    std::vector<particle> StoneParticles;

    //init table of particles for constant image

    //Setup particle start

    //makeWall(vector((SIM_WIDTH * 3) / 7, (SIM_HEIGHT* 3) / 7), vector(((SIM_WIDTH * 3) / 7) + WALL_WIDTH, ((SIM_HEIGHT* 4) / 7) + WALL_WIDTH - 300), StoneParticles);
    //makeWall(vector((SIM_WIDTH * 3) / 7, ((SIM_HEIGHT* 4) / 7) + WALL_WIDTH - 200), vector(((SIM_WIDTH * 3) / 7) + WALL_WIDTH, ((SIM_HEIGHT* 4) / 7) + WALL_WIDTH), StoneParticles);

    //makeWall(vector((SIM_WIDTH * 4) / 7, (SIM_HEIGHT* 3) / 7), vector(((SIM_WIDTH * 4) / 7) + WALL_WIDTH, ((SIM_HEIGHT* 4) / 7) + WALL_WIDTH), StoneParticles);

   // makeWall(vector((SIM_WIDTH * 3) / 7, (SIM_HEIGHT* 3) / 7), vector(((SIM_WIDTH * 4) / 7) + WALL_WIDTH, ((SIM_HEIGHT* 3) / 7) + WALL_WIDTH), StoneParticles);
    //makeWall(vector((SIM_WIDTH * 3) / 7, (SIM_HEIGHT* 4) / 7), vector(((SIM_WIDTH * 4) / 7) + WALL_WIDTH, ((SIM_HEIGHT* 4) / 7) + WALL_WIDTH), StoneParticles);

    for (int i = 0; i < SIM_WIDTH * SIM_HEIGHT * WATER_PERCENTAGE; i++) {
        WaterParticles.emplace_back(PTYPE_WATER, 1, vector(SIM_WIDTH/2 + (std::rand() % 4 - 2), SIM_HEIGHT/2 + (std::rand() % 4 - 2)));
    }

    //Init particle table

    particleBufferSize = (WaterParticles.size() + StoneParticles.size());
    particle* new_h_particles = static_cast<particle*>(malloc(particleBufferSize * sizeof(particle)));
    memcpy(new_h_particles, WaterParticles.data(), WaterParticles.size() * sizeof(particle));
    memcpy(new_h_particles + WaterParticles.size(), StoneParticles.data(), StoneParticles.size() * sizeof(particle));

    //Setup kernel

    setupKernelOptimized(new_h_particles);

    //UPDATING PARTICLES SHOULD BE DONE IN kernels/cpuloadkernel.cu IN THE HOST FUNCTION - G.O

    //loop

    glutMainLoop();

    return 0;
}
