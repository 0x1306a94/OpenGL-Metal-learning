//
//  SSShaderTypes.h
//  MetalSample
//
//  Created by king on 2020/10/19.
//

#ifndef SSShaderTypes_h
#define SSShaderTypes_h

#include <simd/simd.h>

typedef struct {
	vector_float4 position;
	vector_float4 color;
} SSVertex;

typedef struct {
	bool transformed;
	matrix_float4x4 transform;
} SSUniform;

typedef enum SSVertexInputIndex {
	SSVertexInputIndexVertexs  = 0,
	SSVertexInputIndexUniforms = 1,
} SSVertexInputIndex;

#endif /* SSShaderTypes_h */

