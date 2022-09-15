//
//  ViewController.swift
//  MetalGradientMeshSample
//
//  Created by king on 2022/9/15.
//

import UIKit

class ViewController: UIViewController {
    var gradientMeshView: MetalGradientMeshView?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        guard let device = MTLCreateSystemDefaultDevice(),
              let library = device.makeDefaultLibrary(),
              let renderer = MetalGradientMeshRenderer(device: device, library: library)
        else {
            return
        }

        let gradientMeshView = MetalGradientMeshView()
        self.gradientMeshView = gradientMeshView
        gradientMeshView.setupRenderer(renderer: renderer)
        gradientMeshView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(gradientMeshView)

        NSLayoutConstraint.activate([
            gradientMeshView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            gradientMeshView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            gradientMeshView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            gradientMeshView.heightAnchor.constraint(equalTo: self.view.heightAnchor),
//            gradientMeshView.heightAnchor.constraint(equalToConstant: 300)
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gradientMeshView?.paused = false
    }
}
