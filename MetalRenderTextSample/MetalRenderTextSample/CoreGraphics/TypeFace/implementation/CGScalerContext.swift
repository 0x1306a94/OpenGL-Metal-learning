//
//  CGScalerContext.swift
//  MetalRenderTextSample
//
//  Created by king on 2022/4/12.
//

import CoreText
import Foundation

private let ITALIC_SKEW: Float = -0.20
private let kStdFakeBoldInterpKeys: [Float] = [
    9.0,
    36.0,
]
private let kStdFakeBoldInterpValues: [Float] = [
    1.0 / 24.0,
    1.0 / 32.0,
]

private func FloatInterpFunc(searchKey: Float, keys: [Float], values: [Float], lenght: Int) -> Float {
    var right = 0
    while right < lenght, keys[right] < searchKey {
        right += 1
    }

    if right == lenght {
        return values[lenght - 1]
    }

    if right == 0 {
        return values[0]
    }

    let leftKey = keys[right - 1]
    let rightKey = keys[right]
    let t = (searchKey - leftKey) / (rightKey - leftKey)

    return Interpolate(a: values[right - 1], b: values[right], t: t)
}

final class CGScalerContextRec {
    var textSize: Float = 12
    var skewX: Float = 0
    var fauxBoldSize: Float = 0
    var verticalText: Bool = false
}

final class CGScalerContext {
    private let typeface: TypeFace
    private let rec: CGScalerContextRec
    private let font: CTFont
    private let transform: CGAffineTransform

    init(typeface: TypeFace, size: Float, fauxBold: Bool = false, fauxItalic: Bool = false, verticalText: Bool = false) {
        guard let cfTypeface = typeface as? CGTypeFace else {
            fatalError()
        }

        self.typeface = cfTypeface

        let rec = CGScalerContextRec()
        rec.textSize = size
        if fauxBold {
            let fauxBoldScale = FloatInterpFunc(searchKey: size, keys: kStdFakeBoldInterpKeys, values: kStdFakeBoldInterpValues, lenght: 2)
            rec.fauxBoldSize = size * fauxBoldScale
        }
        rec.skewX = fauxItalic ? ITALIC_SKEW : 0
        rec.verticalText = verticalText
        self.rec = rec

        var m = Matrix.identity()
        m.postSkew(sx: rec.skewX, sy: 0)
        self.transform = m.toAffineTransform()

        self.font = CTFontCreateCopyWithAttributes(cfTypeface.font, CGFloat(rec.textSize), nil, nil)
    }
}

extension CGScalerContext {
    func generateFontMetrics() -> FontMetrics {
        let metrics = FontMetrics()
        let theBounds = CTFontGetBoundingBox(self.font)
        metrics.top = Float(-theBounds.maxY)
        metrics.ascent = Float(-CTFontGetAscent(self.font))
        metrics.descent = Float(CTFontGetDescent(self.font))
        metrics.bottom = Float(-theBounds.minY)
        metrics.leading = Float(CTFontGetLeading(self.font))
        metrics.xMin = Float(theBounds.minX)
        metrics.xMax = Float(theBounds.maxX)
        metrics.xHeight = Float(theBounds.maxY)
        metrics.capHeight = Float(CTFontGetCapHeight(self.font))
        metrics.underlineThickness = Float(CTFontGetUnderlineThickness(self.font))
        metrics.underlinePosition = Float(-CTFontGetUnderlinePosition(self.font))
        return metrics
    }
}
