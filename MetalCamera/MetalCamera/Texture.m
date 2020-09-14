//
//  Texture.m
//  MetalCamera
//
//  Created by king on 2020/9/11.
//  Copyright © 2020 0x1306a94. All rights reserved.
//

#import "Texture.h"

@interface Texture ()
@property (nonatomic, strong) id<MTLTexture> texture;
@property (nonatomic, strong) id<MTLTexture> textureY;
@property (nonatomic, strong) id<MTLTexture> textureUV;
@end

@implementation Texture
//#if DEBUG
//- (void)dealloc {
//	NSLog(@"[%@ dealloc]", NSStringFromClass(self.class));
//}
//#endif

- (instancetype)initWithSampleBuffer:(CMSampleBufferRef)sampleBuffer textureCache:(CVMetalTextureCacheRef)textureCache separatedYUV:(BOOL)separatedYUV {
	if (sampleBuffer == nil || textureCache == nil) {
		return nil;
	}
	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	if (pixelBuffer == NULL) {
		return nil;
	}

	if (separatedYUV) {
		id<MTLTexture> textureY, textureUV;

		// textureY 设置
		{
			size_t width               = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
			size_t height              = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
			MTLPixelFormat pixelFormat = MTLPixelFormatR8Unorm;  // 这里的颜色格式不是RGBA

			CVMetalTextureRef texture = NULL;  // CoreVideo的Metal纹理
			CVReturn status           = CVMetalTextureCacheCreateTextureFromImage(NULL, textureCache, pixelBuffer, NULL, pixelFormat, width, height, 0, &texture);
			if (status == kCVReturnSuccess) {
				textureY = CVMetalTextureGetTexture(texture);  // 转成Metal用的纹理
				CFRelease(texture);
			}
		}

		// textureUV 设置
		{
			size_t width               = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
			size_t height              = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
			MTLPixelFormat pixelFormat = MTLPixelFormatRG8Unorm;  // 2-8bit的格式

			CVMetalTextureRef texture = NULL;  // CoreVideo的Metal纹理
			CVReturn status           = CVMetalTextureCacheCreateTextureFromImage(NULL, textureCache, pixelBuffer, NULL, pixelFormat, width, height, 1, &texture);
			if (status == kCVReturnSuccess) {
				textureUV = CVMetalTextureGetTexture(texture);  // 转成Metal用的纹理
				CFRelease(texture);
			}
		}

		if (textureY != nil && textureUV != nil && self == [super init]) {
			self.textureY  = textureY;
			self.textureUV = textureUV;
			return self;
		}
	} else {
		id<MTLTexture> texture;

		// textureY 设置
		{
			size_t width               = CVPixelBufferGetWidth(pixelBuffer);
			size_t height              = CVPixelBufferGetHeight(pixelBuffer);
			MTLPixelFormat pixelFormat = MTLPixelFormatBGRA8Unorm;  // 这里的颜色格式不是RGBA

			CVMetalTextureRef textureRef = NULL;  // CoreVideo的Metal纹理
			CVReturn status              = CVMetalTextureCacheCreateTextureFromImage(NULL, textureCache, pixelBuffer, NULL, pixelFormat, width, height, 0, &textureRef);
			if (status == kCVReturnSuccess) {
				texture = CVMetalTextureGetTexture(textureRef);  // 转成Metal用的纹理
				CFRelease(textureRef);
			}
		}

		if (texture != nil && self == [super init]) {
			self.texture = texture;
			return self;
		}
	}
	return nil;
}
@end

