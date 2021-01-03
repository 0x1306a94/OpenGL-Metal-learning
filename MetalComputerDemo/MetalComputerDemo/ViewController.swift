//
//  ViewController.swift
//  MetalComputerDemo
//
//  Created by king on 2021/1/2.
//

import Cocoa
import Metal
import simd

//struct DataGroupBuffer {
//    var data: [[simd_uint8]] = []
//}
//
//struct DataBuffer {
//    var data: [[DataGroupBuffer]] = []
//}

class ViewController: NSViewController {

    let device: MTLDevice = MTLCreateSystemDefaultDevice()!
    
    var commandQueue: MTLCommandQueue!
    var inBuffer: MTLBuffer!
    var outBuffer: MTLBuffer!
    var computerPipeline: MTLComputePipelineState!
    let size = (2048, 2048)
    override func viewDidLoad() {
        super.viewDidLoad()

        commandQueue = device.makeCommandQueue()
        
        var array:[UInt8] = []
       
        let inputCount = size.0 / 16 + size.1 / 16
        for _ in 0..<inputCount {
            for _ in 0..<256 {
                array.append(UInt8.random(in: 0...255))
            }
        }
//        print(array)
        let length = array.count
        let outLength = 64 * inputCount
        inBuffer = device.makeBuffer(bytes: &array, length: length, options: .storageModeShared)
        outBuffer = device.makeBuffer(length: outLength, options: .storageModeShared)
        
        guard let library = device.makeDefaultLibrary() else { return }
        guard let kernelFunc = library.makeFunction(name: "ComputeKernelShader2") else { return }
        
        computerPipeline = try! device.makeComputePipelineState(function: kernelFunc)

        let w = 16
        let h = 16
        
        let threadsPerThreadGroup = MTLSizeMake(w, h, 1)
        let threadgroupsPerGrid = MTLSizeMake((size.0 + w - 1) / w, (size.1 + h - 1) / h, 1)

        print("threadsPerThreadGroup: \(threadsPerThreadGroup)")
        print("threadgroupsPerGrid: \(threadgroupsPerGrid)")
        var count = size.0 / w
        let start = CFAbsoluteTimeGetCurrent()
        let commandBuffer = commandQueue.makeCommandBuffer()
        let encoder = commandBuffer?.makeComputeCommandEncoder()
        encoder?.setComputePipelineState(computerPipeline)
        encoder?.setBuffer(inBuffer, offset: 0, index: 0)
        encoder?.setBytes(&count, length: MemoryLayout.size(ofValue: count), index: 1)
        encoder?.setBuffer(outBuffer, offset: 0, index: 2)
        encoder?.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
        encoder?.endEncoding()
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        let end = CFAbsoluteTimeGetCurrent()
        
        
        let contents = outBuffer.contents()
        let res = contents.toArray(to: UInt8.self, capacity: outLength)
//        print(res)
        var fingerprints: [String] = []
        
        for i in 0..<inputCount {
            var fingerprint = ""
            let start = i * 64
            let end = start + 63
            for v in stride(from: start, through: end, by: 1) {
                fingerprint += "\(res[v])"
            }
            fingerprints.append(fingerprint)
        }

        print(fingerprints.joined(separator: "\n"))
        print("耗时 \(end - start)")
        
        // 4 x 4
        // 每一组为 2 x 2
        let temp:[UInt8] = [uint8](0...UInt8(3)) + [uint8](4...UInt8(7)) + [uint8](8...UInt8(11)) + [uint8](12...UInt8(15))
        let size = (row: 2, col: 2)
        let gsize = (w: 2, h: 2)
        let g = (x:1, y:0)
        let p = (x:1, y:1)
        
        print(temp)
        let index = ((g.y * size.col + g.x) * (gsize.w * gsize.h)) + (p.y * gsize.w) + p.x
        print(temp[index])
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

extension UnsafeMutableRawPointer {
    func toArray<T>(to type: T.Type, capacity count: Int) -> [T]{
        let pointer = bindMemory(to: type, capacity: count)
        return Array(UnsafeBufferPointer(start: pointer, count: count))
    }
}

/*
 
 4*4/2*2
 
 1 2 5 6
 3 4 7 8
 9 10 13 14
 11 12 15 16
 
 
 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
 g (0, 0)
 s (2, 2)
 4
 */
