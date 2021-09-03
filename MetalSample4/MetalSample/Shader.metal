//
//  Shader.metal
//  MetalSample
//
//  Created by king on 2020/10/13.
//

#include <metal_stdlib>

#include "ShaderTypes.h"

using namespace metal;

#define PI 3.141592653

typedef struct {
    float4 clipSpacePosition [[position]];  // position的修饰符表示这个是顶点
    float2 textureCoordinate;
} RasterizerData;

half4 texture2D(texture2d<half, access::sample> texture, float2 uv);

vertex RasterizerData
vertex_main(uint vertexID [[vertex_id]],
            constant SSVertex *vertexArray [[buffer(SSVertexInputIndexVertices)]]) {
    RasterizerData out;
    SSVertex vertext = vertexArray[vertexID];

    out.clipSpacePosition = vertext.position;
    out.textureCoordinate = vertext.textureCoordinate;
    return out;
}

fragment half4
fragment_main(RasterizerData input [[stage_in]],
              texture2d<half, access::sample> texture0 [[texture(SSFragmentTextureIndexOne)]]) {
    return texture2D(texture0, input.textureCoordinate);
}

half4 texture2D(texture2d<half, access::sample> texture, float2 uv) {
    constexpr sampler textureSampler(s_address::repeat, t_address::repeat, mag_filter::linear, min_filter::linear);
    return texture.sample(textureSampler, uv);
}

float2 moveOffset(float2 videoImageCoord, float2 direction, float percent) {
    videoImageCoord = videoImageCoord + direction * percent;
    return videoImageCoord;
}

float2 rotate(float2 videoImageCoord, float2 centerImageCoord, float radianAngle) {
    float2 rotateCenter = centerImageCoord;
    float rotateAngle = radianAngle;

    float cosRotateAngle = cos(rotateAngle);
    float sinRotateAngle = sin(rotateAngle);
    float3x3 rotateMat = float3x3(float3(cosRotateAngle, -sinRotateAngle, 0.0),
                                  float3(sinRotateAngle, cosRotateAngle, 0.0),
                                  float3(0.0, 0.0, 1.0));
    float3 deltaOffset;
    deltaOffset = rotateMat * float3(videoImageCoord.x - rotateCenter.x, videoImageCoord.y - rotateCenter.y, 1.0);
    videoImageCoord.x = deltaOffset.x + rotateCenter.x;
    videoImageCoord.y = deltaOffset.y + rotateCenter.y;
    return videoImageCoord;
}

float2 movePercent(float2 videoImageCoord, float2 resolution, float2 start, float2 to, float percent) {
    float2 direction = float2(0, resolution.y);
    if (start.x == 0 && to.x == 0 && start.y > to.y) {  // 向上
        direction = float2(0, resolution.y);
    } else if (start.x == 0 && to.x == 0 && start.y < to.y) {  // 向下
        direction = float2(0, -resolution.y);
    } else if (start.y == 0 && to.y == 0 && start.x > to.x) {  // 向左
        direction = float2(resolution.x, 0);
    } else if (start.y == 0 && to.y == 0 && start.x < to.x) {  //向右
        direction = float2(-resolution.x, 0);
    }
    float2 offset = start - (start - to) * percent;
    videoImageCoord = videoImageCoord - resolution * offset;
    return videoImageCoord / resolution;
}

float2 zoom(float2 uv, float amount) {
    return 0.5 + ((uv - 0.5) * (1 - amount));
}

float2 getBezierValue(float controls[4], float t) {
    float xc1 = controls[0];
    float yc1 = controls[1];
    float xc2 = controls[2];
    float yc2 = controls[3];
    float a = 3 * xc1 * (1 - t) * (1 - t) * t + 3 * xc2 * (1 - t) * t * t + t * t * t;
    float b = 3 * yc1 * (1 - t) * (1 - t) * t + 3 * yc2 * (1 - t) * t * t + t * t * t;
    return float2(a, b);
}

float getBezierTfromX(float controls[4], float x) {
    float ts = 0;
    float te = 1;
    while (te - ts >= 0.0001) {
        float tm = (ts + te) / 2;
        float2 value = getBezierValue(controls, tm);
        if (value.x > x) {
            te = tm;
        } else {
            ts = tm;
        }
    }
    return (te + ts) / 2;
}

float toBezier(float t, float P0, float P1, float P2, float P3) {
    float controls[] = {P0, P1, P2, P3};
    float tvalue = getBezierTfromX(controls, t);
    float2 value = getBezierValue(controls, tvalue);
    return value.y;
}

half4 _resultKernel(texture2d<half, access::sample> inputTexture [[texture(1)]],
                    float angle,
                    float progress,
                    float2 center,
                    float blurTime,
                    uint2 gid [[thread_position_in_grid]]) {
    float inputWidth = inputTexture.get_width();
    float inputHeight = inputTexture.get_height();
    float2 uv0 = float2(gid) / float2(inputWidth, inputHeight);

    float2 resolution = float2(float(inputTexture.get_width()), float(inputTexture.get_height()));
    float2 rotateCenter = resolution * center;
    float2 realCoord = uv0 * resolution;
    uv0 = rotate(realCoord, rotateCenter, angle) / resolution;

    float ratio = inputWidth / inputHeight;
    float blurScale = 1.5 * max(0.0, (progress - (1 - blurTime)) * 2);
    const int rotateNum = 10;
    float rotateAngle = blurScale * PI / 400.0;

    float fRotateNum = float(rotateNum);
    float2x2 startRotateMat = float2x2(float2(cos(-rotateAngle * fRotateNum), sin(-rotateAngle * fRotateNum)),
                                       float2(-sin(-rotateAngle * fRotateNum), cos(-rotateAngle * fRotateNum)));

    //    float2x2 stepRotateMat = float2x2(float2(cos(rotateAngle), sin(rotateAngle)),
    //                                      float2(-sin(rotateAngle), cos(rotateAngle)));

    float2 uv_ori = uv0 * float2(ratio, 1.0);
    uv_ori = (float4(uv_ori.x * 2.0 - ratio, uv_ori.y * 2.0 - 1.0, 0.0, 1.0)).xy;
    uv_ori.x = (uv_ori.x / ratio + 1.0) / 2.0;
    uv_ori.y = (uv_ori.y + 1.0) / 2.0;
    uv_ori = float2(1.0 - abs(abs(uv_ori.x) - 1.0), 1.0 - abs(abs(uv_ori.y) - 1.0));
    //    float A = texture2D(inputTexture, uv_ori).a;

    float2 uv = uv0 * float2(ratio, 1.0);
    float2 ct = center * float2(ratio, 1.0);
    uv = startRotateMat * (uv - ct) + ct;
    return half4(texture2D(inputTexture, uv));
}

kernel void processAnimation(texture2d<half, access::write> outputTexture [[texture(0)]],
                             texture2d<half, access::sample> inputTexture [[texture(1)]],
                             constant float *time [[buffer(0)]],
                             constant float *duration [[buffer(1)]],
                             uint2 gid [[thread_position_in_grid]]) {
    float timeValue = *time;
    float durationValue = *duration;
    float progress = timeValue / durationValue;

    if (progress < 0.5) {
        progress = progress * 2;

        progress = toBezier(progress, 0.27, 0.87, 0.35, 0.98);
        progress = 1 - progress;
        float2 center = float2(0, 0.5);
        float angle = PI / 3 * progress;
        outputTexture.write(_resultKernel(inputTexture, angle, progress, center, 0.6, gid), gid);
    } else {
        progress = progress * 2 - 1;

        progress = toBezier(1 - progress, 0.27, 0.87, 0.35, 0.98);
        progress = 1 - progress;
        float2 center = float2(1, 0.5);
        float angle = PI / 3 * progress;
        outputTexture.write(_resultKernel(inputTexture, angle, progress, center, 0.6, gid), gid);
    }
}

