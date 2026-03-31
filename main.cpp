#include <iostream>
#include <GL/glew.h>
#include <GL/glut.h>
#include "util/ogldev_util.h"

static int WIDTH = 1920;
static int HEIGHT = 1080;

const char* pVSFileName = "shader.vs";
const char* pFSFileName = "shader.fs";

static void RenderSceneCB() {
    glClear(GL_COLOR_BUFFER_BIT);
    glutSwapBuffers();
}

static void CreateVertexBuffer() {

}

static void CompileShaders() {
    GLuint ShaderProgram = __glewCreateProgram();

    if (ShaderProgram == 0) {
        fprintf(stderr, "Error creating shader program\n");
        exit(EXIT_FAILURE);
    }

    std::string vs, fs;

    if (!ReadFile(pVSFileName, vs)) {
        exit(EXIT_FAILURE);
    }
}

int main(int argc, char** argv) {

    //Init
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA);
    glutInitWindowSize(WIDTH, HEIGHT);
    glutInitWindowPosition(0, 0);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);

    //Glew
    GLenum res = glewInit();
    if (res != GLEW_OK) {
        fprintf(stderr, "Glew Error: '%s'\n", glewGetErrorString(res));
        return EXIT_FAILURE;
    }

    //Window
    int windID = glutCreateWindow("WaterSimulator");

    glutDisplayFunc(RenderSceneCB);

    glutMainLoop();

    return EXIT_SUCCESS;
}