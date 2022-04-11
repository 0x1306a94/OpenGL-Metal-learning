//
//  CGTypeFace.swift
//  MetalRenderTextSample
//
//  Created by king on 2022/4/11.
//

import CoreText
import Foundation

final class CGTypeFace {
    let font: CTFont
    init(font: CTFont) {
        self.font = font
    }
}

extension CGTypeFace: TypeFace {
    static func `default`() -> Self {
        from(fontFamily: "Lucida Sans", fontStyle: "")
    }

    static func from(fontFamily: String, fontStyle: String) -> Self {
        var keyCallBacks = kCFTypeDictionaryKeyCallBacks
        var valueCallBacks = kCFTypeDictionaryValueCallBacks
        guard let cfAttributes = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &keyCallBacks, &valueCallBacks) else {
            fatalError()
        }

        if !fontFamily.isEmpty {
            let key = Unmanaged.passRetained(kCTFontFamilyNameAttribute).autorelease().toOpaque()
            let value = Unmanaged.passRetained(fontFamily as NSString).autorelease().toOpaque()
            CFDictionaryAddValue(cfAttributes, key, value)
        }

        if !fontStyle.isEmpty {
            let key = Unmanaged.passRetained(kCTFontStyleNameAttribute).autorelease().toOpaque()
            let value = Unmanaged.passRetained(fontStyle as NSString).autorelease().toOpaque()
            CFDictionaryAddValue(cfAttributes, key, value)
        }

        let cfDesc = CTFontDescriptorCreateWithAttributes(cfAttributes)
        let font = CTFontCreateWithFontDescriptor(cfDesc, 0, nil)
        return CGTypeFace(font: font) as! Self
    }

    func fontFamily() -> String {
        guard let name = CTFontCopyName(self.font, kCTFontFamilyNameKey) else {
            return ""
        }
        return name as String
    }

    func fontStyle() -> String {
        guard let style = CTFontCopyName(self.font, kCTFontStyleNameKey) else {
            return ""
        }
        return style as String
    }

    func unitsPerEm() -> Int {
        let cgfont = CTFontCopyGraphicsFont(self.font, nil)
        return Int(cgfont.unitsPerEm)
    }

    func hasColor() -> Bool {
        let traits = CTFontGetSymbolicTraits(self.font)
        return traits.contains(.traitColorGlyphs)
    }
}
