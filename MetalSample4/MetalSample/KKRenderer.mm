//
//  KKRenderer.m
//  MetalSample3
//
//  Created by king on 2021/9/1.
//

#import "KKRenderer.h"

// 需要在 Foundation.h 后面
#import "AAPLTransforms.h"

#import <AVFoundation/AVUtilities.h>
#import <MetalKit/MetalKit.h>

@interface KKRenderer ()
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) MTKView *view;
@property (nonatomic, strong) MTKTextureLoader *textureLoader;
@property (nonatomic, strong) id<MTLRenderPipelineState> renderState;
@property (nonatomic, strong) id<MTLComputePipelineState> computeState;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLTexture> inputTexture;
@property (nonatomic, strong) id<MTLTexture> outTexture;

@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;

@property (nonatomic, assign) CGRect renderRect;
@property (nonatomic, assign) CGSize drawableSize;

@property (nonatomic, assign) float time;
@end

@implementation KKRenderer
- (void)dealloc {
#if DEBUG
    NSLog(@"[%@ dealloc]", NSStringFromClass(self.class));
#endif
}
- (instancetype)initWithView:(MTKView *)view {
    if (self == [super init]) {
        self.device = view.device;
        self.textureLoader = [[MTKTextureLoader alloc] initWithDevice:self.device];
        self.view = view;
        //        view.framebufferOnly = NO;
        view.paused = YES;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.drawableSize = CGSizeApplyAffineTransform(self.view.bounds.size, CGAffineTransformMakeScale(NSScreen.mainScreen.backingScaleFactor, NSScreen.mainScreen.backingScaleFactor));

    [self makePipeline];
    [self makeTexture];
    [self makeBuffers];
}

- (void)makePipeline {
    id<MTLLibrary> library = [self.device newDefaultLibrary];

    id<MTLFunction> kernelFunc = [library newFunctionWithName:@"processAnimation"];
    id<MTLFunction> vertexFunc = [library newFunctionWithName:@"vertex_main"];
    id<MTLFunction> fragmentFunc = [library newFunctionWithName:@"fragment_main"];

    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    //    pipelineDescriptor.rasterSampleCount               = 4;
    pipelineDescriptor.colorAttachments[0].pixelFormat = self.view.colorPixelFormat;
    pipelineDescriptor.vertexFunction = vertexFunc;
    pipelineDescriptor.fragmentFunction = fragmentFunc;

    NSError *error = nil;
    _renderState = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor
                                                               error:&error];

    if (!_renderState) {
        NSLog(@"Error occurred when creating render pipeline state: %@", error);
    }

    _computeState = [self.device newComputePipelineStateWithFunction:kernelFunc error:&error];
    if (!_computeState) {
        NSLog(@"Error occurred when creating compute pipeline state: %@", error);
    }

    _commandQueue = [self.device newCommandQueue];
}

- (void)makeTexture {
    self.inputTexture = [self loadTexture:@"76824d1cd998d76ce18040a48fd49b920cb377b1.JPG"];
    self.inputTexture = [self loadTexture:@"7DFF4B43-819E-48AD-88E1-DE68CA71D33C.jpeg"];

    MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:self.inputTexture.pixelFormat width:self.inputTexture.width height:self.inputTexture.height mipmapped:NO];
    desc.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite;
    desc.storageMode = MTLStorageModeManaged;

    self.outTexture = [self.device newTextureWithDescriptor:desc];
}

- (id<MTLTexture>)loadTexture:(NSString *)imageName {
    NSImage *image = [NSImage imageNamed:imageName];
    NSSize imageSize = [image size];

    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, imageSize.width, imageSize.height, 8, 0, [[NSColorSpace genericRGBColorSpace] CGColorSpace], kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst);

    [NSGraphicsContext saveGraphicsState];

    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithCGContext:bitmapContext flipped:NO]];

    [image drawInRect:NSMakeRect(0, 0, imageSize.width, imageSize.height) fromRect:NSZeroRect operation:NSCompositingOperationCopy fraction:1.0];

    [NSGraphicsContext restoreGraphicsState];

    CGImageRef cgImage = CGBitmapContextCreateImage(bitmapContext);

    CGContextRelease(bitmapContext);

    NSError *error = nil;
    id<MTLTexture> imageTexture = [self.textureLoader newTextureWithCGImage:cgImage options:@{MTKTextureLoaderOptionSRGB: @(NO), MTKTextureLoaderOriginTopLeft: @YES} error:&error];
    if (error) {
        NSAssert(NO, @"%@", error);
    }
    return imageTexture;
}

- (void)makeBuffers {
    CGSize drawableSize = self.drawableSize;
    if (CGSizeEqualToSize(drawableSize, CGSizeZero)) {
        return;
    }
    CGRect boundingRect = CGRectMake(0, 0, drawableSize.width, drawableSize.height);
    CGSize imageSize = CGSizeMake(self.inputTexture.width, self.inputTexture.height);
    // 按比例计算大小
    CGRect renderRect = AVMakeRectWithAspectRatioInsideRect(imageSize, boundingRect);
    renderRect.size.width = floor(renderRect.size.width);
    renderRect.size.height = floor(renderRect.size.height);
    // 居中
    renderRect.origin.x = (drawableSize.width - renderRect.size.width) * 0.5;
    renderRect.origin.y = (drawableSize.height - renderRect.size.height) * 0.5;

    self.renderRect = renderRect;

    // 画布大小
    simd::float2 containerSize = simd::make_float2(self.drawableSize.width, self.drawableSize.height);
    // N 倒N 型顶点排布
    simd::float4 positions[4] = {0};
    simd::float2 textureCoordinates[4] = {0};
    AAPL::genQuadVertices(positions, simd::make_float4(renderRect.origin.x, renderRect.origin.y, renderRect.size.width, renderRect.size.height), containerSize, true, true);
    AAPL::genQuadTextureCoordinates(textureCoordinates, simd::make_float4(0, 0, renderRect.size.width, renderRect.size.height), simd::make_float2(CGRectGetWidth(renderRect), CGRectGetHeight(renderRect)));

    _vertexBuffer = [self.device newBufferWithLength:sizeof(SSVertex) * 4 options:MTLResourceStorageModeShared];

    SSVertex *vertexContents = static_cast<SSVertex *>(self.vertexBuffer.contents);
    // 左下
    vertexContents[0] = (SSVertex){positions[0], textureCoordinates[0]};
    // 左上
    vertexContents[1] = (SSVertex){positions[1], textureCoordinates[1]};
    // 右下
    vertexContents[2] = (SSVertex){positions[2], textureCoordinates[2]};
    // 右上
    vertexContents[3] = (SSVertex){positions[3], textureCoordinates[3]};
}

- (void)prepareDraw {
}

- (void)updateTime:(float)time {
    self.time = time;
    [self.view draw];
}
#pragma mark - MTKViewDelegate
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    [self makeBuffers];
}

- (void)drawInMTKView:(MTKView *)view {
    CGSize drawableSize = self.drawableSize;
    if (CGSizeEqualToSize(drawableSize, CGSizeZero)) {
        return;
    }
    id<CAMetalDrawable> drawable = [self.view currentDrawable];

    if (!drawable) {
        return;
    }

    [self prepareDraw];

    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];

    float time = self.time;
    float duration = 3;

    do {
        id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
        [computeEncoder setComputePipelineState:self.computeState];
        [computeEncoder setTexture:self.outTexture atIndex:0];
        [computeEncoder setTexture:self.inputTexture atIndex:1];
        [computeEncoder setBytes:&time length:sizeof(float) atIndex:0];
        [computeEncoder setBytes:&duration length:sizeof(float) atIndex:1];

        MTLSize threadsPerGroup = {self.computeState.threadExecutionWidth, self.computeState.threadExecutionWidth, 1};
        //        MTLSize threadsPerGroup = {16, 16, 1};
        MTLSize numThreadgroups = {self.inputTexture.width / threadsPerGroup.width,
                                   self.inputTexture.height / threadsPerGroup.height, 1};

        [computeEncoder dispatchThreadgroups:numThreadgroups threadsPerThreadgroup:threadsPerGroup];
        [computeEncoder endEncoding];
    } while (0);

    do {
        MTLRenderPassDescriptor *passDescriptor = self.view.currentRenderPassDescriptor;
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1);

        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
        [commandEncoder setRenderPipelineState:self.renderState];
        [commandEncoder setViewport:(MTLViewport){0, 0, drawableSize.width, drawableSize.height, -1, 1}];
        [commandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:SSVertexInputIndexVertices];
        [commandEncoder setFragmentTexture:self.outTexture atIndex:SSFragmentTextureIndexOne];
        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
        [commandEncoder endEncoding];

        [commandBuffer presentDrawable:drawable];
    } while (0);

    [commandBuffer commit];
}
@end

