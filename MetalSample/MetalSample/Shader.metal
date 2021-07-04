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

float4 fxaa(texture2d<float> buf0, sampler textureSampler, float2 texCoords, float2 frameBufSize);

vertex RasterizerData
vertex_main(uint vertexID [[vertex_id]],
            constant SSVertex *vertexArray [[buffer(SSVertexInputIndexVertices)]],
            constant SSUniform &uniforms [[buffer(SSVertexInputIndexUniforms)]]) {
    RasterizerData out;
    out.clipSpacePosition = uniforms.projection * uniforms.model * vertexArray[vertexID].position;
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    return out;
}

fragment float4
fragment_main(RasterizerData input [[stage_in]],
              texture2d<float> texture [[texture(SSFragmentTextureIndexOne)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    return texture2D(texture, textureSampler, input.textureCoordinate);
}

fragment float4
fragment_fxaa_main(RasterizerData input [[stage_in]],
                   constant float2 &size [[buffer(0)]],
                   constant bool &enable [[buffer(1)]],
                   texture2d<float> texture [[texture(SSFragmentTextureIndexOne)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    if (!enable) {
        return texture2D(texture, textureSampler, input.textureCoordinate);
    }
    float4 color = fxaa(texture, textureSampler, input.textureCoordinate, size);
    return color;
}

float4 texture2D(texture2d<float> texture, sampler textureSampler, float2 uv) {
    return texture.sample(textureSampler, uv);
}

// https://developer.apple.com/forums/thread/25443
float4 fxaa(texture2d<float> texture, sampler textureSampler, float2 texCoords, float2 frameBufSize) {
    constexpr float FXAA_SPAN_MAX   = 8.0;
    constexpr float FXAA_REDUCE_MUL = 1.0 / 8.0;
    constexpr float FXAA_REDUCE_MIN = 1.0 / 128.0;

    float2 v_rgbNW = texCoords + (float2(-1.0, -1.0) / frameBufSize);
    float2 v_rgbNE = texCoords + (float2(1.0, -1.0) / frameBufSize);
    float2 v_rgbSW = texCoords + (float2(-1.0, 1.0) / frameBufSize);
    float2 v_rgbSE = texCoords + (float2(1.0, 1.0) / frameBufSize);
    float2 v_rgbM  = texCoords;

    float3 rgbNW = texture2D(texture, textureSampler, v_rgbNW).xyz;
    float3 rgbNE = texture2D(texture, textureSampler, v_rgbNE).xyz;
    float3 rgbSW = texture2D(texture, textureSampler, v_rgbSW).xyz;
    float3 rgbSE = texture2D(texture, textureSampler, v_rgbSE).xyz;
    float4 rgbM  = texture2D(texture, textureSampler, v_rgbM);

    float3 luma   = float3(0.299, 0.587, 0.114);
    float lumaNW  = dot(rgbNW, luma);
    float lumaNE  = dot(rgbNE, luma);
    float lumaSW  = dot(rgbSW, luma);
    float lumaSE  = dot(rgbSE, luma);
    float lumaM   = dot(rgbM.xyz, luma);
    float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
    float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

    float2 dir;
    dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
    dir.y = ((lumaNW + lumaSW) - (lumaNE + lumaSE));

    float dirReduce = max((lumaNW + lumaNE + lumaSW + lumaSE) * (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN);

    float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);

    dir = min(float2(FXAA_SPAN_MAX, FXAA_SPAN_MAX), max(float2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX), dir * rcpDirMin)) / frameBufSize;

    float3 rgbA = (1.0 / 2.0) * (texture2D(texture, textureSampler, texCoords.xy + dir * (1.0 / 3.0 - 0.5)).xyz + texture2D(texture, textureSampler, texCoords.xy + dir * (2.0 / 3.0 - 0.5)).xyz);

    float3 rgbB = rgbA * (1.0 / 2.0) + (1.0 / 4.0) * (texture2D(texture, textureSampler, texCoords.xy + dir * (0.0 / 3.0 - 0.5)).xyz + texture2D(texture, textureSampler, texCoords.xy + dir * (3.0 / 3.0 - 0.5)).xyz);

    float lumaB = dot(rgbB, luma);

    if ((lumaB < lumaMin) || (lumaB > lumaMax)) {
        return float4(rgbA, rgbM.a);
    } else {
        return float4(rgbB, rgbM.a);
    }
}

