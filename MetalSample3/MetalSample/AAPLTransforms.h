/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility methods for linear transformations of projective
  geometry of the left-handed coordinate system.
 */

#ifndef _METAL_MATH_TRANSFORMS_H_
#define _METAL_MATH_TRANSFORMS_H_

#import "ShaderTypes.h"
#import <simd/simd.h>

#ifdef __cplusplus

namespace AAPL {
float radians(const float &degrees);

simd::float4x4 scale(const float &x,
                     const float &y,
                     const float &z);

simd::float4x4 scale(const simd::float3 &s);

simd::float4x4 translate(const float &x,
                         const float &y,
                         const float &z);

simd::float4x4 translate(const simd::float3 &t);

simd::float4x4 rotate(const float &angle,
                      const float &x,
                      const float &y,
                      const float &z);

simd::float4x4 rotate(const float &angle,
                      const simd::float3 &u);

simd::float4x4 frustum(const float &fovH,
                       const float &fovV,
                       const float &near,
                       const float &far);

simd::float4x4 frustum(const float &left,
                       const float &right,
                       const float &bottom,
                       const float &top,
                       const float &near,
                       const float &far);

simd::float4x4 frustum_oc(const float &left,
                          const float &right,
                          const float &bottom,
                          const float &top,
                          const float &near,
                          const float &far);

simd::float4x4 lookAt(const float *const pEye,
                      const float *const pCenter,
                      const float *const pUp);

simd::float4x4 lookAt(const simd::float3 &eye,
                      const simd::float3 &center,
                      const simd::float3 &up);

simd::float4x4 perspective(const float &width,
                           const float &height,
                           const float &near,
                           const float &far);

simd::float4x4 perspective_fov(const float &fovy,
                               const float &aspect,
                               const float &near,
                               const float &far);

simd::float4x4 perspective_fov(const float &fovy,
                               const float &width,
                               const float &height,
                               const float &near,
                               const float &far);

simd::float4x4 ortho2d_oc(const float &left,
                          const float &right,
                          const float &bottom,
                          const float &top,
                          const float &near,
                          const float &far);

simd::float4x4 ortho2d_oc(const simd::float3 &origin,
                          const simd::float3 &size);

simd::float4x4 ortho2d(const float &left,
                       const float &right,
                       const float &bottom,
                       const float &top,
                       const float &near,
                       const float &far);

simd::float4x4 ortho2d(const simd::float3 &origin,
                       const simd::float3 &size);

void genQuadVertices(simd::float4 result[4], const simd::float4 rect, const simd::float2 containerSize, bool reverse = false, bool normalized = false);

// 倒N
void genQuadTextureCoordinates(simd::float2 result[4], const simd::float4 rect, const simd::float2 containerSize, bool hflip = false, bool vflip = false);

SSVertex makeVertex(simd::float4 position, simd::float2 textureCoordinate);

static simd::float2 leftTopTextureCoordinate = simd::make_float2(0, 0);

static simd::float2 rightTopTextureCoordinate = simd::make_float2(1, 0);

static simd::float2 leftBottomTextureCoordinate = simd::make_float2(0, 1);

static simd::float2 rightBottomTextureCoordinate = simd::make_float2(1, 1);
}  // namespace AAPL

#endif

#endif

