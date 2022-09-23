//
//  AAPLShaderTypes.h
//  MetalLoadOBJ
//
//  Created by king on 2022/9/22.
//

#ifndef AAPLShaderTypes_h
#define AAPLShaderTypes_h

#include <simd/simd.h>

using namespace simd;
/// Indices of vertex attribute in descriptor.
enum AAPLVertexAttributes {
    AAPLVertexAttributePosition = 0,
    AAPLVertexAttributeNormal = 1,
    AAPLVertexAttributeTexcoord = 2,
};

/// Indices for texture bind points.
enum AAPLTextureIndex {
    AAPLNormalTextureIndex = 0,
    AAPLDiffuseTextureIndex = 1,
};

/// Indices for buffer bind points.
enum AAPLBufferIndex {
    AAPLMeshVertexBuffer = 0,
    AAPLFrameUniformBuffer = 1,
    AAPLMaterialUniformBuffer = 2,
};

/// Per frame uniforms.
typedef struct {
    float4x4 model;
    float4x4 view;
    float4x4 projection;
    float4x4 projectionView;
    float4x4 normal;
} AAPLFrameUniforms;

/// Material uniforms.
typedef struct {
    float4 emissiveColor;
    float4 diffuseColor;
    float4 specularColor;

    float specularIntensity;
    float pad1;
    float pad2;
    float pad3;
} AAPLMaterialUniforms;

#endif /* AAPLShaderTypes_h */

