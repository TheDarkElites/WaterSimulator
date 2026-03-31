cmake_minimum_required(VERSION 4.3)
project(WaterSimulator)

set(CMAKE_CXX_STANDARD 20)

add_executable(WaterSimulator main.cpp)
target_link_libraries(main PRIVATE OpenGL::GL OpenGL::GLU GLUT::GLUT)
