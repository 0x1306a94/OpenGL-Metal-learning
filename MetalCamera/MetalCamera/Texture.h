//
//  Texture.h
//  MetalCamera
//
//  Created by king on 2020/9/11.
//  Copyright © 2020 0x1306a94. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreMedia/CoreMedia.h>
#import <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Texture : NSObject
@property (nonatomic, strong, readonly) id<MTLTexture> textureY;
@property (nonatomic, strong, readonly) id<MTLTexture> textureUV;

- (instancetype)initWithSampleBuffer:(CMSampleBufferRef)sampleBuffer textureCache:(CVMetalTextureCacheRef)textureCache;
@end

NS_ASSUME_NONNULL_END

