//
//  ViewController.m
//  MetalSample
//
//  Created by king on 2020/10/13.
//

#import "ViewController.h"

#import "AAPLTransforms.h"
#import "ShaderTypes.h"
#import "Util.h"

#import <AVFoundation/AVUtilities.h>
#import <MetalKit/MetalKit.h>

using namespace AAPL;
using namespace simd;

struct KeyFrameParams {
    float time;
    float value;
};

#define keyframesCount 6

@interface ViewController () <MTKViewDelegate>
@property (nonatomic, weak) IBOutlet MTKView *metalView;
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLTexture> imageTexture;
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;
@property (nonatomic, strong) id<MTLBuffer> indexBuffer;

@property (nonatomic, assign) SSUniform uniform;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) CGRect renderRect;
@property (nonatomic, assign) CGSize drawableSize;
@end

@implementation ViewController {
    KeyFrameParams keyframes[keyframesCount];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    _drawableSize = CGSizeZero;

    keyframes[0] = {0.f, -90.f};
    keyframes[1] = {5.f / 30.f, 25.f};
    keyframes[2] = {8.f / 30.f, -25.f};
    keyframes[3] = {10.f / 30.f, 15.f};
    keyframes[4] = {14.f / 30.f, -15.f};
    keyframes[5] = {18.f / 30.f, 0.f};
}

- (void)viewWillAppear {
    [super viewWillAppear];

    [self.view.window setFrame:NSMakeRect(0, 0, 360, 640) display:YES];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view.window center];
        [self commonInit];
    });
}

- (void)viewDidAppear {
    [super viewDidAppear];

    self.view.window.movableByWindowBackground = YES;
}

#pragma mark - commonInit
- (void)commonInit {
    _device = MTLCreateSystemDefaultDevice();

    self.metalView.device = _device;

    _drawableSize = CGSizeApplyAffineTransform(self.view.bounds.size, CGAffineTransformMakeScale(NSScreen.mainScreen.backingScaleFactor, NSScreen.mainScreen.backingScaleFactor));

    [self makeTexture];
    [self makeBuffers];
    [self makePipeline];

    self.metalView.clearColor = MTLClearColorMake(1, 1, 1, 1);
    self.metalView.delegate = self;

    [self.metalView draw];
}

- (void)makePipeline {
    id<MTLLibrary> library = [self.device newDefaultLibrary];

    id<MTLFunction> vertexFunc = [library newFunctionWithName:@"vertex_main"];
    id<MTLFunction> fragmentFunc = [library newFunctionWithName:@"fragment_main"];

    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    //    pipelineDescriptor.rasterSampleCount               = 4;
    pipelineDescriptor.colorAttachments[0].pixelFormat = self.metalView.colorPixelFormat;
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

- (void)makeBuffers {

    CGSize drawableSize = _drawableSize;
    if (CGSizeEqualToSize(drawableSize, CGSizeZero)) {
        return;
    }
    CGRect renderRect = self.view.bounds;
    renderRect = CGRectApplyAffineTransform(renderRect, CGAffineTransformMakeScale(NSScreen.mainScreen.backingScaleFactor, NSScreen.mainScreen.backingScaleFactor));
    float vertices[16], sourceCoordinates[8];

    renderRect = AVMakeRectWithAspectRatioInsideRect(drawableSize, CGRectMake(0, 0, self.imageTexture.width, self.imageTexture.height));
    renderRect.origin.x = (drawableSize.width - renderRect.size.width) * 0.5;
    renderRect.origin.y = (drawableSize.height - renderRect.size.height) * 0.5;
    genMTLVertices(renderRect, drawableSize, vertices, YES, YES);

    //    replaceArrayElements(sourceCoordinates, kMTLTextureCoordinatesIdentity, 8);
    //    SSVertex vertexData[4] = {
    //        (SSVertex){simd_make_float4(-1, -1, 0, 1), simd_make_float2(0, 1)},
    //        (SSVertex){simd_make_float4(-1, 1, 0, 1), simd_make_float2(0, 0)},
    //        (SSVertex){simd_make_float4(1, -1, 0, 1), simd_make_float2(1, 1)},
    //        (SSVertex){simd_make_float4(1, 1, 0, 1), simd_make_float2(1, 0)},
    //    };

    //    SSVertex vertexData[4] = {
    //        (SSVertex){simd_make_float4(-1, -1, 0, 1), simd_make_float2(0, 1)},
    //        (SSVertex){simd_make_float4(-1, 1, 0, 1), simd_make_float2(0, 0)},
    //        (SSVertex){simd_make_float4(1, -1, 0, 1), simd_make_float2(1, 1)},
    //        (SSVertex){simd_make_float4(1, 1, 0, 1), simd_make_float2(1, 0)},
    //    };

    SSVertex vertexData[4] = {
        (SSVertex){simd_make_float4(vertices[0], vertices[1], 0, 1), simd_make_float2(0, 1)},
        (SSVertex){simd_make_float4(vertices[4], vertices[5], 0, 1), simd_make_float2(0, 0)},
        (SSVertex){simd_make_float4(vertices[8], vertices[9], 0, 1), simd_make_float2(1, 1)},
        (SSVertex){simd_make_float4(vertices[12], vertices[13], 0, 1), simd_make_float2(1, 0)},
    };

    _vertexBuffer = [self.device newBufferWithBytes:vertexData
                                             length:sizeof(vertexData)
                                            options:MTLResourceStorageModeShared];
}

- (void)makeTexture {
    MTKTextureLoader *loader = [[MTKTextureLoader alloc] initWithDevice:self.device];

    NSImage *image = [NSImage imageNamed:@"test.jpg"];
    NSSize imageSize = [image size];

    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, imageSize.width, imageSize.height, 8, 0, [[NSColorSpace genericRGBColorSpace] CGColorSpace], kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst);

    [NSGraphicsContext saveGraphicsState];

    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithCGContext:bitmapContext flipped:NO]];

    [image drawInRect:NSMakeRect(0, 0, imageSize.width, imageSize.height) fromRect:NSZeroRect operation:NSCompositingOperationCopy fraction:1.0];

    [NSGraphicsContext restoreGraphicsState];

    CGImageRef cgImage = CGBitmapContextCreateImage(bitmapContext);

    CGContextRelease(bitmapContext);

    NSError *error = nil;
    self.imageTexture = [loader newTextureWithCGImage:cgImage options:@{MTKTextureLoaderOptionSRGB: @(NO), MTKTextureLoaderOriginTopLeft: @YES} error:&error];
    if (error) {
        NSAssert(NO, @"%@", error);
    }
}

#pragma mark - MTKViewDelegate
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    _drawableSize = size;
    [self makeBuffers];
}

- (void)drawInMTKView:(MTKView *)view {

    CGSize drawableSize = _drawableSize;
    if (CGSizeEqualToSize(drawableSize, CGSizeZero)) {
        return;
    }

    id<CAMetalDrawable> drawable = [self.metalView currentDrawable];

    if (drawable) {

        id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];

        MTLRenderPassDescriptor *passDescriptor = self.metalView.currentRenderPassDescriptor;
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1);

        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
        [commandEncoder setRenderPipelineState:self.pipelineState];
        [commandEncoder setViewport:(MTLViewport){0, 0, drawableSize.width, drawableSize.height, -1, 1}];
        [commandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:SSVertexInputIndexVertices];
        [commandEncoder setFragmentTexture:self.imageTexture atIndex:SSFragmentTextureIndexOne];

        // 贴图统一使用像素坐标系
        // 正交投影矩阵
        //        GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(-1, 1, -1, 1, -1, 1);

        //        float aspect = 1.0f * drawableSize.width / drawableSize.height;
        //                GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90), aspect, 1, 10);

        //        float width = drawableSize.width;
        //        float height = drawableSize.height;
        float4x4 projectionMatrix = frustum(-1.f, 1.f, -1.f, 1.f, 1.f, 1000.f);
        //        projectionMatrix          = perspective_fov(65.f, width, height, 0.1, 100.f);
        //        projectionMatrix = ortho2d_oc(-1, 1, -1, 1, -1, 1);
        float3 eye = {0.f, 0.f, 1.f};
        float3 center = {0.f, 0.f, 0.f};
        float3 up = {0.f, 1.f, 0.f};

        float4x4 viewMatrix = lookAt(eye, center, up);

        static float beginTime = -1;
        if (beginTime == -1) {
            beginTime = CACurrentMediaTime();
        }

        float time = CACurrentMediaTime() - beginTime;

        float degree = 0;
        for (int i = 0; i < keyframesCount - 1; i++) {
            float startTime = keyframes[i].time;
            float endTime = keyframes[i + 1].time;
            if (i == 0 && time < startTime) {
                degree = keyframes[i].value;
                break;
            }

            if (i == (keyframesCount - 2) && time > endTime) {
                degree = keyframes[i + 1].value;
                break;
            }

            if (time >= startTime && time <= endTime) {
                float progress = (time - startTime) / (endTime - startTime);

                //            progress = elasticEaseInOut(progress);
                //            progress = bounceEaseOut(progress);
                float fromValue = keyframes[i].value;
                float toValue = keyframes[i + 1].value;
                degree = fromValue + progress * (toValue - fromValue);
                break;
            }
        }

        if (time >= 1.2) {
            beginTime = CACurrentMediaTime();
        }
        // matrix_identity_float4x4
        // 需要加 translate z -1
        float4x4 modelMatrix = translate(0.0, 0.0, -1.0) * rotate(degree, 1.0, 0, 0);  // * scale(2.0, 2.0, .0);

        SSUniform uniform = (SSUniform){
            .projection = projectionMatrix,
            .view = viewMatrix,
            .model = modelMatrix,
        };

        [commandEncoder setVertexBytes:&uniform length:sizeof(uniform) atIndex:SSVertexInputIndexUniforms];

        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
        [commandEncoder endEncoding];

        [commandBuffer presentDrawable:drawable];

        [commandBuffer commit];
    }
}
@end

