//
//  KKRenderer.m
//  MetalSample3
//
//  Created by king on 2021/9/1.
//

#import "KKRenderer.h"

// 需要在 Foundation.h 后面
#import "AAPLTransforms.h"

#import "AnimationParams.hpp"

#import <AVFoundation/AVUtilities.h>
#import <MetalKit/MetalKit.h>

@interface KKRenderer ()
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) MTKView *view;
@property (nonatomic, strong) MTKTextureLoader *textureLoader;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLTexture> imageTexture0;
@property (nonatomic, strong) id<MTLTexture> imageTexture1;
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;
@property (nonatomic, strong) id<MTLBuffer> uniformBuffer;
@property (nonatomic, strong) id<MTLBuffer> progressBuffer;
@property (nonatomic, strong) id<MTLBuffer> indexBuffer;
@property (nonatomic, assign) NSInteger vertexCount;
@property (nonatomic, assign) NSInteger indexCount;
@property (nonatomic, assign) NSInteger instanceCount;

@property (nonatomic, assign) CGSize drawableSize;

@property (nonatomic, assign) AnimationParams *animationParams;
@end

@implementation KKRenderer
- (void)dealloc {
#if DEBUG
    NSLog(@"[%@ dealloc]", NSStringFromClass(self.class));
#endif
    if (_animationParams != NULL) {
        free(_animationParams);
        _animationParams = NULL;
    }
}
- (instancetype)initWithView:(MTKView *)view {
    if (self == [super init]) {
        self.device = view.device;
        self.textureLoader = [[MTKTextureLoader alloc] initWithDevice:self.device];
        self.view = view;
        _animationParams = NULL;
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

    id<MTLFunction> vertexFunc = [library newFunctionWithName:@"vertex_main"];
    id<MTLFunction> fragmentFunc = [library newFunctionWithName:@"fragment_main"];

    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    //    pipelineDescriptor.rasterSampleCount               = 4;
    pipelineDescriptor.colorAttachments[0].pixelFormat = self.view.colorPixelFormat;
    pipelineDescriptor.vertexFunction = vertexFunc;
    pipelineDescriptor.fragmentFunction = fragmentFunc;

    NSError *error = nil;
    _pipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor
                                                                 error:&error];

    if (!_pipelineState) {
        NSLog(@"Error occurred when creating render pipeline state: %@", error);
    }

    _commandQueue = [self.device newCommandQueue];
}

- (void)makeTexture {
    self.imageTexture0 = [self loadTexture:@"76824d1cd998d76ce18040a48fd49b920cb377b1.JPG"];
    self.imageTexture1 = [self loadTexture:@"7DFF4B43-819E-48AD-88E1-DE68CA71D33C.jpeg"];
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
    CGRect renderRect = CGRectMake(0, 0, drawableSize.width, drawableSize.height);
    CGSize imageSize = CGSizeMake(self.imageTexture0.width, self.imageTexture0.height);
    // 按比例计算大小
    CGRect insideRect = AVMakeRectWithAspectRatioInsideRect(imageSize, renderRect);
    insideRect.size.width = floor(insideRect.size.width);
    insideRect.size.height = floor(insideRect.size.height);
    // 居中
    insideRect.origin.x = (drawableSize.width - insideRect.size.width) * 0.5;
    insideRect.origin.y = (drawableSize.height - insideRect.size.height) * 0.5;

    int col = 4, row = 6;

    // 一个矩形 4个顶点, 通过三角形扇
    self.vertexCount = col * row * 4;
    // 一个矩形 算两个三角形实例
    self.instanceCount = col * row;
    // 一个三角形需要三个顶点索引
    self.indexCount = self.instanceCount * 6;
    // 每一个小矩形大小
    CGSize itemSize = CGSizeMake(CGRectGetWidth(insideRect) / col, CGRectGetHeight(insideRect) / row);

    _vertexBuffer = [self.device newBufferWithLength:sizeof(SSVertex) * self.vertexCount options:MTLResourceStorageModeShared];
    _uniformBuffer = [self.device newBufferWithLength:sizeof(SSUniform) * self.instanceCount options:MTLResourceStorageModeShared];
    _indexBuffer = [self.device newBufferWithLength:sizeof(UInt16) * self.indexCount options:MTLResourceStorageModeShared];
    _progressBuffer = [self.device newBufferWithLength:sizeof(simd::float1) * self.indexCount options:MTLResourceStorageModeShared];

    SSVertex *vertexContents = static_cast<SSVertex *>(_vertexBuffer.contents);
    SSUniform *uniformContents = static_cast<SSUniform *>(_uniformBuffer.contents);
    SSProgressUniform *progressContents = static_cast<SSProgressUniform *>(_progressBuffer.contents);
    UInt16 *indexContents = static_cast<UInt16 *>(_indexBuffer.contents);
    // 画布大小
    simd::float2 containerSize = simd::make_float2(drawableSize.width, drawableSize.height);

    float4x4 projectionMatrix = AAPL::frustum(-1.f, 1.f, -1.f, 1.f, 1.f, 1000.f);
    float3 eye = {0.f, 0.f, -2.f};
    float3 center = {0.f, 0.f, 0.f};
    float3 up = {0.f, 1.f, 0.f};

    float4x4 viewMatrix = AAPL::lookAt(eye, center, up);

    _animationParams = (AnimationParams *)malloc(sizeof(AnimationParams) * self.instanceCount);

    for (NSInteger i = 0; i < self.instanceCount; i++) {
        float4x4 modelMatrix = matrix_identity_float4x4;
        uniformContents[i] = (SSUniform){
            .projection = projectionMatrix,
            .view = viewMatrix,
            .model = modelMatrix,
        };

        progressContents[0].progress = 0;

        _animationParams[i] = (AnimationParams){
            .time = static_cast<float>(i) * 0.025f + 2.0f,
            .duration = 0.4,
            .form = 0,
            .to = -180,
        };
    }

    for (int r = 0; r < row; r++) {
        for (int c = 0; c < col; c++) {
            int rectIdx = (r * col + c);
            int vertexStart = rectIdx * 4;
            // 小矩形区域
            CGRect targetRect = CGRectMake(c * itemSize.width + insideRect.origin.x, r * itemSize.height + insideRect.origin.y, itemSize.width, itemSize.height);
            // N 倒N 型顶点排布
            simd::float4 positions[4] = {0};
            simd::float2 textureCoordinates[4] = {0};
            AAPL::genQuadVertices(positions, simd::make_float4(targetRect.origin.x, targetRect.origin.y, targetRect.size.width, targetRect.size.height), containerSize, true, true);
            AAPL::genQuadTextureCoordinates(textureCoordinates, simd::make_float4(c * itemSize.width, r * itemSize.height, itemSize.width, itemSize.height), simd::make_float2(CGRectGetWidth(insideRect), CGRectGetHeight(insideRect)));

            do {
                simd::float4 _positions[4] = {0};
                AAPL::genQuadVertices(_positions, simd::make_float4(CGRectGetMidX(targetRect), CGRectGetMidY(targetRect), targetRect.size.width, targetRect.size.height), containerSize, true, true);
                _animationParams[rectIdx].tx = 0 - _positions[1].x;
                _animationParams[rectIdx].ty = 0 - _positions[1].y;
            } while (0);
            // 左下
            vertexContents[vertexStart + 0] = (SSVertex){positions[0], textureCoordinates[0]};
            // 左上
            vertexContents[vertexStart + 1] = (SSVertex){positions[1], textureCoordinates[1]};
            // 右下
            vertexContents[vertexStart + 2] = (SSVertex){positions[2], textureCoordinates[2]};
            // 右上
            vertexContents[vertexStart + 3] = (SSVertex){positions[3], textureCoordinates[3]};
            NSLog(@"%d %@", rectIdx, NSStringFromRect(targetRect));
            NSLog(@"vertex: {%.3f, %.3f} {%.3f, %.3f} {%.3f, %.3f} {%.3f, %.3f}", positions[0].x, positions[0].y,
                  positions[1].x, positions[1].y,
                  positions[2].x, positions[2].y,
                  positions[3].x, positions[3].y);

            // 顶点索引绘制
            //            // 右上
            //            vertexContents[vertexStart + 0] = (SSVertex){positions[3], textureCoordinates[3]};
            //            // 右下
            //            vertexContents[vertexStart + 1] = (SSVertex){positions[2], textureCoordinates[2]};
            //            // 左下
            //            vertexContents[vertexStart + 2] = (SSVertex){positions[0], textureCoordinates[0]};
            //            // 左上
            //            vertexContents[vertexStart + 3] = (SSVertex){positions[1], textureCoordinates[1]};

            //            // 左下
            //            vertexContents[rectIdx + 3] = (SSVertex){positions[0], textureCoordinates[0]};
            //            // 左上
            //            vertexContents[rectIdx + 4] = (SSVertex){positions[1], textureCoordinates[1]};
            //            // 右上
            //            vertexContents[rectIdx + 5] = (SSVertex){positions[3], textureCoordinates[3]};

            //            NSLog(@"%d %@", rectIdx, NSStringFromRect(targetRect));
            //            NSLog(@"vertex: {%.3f, %.3f} {%.3f, %.3f} {%.3f, %.3f} {%.3f, %.3f}", positions[3].x, positions[3].y,
            //                  positions[2].x, positions[2].y,
            //                  positions[0].x, positions[0].y,
            //                  positions[1].x, positions[1].y);

            //            int indexStart = rectIdx * 6;
            //
            //            indexContents[indexStart + 0] = vertexStart + 0;
            //            indexContents[indexStart + 1] = vertexStart + 1;
            //            indexContents[indexStart + 2] = vertexStart + 2;
            //
            //            indexContents[indexStart + 3] = vertexStart + 2;
            //            indexContents[indexStart + 4] = vertexStart + 3;
            //            indexContents[indexStart + 5] = vertexStart + 0;
            //
            //            NSLog(@"index:  %d %d %d %d %d %d", indexContents[indexStart + 0],
            //                  indexContents[indexStart + 1],
            //                  indexContents[indexStart + 2],
            //                  indexContents[indexStart + 3],
            //                  indexContents[indexStart + 4],
            //                  indexContents[indexStart + 5]);
        }
    }
}

#pragma mark - MTKViewDelegate
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    self.drawableSize = size;
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

    do {
        // 计算动画值
        static float beginTime = -1;
        if (beginTime == -1) {
            beginTime = CACurrentMediaTime();
        }
        float time = CACurrentMediaTime() - beginTime;

        SSUniform *uniformContents = static_cast<SSUniform *>(self.uniformBuffer.contents);
        SSProgressUniform *progressContents = static_cast<SSProgressUniform *>(self.progressBuffer.contents);
        for (int i = 0; i < self.instanceCount; i++) {

            float4x4 modelMatrix = matrix_identity_float4x4;
            float degree = 0;
            float progress = 0.0;
            AnimationParams params = self.animationParams[i];
            float startTime = params.time;
            float endTime = startTime + params.duration;
            if (time >= startTime && time <= endTime) {
                progress = (time - startTime) / params.duration;
                float fromValue = params.form;
                float toValue = params.to;
                degree = fromValue + progress * (toValue - fromValue);
                /*
                 旋转 缩放 是以原点(0,0,0)为中心进行
                 所以需要 先平移到 原点 -> 旋转.缩放 -> 平移回去
                 但是在矩阵乘法上,需要从右往左读, 也就是下面的计算顺序
                 */
                modelMatrix = AAPL::translate(-params.tx, -params.ty, 0) * AAPL::rotate(degree, 0.0, 1.0, 0) * AAPL::translate(params.tx, params.ty, 0);
            } else if (time >= endTime) {
                progress = 1.0;
            }

            progressContents[i].progress = progress;
            uniformContents[i].model = modelMatrix;
        }

        if (time >= 4.0) {
            beginTime = CACurrentMediaTime();
        }
    } while (0);

    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];

    MTLRenderPassDescriptor *passDescriptor = self.view.currentRenderPassDescriptor;
    passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1);

    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
    [commandEncoder setRenderPipelineState:self.pipelineState];
    [commandEncoder setViewport:(MTLViewport){0, 0, drawableSize.width, drawableSize.height, -1, 1}];
    //    [commandEncoder setCullMode:MTLCullModeFront];
    [commandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:SSVertexInputIndexVertices];
    [commandEncoder setVertexBuffer:self.uniformBuffer offset:0 atIndex:SSVertexInputIndexUniforms];
    uint vertexCount = 4;
    [commandEncoder setVertexBytes:&vertexCount length:sizeof(uint) atIndex:SSVertexInputIndexVertexCount];
    [commandEncoder setFragmentBuffer:self.progressBuffer offset:0 atIndex:SSVertexInputIndexUniforms];
    [commandEncoder setFragmentTexture:self.imageTexture0 atIndex:SSFragmentTextureIndexOne];
    [commandEncoder setFragmentTexture:self.imageTexture1 atIndex:SSFragmentTextureIndexTow];
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:vertexCount instanceCount:self.instanceCount];
    //    [commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:self.indexCount indexType:MTLIndexTypeUInt16 indexBuffer:self.indexBuffer indexBufferOffset:0];
    [commandEncoder endEncoding];

    [commandBuffer presentDrawable:drawable];

    [commandBuffer commit];
}
@end

