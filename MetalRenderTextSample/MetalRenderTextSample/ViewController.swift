//
//  ViewController.swift
//  MetalRenderTextSample
//
//  Created by king on 2022/4/11.
//

import Cocoa

class ViewController: NSViewController {
    let typeface: TypeFace = CGTypeFace.default()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        print(typeface.fontFamily())
        print(typeface.fontStyle())

        var test = "你"
        print(test.utf8.count)
        let count: Int = test.withUTF8 {
            $0.withMemoryRebound(to: Int8.self) {
                guard let ptr = $0.baseAddress else { return 0 }
                return uft8_text_count(ptr: ptr)
            }
        }
        print(count)
//
//        var characters: UnsafePointer<CChar>?
//        withUnsafeMutablePointer(to: &characters) {
//            uft8_text_next_char(ptr: $0)
//        }
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}
