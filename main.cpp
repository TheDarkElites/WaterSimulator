#include <iostream>
#include <random>
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

    // We represent each cell with a char
    // 0 - for air, 1 - for water, we can add aditional substances/materials later
    char* grid = new char[gridX*gridY];

    if (randomInit) {
        cout << "Randomly initializing " << gridX << " by " << gridY << " grid" << endl;
        std::random_device rd; // seed
        std::mt19937 gen(rd()); // Mersenne Twister engine
        std::uniform_int_distribution<> dist(0, 1); // range [0, 1]

        for (int i = 0; i < gridX*gridY; ++i) grid[i] = dist(gen);

        // this code will crash for grid size < 10
        // remove it after we get the display going
        cout << "Generated Grid" << endl;
        for (int i = 0; i < 10; ++i) {
            for (int j = 0; j < 10; ++j) cout << (int) grid[i*gridX + j] << " ";
            cout << endl;
        }
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