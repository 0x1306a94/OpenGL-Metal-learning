//
//  Matrix.swift
//  MetalRenderTextSample
//
//  Created by king on 2022/4/12.
//

import Foundation

struct Matrix {
    private static let SCALE_X = 0 //! < horizontal scale factor
    private static let SKEW_X = 1 //! < horizontal skew factor
    private static let TRANS_X = 2 //! < horizontal translation
    private static let SKEW_Y = 3 //! < vertical skew factor
    private static let SCALE_Y = 4 //! < vertical scale factor
    private static let TRANS_Y = 5 //! < vertical translation
    private static let PERSP_0 = 6 //! < input x perspective factor
    private static let PERSP_1 = 7 //! < input y perspective factor
    private static let PERSP_2 = 8 //! < perspective bias

    private var values: [Float] = [0]

    init(scaleX: Float = 0, skewX: Float = 0, transX: Float = 0, skewY: Float = 0, scaleY: Float = 0,
         transY: Float = 0, persp0: Float = 0, persp1: Float = 0, persp2: Float = 0)
    {
        self.values = [Float](repeating: 0, count: 9)
        self.setAll(scaleX: scaleX, skewX: skewX, transX: transX,
                    skewY: skewY, scaleY: scaleY, transY: transY,
                    persp0: persp0, persp1: persp1, persp2: persp2)
    }
}

extension Matrix {
    static func identity() -> Matrix {
        Matrix(scaleX: 1.0, skewX: 0.0, transX: 0.0,
               skewY: 0.0, scaleY: 1.0, transY: 0.0,
               persp0: 0.0, persp1: 0.0, persp2: 1.0)
    }

    static func invalid() -> Matrix {
        Matrix(scaleX: .greatestFiniteMagnitude, skewX: .greatestFiniteMagnitude, transX: .greatestFiniteMagnitude,
               skewY: .greatestFiniteMagnitude, scaleY: .greatestFiniteMagnitude, transY: .greatestFiniteMagnitude,
               persp0: .greatestFiniteMagnitude, persp1: .greatestFiniteMagnitude, persp2: .greatestFiniteMagnitude)
    }

    mutating func setAll(scaleX: Float, skewX: Float, transX: Float, skewY: Float, scaleY: Float,
                         transY: Float, persp0: Float, persp1: Float, persp2: Float)
    {
        values[Self.SCALE_X] = scaleX
        values[Self.SKEW_X] = skewX
        values[Self.TRANS_X] = transX
        values[Self.SKEW_Y] = skewY
        values[Self.SCALE_Y] = scaleY
        values[Self.TRANS_Y] = transY
        values[Self.PERSP_0] = persp0
        values[Self.PERSP_1] = persp1
        values[Self.PERSP_2] = persp2
    }

    func getScaleX() -> Float {
        values[Self.SCALE_X]
    }

    func getScaleY() -> Float {
        values[Self.SCALE_Y]
    }

    func getSkewX() -> Float {
        values[Self.SCALE_X]
    }

    func getSkewY() -> Float {
        values[Self.SKEW_X]
    }

    func getTranslateX() -> Float {
        values[Self.TRANS_X]
    }

    func getTranslateY() -> Float {
        values[Self.TRANS_Y]
    }

    func isIdentity() -> Bool {
        return values[0] == 1 && values[1] == 0 && values[2] == 0 && values[3] == 0 && values[4] == 1 &&
            values[5] == 0 && values[6] == 0 && values[7] == 0 && values[8] == 1
    }

    mutating func setSkew(sx: Float, sy: Float) {
        values[Self.SCALE_X] = 1.0
        values[Self.SKEW_X] = sx
        values[Self.TRANS_X] = 0.0

        values[Self.SKEW_Y] = sy
        values[Self.SCALE_Y] = 1.0
        values[Self.TRANS_Y] = 0.0

        values[Self.PERSP_0] = 0.0
        values[Self.PERSP_1] = 0.0
        values[Self.PERSP_2] = 1.0
    }

    mutating func postSkew(sx: Float, sy: Float) {
        var m = Matrix()
        m.setSkew(sx: sx, sy: sy)
        self.postConcat(mat: m)
    }

    mutating func setConcat(mat: Matrix) {
        let matA = self.values
        let matB = mat.values

        var a: Float = matB[Self.SCALE_X] * matA[Self.SCALE_X]
        var b: Float = 0.0
        var c: Float = 0.0
        var d: Float = matB[Self.SCALE_Y] * matA[Self.SCALE_Y]
        var tx: Float = matB[Self.TRANS_X] * matA[Self.SCALE_X] + matA[Self.TRANS_X]
        var ty: Float = matB[Self.TRANS_Y] * matA[Self.SCALE_Y] + matA[Self.TRANS_Y]

        if matB[Self.SKEW_Y] != 0.0 || matB[Self.SKEW_X] != 0.0 || matA[Self.SKEW_Y] != 0.0 || matA[Self.SKEW_X] != 0.0 {
            a += matB[Self.SKEW_Y] * matA[Self.SKEW_X]
            d += matB[Self.SKEW_X] * matA[Self.SKEW_Y]
            b += matB[Self.SCALE_X] * matA[Self.SKEW_Y] + matB[Self.SKEW_Y] * matA[Self.SCALE_Y]
            c += matB[Self.SKEW_X] * matA[Self.SCALE_X] + matB[Self.SCALE_Y] * matA[Self.SKEW_X]
            tx += matB[Self.TRANS_Y] * matA[Self.SKEW_X]
            ty += matB[Self.TRANS_X] * matA[Self.SKEW_Y]
        }

        values[Self.SCALE_X] = a
        values[Self.SKEW_Y] = b
        values[Self.SKEW_X] = c
        values[Self.SCALE_Y] = d
        values[Self.TRANS_X] = tx
        values[Self.TRANS_Y] = ty
        values[Self.PERSP_0] = 0
        values[Self.PERSP_1] = 0
        values[Self.PERSP_2] = 1
    }

    mutating func postConcat(mat: Matrix) {
        if !mat.isIdentity() {
            self.setConcat(mat: mat)
        }
    }
}

extension Matrix {
    func toAffineTransform() -> CGAffineTransform {
        let sx = CGFloat(self.getScaleX())
        let sy = CGFloat(self.getScaleY())
        let skewx = CGFloat(self.getSkewX())
        let skewy = CGFloat(self.getSkewY())
        let tx = CGFloat(self.getTranslateX())
        let ty = CGFloat(self.getTranslateY())
        return __CGAffineTransformMake(sx, skewy, -skewx, sy, tx, ty)
    }
}
