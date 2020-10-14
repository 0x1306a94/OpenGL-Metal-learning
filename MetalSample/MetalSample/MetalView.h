//
//  MetalView.h
//  MetalSample
//
//  Created by king on 2020/10/13.
//

@import Cocoa;
@import Metal;
@import QuartzCore;

NS_ASSUME_NONNULL_BEGIN

@interface MetalView : NSView
@property (nonatomic, readonly) CAMetalLayer *metalLayer;
@property (nonatomic) MTLPixelFormat colorPixelFormat;
@property (nonatomic, assign) MTLClearColor clearColor;
@property (nonatomic, readonly) NSTimeInterval frameDuration;
@property (nonatomic, readonly) id<CAMetalDrawable> currentDrawable;
@property (nonatomic, readonly) MTLRenderPassDescriptor *currentRenderPassDescriptor;
- (instancetype)initWithFrame:(CGRect)frame device:(id<MTLDevice>)device;

- (void)startDrawing;
- (void)stopDrawing;
@end

NS_ASSUME_NONNULL_END

