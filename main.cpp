#include <iostream>
#include <GL/glut.h>

using std::cout;
using std::endl;
using std::stoi;

static int WIDTH = 1920;
static int HEIGHT = 1080;

static void RenderSceneCB() {
    glClear(GL_COLOR_BUFFER_BIT);
    glutSwapBuffers();
}

int main(int argc, char** argv) {
    int gridX, gridY;
    bool randomInit = true;

    if (argc == 1) {
        gridX = 100;
        gridY = 100;
    }
    else if (argc >= 3) {
        gridX = stoi(argv[1]);
        gridY = stoi(argv[2]);
        // only random init if filename not provided
        randomInit = argc == 3;
    }
    else {
        cout << "Usage: " << argv[0] << " [cellsX] [cellsY] [initial-steup-file]" << endl;
    }

    if (randomInit) {
        cout << "Randomly initializing " << gridX << " by " << gridY << " grid" << endl;
        cout << "Operation currently not supported!" << endl;
        exit(EXIT_SUCCESS);
    }
    else {
        const char* filename = argv[3];
        cout << "Initializing " << gridX << " by " << gridY << " grid from " << filename << endl;
        cout << "Operation currently not supported!" << endl;
        exit(EXIT_SUCCESS);
    }

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