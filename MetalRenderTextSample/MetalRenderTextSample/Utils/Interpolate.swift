//
//  Interpolate.swift
//  MetalRenderTextSample
//
//  Created by king on 2022/4/12.
//

import Foundation

func Interpolate(a: Float, b: Float, t: Float) -> Float {
    a + (b - a) * t
}
