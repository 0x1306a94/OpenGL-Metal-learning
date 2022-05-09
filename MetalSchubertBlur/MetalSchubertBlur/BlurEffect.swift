//
//  BlurEffect.swift
//  MetalSchubertBlur
//
//  Created by king on 2022/5/7.
//

import Foundation
import Metal
import MetalKit
import MetalPerformanceShaders
import simd

enum BlurEffectError: Error {
    case functionFail(String)
    case commandQueueFail
    case sourceImageFail
    case textureFail
    case bufferFail
}

final class BlurEffect {
    let device: MTLDevice
    let resizePipelineState: MTLRenderPipelineState
//    let blurPipelineState: MTLRenderPipelineState
    let blendPipelineState: MTLRenderPipelineState
    let commandQueue: MTLCommandQueue
//    let sourceTexture: MTLTexture
//    let resizeTexture: MTLTexture
//    let blurTexture: MTLTexture
//    let outputTexture: MTLTexture
    let vertexBuffer: MTLBuffer
    let library: MTLLibrary
    let textureLoader: MTKTextureLoader
    var size: (Int, Int) = (0, 0)
    init(device: MTLDevice, library: MTLLibrary) throws {
        self.device = device
        self.library = library
        
        guard let vertexFunc = library.makeFunction(name: "vertex_main") else {
            throw BlurEffectError.functionFail("vertex_main")
        }
        
        guard let fragmentResizeFunc = library.makeFunction(name: "fragment_resize") else {
            throw BlurEffectError.functionFail("fragment_resize")
        }
        
//        guard let fragmentBlurFunc = library.makeFunction(name: "fragment_blur") else {
//            throw BlurEffectError.functionFail("fragment_blur")
//        }
        
        guard let fragmentBlurBlendFunc = library.makeFunction(name: "fragment_blur_blend") else {
            throw BlurEffectError.functionFail("fragment_blur_blend")
        }
        
        do {
            let resizeDesc = MTLRenderPipelineDescriptor()
            resizeDesc.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
            resizeDesc.vertexFunction = vertexFunc
            resizeDesc.fragmentFunction = fragmentResizeFunc
            
//            let blurDesc = MTLRenderPipelineDescriptor()
//            blurDesc.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
//            blurDesc.vertexFunction = vertexFunc
//            blurDesc.fragmentFunction = fragmentBlurFunc
            
            let blendDesc = MTLRenderPipelineDescriptor()
            blendDesc.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
            blendDesc.vertexFunction = vertexFunc
            blendDesc.fragmentFunction = fragmentBlurBlendFunc
            
            self.resizePipelineState = try device.makeRenderPipelineState(descriptor: resizeDesc)
//            self.blurPipelineState = try device.makeRenderPipelineState(descriptor: blurDesc)
            self.blendPipelineState = try device.makeRenderPipelineState(descriptor: blendDesc)
        }
        
        guard let commandQueue = device.makeCommandQueue() else {
            throw BlurEffectError.commandQueueFail
        }
        self.commandQueue = commandQueue
        
        self.textureLoader = MTKTextureLoader(device: device)
        
        let vertexs: [KKVertex] = [
            KKVertex(position: vector_float2(x: -1, y: -1), textureCoordinate: vector_float2(0, 1)),
            KKVertex(position: vector_float2(x: -1, y: 1), textureCoordinate: vector_float2(0, 0)),
            KKVertex(position: vector_float2(x: 1, y: -1), textureCoordinate: vector_float2(1, 1)),
            KKVertex(position: vector_float2(x: 1, y: 1), textureCoordinate: vector_float2(1, 0)),
        ]
        
        guard let buffer = device.makeBuffer(bytes: vertexs, length: MemoryLayout<KKVertex>.size * 4, options: .storageModeShared) else {
            throw BlurEffectError.bufferFail
        }
        
        self.vertexBuffer = buffer
    }
}

extension BlurEffect {
    func apply(size: (Int, Int), sourceImage: Data) -> CIImage? {
        let sourceTexture: MTLTexture
        let resizeTexture: MTLTexture
        let blurTexture: MTLTexture
        let outputTexture: MTLTexture
        
        do {
            let origin = MTKTextureLoader.Origin.flippedVertically
            sourceTexture = try textureLoader.newTexture(data: sourceImage, options: [.SRGB: false, .origin: origin])
            let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: size.0, height: size.1, mipmapped: false)
            desc.storageMode = .shared
            desc.usage = [.shaderWrite, .shaderRead, .renderTarget]
            
            guard let resize = device.makeTexture(descriptor: desc) else {
                return nil
            }
            
            guard let blur = device.makeTexture(descriptor: desc) else {
                return nil
            }
            
            guard let blend = device.makeTexture(descriptor: desc) else {
                return nil
            }
            
            resizeTexture = resize
            blurTexture = blur
            outputTexture = blend
        } catch {
            return nil
        }
        
        guard let commandBuffer = self.commandQueue.makeCommandBuffer() else {
            return nil
        }
        
        do {
            let desc = MTLRenderPassDescriptor()
            desc.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1.0)
            desc.colorAttachments[0].texture = resizeTexture
            desc.colorAttachments[0].loadAction = .clear
            desc.colorAttachments[0].storeAction = .store
            
            guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: desc) else {
                commandBuffer.commit()
                return nil
            }
            commandEncoder.setRenderPipelineState(self.resizePipelineState)
            commandEncoder.setViewport(MTLViewport(originX: 0, originY: 0, width: Double(size.0), height: Double(size.1), znear: -1, zfar: 1))
            commandEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, index: Int(KKVertexInputIndexVertexs.rawValue))
            commandEncoder.setFragmentTexture(sourceTexture, index: Int(KKFragmentTextureIndexOne.rawValue))
            commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            commandEncoder.endEncoding()
        }
        
        do {
            let gaussianblur = MPSImageGaussianBlur(device: self.device, sigma: 100)
            gaussianblur.edgeMode = .clamp
            gaussianblur.encode(commandBuffer: commandBuffer, sourceTexture: resizeTexture, destinationTexture: blurTexture)
        }
        
        do {
            let desc = MTLRenderPassDescriptor()
            desc.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1.0)
            desc.colorAttachments[0].texture = outputTexture
            desc.colorAttachments[0].loadAction = .clear
            desc.colorAttachments[0].storeAction = .store
            
            guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: desc) else {
                commandBuffer.commit()
                return nil
            }
            commandEncoder.setRenderPipelineState(self.blendPipelineState)
            commandEncoder.setViewport(MTLViewport(originX: 0, originY: 0, width: Double(size.0), height: Double(size.1), znear: -1, zfar: 1))
             
            let dominantColor = simd_float3(x: 0.443062, y: 0.274907, z: 0.286831)
            var uniform = KKUniform(top: 0.3, bottom: 0.3, lenght: 0.08, saturation: 1.5, dominantColor: dominantColor)
            
            commandEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, index: Int(KKVertexInputIndexVertexs.rawValue))
            commandEncoder.setFragmentTexture(blurTexture, index: Int(KKFragmentTextureIndexOne.rawValue))
            commandEncoder.setFragmentTexture(sourceTexture, index: Int(KKFragmentTextureIndexTow.rawValue))
            commandEncoder.setFragmentBytes(&uniform, length: MemoryLayout<KKUniform>.size, index: Int(KKVertexInputIndexUniforms.rawValue))
            commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            commandEncoder.endEncoding()
        }
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        let options = [
            CIImageOption.colorSpace: CGColorSpaceCreateDeviceRGB(),
        ]
        
        guard let image = CIImage(mtlTexture: outputTexture, options: options) else {
            return nil
        }
        
        return image
    }
}
