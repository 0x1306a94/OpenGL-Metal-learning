//
//  MetalCameraViewController.m
//  MetalCamera
//
//  Created by king on 2020/9/11.
//  Copyright © 2020 0x1306a94. All rights reserved.
//

#import "AssetReader.h"
#import "MetalCameraViewController.h"
#import "ShaderTypes.h"
#import "Texture.h"
#import "constant.h"

#import <AVFoundation/AVFoundation.h>
#import <MetalKit/MetalKit.h>

@interface MetalCameraViewController () <AVCaptureVideoDataOutputSampleBufferDelegate, MTKViewDelegate>
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDeviceInput *deviceInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *dataOutput;
@property (nonatomic, strong) AVCaptureConnection *connection;

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, assign) CVMetalTextureCacheRef textureCache;
@property (nonatomic, strong) dispatch_queue_t dataOutputQueue;
@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLRenderPipelineState> effectsPipelineState;
@property (nonatomic, strong) id<MTLRenderPipelineState> normalPipelineState;
@property (nonatomic, strong) id<MTLBuffer> vertices;
@property (nonatomic, strong) id<MTLBuffer> convertMatrix;
@property (nonatomic, assign) NSInteger numVertices;
@property (nonatomic, assign) CGSize viewportSize;
@property (nonatomic, strong) AssetReader *gGreenAssetReader;

@property (nonatomic, strong) Texture *lastCameraTexture;

@end

@implementation MetalCameraViewController
- (void)dealloc {
	NSLog(@"[%@ dealloc]", NSStringFromClass(self.class));
	if (self.session.isRunning) {
		[self.session stopRunning];
	}

	CVMetalTextureCacheFlush(_textureCache, 0);
}

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view.
	self.view.backgroundColor = UIColor.orangeColor;
	[self setup];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	self.viewportSize = self.mtkView.drawableSize;

	if (self.session.isRunning == NO) {
		[self.session startRunning];
	}
}

- (void)setup {

	self.dataOutputQueue    = dispatch_queue_create("com.0x1306a94.camera.queue", DISPATCH_QUEUE_SERIAL);
	AVCaptureDevice *device = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront].devices.firstObject;

	self.session = [[AVCaptureSession alloc] init];
	[self.session beginConfiguration];
	self.session.sessionPreset = AVCaptureSessionPresetiFrame960x540;
	[device lockForConfiguration:nil];
	device.activeVideoMaxFrameDuration = CMTimeMake(1, 25);
	device.activeVideoMinFrameDuration = CMTimeMake(1, 25);
	[device unlockForConfiguration];

	self.deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];

	if ([self.session canAddInput:self.deviceInput]) {
		[self.session addInput:self.deviceInput];
	}

	self.dataOutput                               = [[AVCaptureVideoDataOutput alloc] init];
	self.dataOutput.alwaysDiscardsLateVideoFrames = NO;
	self.dataOutput.videoSettings                 = @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)};
	[self.dataOutput setSampleBufferDelegate:self queue:self.dataOutputQueue];

	if ([self.session canAddOutput:self.dataOutput]) {
		[self.session addOutput:self.dataOutput];
	}

	self.connection                  = [self.dataOutput connectionWithMediaType:AVMediaTypeVideo];
	self.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
	self.connection.videoMirrored    = YES;
	[self.session commitConfiguration];

	self.device = MTLCreateSystemDefaultDevice();

	self.mtkView                          = [[MTKView alloc] initWithFrame:UIScreen.mainScreen.bounds];
	self.mtkView.device                   = self.device;
	self.mtkView.delegate                 = self;
	self.mtkView.framebufferOnly          = NO;
	self.mtkView.preferredFramesPerSecond = 25;
	[self.view addSubview:self.mtkView];

	NSURL *url             = [[NSBundle mainBundle] URLForResource:@"fireworks" withExtension:@"mp4"];
	self.gGreenAssetReader = [[AssetReader alloc] initWithURL:url];

	self.commandQueue = [self.mtkView.device newCommandQueue];
	[self setupPipelineState];
	[self setupVertex];
	[self setupMatrix];

	CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, self.device, nil, &_textureCache);
}

- (void)setupPipelineState {
	id<MTLLibrary> defaultLibrary    = [self.device newDefaultLibrary];
	id<MTLFunction> vertexFunction   = [defaultLibrary newFunctionWithName:@"vertexShader"];
	id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"samplingShader"];

	MTLRenderPipelineDescriptor *pipelineStateDescriptor    = [[MTLRenderPipelineDescriptor alloc] init];
	pipelineStateDescriptor.vertexFunction                  = vertexFunction;
	pipelineStateDescriptor.fragmentFunction                = fragmentFunction;
	pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.mtkView.colorPixelFormat;

	self.effectsPipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:nil];

	fragmentFunction                         = [defaultLibrary newFunctionWithName:@"normalSamplingShader"];
	pipelineStateDescriptor.fragmentFunction = fragmentFunction;
	self.normalPipelineState                 = [self.device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:nil];
}

- (void)setupVertex {

	self.vertices    = [self.device newBufferWithBytes:&quadVertices length:quadVerticesLength options:MTLResourceStorageModeShared];
	self.numVertices = 6;
}

- (void)setupMatrix {

	SSConvertMatrix matrix = (SSConvertMatrix){
	    .matrix = kColorConversion601FullRangeMatrix,
	    .offset = kColorConversion601FullRangeOffset,
	};

	self.convertMatrix = [self.device newBufferWithBytes:&matrix length:sizeof(matrix) options:MTLResourceStorageModeShared];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	self.lastCameraTexture = [[Texture alloc] initWithSampleBuffer:sampleBuffer textureCache:self.textureCache];
//	NSLog(@"captureOutput: %f", CACurrentMediaTime());
}

#pragma mark - MTKViewDelegate
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
	self.viewportSize = size;
}

- (void)drawInMTKView:(MTKView *)view {
	//	return;
	[self renderEffectsInMTKView:view];
	//		[self renderNormalInMTKView:view];
}

#pragma mark - render
- (void)renderEffectsInMTKView:(MTKView *)view {
	@autoreleasepool {

		if (!self.lastCameraTexture) {
			return;
		}

		Texture *lastCameraTexture = self.lastCameraTexture;

		self.lastCameraTexture = nil;

		MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
		id<CAMetalDrawable> currentDrawable           = view.currentDrawable;

		if (renderPassDescriptor == nil || currentDrawable == nil) {
			return;
		}
		CMSampleBufferRef greenSampleBuffer = [self.gGreenAssetReader readBuffer];
		if (greenSampleBuffer == NULL) {
			return;
		}
		Texture *greenTexture = [[Texture alloc] initWithSampleBuffer:greenSampleBuffer textureCache:self.textureCache];
		if (greenTexture == nil) {
			CFRelease(greenSampleBuffer);
			return;
		}
		CFRelease(greenSampleBuffer);

		id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
		{
			renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1.0);

			id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];

			[renderEncoder setViewport:(MTLViewport){0, 0, self.viewportSize.width, self.viewportSize.height, -1, 1}];

			[renderEncoder setRenderPipelineState:self.effectsPipelineState];

			[renderEncoder setVertexBuffer:self.vertices offset:0 atIndex:SSVertexInputIndexVertices];

			[renderEncoder setFragmentTexture:greenTexture.textureY atIndex:SSFragmentTextureIndexGreenTextureY];
			[renderEncoder setFragmentTexture:greenTexture.textureUV atIndex:SSFragmentTextureIndexGreenTextureUV];

			[renderEncoder setFragmentTexture:lastCameraTexture.textureY atIndex:SSFragmentTextureIndexNormalTextureY];
			[renderEncoder setFragmentTexture:lastCameraTexture.textureUV atIndex:SSFragmentTextureIndexNormalTextureUV];

			[renderEncoder setFragmentBuffer:self.convertMatrix offset:0 atIndex:SSFragmentInputIndexMatrix];

			[renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:self.numVertices];

			[renderEncoder endEncoding];

			[commandBuffer presentDrawable:currentDrawable];
		}

		[commandBuffer commit];
	}
}

- (void)renderNormalInMTKView:(MTKView *)view {
	@autoreleasepool {

		if (!self.lastCameraTexture) {
			return;
		}

		Texture *lastCameraTexture = self.lastCameraTexture;

		self.lastCameraTexture = nil;

		MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
		id<CAMetalDrawable> currentDrawable           = view.currentDrawable;

		if (renderPassDescriptor == nil || currentDrawable == nil) {
			return;
		}

		id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
		{
			renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1.0);
			id<MTLRenderCommandEncoder> renderEncoder           = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
			[renderEncoder setViewport:(MTLViewport){0, 0, self.viewportSize.width, self.viewportSize.height, -1, 1}];

			[renderEncoder setRenderPipelineState:self.normalPipelineState];

			[renderEncoder setVertexBuffer:self.vertices offset:0 atIndex:SSVertexInputIndexVertices];

			[renderEncoder setFragmentTexture:lastCameraTexture.textureY atIndex:SSFragmentTextureIndexNormalTextureY];
			[renderEncoder setFragmentTexture:lastCameraTexture.textureUV atIndex:SSFragmentTextureIndexNormalTextureUV];

			[renderEncoder setFragmentBuffer:self.convertMatrix offset:0 atIndex:SSFragmentInputIndexMatrix];

			[renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:self.numVertices];

			[renderEncoder endEncoding];

			[commandBuffer presentDrawable:currentDrawable];
		}

		[commandBuffer commit];
	}
}
@end

