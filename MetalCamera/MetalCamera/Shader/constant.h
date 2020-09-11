//
//  constant.h
//  MetalCamera
//
//  Created by king on 2020/9/11.
//  Copyright © 2020 0x1306a94. All rights reserved.
//

#ifndef constant_h
#define constant_h

#import "ShaderTypes.h"

static matrix_float3x3 kColorConversion601FullRangeMatrix = (matrix_float3x3){
    (simd_float3){1.0, 1.0, 1.0},
    (simd_float3){0.0, -0.343, 1.765},
    (simd_float3){1.4, -0.711, 0.0},
};

static vector_float3 kColorConversion601FullRangeOffset = (vector_float3){
    -(16.0 / 255.0),
    -0.5,
    -0.5,
};

static const SSVertex quadVertices[] = {
    // 顶点坐标，分别是x、y、z、w；    纹理坐标，x、y；
    {{1.0, -1.0, 0.0, 1.0}, {1.f, 1.f}},
    {{-1.0, -1.0, 0.0, 1.0}, {0.f, 1.f}},
    {{-1.0, 1.0, 0.0, 1.0}, {0.f, 0.f}},

    {{1.0, -1.0, 0.0, 1.0}, {1.f, 1.f}},
    {{-1.0, 1.0, 0.0, 1.0}, {0.f, 0.f}},
    {{1.0, 1.0, 0.0, 1.0}, {1.f, 0.f}},
};

static const int quadVerticesLength = sizeof(quadVertices);

#endif /* constant_h */

