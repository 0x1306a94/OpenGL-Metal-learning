//
//  Util.h
//  MetalSample
//
//  Created by king on 2020/10/18.
//

#ifndef Util_h
#define Util_h

@import simd;
@import GLKit;
@import CoreGraphics;

float const kMTLTextureCoordinatesIdentity[8] = {
    0.0, 1.0,  //
    0.0, 0.0,  //
    1.0, 1.0,  //
    1.0, 0.0   //
};

static void replaceArrayElements(float arr0[], float arr1[], int size) {

    if ((arr0 == NULL || arr1 == NULL) && size > 0) {
        assert(0);
    }
    if (size < 0) {
        assert(0);
    }
    for (int i = 0; i < size; i++) {
        arr0[i] = arr1[i];
    }
}

//倒N形
static void genMTLVertices(CGRect rect, CGSize containerSize, float vertices[16], BOOL reverse, BOOL normalized) {
	if (vertices == NULL) {
		NSLog(@"generateMTLVertices params illegal.");
		assert(0);
		return;
	}
	if (containerSize.width <= 0 || containerSize.height <= 0) {
		NSLog(@"generateMTLVertices params containerSize illegal.");
		assert(0);
		return;
	}
	float originX, originY, width, height;
	if (normalized) {
		originX = -1 + 2 * rect.origin.x / containerSize.width;
		originY = 1 - 2 * rect.origin.y / containerSize.height;
		width   = 2 * rect.size.width / containerSize.width;
		height  = 2 * rect.size.height / containerSize.height;
	} else {
		originX = rect.origin.x;
		originY = rect.origin.y;
		width   = rect.size.width;
		height  = rect.size.height;
	}

	if (reverse) {

		if (normalized) {
			float tempVertices[] = {
				originX, originY - height, 0.0, 1.0,          //
				originX, originY, 0.0, 1.0,                   //
				originX + width, originY - height, 0.0, 1.0,  //
				originX + width, originY, 0.0, 1.0            //
			};
			replaceArrayElements(vertices, tempVertices, 16);
			return;
		}
		float tempVertices[] = {
			originX, originY + height, 0.0, 1.0,          //
			originX, originY, 0.0, 1.0,                   //
			originX + width, originY + height, 0.0, 1.0,  //
			originX + width, originY, 0.0, 1.0            //
		};
		replaceArrayElements(vertices, tempVertices, 16);
		return;
	}
	if (normalized) {
		float tempVertices[] = {
			originX, originY, 0.0, 1.0,                  //
			originX, originY - height, 0.0, 1.0,         //
			originX + width, originY, 0.0, 1.0,          //
			originX + width, originY - height, 0.0, 1.0  //
		};
		replaceArrayElements(vertices, tempVertices, 16);
		return;
	}
	float tempVertices[] = {
		originX, originY, 0.0, 1.0,                  //
		originX, originY + height, 0.0, 1.0,         //
		originX + width, originY, 0.0, 1.0,          //
		originX + width, originY + height, 0.0, 1.0  //
	};
	replaceArrayElements(vertices, tempVertices, 16);
}

static simd_float4x4 getMetalMatrixFromGLKMatrix(GLKMatrix4 matrix) {
    simd_float4x4 ret = (simd_float4x4){
        simd_make_float4(matrix.m00, matrix.m01, matrix.m02, matrix.m03),
        simd_make_float4(matrix.m10, matrix.m11, matrix.m12, matrix.m13),
        simd_make_float4(matrix.m20, matrix.m21, matrix.m22, matrix.m23),
        simd_make_float4(matrix.m30, matrix.m31, matrix.m32, matrix.m33),
    };
    return ret;
}

/// 由屏幕坐标转换到归一化坐标
/// @param pt_dc 屏幕坐标
/// @param size 屏幕大小
/// @return 归一化坐标
static CGPoint dc_to_ndc(CGPoint pt_dc, CGSize size) {
    CGFloat x = (pt_dc.x + 0.5) / size.width;
    CGFloat y = (pt_dc.y + 0.5) / size.height;
    return CGPointMake(x * 2.0 - 1.0, -(y * 2.0 - 1.0));
}

/// 由归一化坐标转换到屏幕坐标
/// @param pt_ndc 归一化坐标
/// @param size 屏幕大小
/// @return 屏幕坐标
static CGPoint ndc_to_dc(CGPoint pt_ndc, CGSize size) {
    CGFloat x = (pt_ndc.x + 1.0) * 0.5;
    CGFloat y = (-pt_ndc.y + 1.0) * 0.5;
    x         = x * size.width - 0.5;
    y         = y * size.height - 0.5;

    return CGPointMake(x, y);
}
#endif /* Util_h */

