//
//  ViewController.m
//  MetalSample
//
//  Created by king on 2020/10/13.
//

#import "ViewController.h"

#import "ShaderTypes.h"
#import "Util.h"

#import <MetalKit/MetalKit.h>

@interface ViewController () <MTKViewDelegate>
@property (nonatomic, weak) IBOutlet MTKView *metalView;
@property (nonatomic, weak) IBOutlet NSSwitch *fxaaSwitch;
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLRenderPipelineState> fboPipeline;
@property (nonatomic, strong) id<MTLRenderPipelineState> fxaaPipeline;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLBuffer> fboVertexBuffer;
@property (nonatomic, strong) id<MTLBuffer> fboUniformBuffer;
@property (nonatomic, strong) id<MTLTexture> fboTexture;
@property (nonatomic, strong) id<MTLTexture> imageTexture;

@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;
@property (nonatomic, strong) id<MTLBuffer> indexBuffer;

@property (nonatomic, assign) SSUniform uniform;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) CGRect renderRect;
@property (nonatomic, assign) CGSize drawableSize;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    _drawableSize = CGSizeZero;
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

    [self makeBuffers];
    [self makeTexture];
    [self makeFBOTexture];
    [self makePipeline];

    self.metalView.clearColor = MTLClearColorMake(1, 1, 1, 1);
    //    self.metalView.sampleCount = 4;
    self.metalView.delegate = self;

    [self.metalView draw];
}

- (void)makePipeline {
    id<MTLLibrary> library = [self.device newDefaultLibrary];

    id<MTLFunction> vertexFunc   = [library newFunctionWithName:@"vertex_main"];
    id<MTLFunction> fragmentFunc = [library newFunctionWithName:@"fragment_main"];

    id<MTLFunction> fragmentFxaaFunc = [library newFunctionWithName:@"fragment_fxaa_main"];

    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    //    pipelineDescriptor.rasterSampleCount               = 4;
    pipelineDescriptor.colorAttachments[0].pixelFormat = self.metalView.colorPixelFormat;
    pipelineDescriptor.vertexFunction                  = vertexFunc;
    pipelineDescriptor.fragmentFunction                = fragmentFunc;

    NSError *error = nil;
    _fboPipeline   = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor
                                                               error:&error];

    if (!_fboPipeline) {
        NSLog(@"Error occurred when creating render pipeline state: %@", error);
    }

    pipelineDescriptor.fragmentFunction = fragmentFxaaFunc;

    _fxaaPipeline = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor
                                                                error:&error];

    if (!_fxaaPipeline) {
        NSLog(@"Error occurred when creating render pipeline state: %@", error);
    }

    _commandQueue = [self.device newCommandQueue];
}

- (void)makeBuffers {

    CGSize drawableSize = _drawableSize;
    if (CGSizeEqualToSize(drawableSize, CGSizeZero)) {
        return;
    }
    do {
        CGRect renderRect   = CGRectMake(200, 50, 200, 200);
        renderRect          = CGRectApplyAffineTransform(renderRect, CGAffineTransformMakeScale(NSScreen.mainScreen.backingScaleFactor, NSScreen.mainScreen.backingScaleFactor));
        renderRect.origin.x = (drawableSize.width - renderRect.size.width) * 0.5;
        self.renderRect     = renderRect;
        float vertices[16], sourceCoordinates[8];
        genMTLVertices(renderRect, drawableSize, vertices, YES, NO);

        replaceArrayElements(sourceCoordinates, (void *)kMTLTextureCoordinatesIdentity, 8);
        SSVertex vertexData[4] = {0};
        for (int i = 0; i < 4; i++) {
            vertexData[i] = (SSVertex){
                {vertices[(i * 4)], vertices[(i * 4) + 1], vertices[(i * 4) + 2], vertices[(i * 4) + 3]},
                {sourceCoordinates[(i * 2)], sourceCoordinates[(i * 2) + 1]},
            };
        }

        _fboVertexBuffer = [self.device newBufferWithBytes:vertexData
                                                    length:sizeof(vertexData)
                                                   options:MTLResourceStorageModeShared];
    } while (0);

    do {
        CGRect renderRect = CGRectMake(0, 0, 360, 640);
        renderRect        = CGRectApplyAffineTransform(renderRect, CGAffineTransformMakeScale(NSScreen.mainScreen.backingScaleFactor, NSScreen.mainScreen.backingScaleFactor));
        float vertices[16], sourceCoordinates[8];
        genMTLVertices(renderRect, drawableSize, vertices, YES, NO);

        replaceArrayElements(sourceCoordinates, (void *)kMTLTextureCoordinatesIdentity, 8);
        SSVertex vertexData[4] = {0};
        for (int i = 0; i < 4; i++) {
            vertexData[i] = (SSVertex){
                {vertices[(i * 4)], vertices[(i * 4) + 1], vertices[(i * 4) + 2], vertices[(i * 4) + 3]},
                {sourceCoordinates[(i * 2)], sourceCoordinates[(i * 2) + 1]},
            };
        }

        _vertexBuffer = [self.device newBufferWithBytes:vertexData
                                                 length:sizeof(vertexData)
                                                options:MTLResourceStorageModeShared];
    } while (0);
}

- (void)makeTexture {
    MTKTextureLoader *loader = [[MTKTextureLoader alloc] initWithDevice:self.device];

    NSImage *image   = [NSImage imageNamed:@"IMG_3750.jpeg"];
    NSSize imageSize = [image size];

    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, imageSize.width, imageSize.height, 8, 0, [[NSColorSpace genericRGBColorSpace] CGColorSpace], kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst);

    [NSGraphicsContext saveGraphicsState];

    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithCGContext:bitmapContext flipped:NO]];

    [image drawInRect:NSMakeRect(0, 0, imageSize.width, imageSize.height) fromRect:NSZeroRect operation:NSCompositingOperationCopy fraction:1.0];

    [NSGraphicsContext restoreGraphicsState];

    CGImageRef cgImage = CGBitmapContextCreateImage(bitmapContext);

    CGContextRelease(bitmapContext);

    NSError *error    = nil;
    self.imageTexture = [loader newTextureWithCGImage:cgImage options:@{MTKTextureLoaderOptionSRGB: @(NO)} error:&error];
    if (error) {
        NSAssert(NO, @"%@", error);
    }
}

- (void)makeFBOTexture {

    MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:self.metalView.colorPixelFormat width:_drawableSize.width height:_drawableSize.height mipmapped:NO];

    desc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;

    _fboTexture = [self.device newTextureWithDescriptor:desc];
    if (!_fboTexture) {
        NSAssert(NO, @"创建 fboTexture 失败");
    }
}

static CGFloat Degrees = 0;
static CGFloat tx      = 0;
static BOOL addTx      = YES;

#pragma mark - MTKViewDelegate
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    _drawableSize = size;
    [self makeBuffers];
    [self makeFBOTexture];
}

- (void)drawInMTKView:(MTKView *)view {

    CGSize drawableSize = _drawableSize;
    if (CGSizeEqualToSize(drawableSize, CGSizeZero)) {
        return;
    }

    if (!_fboTexture) {
        [self makeFBOTexture];
    }
    id<CAMetalDrawable> drawable = [self.metalView currentDrawable];

    CGSize renderSize = drawableSize;

    if (drawable) {

        MTLRenderPassDescriptor *passDescriptor        = [MTLRenderPassDescriptor renderPassDescriptor];
        passDescriptor.colorAttachments[0].loadAction  = MTLLoadActionClear;
        passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        passDescriptor.colorAttachments[0].texture     = self.fboTexture;
        passDescriptor.colorAttachments[0].clearColor  = MTLClearColorMake(1, 1, 1, 1);

        id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];

        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
        [commandEncoder setRenderPipelineState:self.fboPipeline];
        [commandEncoder setViewport:(MTLViewport){0, 0, drawableSize.width, drawableSize.height, -1, 1}];
        [commandEncoder setVertexBuffer:self.fboVertexBuffer offset:0 atIndex:SSVertexInputIndexVertices];

        [commandEncoder setFragmentTexture:self.imageTexture atIndex:SSFragmentTextureIndexOne];

        // 贴图统一使用像素坐标系
        // 正交投影矩阵
        GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, renderSize.width, renderSize.height, 0, -1, 1);

        GLKMatrix4 modelMatrix = GLKMatrix4Identity;

        // 修改旋转中心
        CGPoint controlPoint     = CGPointMake(CGRectGetMidX(self.renderRect), CGRectGetMidY(self.renderRect));
        GLKMatrix4 transformto   = GLKMatrix4MakeTranslation(-controlPoint.x, -controlPoint.y, 0);
        GLKMatrix4 rotateMatrix  = GLKMatrix4MakeZRotation(GLKMathDegreesToRadians(15));
        GLKMatrix4 transformback = GLKMatrix4MakeTranslation(controlPoint.x, controlPoint.y, 0);

        modelMatrix = GLKMatrix4Multiply(transformto, modelMatrix);
        modelMatrix = GLKMatrix4Multiply(rotateMatrix, modelMatrix);
        modelMatrix = GLKMatrix4Multiply(transformback, modelMatrix);

        SSUniform uniform = (SSUniform){
            .projection = getMetalMatrixFromGLKMatrix(projectionMatrix),
            .model      = getMetalMatrixFromGLKMatrix(modelMatrix),
        };

        [commandEncoder setVertexBytes:&uniform length:sizeof(uniform) atIndex:SSVertexInputIndexUniforms];
        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
        //        Degrees += 0.25;
        //        if (Degrees > 360) {
        //            Degrees = 0;
        //        }
        //        if (addTx) {
        //            tx += 0.001;
        //        } else {
        //            tx -= 0.001;
        //        }
        //        if (tx > 0.5) {
        //            tx    = 0.5;
        //            addTx = NO;
        //        } else if (tx < 0) {
        //            tx    = 0;
        //            addTx = YES;
        //        }

        modelMatrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(tx * 300, 500, 0), modelMatrix);

        SSUniform uniform2 = (SSUniform){
            .projection = getMetalMatrixFromGLKMatrix(projectionMatrix),
            .model      = getMetalMatrixFromGLKMatrix(modelMatrix),
        };

        [commandEncoder setVertexBytes:&uniform2 length:sizeof(uniform2) atIndex:SSVertexInputIndexUniforms];
        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
        [commandEncoder endEncoding];

        do {
            // 执行 FXAA
            MTLRenderPassDescriptor *passDescriptor = self.metalView.currentRenderPassDescriptor;

            id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
            [commandEncoder setRenderPipelineState:self.fxaaPipeline];
            [commandEncoder setViewport:(MTLViewport){0, 0, drawableSize.width, drawableSize.height, -1, 1}];
            [commandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:SSVertexInputIndexVertices];

            [commandEncoder setFragmentTexture:self.fboTexture atIndex:SSFragmentTextureIndexOne];

            // 贴图统一使用像素坐标系
            // 正交投影矩阵
            GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, renderSize.width, renderSize.height, 0, -1, 1);

            GLKMatrix4 modelMatrix = GLKMatrix4Identity;

            SSUniform uniform = (SSUniform){
                .projection = getMetalMatrixFromGLKMatrix(projectionMatrix),
                .model      = getMetalMatrixFromGLKMatrix(modelMatrix),
            };

            [commandEncoder setVertexBytes:&uniform length:sizeof(uniform) atIndex:SSVertexInputIndexUniforms];

            float size[2] = {renderSize.width, renderSize.height};
            bool enable   = (self.fxaaSwitch.state == NSControlStateValueOn) ? true : false;

            [commandEncoder setFragmentBytes:&size length:sizeof(size) atIndex:0];
            [commandEncoder setFragmentBytes:&enable length:sizeof(enable) atIndex:1];

            [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
            [commandEncoder endEncoding];

            [commandBuffer presentDrawable:drawable];

        } while (0);

        [commandBuffer commit];
    }
}
@end

