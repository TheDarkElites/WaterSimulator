#include "generickernel.h"
#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#include <math.h>

__global__ void generatePixels(uchar4* d_ptr, int width, int height, float time) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x >= width || y >= height) return;

    int index = y * width + x;

    unsigned char r = 0;
    unsigned char g = (unsigned char)(128.0f + 127.0f * sinf(x * 0.1f + time));
    unsigned char b = (unsigned char)(128.0f + 127.0f * cosf(y * 0.1f + time));
    unsigned char a = 255;

    d_ptr[index] = make_uchar4(r, g, b, a);
}

// 2. The standard C++ wrapper function that OpenGL can call
void launchGeneratePixels(uchar4* d_ptr, int width, int height, float time) {
    dim3 blockSize(16, 16);
    dim3 gridSize((width + blockSize.x - 1) / blockSize.x, (height + blockSize.y - 1) / blockSize.y);

    // Launch the kernel
    generatePixels<<<gridSize, blockSize>>>(d_ptr, width, height, time);
}