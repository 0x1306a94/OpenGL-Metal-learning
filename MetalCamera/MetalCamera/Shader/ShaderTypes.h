//
//  ShaderTypes.h
//  MetalCamera
//
//  Created by king on 2020/9/11.
//  Copyright © 2020 0x1306a94. All rights reserved.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

typedef struct {
	vector_float4 position;
	vector_float2 textureCoordinate;
} SSVertex;

typedef struct {
	matrix_float3x3 matrix;
	vector_float3 offset;
} SSConvertMatrix;

typedef enum SSVertexInputIndex {
	SSVertexInputIndexVertices = 0,
} SSVertexInputIndex;

typedef enum SSFragmentBufferIndex {
	SSFragmentInputIndexMatrix = 0,
} SSFragmentBufferIndex;

typedef enum SSFragmentTextureIndex {
	SSFragmentTextureIndexGreenTextureY   = 0,
	SSFragmentTextureIndexGreenTextureUV  = 1,
	SSFragmentTextureIndexNormalTextureY  = 2,
	SSFragmentTextureIndexNormalTextureUV = 3,
} SSFragmentTextureIndex;


#endif /* ShaderTypes_h */

