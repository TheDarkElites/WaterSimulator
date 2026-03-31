#include <iostream>
#include <GL/glut.h>

static int WIDTH = 1920;
static int HEIGHT = 1080;

static void RenderSceneCB() {
    glClear(GL_COLOR_BUFFER_BIT);
    glutSwapBuffers();
}

int main(int argc, char** argv) {

    //Init
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA);
    glutInitWindowSize(WIDTH, HEIGHT);
    glutInitWindowPosition(0, 0);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);

    //Window
    int windID = glutCreateWindow("WaterSimulator");

    glutDisplayFunc(RenderSceneCB);

    glutMainLoop();

    return 0;
}