//
//  Shader.metal
//  MetalLoadOBJ
//
//  Created by king on 2022/9/22.
//

#include <metal_geometric>
#include <metal_graphics>
#include <metal_math>
#include <metal_matrix>
#include <metal_stdlib>
#include <metal_texture>
#include <simd/simd.h>

#include "AAPLShaderTypes.h"

using namespace metal;

struct VertexIn {
    float3 position [[attribute(AAPLVertexAttributePosition)]];
    float3 normal [[attribute(AAPLVertexAttributeNormal)]];
    half2 texcoord [[attribute(AAPLVertexAttributeTexcoord)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
    half2 texcoord;
    float occlusion;
};

constant float3 lightPosition = float3(0.0, 1.0, -1.0);

vertex VertexOut vertex_func(const VertexIn in [[stage_in]],
                             constant AAPLFrameUniforms &frameUniforms [[buffer(AAPLFrameUniformBuffer)]],
                             uint vertexId [[vertex_id]]) {
    float4 position = float4(in.position, 1.0);
    VertexOut out;
    out.position = frameUniforms.projectionView * position;
    out.color = float4(0.2, 0.4, 0.4, 1.0);

    float4 eye_normal = normalize(frameUniforms.normal * float4(in.normal, 0.0));
    float n_dot_l = dot(eye_normal.rgb, normalize(lightPosition));
    n_dot_l = fmax(0.0, n_dot_l);
    out.color = n_dot_l;  //half4(materialUniforms.emissiveColor + n_dot_l);

    out.texcoord = in.texcoord;
    return out;
}

fragment half4 fragment_func(VertexOut in [[stage_in]],
                             texture2d<float> texture [[texture(AAPLNormalTextureIndex)]]) {
    constexpr sampler defaultSampler(coord::normalized,
                                     address::repeat,
                                     mag_filter::nearest,
                                     min_filter::linear);

    float4 baseColor = in.color;
    baseColor = texture.sample(defaultSampler, float2(in.texcoord));
    return half4(baseColor);
}

