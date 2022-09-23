//
//  KKRenderder.m
//  MetalLoadOBJ
//
//  Created by king on 2022/9/22.
//

#import "KKRenderder.h"

#import "AAPLShaderTypes.h"

#import <GLKit/GLKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <simd/simd.h>

const NSUInteger AAPLBuffersInflightBuffers = 3;

@interface KKRenderder () <MTKViewDelegate>
@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLLibrary> library;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLDepthStencilState> dss;
@property (nonatomic, strong) id<MTLRenderPipelineState> rps;
@property (nonatomic, strong) MTLVertexDescriptor *vertexDescriptor;
@property (nonatomic, strong) id<MTLTexture> texture;
@property (nonatomic, strong) NSArray<MTKMesh *> *meshs;

@end

@implementation KKRenderder {
    dispatch_semaphore_t _inflightSemaphore;
    uint8_t _constantDataBufferIndex;

    // Uniforms.
    matrix_float4x4 _projectionMatrix;
    matrix_float4x4 _viewMatrix;
    float _rotation;

    id<MTLBuffer> _frameUniformBuffers[AAPLBuffersInflightBuffers];
}

- (instancetype)initWithMtkView:(MTKView *)mtkView {
    if (self == [super init]) {
        self.mtkView = mtkView;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {

    self.mtkView.clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1.0);
    self.mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    self.mtkView.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
    self.mtkView.framebufferOnly = NO;

    _constantDataBufferIndex = 0;
    _inflightSemaphore = dispatch_semaphore_create(AAPLBuffersInflightBuffers);

    [self initializeMetalObjects];
    [self loadAsset];

    for (uint8_t i = 0; i < AAPLBuffersInflightBuffers; i++) {
        _frameUniformBuffers[i] = [_device newBufferWithLength:sizeof(AAPLFrameUniforms) options:0];
    }

    [self reshape];

    self.mtkView.delegate = self;
    self.mtkView.device = self.device;
}

- (void)initializeMetalObjects {
    self.device = MTLCreateSystemDefaultDevice();
    self.commandQueue = [self.device newCommandQueue];

    do {
        MTLDepthStencilDescriptor *desc = [MTLDepthStencilDescriptor new];
        desc.depthCompareFunction = MTLCompareFunctionLess;
        desc.depthWriteEnabled = YES;
        self.dss = [self.device newDepthStencilStateWithDescriptor:desc];

    } while (0);

    do {
        id<MTLLibrary> library = [self.device newDefaultLibrary];
        self.library = library;

        id<MTLFunction> vertFunc = [library newFunctionWithName:@"vertex_func"];
        id<MTLFunction> fragFunc = [library newFunctionWithName:@"fragment_func"];

        MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor new];
        self.vertexDescriptor = vertexDescriptor;
        // position
        vertexDescriptor.attributes[AAPLVertexAttributePosition].offset = 0;
        vertexDescriptor.attributes[AAPLVertexAttributePosition].format = MTLVertexFormatFloat3;
        vertexDescriptor.attributes[AAPLVertexAttributePosition].bufferIndex = AAPLMeshVertexBuffer;
        // color
        vertexDescriptor.attributes[AAPLVertexAttributeNormal].offset = 12;
        vertexDescriptor.attributes[AAPLVertexAttributeNormal].format = MTLVertexFormatFloat3;
        vertexDescriptor.attributes[AAPLVertexAttributeNormal].bufferIndex = AAPLMeshVertexBuffer;

        // texture
        vertexDescriptor.attributes[AAPLVertexAttributeTexcoord].offset = 24;
        vertexDescriptor.attributes[AAPLVertexAttributeTexcoord].format = MTLVertexFormatHalf2;
        vertexDescriptor.attributes[AAPLVertexAttributeTexcoord].bufferIndex = AAPLMeshVertexBuffer;

        NSUInteger stride = 28;
        vertexDescriptor.layouts[AAPLMeshVertexBuffer].stride = stride;
        vertexDescriptor.layouts[AAPLMeshVertexBuffer].stepRate = 1;
        vertexDescriptor.layouts[AAPLMeshVertexBuffer].stepFunction = MTLVertexStepFunctionPerVertex;

        MTLRenderPipelineDescriptor *desc = [MTLRenderPipelineDescriptor new];
        desc.vertexDescriptor = vertexDescriptor;
        desc.vertexFunction = vertFunc;
        desc.fragmentFunction = fragFunc;
        desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        desc.depthAttachmentPixelFormat = self.mtkView.depthStencilPixelFormat;
        desc.stencilAttachmentPixelFormat = self.mtkView.depthStencilPixelFormat;
        NSError *error = nil;
        self.rps = [self.device newRenderPipelineStateWithDescriptor:desc error:&error];
        if (error) {
            NSLog(@"%@", error);
            NSCAssert(NO, @"newRenderPipelineStateWithDescriptor faile");
        }
    } while (0);
}

- (void)loadAsset {
    do {
        MDLVertexDescriptor *desc = MTKModelIOVertexDescriptorFromMetal(self.vertexDescriptor);
        desc.attributes[AAPLVertexAttributePosition].name = MDLVertexAttributePosition;
        desc.attributes[AAPLVertexAttributeNormal].name = MDLVertexAttributeColor;
        desc.attributes[AAPLVertexAttributeTexcoord].name = MDLVertexAttributeTextureCoordinate;

        MTKMeshBufferAllocator *allocator = [[MTKMeshBufferAllocator alloc] initWithDevice:self.device];
        //        NSURL *url = [[NSBundle mainBundle] URLForResource:@"cup" withExtension:@"obj"];
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"ht" withExtension:@"obj"];

        MDLAsset *asset = [[MDLAsset alloc] initWithURL:url vertexDescriptor:desc bufferAllocator:allocator];
        NSLog(@"%@", asset);
        NSError *error = nil;
        NSArray<MTKMesh *> *meshs = [MTKMesh newMeshesFromAsset:asset device:self.device sourceMeshes:nil error:&error];
        self.meshs = meshs;
        if (error) {
            NSLog(@"%@", error);
            NSCAssert(NO, @"newMeshesFromAsset faile");
        }
    } while (0);

    do {
        MTKTextureLoader *loader = [[MTKTextureLoader alloc] initWithDevice:self.device];
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"ht" withExtension:@"png"];
        NSError *error = nil;
        self.texture = [loader newTextureWithContentsOfURL:url options:@{MTKTextureLoaderOptionOrigin: @YES} error:&error];
        if (error) {
            NSLog(@"%@", error);
            NSCAssert(NO, @"newTextureWithContentsOfURL faile");
        }
    } while (0);
}

- (void)reshape {
    /*
        When reshape is called, update the view and projection matricies since
        this means the view orientation or size changed.
    */
    float aspect = fabs(self.mtkView.bounds.size.width / self.mtkView.bounds.size.height);
    _projectionMatrix = matrix_from_perspective_fov_aspectLH(65.0f * (M_PI / 180.0f), aspect, 0.1f, 100.0f);

    _viewMatrix = matrix_identity_float4x4;
}

- (void)update {
    AAPLFrameUniforms *frameData = (AAPLFrameUniforms *)[_frameUniformBuffers[_constantDataBufferIndex] contents];

    matrix_float4x4 translation = matrix_from_translation(0.0f, 0.0f, 10.0f);
    float sclae_ratio = 0.2;
    matrix_float4x4 sclae = matrix_from_glk(GLKMatrix4MakeScale(-sclae_ratio, sclae_ratio, sclae_ratio));
    matrix_float4x4 rotation = matrix_from_rotation(_rotation, 0.0f, 1.0f, 0.0f);
    //    rotation = matrix_from_glk(GLKMatrix4MakeRotation(GLKMathDegreesToRadians(-90), 0, 1, 0));
    //    sclae = matrix_identity_float4x4;
    //        rotation = matrix_identity_float4x4;
    frameData->model = translation;
    frameData->model = translation * sclae * rotation;
    frameData->view = _viewMatrix;

    matrix_float4x4 modelViewMatrix = frameData->view * frameData->model;

    frameData->projectionView = _projectionMatrix * modelViewMatrix;

    frameData->normal = matrix_invert(matrix_transpose(modelViewMatrix));

    _rotation += 0.015f;
}
#pragma mark - MTKViewDelegate
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    [self reshape];
}

- (void)drawInMTKView:(MTKView *)view {

    id<CAMetalDrawable> drawable = view.currentDrawable;
    MTLRenderPassDescriptor *desc = view.currentRenderPassDescriptor;
    if (drawable == nil || desc == nil) {
        return;
    }

    dispatch_semaphore_wait(_inflightSemaphore, DISPATCH_TIME_FOREVER);

    [self update];
    desc.colorAttachments[0].texture = drawable.texture;
    desc.colorAttachments[0].loadAction = MTLLoadActionClear;
    desc.colorAttachments[0].storeAction = MTLStoreActionStore;
    desc.colorAttachments[0].clearColor = MTLClearColorMake(0.5, 0.8, 0.5, 1.0);

    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:desc];
    [commandEncoder setViewport:{0, 0, view.drawableSize.width, view.drawableSize.height, 0, 1}];
    [commandEncoder setRenderPipelineState:self.rps];
    [commandEncoder setDepthStencilState:self.dss];
    [commandEncoder setCullMode:MTLCullModeBack];
    [commandEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [commandEncoder setVertexBuffer:_frameUniformBuffers[_constantDataBufferIndex]
                             offset:0
                            atIndex:AAPLFrameUniformBuffer];
    [commandEncoder setFragmentTexture:self.texture atIndex:AAPLNormalTextureIndex];

    for (MTKMesh *mesh in self.meshs) {
        for (MTKMeshBuffer *buffer in mesh.vertexBuffers) {
            [commandEncoder setVertexBuffer:buffer.buffer offset:buffer.offset atIndex:AAPLMeshVertexBuffer];
        }

        for (MTKSubmesh *submesh in mesh.submeshes) {
            [commandEncoder drawIndexedPrimitives:submesh.primitiveType
                                       indexCount:submesh.indexCount
                                        indexType:submesh.indexType
                                      indexBuffer:submesh.indexBuffer.buffer
                                indexBufferOffset:submesh.indexBuffer.offset];
        }
    }
    [commandEncoder endEncoding];

    __block dispatch_semaphore_t block_sema = _inflightSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        dispatch_semaphore_signal(block_sema);
    }];

    _constantDataBufferIndex = (_constantDataBufferIndex + 1) % AAPLBuffersInflightBuffers;

    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

#pragma mark Utilities

static matrix_float4x4 matrix_from_perspective_fov_aspectLH(const float fovY, const float aspect, const float nearZ, const float farZ) {
    // 1 / tan == cot
    float yscale = 1.0f / tanf(fovY * 0.5f);
    float xscale = yscale / aspect;
    float q = farZ / (farZ - nearZ);

    matrix_float4x4 m = {
        .columns[0] = {xscale, 0.0f, 0.0f, 0.0f},
        .columns[1] = {0.0f, yscale, 0.0f, 0.0f},
        .columns[2] = {0.0f, 0.0f, q, 1.0f},
        .columns[3] = {0.0f, 0.0f, q * -nearZ, 0.0f}};

    return m;
}

static matrix_float4x4 matrix_from_glk(GLKMatrix4 matrix) {
    matrix_float4x4 ret = (matrix_float4x4){
        simd_make_float4(matrix.m00, matrix.m01, matrix.m02, matrix.m03),
        simd_make_float4(matrix.m10, matrix.m11, matrix.m12, matrix.m13),
        simd_make_float4(matrix.m20, matrix.m21, matrix.m22, matrix.m23),
        simd_make_float4(matrix.m30, matrix.m31, matrix.m32, matrix.m33),
    };
    return ret;
}

static matrix_float4x4 matrix_from_translation(float x, float y, float z) {
    matrix_float4x4 m = matrix_identity_float4x4;
    m.columns[3] = (vector_float4){x, y, z, 1.0};
    return m;
}

static matrix_float4x4 matrix_from_rotation(float radians, float x, float y, float z) {
    vector_float3 v = vector_normalize(((vector_float3){x, y, z}));
    float cos = cosf(radians);
    float cosp = 1.0f - cos;
    float sin = sinf(radians);

    return (matrix_float4x4){
        .columns[0] = {
            cos + cosp * v.x * v.x,
            cosp * v.x * v.y + v.z * sin,
            cosp * v.x * v.z - v.y * sin,
            0.0f,
        },

        .columns[1] = {
            cosp * v.x * v.y - v.z * sin,
            cos + cosp * v.y * v.y,
            cosp * v.y * v.z + v.x * sin,
            0.0f,
        },

        .columns[2] = {
            cosp * v.x * v.z + v.y * sin,
            cosp * v.y * v.z - v.x * sin,
            cos + cosp * v.z * v.z,
            0.0f,
        },

        .columns[3] = {0.0f, 0.0f, 0.0f, 1.0f}};
}
@end

