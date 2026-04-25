#include "opengl_interface.h"

#include <chrono>
#include <iostream>

// Static member initialization
int opengl_interface::windID = 0;
GLuint opengl_interface::pboID = 0;
GLuint opengl_interface::textureID = 0;
std::chrono::time_point<std::chrono::system_clock> opengl_interface::prevTime;
cudaGraphicsResource_t opengl_interface::cudaResource;
void (*opengl_interface::kernel)(uchar4*, int, int, float) = nullptr;

void opengl_interface::initWindow(int &argc, char **argv) {
    //Init GLUT
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA);
    glutInitWindowSize(WINDOW_WIDTH, WINDOW_HEIGHT);
    glutInitWindowPosition(0, 0);
    windID = glutCreateWindow("WaterSimulator");

    //Init GLEW
    GLenum err = glewInit();
    if (GLEW_OK != err) {
        std::cerr << "GLEW Error: " << glewGetErrorString(err) << std::endl;
        exit(1);
    }

    //OpenGL PBO matching the SIMULATION size
    glGenBuffers(1, &pboID);
    glBindBuffer(GL_PIXEL_UNPACK_BUFFER, pboID);
    glBufferData(GL_PIXEL_UNPACK_BUFFER, SIM_WIDTH * SIM_HEIGHT * 4, NULL, GL_DYNAMIC_DRAW);
    glBindBuffer(GL_PIXEL_UNPACK_BUFFER, 0);

    //Register PBO with CUDA
    cudaGraphicsGLRegisterBuffer(&cudaResource, pboID, cudaGraphicsRegisterFlagsWriteDiscard);

    //Texture that will hold our CUDA pixels
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);

    //Prevents blurring
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, SIM_WIDTH, SIM_HEIGHT, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glBindTexture(GL_TEXTURE_2D, 0);

    //callbacks
    glutDisplayFunc(render);
    glutIdleFunc(render);

}

void opengl_interface::render() {
    //deltatime
    std::chrono::nanoseconds deltaTime = std::chrono::high_resolution_clock::now() - prevTime;
    if (prevTime == std::chrono::system_clock::time_point{}) {
        deltaTime = std::chrono::nanoseconds(1000000000);
    }
    prevTime = std::chrono::high_resolution_clock::now();

    // --- CUDA PART ---
    uchar4* d_ptr;
    size_t num_bytes;

    cudaGraphicsMapResources(1, &cudaResource, 0);
    cudaGraphicsResourceGetMappedPointer((void**)&d_ptr, &num_bytes, cudaResource);

    cudaMemset(d_ptr, 0, SIM_WIDTH * SIM_HEIGHT * sizeof(uchar4)); //Clear buffer

    // Launch Kernel
    kernel(d_ptr, SIM_WIDTH, SIM_HEIGHT, std::chrono::duration_cast<std::chrono::duration<float>>(deltaTime/SIMFACTOR).count());

    cudaGraphicsUnmapResources(1, &cudaResource, nullptr);

    // --- OPENGL PART ---
    glClear(GL_COLOR_BUFFER_BIT);

    // Copy from PBO to Texture
    glBindTexture(GL_TEXTURE_2D, textureID);
    glBindBuffer(GL_PIXEL_UNPACK_BUFFER, pboID);
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, SIM_WIDTH, SIM_HEIGHT, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    glBindBuffer(GL_PIXEL_UNPACK_BUFFER, 0);

    // Draw the full-screen quad mapping the texture
    glEnable(GL_TEXTURE_2D);
    glBegin(GL_QUADS);
        glTexCoord2f(0.0f, 0.0f); glVertex2f(-1.0f, -1.0f);
        glTexCoord2f(1.0f, 0.0f); glVertex2f( 1.0f, -1.0f);
        glTexCoord2f(1.0f, 1.0f); glVertex2f( 1.0f,  1.0f);
        glTexCoord2f(0.0f, 1.0f); glVertex2f(-1.0f,  1.0f);
    glEnd();
    glDisable(GL_TEXTURE_2D);

    glutSwapBuffers();
}