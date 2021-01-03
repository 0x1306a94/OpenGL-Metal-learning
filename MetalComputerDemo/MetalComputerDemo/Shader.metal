//
//  Shader.metal
//  MetalComputerDemo
//
//  Created by king on 2021/1/2.
//

#include <metal_stdlib>
//#include "ShaderType.h"

using namespace metal;

typedef struct {
    uint8_t data[16][16];
} DataBuffer;

typedef struct {
    uint8_t data[8][8];
} DataGroupBuffer;

kernel
void ComputeKernelShader(constant DataBuffer &inBuffer [[ buffer(0) ]],
                         device DataBuffer &outBuffer [[ buffer(1) ]],
//                         uint2 threadgroup_position_in_grid [[ threadgroup_position_in_grid ]],
                         uint2 threads_per_threadgroup [[ threads_per_threadgroup ]],
                         uint2 thread_position_in_threadgroup [[ thread_position_in_threadgroup ]]
                         /* uint2 grid [[ thread_position_in_grid ]] */) {
    
    DataGroupBuffer groupBuffer;
    
    uint row = threads_per_threadgroup.x;
    uint col = threads_per_threadgroup.y;
    // 读取对应数据
    for (uint x = 0; x < row; x++) {
        for (uint y = 0; y < col; y++) {
//            uint2 thread_position_in_grid = uint2(x, y) * threads_per_threadgroup + thread_position_in_threadgroup;
//            outBuffer.data[thread_position_in_grid.x][thread_position_in_grid.y] = 128 * thread_position_in_threadgroup.x + 25 * thread_position_in_threadgroup.y;
            
            groupBuffer.data[x][y] = 128 * thread_position_in_threadgroup.x + 25 * thread_position_in_threadgroup.y;
            
//            outBuffer.data[thread_position_in_grid.x][thread_position_in_grid.y] = groupBuffer.data[x][y];
        }
    }
    // 转为灰度
    for (uint c = 0; c < col / 2; c += 4) {
        for (uint r = 0; r < row; r++) {
            uint R = groupBuffer.data[c + 0][r];
            uint G = groupBuffer.data[c + 1][r];
            uint B = groupBuffer.data[c + 2][r];
            
            uint gray = ~~((R + G + B) / 3);
            
            groupBuffer.data[c + 0][r] = gray;
            groupBuffer.data[c + 1][r] = gray;
            groupBuffer.data[c + 2][r] = gray;
            groupBuffer.data[c + 3][r] = 255;
        }
    }
    // 计算平均值
    uint total = 0;
    for (uint x = 0; x < row; x++) {
        for (uint y = 0; y < col; y++) {
            total += groupBuffer.data[x][y];
        }
    }
    
    uint grayAverage = total / (row * col);
    
    for (uint x = 0; x < row; x++) {
        for (uint y = 0; y < col; y++) {
            uint2 thread_position_in_grid = uint2(x, y) * threads_per_threadgroup + thread_position_in_threadgroup;
            uint v = groupBuffer.data[x][y];
            outBuffer.data[thread_position_in_grid.x][thread_position_in_grid.y] = v >= grayAverage ? 1 : 0;
        }
    }
}


#define THREAD_GROUP_OUT_SIZE 64
kernel
void ComputeKernelShader2(constant uint8_t *inBuffer [[ buffer(0) ]],
                          constant uint &col [[ buffer(1) ]],
                         device uint8_t *outBuffer [[ buffer(2) ]],
                         uint2 threadgroup_position_in_grid [[ threadgroup_position_in_grid ]],
                         uint2 threads_per_threadgroup [[ threads_per_threadgroup ]],
                         uint2 thread_position_in_threadgroup [[ thread_position_in_threadgroup ]]
                         /*uint2 grid [[ thread_position_in_grid ]]*/) {
        
    uint groupSize = threads_per_threadgroup.x * threads_per_threadgroup.y;
    uint startIndex = (threadgroup_position_in_grid.y * col + threadgroup_position_in_grid.x) * groupSize;
    uint outStartIndex = (threadgroup_position_in_grid.y * col + threadgroup_position_in_grid.x) * THREAD_GROUP_OUT_SIZE;
    uint endIndex = groupSize;

    uint total = 0;
    uint8_t buffer[THREAD_GROUP_OUT_SIZE];
    
    for (uint x = 0, tx = 0; x < endIndex; x += 4, tx ++) {
        uint8_t R = inBuffer[startIndex + x];
        uint8_t G = inBuffer[startIndex + x + 1];
        uint8_t B = inBuffer[startIndex + x + 2];
        uint8_t gray = ~~((R + G + B) / 3);
        total += gray;
        buffer[tx] = gray;
    }

    uint grayAverage = total / THREAD_GROUP_OUT_SIZE;
    for (uint x = 0, tx = 0; x < THREAD_GROUP_OUT_SIZE; x++) {
        uint8_t v = inBuffer[outStartIndex + x];
        outBuffer[outStartIndex + x] = v >= grayAverage ? 1 : 0;
        tx++;
    }
}
