//
//  MetalView.m
//  MetalSample
//
//  Created by king on 2020/10/13.
//

#import "MetalView.h"
#import "ShaderTypes.h"
#import "Util.h"

@import CoreVideo;
@import MetalKit;

@interface MetalView ()
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipeline;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;
@property (nonatomic, strong) id<MTLBuffer> uniformBuffer;
@property (nonatomic, strong) id<MTLTexture> texture;
//@property (nonatomic, assign) CVDisplayLinkRef displayLink;
@property (nonatomic, assign) SSUniform uniform;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation MetalView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        _device = MTLCreateSystemDefaultDevice();
        [self commonInit];
    }

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame device:(id<MTLDevice>)device {
    if ((self = [super initWithFrame:frame])) {
        _device = device;
        [self commonInit];
    }

    return self;
}

- (void)commonInit {
    _frameDuration = 1.0 / 30.0;
    _clearColor    = MTLClearColorMake(0.2, 0.3, 0.4, 1);

    [self makeBackingLayer];
    [self makeBuffers];
    [self makeTexture];
    [self makePipeline];
}

- (CAMetalLayer *)metalLayer {
    return (CAMetalLayer *)self.layer;
}

- (CALayer *)makeBackingLayer {
    CAMetalLayer *layer = [[CAMetalLayer alloc] init];
    layer.bounds        = self.bounds;
    layer.device        = self.device;
    layer.pixelFormat   = MTLPixelFormatBGRA8Unorm;

    return layer;
}

- (void)layout {
    [super layout];
    CGFloat scale = [NSScreen mainScreen].backingScaleFactor;

    // If we've moved to a window by the time our frame is being set, we can take its scale as our own
    if (self.window) {
        scale = self.window.screen.backingScaleFactor;
    }

    CGSize drawableSize = self.bounds.size;

    // Since drawable size is in pixels, we need to multiply by the scale to move from points to pixels
    drawableSize.width *= scale;
    drawableSize.height *= scale;

    self.metalLayer.drawableSize = drawableSize;

    [self makeBuffers];
}

- (void)setColorPixelFormat:(MTLPixelFormat)colorPixelFormat {
    self.metalLayer.pixelFormat = colorPixelFormat;
}

- (MTLPixelFormat)colorPixelFormat {
    return self.metalLayer.pixelFormat;
}

- (void)makePipeline {
    id<MTLLibrary> library = [self.device newDefaultLibrary];

    id<MTLFunction> vertexFunc   = [library newFunctionWithName:@"vertex_main"];
    id<MTLFunction> fragmentFunc = [library newFunctionWithName:@"fragment_main"];

    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    //    pipelineDescriptor.sampleCount=4;
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineDescriptor.vertexFunction                  = vertexFunc;
    pipelineDescriptor.fragmentFunction                = fragmentFunc;

    NSError *error = nil;
    _pipeline      = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor
                                                            error:&error];

    if (!_pipeline) {
        NSLog(@"Error occurred when creating render pipeline state: %@", error);
    }

    _commandQueue = [self.device newCommandQueue];
}

- (void)makeBuffers {

    CGSize drawableSize = self.metalLayer.drawableSize;
    if (CGSizeEqualToSize(drawableSize, CGSizeZero)) {
        return;
    }
    CGRect renderRect = CGRectMake(200, 200, 600, 600);
    //    renderRect.origin.x = (drawableSize.width - renderRect.size.width) * 0.5;
    //    renderRect.origin.y = (drawableSize.height - renderRect.size.height) * 0.5;
    float vertices[16], sourceCoordinates[8];
    genMTLVertices(renderRect, drawableSize, vertices, YES);

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
                                            options:MTLResourceOptionCPUCacheModeDefault];

    CGPoint controlPoint     = dc_to_ndc(CGPointMake(500, 500), drawableSize);
    GLKMatrix4 transformto   = GLKMatrix4MakeTranslation(-controlPoint.x, -controlPoint.y, 0);
    GLKMatrix4 rotate        = GLKMatrix4MakeZRotation(GLKMathDegreesToRadians(-15));
    GLKMatrix4 transformback = GLKMatrix4MakeTranslation(controlPoint.x, controlPoint.y, 0);

    rotate = GLKMatrix4Multiply(transformback, rotate);
    rotate = GLKMatrix4Multiply(rotate, transformto);

    _uniform = (SSUniform){
        false,
        getMetalMatrixFromGLKMatrix(rotate),
        getMetalMatrixFromGLKMatrix(GLKMatrix4MakeTranslation(0, 0, 0)),
    };
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

    NSError *error = nil;
    self.texture   = [loader newTextureWithCGImage:cgImage options:@{MTKTextureLoaderOptionSRGB: @(NO)} error:&error];
    if (error) {
        NSAssert(NO, @"%@", error);
    }
}

static CGFloat Degrees = 0;
static CGFloat tx      = 0;
static BOOL addTx      = YES;
- (void)redraw {
    if (CGSizeEqualToSize(self.metalLayer.drawableSize, CGSizeZero)) {
        return;
    }

    id<CAMetalDrawable> drawable      = [self.metalLayer nextDrawable];
    id<MTLTexture> framebufferTexture = drawable.texture;

    if (drawable) {
        MTLRenderPassDescriptor *passDescriptor        = [MTLRenderPassDescriptor renderPassDescriptor];
        passDescriptor.colorAttachments[0].texture     = framebufferTexture;
        passDescriptor.colorAttachments[0].clearColor  = _clearColor;
        passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        passDescriptor.colorAttachments[0].loadAction  = MTLLoadActionClear;

        id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];

        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
        [commandEncoder setRenderPipelineState:self.pipeline];
        [commandEncoder setViewport:(MTLViewport){0, 0, self.metalLayer.drawableSize.width, self.metalLayer.drawableSize.height, -1, 1}];
        [commandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:SSVertexInputIndexVertices];

        [commandEncoder setFragmentTexture:self.texture atIndex:SSFragmentTextureIndexOne];

        _uniform.transformed = false;
        [commandEncoder setVertexBytes:&_uniform length:sizeof(_uniform) atIndex:SSVertexInputIndexUniforms];
        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];

        _uniform.transformed = true;
        Degrees += 1;
        if (Degrees > 360.0) {
            Degrees = 0;
        }
        if (addTx) {
            tx += 0.001;
        } else {
            tx -= 0.001;
        }
        if (tx > 0.5) {
            tx    = 0.5;
            addTx = NO;
        } else if (tx < 0) {
            tx    = 0;
            addTx = YES;
        }
        CGPoint controlPoint     = dc_to_ndc(CGPointMake(500, 500), self.metalLayer.drawableSize);
        GLKMatrix4 transformto   = GLKMatrix4MakeTranslation(-controlPoint.x, -controlPoint.y, 0);
        GLKMatrix4 rotate        = GLKMatrix4MakeZRotation(GLKMathDegreesToRadians(-Degrees));
        GLKMatrix4 transformback = GLKMatrix4MakeTranslation(controlPoint.x, controlPoint.y, 0);

        rotate              = GLKMatrix4Multiply(transformback, rotate);
        rotate              = GLKMatrix4Multiply(rotate, transformto);
        _uniform.transform  = getMetalMatrixFromGLKMatrix(rotate);
        _uniform.transform2 = getMetalMatrixFromGLKMatrix(GLKMatrix4MakeTranslation(tx, 0, 0));
        [commandEncoder setVertexBytes:&_uniform length:sizeof(_uniform) atIndex:SSVertexInputIndexUniforms];
        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];

        [commandEncoder endEncoding];

        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
    }
}

- (void)startDrawing {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    self.timer = [NSTimer timerWithTimeInterval:_frameDuration target:self selector:@selector(redraw) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)stopDrawing {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}
@end

