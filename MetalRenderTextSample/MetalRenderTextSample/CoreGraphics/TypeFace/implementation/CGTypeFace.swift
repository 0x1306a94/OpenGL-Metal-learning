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

extension CGTypeFace {
    static func toUTF16(uni: Int32, utf16: inout [UInt16]) -> Int {
        if UInt32(uni) > 0x10FFFF {
            return 0
        }

        let extra = (uni > 0xFFFF)
        if extra {
            utf16[0] = UInt16((0xD800 - 64) + (uni >> 10))
            utf16[1] = UInt16(0xDC00 | (uni & 0x3FF))
        } else {
            utf16[0] = UInt16(uni)
        }
        return 1 + (extra ? 1 : 0)
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

    func glyphId(name: String) -> GlyphID {
        var _name = name
        let uni: Int32 = _name.withUTF8 {
            $0.withMemoryRebound(to: Int8.self) {
                guard var ptr = $0.baseAddress else { return 0 }
                return uft8_text_next_char(ptr: &ptr)
            }
        }
        var utf16: [UniChar] = [0, 0]
        var macGlyphs: [UniChar] = [0, 0]
        let scrCount = Self.toUTF16(uni: uni, utf16: &utf16)
        CTFontGetGlyphsForCharacters(self.font, utf16, &macGlyphs, scrCount)
        return macGlyphs[0]
    }
}
