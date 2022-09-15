//
//  Shader.metal
//  MetalGradientMeshSample
//
//  Created by king on 2022/9/15.
//

#include <metal_stdlib>
using namespace metal;

typedef float2 vec2;
typedef float3 vec3;
typedef float4 vec4;

float rand(float co) {
    return fract(sin(co * (91.3458)) * 47453.5453);
}

#define PI 3.141592
#define backgroundColor vec3(7.0 / 256.0, 32.0 / 256.0, 61.0 / 256.0)
#define primaryColor vec3(99.0 / 256.0, 201.0 / 256.0, 247.0 / 256.0)
#define secondaryColor vec3(236.0 / 256.0, 137.0 / 256.0, 240.0 / 256.0)

/* discontinuous pseudorandom uniformly distributed in [-0.5, +0.5]^3 */
vec3 pseudoRandom3(vec3 seed) {
    float multiplier = 4096.0 * sin(dot(seed, vec3(17.0, 59.4, 15.0)));
    vec3 pseudoRandomOutput;
    pseudoRandomOutput.z = fract(512.0 * multiplier);
    multiplier *= .125;
    pseudoRandomOutput.x = fract(512.0 * multiplier);
    multiplier *= .125;
    pseudoRandomOutput.y = fract(512.0 * multiplier);
    return pseudoRandomOutput - 0.5;
}

/* skew constants for 3d simplex functions */
constant float F3 = 0.3333333;
constant float G3 = 0.1666667;

/* 3d simplex noise */
float simplex3(vec2 xy, float z, float size, float offset) {
    /* 1. find current tetrahedron T and it's four vertices */
    /* s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices */
    /* x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices*/

    vec3 p = vec3(xy, z);
    p.xy *= size;
    p.xy += offset;

    /* calculate s and x */
    vec3 s = floor(p + dot(p, vec3(F3)));
    vec3 x = p - s + dot(s, vec3(G3));

    /* calculate i1 and i2 */
    vec3 e = step(vec3(0.0), x - x.yzx);
    vec3 i1 = e * (1.0 - e.zxy);
    vec3 i2 = 1.0 - e.zxy * (1.0 - e);

    /* x1, x2, x3 */
    vec3 x1 = x - i1 + G3;
    vec3 x2 = x - i2 + 2.0 * G3;
    vec3 x3 = x - 1.0 + 3.0 * G3;

    /* 2. find four surflets and store them in d */
    vec4 w, d;

    /* calculate surflet weights */
    w.x = dot(x, x);
    w.y = dot(x1, x1);
    w.z = dot(x2, x2);
    w.w = dot(x3, x3);

    /* w fades from 0.6 at the center of the surflet to 0.0 at the margin */
    w = max(0.6 - w, 0.0);

    /* calculate surflet components */
    d.x = dot(pseudoRandom3(s), x);
    d.y = dot(pseudoRandom3(s + i1), x1);
    d.z = dot(pseudoRandom3(s + i2), x2);
    d.w = dot(pseudoRandom3(s + 1.0), x3);

    /* multiply d by w^4 */
    w *= w;
    w *= w;
    d *= w;

    /* 3. return the sum of the four surflets */
    return 0.5 + 0.5 * dot(d, vec4(52.0));
}

float stereotype(float x, float factor, float center) {
    return (-cos(PI * clamp(x - (center - 0.5 / factor), 0.0, 1.0 / factor) * factor) + 1.0) / 2.0;
}

// https://www.shadertoy.com/view/sslcW2
kernel void gradient_mesh_1(constant float &iTime [[buffer(0)]],
                            constant uint2 &iResolution [[buffer(1)]],
                            texture2d<float, access::write> outTexture [[texture(0)]],
                            uint2 gid [[thread_position_in_grid]]) {

    if (gid.x > iResolution.x || gid.y > iResolution.y) {
        return;
    }
    //    outTexture.write(float4(1.0, sin(iTime), cos(iTime), 1.0), gid);

    vec2 points[10] = {
        vec2(4., 2.),
        vec2(1., 1.),
        vec2(0.5, 1.),
        vec2(0.25, 0.75),
        vec2(8., 4.),
        vec2(8., 4.),
        vec2(8., 4.),
        vec2(8., 4.),
        vec2(8., 4.),
        vec2(8., 4.),
    };

    vec3 colours[10] = {
        vec3(1., 0., .0),
        vec3(0.0, 1.0, 0.0),
        vec3(0.0, 0.0, 1.0),
        vec3(.2, .1, 0.8),
        vec3(1., 0., .0),
        vec3(1., 0., .0),
        vec3(1., 0., .0),
        vec3(1., 0., .0),
        vec3(1., 0., .0),
        vec3(1., 0., .0),
    };

    vec2 uv = vec2(min(gid.x, iResolution.x), min(gid.y, iResolution.y)) / vec2(iResolution);
    // uv.x-=0.5;
    uv *= 5.;
    vec2 xy = vec2(0.5) * 5.;

    for (int i = 0; i < 10; i++) {
        points[i] = vec2(rand(floor(iTime) + float(i)) * 5., rand(floor(iTime + 2.) + float(i)) * 5.);
    }
    for (int i = 0; i < 10; i++) {
        colours[i] = vec3(rand(floor(iTime) + float(i)), rand(floor(iTime + 9.) + float(i)), rand(floor(iTime + 5.) + float(i)));
    }

    vec3 col = vec3(0.);
    float td = 0.;

    int meatballs = 4;
    points[1] = xy;
    colours[1] *= 1.2;
    for (int i = 0; i < meatballs; i++) {
        float dist = length(uv - points[i]);
        float inv = (1. / dist);
        col += 1.1 * colours[i] * inv * inv;
        td += inv * inv;
    }
    //for(int i=0; i<meatballs;i++){
    //   col *= smoothstep(0.0,0.03, length(uv - points[i]));
    //}

    col /= td;
    // Output to screen

    outTexture.write(float4(col, 1.0), gid);
}

// https://www.shadertoy.com/view/7sSGzh
kernel void gradient_mesh_2(constant float &iTime [[buffer(0)]],
                            constant uint2 &iResolution [[buffer(1)]],
                            texture2d<float, access::write> outTexture [[texture(0)]],
                            uint2 gid [[thread_position_in_grid]]) {

    if (gid.x > iResolution.x || gid.y > iResolution.y) {
        return;
    }

    //    float2 uv = -1. + 2. * vec2(min(gid.x, iResolution.x), min(gid.y, iResolution.y)) / vec2(iResolution);
    //    float4 col = float4(
    //        abs(sin(cos(iTime + 3. * uv.y) * 2. * uv.x + iTime)),
    //        abs(cos(sin(iTime + 2. * uv.x) * 3. * uv.y + iTime)),
    //        0 * 100.,
    //        1.0);
    //
    //    outTexture.write(col, gid);
    //    return;

    vec2 normalizedCoordinates = vec2(min(gid.x, iResolution.x), min(gid.y, iResolution.y)) / vec2(iResolution);
    float time = iTime * 0.03;

    float secondaryColorHardeningFactor = stereotype(simplex3(normalizedCoordinates, time * 2.0, 0.5, 0.0), 4.0, 0.6);
    float secondaryColorNoise = simplex3(normalizedCoordinates, time, 1.0, 10.0);
    float firstMix = stereotype(secondaryColorNoise, 8.0 + secondaryColorHardeningFactor * 248.0, 0.65);
    vec3 result = mix(backgroundColor, secondaryColor, firstMix);

    float primaryColorHardeningFactor = stereotype(simplex3(normalizedCoordinates, time * 2.0, 1.0, 20.0), 4.0, 0.6);
    float primaryColorNoise = simplex3(normalizedCoordinates, time, 1.5, 30.0);
    float secondMix = stereotype(primaryColorNoise, 8.0 + primaryColorHardeningFactor * 248.0, 0.5);
    result = mix(primaryColor, result, secondMix);

    float grainNoise = stereotype(simplex3(normalizedCoordinates, time * 5.0, max(iResolution.x, iResolution.y) / 2.0, 40.0), 0.8, 0.8);
    result = result + result * vec3(grainNoise / 6.0);

    //    fragColor = vec4(result, 1.0);
    outTexture.write(vec4(result, 1.0), gid);
}

