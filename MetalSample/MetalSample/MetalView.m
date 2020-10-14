//
//  MetalView.m
//  MetalSample
//
//  Created by king on 2020/10/13.
//

#import "MetalView.h"
#import "ShaderTypes.h"

@import simd;
@import CoreVideo;
@import MetalKit;
@import GLKit;

float const kMTLTextureCoordinatesIdentity[8] = {0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0};

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
static void genMTLVertices(CGRect rect, CGSize containerSize, float vertices[16], BOOL reverse) {
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
	originX = -1 + 2 * rect.origin.x / containerSize.width;
	originY = 1 - 2 * rect.origin.y / containerSize.height;
	width   = 2 * rect.size.width / containerSize.width;
	height  = 2 * rect.size.height / containerSize.height;

	if (reverse) {
		float tempVertices[] = {originX, originY - height, 0.0, 1.0, originX, originY, 0.0, 1.0, originX + width, originY - height, 0.0, 1.0, originX + width, originY, 0.0, 1.0};
		replaceArrayElements(vertices, tempVertices, 16);
		return;
	}
	float tempVertices[] = {originX, originY, 0.0, 1.0, originX, originY - height, 0.0, 1.0, originX + width, originY, 0.0, 1.0, originX + width, originY - height, 0.0, 1.0};
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
	_clearColor    = MTLClearColorMake(0, 0, 0, 1);

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

	MTLRenderPipelineDescriptor *pipelineDescriptor    = [MTLRenderPipelineDescriptor new];
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
	//	renderRect.origin.x = (drawableSize.width - renderRect.size.width) * 0.5;
	//	renderRect.origin.y = (drawableSize.height - renderRect.size.height) * 0.5;
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

	UInt index               = 0;
	GLKMatrix4 transformto   = GLKMatrix4MakeTranslation(-vertexData[index].position[0], -vertexData[index].position[1], 0);
	GLKMatrix4 rotate        = GLKMatrix4MakeZRotation(GLKMathDegreesToRadians(-90));
	GLKMatrix4 transformback = GLKMatrix4MakeTranslation(vertexData[index].position[0], vertexData[index].position[1], 0);

	rotate = GLKMatrix4Multiply(transformback, rotate);
	rotate = GLKMatrix4Multiply(rotate, transformto);

	_uniform = (SSUniform){
	    false,
	    getMetalMatrixFromGLKMatrix(rotate),
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

