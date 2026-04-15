#include <iostream>
#include "util/opengl_interface.h"
#include "kernels/generickernel.h"

static int WIDTH = 1920;
static int HEIGHT = 1080;

static void RenderSceneCB() {
    glClear(GL_COLOR_BUFFER_BIT);
    glutSwapBuffers();
}

int main(int argc, char** argv) {

    opengl_interface::initWindow(argc, argv);\
    opengl_interface::kernel = launchGeneratePixels;
    glutMainLoop();

    return 0;
}