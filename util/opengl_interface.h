#ifndef WATERSIMULATOR_OPENGL_INTERFACE_H
#define WATERSIMULATOR_OPENGL_INTERFACE_H

#include <chrono>
#include <GL/glew.h>
#include <GL/glut.h>
#include <cuda_runtime.h>
#include <cuda_gl_interop.h>

#define WINDOW_WIDTH 3840
#define WINDOW_HEIGHT 2160

#define SIM_WIDTH 480
#define SIM_HEIGHT 270

class opengl_interface {
public:
    static int windID;
    static GLuint pboID;
    static GLuint textureID;
    static std::chrono::time_point<std::chrono::system_clock> prevTime;

    static void initWindow(int &argc, char **argv);
    static void (*kernel)(uchar4*, int, int, float);
private:
    static cudaGraphicsResource_t cudaResource;
    static void render();
};

#endif //WATERSIMULATOR_OPENGL_INTERFACE_H