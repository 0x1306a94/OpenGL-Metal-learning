//
//  FontMetrics.swift
//  MetalRenderTextSample
//
//  Created by king on 2022/4/12.
//

import Foundation

final class FontMetrics {
    /**
     * Extent above baseline.
     */
    var top: Float = 0
    /**
     * Distance to reserve above baseline.
     */
    var ascent: Float = 0
    /**
     * Distance to reserve below baseline.
     */
    var descent: Float = 0
    /**
     * Extent below baseline.
     */
    var bottom: Float = 0
    /**
     * Distance to add between lines.
     */
    var leading: Float = 0
    /**
     * Minimum x.
     */
    var xMin: Float = 0
    /**
     * Maximum x.
     */
    var xMax: Float = 0
    /**
     * Height of lower-case 'x'.
     */
    var xHeight: Float = 0
    /**
     * Height of an upper-case letter.
     */
    var capHeight: Float = 0
    /**
     * Underline thickness.
     */
    var underlineThickness: Float = 0
    /**
     * Underline position relative to baseline.
     */
    var underlinePosition: Float = 0
}

struct GlyphMetrics {
    var width: Float = 0
    var height: Float = 0

    // The offset from the glyphs' origin on the baseline to the top left of the glyph mask.
    var top: Float = 0
    var left: Float = 0

    // The advance for this glyph.
    var advanceX: Float = 0
    var advanceY: Float = 0
}
