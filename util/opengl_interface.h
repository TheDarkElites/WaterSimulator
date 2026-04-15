#ifndef WATERSIMULATOR_OPENGL_INTERFACE_H
#define WATERSIMULATOR_OPENGL_INTERFACE_H

#include <GL/glew.h>
#include <GL/glut.h>
#include <cuda_runtime.h>
#include <cuda_gl_interop.h>

#define WINDOW_WIDTH 3840
#define WINDOW_HEIGHT 2160

// This is your "chunky pixel" resolution.
// A 480x270 simulation scaled up to 1920x1080 will make each CUDA pixel a 4x4 block on screen.
#define SIM_WIDTH 480
#define SIM_HEIGHT 270

class opengl_interface {
public:
    static int windID;
    static GLuint pboID;
    static GLuint textureID;
    static float currentTime;

    static void initWindow(int &argc, char **argv);
private:
    static cudaGraphicsResource_t cudaResource;
    static void render();
};

#endif //WATERSIMULATOR_OPENGL_INTERFACE_H