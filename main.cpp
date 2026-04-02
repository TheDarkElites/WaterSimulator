#include <iostream>
#include <GL/glew.h>
#include <GL/glut.h>
#include <GLFW/glfw3.h>
#include "util/ogldev_util.h"

static int WIDTH = 3840;
static int HEIGHT = 2160;

// Initialize indices so they start correctly
int WindowID, writeIndex = 0, readIndex = 1;
float MouseX, MouseY;
bool MouseDown;

const char* pVSFileName = "../shader/shaderpixel.vsh";
const char* pFSFileName = "../shader/shaderpixel.fsh";

GLuint fbo[2], tex[2];
GLuint VBO; // Added missing VBO declaration

static void RenderSceneCB()
{

    // 2. Bind the FBO we want to DRAW TO
    glBindFramebuffer(GL_FRAMEBUFFER, fbo[writeIndex]);
    glClear(GL_COLOR_BUFFER_BIT);

    // 3. Bind the texture we want to READ FROM (the previous frame)
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, tex[readIndex]);

    // Pass input to shader and previous buffer
    GLint currentProgram;
    glGetIntegerv(GL_CURRENT_PROGRAM, &currentProgram);

    int mouseLoc = glGetUniformLocation(currentProgram, "mousePos");
    int resLoc = glGetUniformLocation(currentProgram, "resolution");
    int mouseStateLoc = glGetUniformLocation(currentProgram, "mouseDown");
    int prevBufferLoc = glGetUniformLocation(currentProgram, "prevBuffer");

    glUniform2f(mouseLoc, MouseX, MouseY);
    glUniform1i(mouseStateLoc, MouseDown);
    glUniform1i(prevBufferLoc, 0);

    GLint viewport[4];
    glGetIntegerv(GL_VIEWPORT, viewport);
    int fbWidth = viewport[2];  // Width is the 3rd element
    int fbHeight = viewport[3]; // Height is the 4th element

    // Now pass these to your shader
    glUniform2f(resLoc, (float)fbWidth, (float)fbHeight);

    // Position Attribute (Location 0)
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)0);

    // UV Attribute (Location 1)
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)(3 * sizeof(float)));

    glDrawArrays(GL_TRIANGLES, 0, 6);

    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);

    // 4. Blit (copy) the FBO we just wrote to over to the default screen buffer
    glBindFramebuffer(GL_READ_FRAMEBUFFER, fbo[writeIndex]);
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
    glBlitFramebuffer(0, 0, WIDTH, HEIGHT, 0, 0, WIDTH, HEIGHT, GL_COLOR_BUFFER_BIT, GL_NEAREST);

    //Swap
    readIndex = writeIndex;
    writeIndex = 1 - writeIndex;

    glutSwapBuffers();
}

static void SetupPingPong() {
    for (int i = 0; i < 2; i++) {
        glGenFramebuffers(1, &fbo[i]);
        glGenTextures(1, &tex[i]);

        glBindTexture(GL_TEXTURE_2D, tex[i]);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, WIDTH, HEIGHT, 0, GL_RGBA, GL_FLOAT, NULL);
        // Set wrapping to CLAMP_TO_EDGE so particles don't wrap around
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE); // Added wrap safety
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

        glBindFramebuffer(GL_FRAMEBUFFER, fbo[i]);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex[i], 0);
    }
    glBindFramebuffer(GL_FRAMEBUFFER, 0); // Unbind
}

static void CreateVertexBuffer() {
    float vertices[] = {
        // Positions          // UVs
        -1.0f,  1.0f, 0.0f,   0.0f, 1.0f, // Top Left
        -1.0f, -1.0f, 0.0f,   0.0f, 0.0f, // Bottom Left
         1.0f, -1.0f, 0.0f,   1.0f, 0.0f, // Bottom Right

        -1.0f,  1.0f, 0.0f,   0.0f, 1.0f, // Top Left
         1.0f, -1.0f, 0.0f,   1.0f, 0.0f, // Bottom Right
         1.0f,  1.0f, 0.0f,   1.0f, 1.0f  // Top Right
    };

    glGenBuffers(1, &VBO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
}

static void AddShader(GLuint ShaderProgram, const char* pShaderText, GLenum ShaderType)
{
    GLuint ShaderObj = glCreateShader(ShaderType);

    if (ShaderObj == 0) {
        fprintf(stderr, "Error creating shader type %d\n", ShaderType);
        exit(0);
    }

    const GLchar* p[1];
    p[0] = pShaderText;

    GLint Lengths[1];
    Lengths[0] = (GLint)strlen(pShaderText);

    glShaderSource(ShaderObj, 1, p, Lengths);

    glCompileShader(ShaderObj);

    GLint success;
    glGetShaderiv(ShaderObj, GL_COMPILE_STATUS, &success);

    if (!success) {
        GLchar InfoLog[1024];
        glGetShaderInfoLog(ShaderObj, 1024, NULL, InfoLog);
        fprintf(stderr, "Error compiling shader type %d: '%s'\n", ShaderType, InfoLog);
        exit(1);
    }

    glAttachShader(ShaderProgram, ShaderObj);
}

static void CompileShaders() {
    GLuint ShaderProgram = glCreateProgram();

    if (ShaderProgram == 0) {
        fprintf(stderr, "Error creating shader program\n");
        exit(1);
    }

    std::string vs, fs;

    if (!ReadFile(pVSFileName, vs)) {
        exit(1);
    };

    AddShader(ShaderProgram, vs.c_str(), GL_VERTEX_SHADER);

    if (!ReadFile(pFSFileName, fs)) {
        exit(1);
    };

    AddShader(ShaderProgram, fs.c_str(), GL_FRAGMENT_SHADER);

    GLint Success = 0;
    GLchar ErrorLog[1024] = { 0 };

    glLinkProgram(ShaderProgram);

    glGetProgramiv(ShaderProgram, GL_LINK_STATUS, &Success);
    if (Success == 0) {
        glGetProgramInfoLog(ShaderProgram, sizeof(ErrorLog), NULL, ErrorLog);
        fprintf(stderr, "Error linking shader program: '%s'\n", ErrorLog);
        exit(1);
    }

    glValidateProgram(ShaderProgram);
    glGetProgramiv(ShaderProgram, GL_VALIDATE_STATUS, &Success);
    if (!Success) {
        glGetProgramInfoLog(ShaderProgram, sizeof(ErrorLog), NULL, ErrorLog);
        fprintf(stderr, "Invalid shader program: '%s'\n", ErrorLog);
        exit(1);
    }

    glUseProgram(ShaderProgram);
}

void mouseEventHandler(int button, int state, int x, int y) {
    MouseX = (float)x;
    // GLUT (0,0) is top-left, OpenGL is bottom-left. Flip.
    MouseY = (float)(HEIGHT - y);
    MouseDown = (state == GLUT_DOWN);
}

// Added motion handler so you can drag to draw
void mouseMotionHandler(int x, int y) {
    MouseX = (float)x;
    MouseY = (float)(HEIGHT - y);
}

int main(int argc, char** argv) {

    // Init
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA);
    glutInitWindowSize(WIDTH, HEIGHT);
    glutInitWindowPosition(0, 0);

    // Window
    WindowID = glutCreateWindow("WaterSimulator");

    // Moved glClearColor here (must occur AFTER window/context creation)
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);

    GLenum res = glewInit();
    if (res != GLEW_OK) {
        fprintf(stderr, "Error: '%s'\n", glewGetErrorString(res));
        return 1;
    }

    CreateVertexBuffer();
    SetupPingPong();
    CompileShaders();

    glutDisplayFunc(RenderSceneCB);
    glutIdleFunc(RenderSceneCB);
    glutMouseFunc(mouseEventHandler);
    glutMotionFunc(mouseMotionHandler); // Bind drag handler

    glutMainLoop();

    return EXIT_SUCCESS;
}