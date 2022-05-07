//
//  ShaderTypes.h
//  MetalSchubertBlur
//
//  Created by king on 2022/5/7.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

typedef struct {
    vector_float2 position;
    vector_float2 textureCoordinate;
} KKVertex;

typedef struct {
    float top;
    float bottom;
    float lenght;
    float saturation;
    vector_float3 dominantColor;
} KKUniform;

typedef enum KKVertexInputIndex {
    KKVertexInputIndexVertexs = 0,
    KKVertexInputIndexUniforms = 1,
} KKVertexInputIndex;

typedef enum KKFragmentTextureIndex {
    KKFragmentTextureIndexOne = 0,
    KKFragmentTextureIndexTow = 1,
} KKFragmentTextureIndex;

#endif /* ShaderTypes_h */

