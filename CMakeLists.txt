cmake_minimum_required(VERSION 4.1)
project(WaterSimulator LANGUAGES CXX CUDA)

set(CMAKE_CXX_STANDARD 20)

find_package(OpenGL REQUIRED)
find_package(GLUT REQUIRED)
find_package(GLEW REQUIRED)
find_package(CUDAToolkit REQUIRED)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include(CheckLanguage)
check_language(CUDA)

add_executable(WaterSimulator main.cpp util/ogldev_util.cpp
        include/particle.hpp
        util/opengl_interface.cpp
        util/opengl_interface.h
        kernels/testkernel.h
        kernels/testkernel.cu
        kernels/cpuloadkernel.cu
        kernels/cpuloadkernel.h
        physics.cpp
        dpd.cpp
        include/dpd.h
)

target_include_directories(WaterSimulator PRIVATE ${CUDAToolkit_INCLUDE_DIRS})

set_target_properties(WaterSimulator PROPERTIES LINKER_LANGUAGE CXX)
target_link_libraries(WaterSimulator PRIVATE OpenGL::GL OpenGL::GLU GLUT::GLUT GLEW::GLEW CUDA::cudart)

set_target_properties(WaterSimulator PROPERTIES CUDA_SEPARABLE_COMPILATION ON)
