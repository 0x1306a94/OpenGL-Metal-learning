//
//  ViewController.swift
//  MetalSchubertBlur
//
//  Created by king on 2022/5/7.
//

import MetalKit
import simd
import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var effect: BlurEffect?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .white

        guard let device = MTLCreateSystemDefaultDevice(), let library = device.makeDefaultLibrary() else {
            return
        }

        self.effect = try? BlurEffect(device: device, library: library)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        segmentedControl.sendActions(for: .valueChanged)
    }

    @IBAction func segmentedAction(_ sender: UISegmentedControl) {
        let imageNames = [
            ("186BFC976E61290ACD82744D62F64F0A", "jpg"),
            ("1B9D11649D0A36576E228D8EFB8A873F", "jpg"),
            ("68AE84400B33148E508B1A6A91E96ADE", "jpg"),
            ("10F11476E028E70EABE77C47BD13409A", "jpg"),
        ]
        let image = imageNames[sender.selectedSegmentIndex]

        guard let url = Bundle.main.url(forResource: image.0, withExtension: image.1) else {
            return
        }
        guard let data = try? Data(contentsOf: url) else {
            return
        }

        self.generate(imageData: data)
    }

    func generate(imageData: Data) {
        guard let effect = self.effect else {
            return
        }
        let size = (Int(UIScreen.main.bounds.width * 2), Int(UIScreen.main.bounds.height * 2))
        let start = CACurrentMediaTime()
        let outputImage = effect.apply(size: size, sourceImage: imageData)
        print("elapsed time:", CACurrentMediaTime() - start)
        if let ciImage = outputImage {
            let image = UIImage(ciImage: ciImage)
            self.imageView.image = image
        }
    }
}
