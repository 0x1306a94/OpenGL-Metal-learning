//
//  Shader.metal
//  MetalSample
//
//  Created by king on 2020/10/13.
//

#include <metal_stdlib>

#include "ShaderTypes.h"
using namespace metal;

typedef struct {
    float4 clipSpacePosition [[position]];  // position的修饰符表示这个是顶点
    float2 textureCoordinate;
} RasterizerData;

float4 texture2D(texture2d<float> texture, sampler textureSampler, float2 uv);

//vertex RasterizerData
//vertex_main(uint vertexID [[vertex_id]],
//            constant SSVertex *vertexArray [[buffer(SSVertexInputIndexVertices)]]) {
//    RasterizerData out;
//    out.clipSpacePosition = vertexArray[vertexID].position;
//    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
//    return out;
//}

vertex RasterizerData
vertex_main(uint vertexID [[vertex_id]],
            uint instanceID [[instance_id]],
            constant SSVertex *vertexArray [[buffer(SSVertexInputIndexVertices)]],
            constant SSUniform *uniformArray [[buffer(SSVertexInputIndexUniforms)]]) {
    RasterizerData out;
    uint idx = instanceID * 4 + vertexID;
    SSVertex vertext = vertexArray[idx];
    SSUniform uniform = uniformArray[instanceID];

    out.clipSpacePosition = uniform.projection * uniform.view * uniform.model * vertext.position;
    out.textureCoordinate = vertext.textureCoordinate;
    return out;
}

fragment float4
fragment_main(RasterizerData input [[stage_in]],
              texture2d<float> texture [[texture(SSFragmentTextureIndexOne)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    return texture2D(texture, textureSampler, input.textureCoordinate);
}

float4 texture2D(texture2d<float> texture, sampler textureSampler, float2 uv) {
    return texture.sample(textureSampler, uv);
}

