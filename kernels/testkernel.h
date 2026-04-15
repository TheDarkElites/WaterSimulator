//
// Created by George on 4/15/26.
//

#ifndef WATERSIMULATOR_GENERICKERNEL_H
#define WATERSIMULATOR_GENERICKERNEL_H

#include <cuda_runtime.h>

void launchGeneratePixels(uchar4* d_ptr, int width, int height, float time);

#endif //WATERSIMULATOR_GENERICKERNEL_H
