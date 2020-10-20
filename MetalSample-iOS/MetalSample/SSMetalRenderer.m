//
//  SSMetalRenderer.m
//  MetalSample
//
//  Created by king on 2020/10/19.
//

#import "SSMetalRenderer.h"

#import "SSShaderTypes.h"
#import "SSUtil.h"

#import <GLKit/GLKMathUtils.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

@interface SSMetalRenderer ()
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLLibrary> library;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;
@property (nonatomic, strong) id<MTLBuffer> uniformBuffer;
@property (nonatomic, strong) id<MTLRenderPipelineState> defaultMainPipelineState;
@end

@implementation SSMetalRenderer
- (instancetype)initWithDevice:(id<MTLDevice>)device {
	if (self == [super init]) {
		_device = device;
		[self commonInit];
	}
	return self;
}

- (void)commonInit {
	_library                  = [_device newDefaultLibrary];
	_commandQueue             = [_device newCommandQueue];
	_commandQueue.label       = @"com.0x1306a94.commandQueue";
	_defaultMainPipelineState = [self createPipelineState:@"vertex_main" fragmentFunction:@"fragment_main"];

	SSVertex vertexData[4] = {
	    {{-0.5, -0.3, 0, 1}, {1, 0, 0, 1}},      // 左下
	    {{-0.5, 0.3, 0, 1}, {0, 1, 0, 1}},       // 左上
	    {{0.5, -0.3, 0, 1}, {0, 0, 1, 1}},       // 右下
	    {{0.5, 0.3, 0, 1}, {0.5, 0.5, 0.5, 1}},  // 右上
	};

	CGFloat screenWidth  = UIScreen.mainScreen.nativeBounds.size.width;
	CGFloat screenHeight = UIScreen.mainScreen.nativeBounds.size.height;

	CGSize renderSize = CGSizeMake(screenWidth, screenHeight);
	CGRect renderRect = CGRectMake((renderSize.width - 600) * 0.5, 200, 600, 800);

#if 1
	// 我们做 2D 变换计算都是像素坐标系。
	// 把顶点提交渲染的时候，做一层转换，像素坐标系 -> 渲染坐标系。
	// 下面这个变换把像素坐标系映射到渲染坐标系：
	// (0, 0) -> (-1, 1)
	// (screenWidth, 0) -> (1, 1)
	// (0, screenHeight) -> (-1, -1)
	// (screenWidth, screenHeight) -> (1, -1)
	GLKMatrix4 toRender = GLKMatrix4MakeScale(2.0 / screenWidth, -2.0 / screenHeight, 1.0);
	toRender            = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(-1, 1, 0), toRender);
	// 这个 translate 实现不对劲，不知道为啥
	// GLKMatrix4Translate(toRender, -1, 1, 0);

	float vertices[16];
	// 由于我们直接用了像素坐标系，这个函数实现就进啥吐啥了
	genMTLVertices(renderRect, renderSize, vertices, YES, NO);

	for (int i = 0; i < 4; i++) {
		vertexData[i].position = simd_make_float4(vertices[i * 4], vertices[i * 4 + 1], vertices[i * 4 + 2], vertices[i * 4 + 3]);
	}
	_vertexBuffer = [_device newBufferWithBytes:vertexData length:sizeof(vertexData) options:MTLResourceStorageModeShared];

	// 修改旋转中心
	CGPoint controlPoint = CGPointMake(CGRectGetMidX(renderRect), CGRectGetMidY(renderRect));
	//CGPoint ndc              = dc_to_ndc(controlPoint, renderSize);
	GLKMatrix4 transformto = GLKMatrix4MakeTranslation(-controlPoint.x, -controlPoint.y, 0);
	// 由于是像素坐标系，y 轴朝下，所以旋转看起来是反的
	GLKMatrix4 rotateMatrix  = GLKMatrix4MakeZRotation(GLKMathDegreesToRadians(15));
	GLKMatrix4 transformback = GLKMatrix4MakeTranslation(controlPoint.x, controlPoint.y, 0);
	//
	GLKMatrix4 result = GLKMatrix4Identity;
	// translation * rotation * scale
	// 像素坐标系下的普通旋转
	result = GLKMatrix4Multiply(transformto, result);
	result = GLKMatrix4Multiply(rotateMatrix, result);
	result = GLKMatrix4Multiply(transformback, result);

	// 要渲染了，再转换回渲染坐标系
	result            = GLKMatrix4Multiply(toRender, result);

	SSUniform uniform = (SSUniform){
	    .transformed = true,
	    .transform   = getMetalMatrixFromGLKMatrix(result),
	};

	GLKMatrix4Show(result);
#else

	CGPoint p0 = CGPointMake(CGRectGetMinX(renderRect), CGRectGetMaxY(renderRect));
	CGPoint p1 = renderRect.origin;
	CGPoint p2 = CGPointMake(CGRectGetMaxX(renderRect), CGRectGetMaxY(renderRect));
	CGPoint p3 = CGPointMake(CGRectGetMaxX(renderRect), CGRectGetMinY(renderRect));
	NSLog(@"p0: %@", NSStringFromCGPoint(p0));
	NSLog(@"p1: %@", NSStringFromCGPoint(p1));
	NSLog(@"p2: %@", NSStringFromCGPoint(p2));
	NSLog(@"p3: %@", NSStringFromCGPoint(p3));

	CGPoint c = CGPointMake(CGRectGetMidX(renderRect), CGRectGetMidY(renderRect));

	CGPointRotation t = CGPointMakeRotation(c, -15);

	p0 = CGPointToRotation(p0, t);
	p1 = CGPointToRotation(p1, t);
	p2 = CGPointToRotation(p2, t);
	p3 = CGPointToRotation(p3, t);

	NSLog(@"p0: %@", NSStringFromCGPoint(p0));
	NSLog(@"p1: %@", NSStringFromCGPoint(p1));
	NSLog(@"p2: %@", NSStringFromCGPoint(p2));
	NSLog(@"p3: %@", NSStringFromCGPoint(p3));

	CGPoint n0 = dc_to_ndc(p0, renderSize);
	CGPoint n1 = dc_to_ndc(p1, renderSize);
	CGPoint n2 = dc_to_ndc(p2, renderSize);
	CGPoint n3 = dc_to_ndc(p3, renderSize);
	NSLog(@"n0: %@", NSStringFromCGPoint(n0));
	NSLog(@"n1: %@", NSStringFromCGPoint(n1));
	NSLog(@"n2: %@", NSStringFromCGPoint(n2));
	NSLog(@"n3: %@", NSStringFromCGPoint(n3));
	vertexData[0].position = simd_make_float4(n0.x, n0.y, 0, 1);
	vertexData[1].position = simd_make_float4(n1.x, n1.y, 0, 1);
	vertexData[2].position = simd_make_float4(n2.x, n2.y, 0, 1);
	vertexData[3].position = simd_make_float4(n3.x, n3.y, 0, 1);

	_vertexBuffer = [_device newBufferWithBytes:vertexData length:sizeof(vertexData) options:MTLResourceStorageModeShared];

	SSUniform uniform = (SSUniform){
	    .transformed = false,
	    .transform   = getMetalMatrixFromGLKMatrix(GLKMatrix4Identity),
	};
#endif

	_uniformBuffer = [_device newBufferWithBytes:&uniform length:sizeof(uniform) options:MTLResourceStorageModeShared];
}

#pragma mark - pipelines
- (id<MTLRenderPipelineState>)createPipelineState:(NSString *)vertexFunction fragmentFunction:(NSString *)fragmentFunction {

	id<MTLFunction> vertexProgram   = [_library newFunctionWithName:vertexFunction];
	id<MTLFunction> fragmentProgram = [_library newFunctionWithName:fragmentFunction];

	if (!vertexProgram || !fragmentProgram) {
		NSAssert(0, @"check if .metal files been compiled to correct target!");
		return nil;
	}

	//融混方程
	//https://objccn.io/issue-3-1/
	//https://www.andersriggelsen.dk/glblendfunc.php
	MTLRenderPipelineDescriptor *pipelineStateDescriptor                    = [MTLRenderPipelineDescriptor new];
	pipelineStateDescriptor.vertexFunction                                  = vertexProgram;
	pipelineStateDescriptor.fragmentFunction                                = fragmentProgram;
	pipelineStateDescriptor.colorAttachments[0].pixelFormat                 = MTLPixelFormatBGRA8Unorm;
	pipelineStateDescriptor.colorAttachments[0].blendingEnabled             = YES;
	pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation           = MTLBlendOperationAdd;
	pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation         = MTLBlendOperationAdd;
	pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor        = MTLBlendFactorSourceAlpha;
	pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor      = MTLBlendFactorSourceAlpha;
	pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor   = MTLBlendFactorOneMinusSourceAlpha;
	pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;

	NSError *psError = nil;

	id<MTLRenderPipelineState> pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&psError];
	if (!pipelineState || psError) {
		NSAssert(0, @"newRenderPipelineStateWithDescriptor error!:%@", psError);
		return nil;
	}

	return pipelineState;
}

#pragma mark - MTKViewDelegate
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
	NSLog(@"drawableSizeWillChange: %@", NSStringFromCGSize(size));
}

- (void)drawInMTKView:(MTKView *)view {

	id<MTLDrawable> drawable                      = view.currentDrawable;
	MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
	if (!drawable || !renderPassDescriptor) {
		return;
	}
	id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];

	renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
	renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.2, 0.3, 0.4, 1.0);

	id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];

	MTLViewport viewport = (MTLViewport){0, 0, view.drawableSize.width, view.drawableSize.height, -1, 1};
	[renderEncoder setViewport:viewport];
	[renderEncoder setRenderPipelineState:_defaultMainPipelineState];
	//	[renderEncoder setTriangleFillMode:MTLTriangleFillModeLines];
	[renderEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:SSVertexInputIndexVertexs];
	[renderEncoder setVertexBuffer:_uniformBuffer offset:0 atIndex:SSVertexInputIndexUniforms];
	[renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4 instanceCount:1];

	[renderEncoder endEncoding];
	[commandBuffer presentDrawable:drawable];
	[commandBuffer commit];
}
@end

