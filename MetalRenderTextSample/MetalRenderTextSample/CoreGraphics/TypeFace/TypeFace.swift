//
//  TypeFace.swift
//  MetalRenderTextSample
//
//  Created by king on 2022/4/11.
//

import Foundation

typealias GlyphID = UInt16

protocol TypeFace: AnyObject {
    static func `default`() -> Self

    static func from(fontFamily: String, fontStyle: String) -> Self

    func fontFamily() -> String

    func fontStyle() -> String

    func unitsPerEm() -> Int

    func hasColor() -> Bool
}
