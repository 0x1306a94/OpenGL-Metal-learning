//
//  ShaderTypes.h
//  MetalSample
//
//  Created by king on 2020/10/13.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

using namespace simd;

typedef struct {
    float4 position;
    float2 textureCoordinate;
} SSVertex;

typedef struct {
    float4x4 projection;
    float4x4 view;
    float4x4 model;
} SSUniform;

typedef enum SSVertexInputIndex {
    SSVertexInputIndexVertices = 0,
    SSVertexInputIndexUniforms = 1,
} SSVertexInputIndex;

typedef enum SSFragmentTextureIndex {
    SSFragmentTextureIndexOne = 0,
} SSFragmentTextureIndex;

#endif /* ShaderTypes_h */

