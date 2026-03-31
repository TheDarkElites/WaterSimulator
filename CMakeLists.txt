cmake_minimum_required(VERSION 4.3)
project(WaterSimulator CXX)

set(CMAKE_CXX_STANDARD 20)

find_package(OpenGL REQUIRED)
find_package(GLUT REQUIRED)

add_executable(WaterSimulator main.cpp)
set_target_properties(WaterSimulator PROPERTIES LINKER_LANGUAGE CXX)
target_link_libraries(WaterSimulator PRIVATE OpenGL::GL OpenGL::GLU GLUT::GLUT)
