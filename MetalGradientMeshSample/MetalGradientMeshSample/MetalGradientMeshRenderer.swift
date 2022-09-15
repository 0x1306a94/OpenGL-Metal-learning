//
//  MetalGradientMeshRenderer.swift
//  MetalGradientMeshSample
//
//  Created by king on 2022/9/15.
//

import Metal
import MetalKit
import QuartzCore
import simd

class MetalGradientMeshRenderer: NSObject {
    let device: MTLDevice
    let library: MTLLibrary

    let commandQueue: MTLCommandQueue
    let pipelineState: MTLComputePipelineState

    var startTime: TimeInterval = 0
    let semaphore = DispatchSemaphore(value: 1)
    init?(device: MTLDevice, library: MTLLibrary) {
        self.device = device
        self.library = library

        guard let kernelFunc = library.makeFunction(name: "gradient_mesh_2"),
              let state = try? device.makeComputePipelineState(function: kernelFunc),
              let queue = device.makeCommandQueue()
        else {
            return nil
        }
        commandQueue = queue
        pipelineState = state
    }
}

extension MetalGradientMeshRenderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else {
            return
        }

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let commandEncoder = commandBuffer.makeComputeCommandEncoder()
        else {
            return
        }

        let texture = drawable.texture
        let width = texture.width
        let height = texture.height

        var iTime = simd_float1(CACurrentMediaTime() - startTime) 
        print("time:", iTime)
        var iResolution = simd_make_uint2(UInt32(width), UInt32(height))
        commandEncoder.setComputePipelineState(self.pipelineState)

        commandEncoder.setBytes(&iTime, length: MemoryLayout<simd_float1>.size, index: 0)
        commandEncoder.setBytes(&iResolution, length: MemoryLayout<simd_uint2>.size, index: 1)
        commandEncoder.setTexture(texture, index: 0)

//        let w = 16
//        let h = 16
        let w = self.pipelineState.threadExecutionWidth // 最有效率的线程执行宽度
        let h = self.pipelineState.maxTotalThreadsPerThreadgroup / w // 每个线程组最多的线程数量

        let threadsPerThreadGroup = MTLSizeMake(w, h, 1)
        let threadgroupsPerGrid = MTLSizeMake((width + w - 1) / w, (height + h - 1) / h, 1)
        commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}
