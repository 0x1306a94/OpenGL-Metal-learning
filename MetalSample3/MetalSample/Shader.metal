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
    uint instanceID [[flat]];  // 不做插值处理
} RasterizerData;

half4 texture2D(texture2d<half> texture, sampler textureSampler, float2 uv);

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
            constant uint &vertexCount [[buffer(SSVertexInputIndexVertexCount)]],
            constant SSVertex *vertexArray [[buffer(SSVertexInputIndexVertices)]],
            constant SSUniform *uniformArray [[buffer(SSVertexInputIndexUniforms)]]) {
    RasterizerData out;
    uint offset = instanceID * vertexCount;
    SSVertex vertext = vertexArray[vertexID + offset];
    SSUniform uniform = uniformArray[instanceID];

    out.clipSpacePosition = uniform.projection * uniform.view * uniform.model * vertext.position;
    out.textureCoordinate = vertext.textureCoordinate;
    out.instanceID = instanceID;
    return out;
}

fragment half4
fragment_main(RasterizerData input [[stage_in]],
              constant SSProgressUniform *uniformArray [[buffer(SSVertexInputIndexUniforms)]],
              texture2d<half, access::sample> texture0 [[texture(SSFragmentTextureIndexOne)]],
              texture2d<half, access::sample> texture1 [[texture(SSFragmentTextureIndexTow)]]) {
    //    half p = half(input.instanceID) / 24.0;
    //    half4 color = half4(p * 1.0, 1.0, 1.0, 1.0);
    //    return color;
    SSProgressUniform uniform = uniformArray[input.instanceID];
    float p = uniform.progress;
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    return texture2D(p < 0.5 ? texture0 : texture1, textureSampler, input.textureCoordinate);
}

half4 texture2D(texture2d<half, access::sample> texture, sampler textureSampler, float2 uv) {
    return texture.sample(textureSampler, uv);
}

