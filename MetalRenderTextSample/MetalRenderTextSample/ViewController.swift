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
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

