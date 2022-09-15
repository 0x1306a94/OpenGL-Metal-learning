//
//  MetalGradientMeshView.swift
//  MetalGradientMeshSample
//
//  Created by king on 2022/9/15.
//

import MetalKit
import QuartzCore

final class MetalGradientMeshView: UIView {
    private var backingView: MTKView = {
        let v = MTKView()
//        v.preferredFramesPerSecond = 30
        v.framebufferOnly = false
        v.isPaused = true
        return v
    }()

    private(set) var renderer: MetalGradientMeshRenderer?

    var paused: Bool {
        get {
            return _paused
        }
        set {
            guard let r = self.renderer else {
                return
            }
            _paused = newValue
            r.startTime = CACurrentMediaTime()
            self.backingView.isPaused = newValue
        }
    }

    private var startTime: TimeInterval = 0
    private var _paused: Bool = true
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.backingView)
        self.backingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.backingView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.backingView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.backingView.topAnchor.constraint(equalTo: self.topAnchor),
            self.backingView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])

        self.backingView.isPaused = true
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupRenderer(renderer: MetalGradientMeshRenderer) {
        self.renderer = renderer
        self.backingView.device = renderer.device
        self.backingView.delegate = renderer
    }
}


