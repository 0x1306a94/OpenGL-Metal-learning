//
//  ViewController.m
//  MetalLoadOBJ
//
//  Created by king on 2022/9/21.
//

#import "ViewController.h"

#import "Frustum.h"
#import "KKRenderder.h"

#import <GLKit/GLKit.h>
#import <MetalKit/MetalKit.h>
#import <SceneKit/ModelIO.h>
#import <SceneKit/SceneKit.h>
#import <objc/message.h>
#import <simd/simd.h>
typedef struct {
    SCNMatrix4 transform;
    SCNVector3 position;
    CGFloat cameraFieldOfView;
} ObjInitialParameters;

@interface ViewController () <MDLAssetResolver>
@property (nonatomic, strong) SCNView *sceneView;
@property (nonatomic, strong) UIButton *resetButton;
@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) SCNNode *cameraNode;
@property (nonatomic, strong) SCNCamera *camera;

@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) KKRenderder *renderder;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) CGFloat rotation;
@property (nonatomic, assign) SCNMatrix4 fixTransform;
@property (nonatomic, assign) ObjInitialParameters initParameters;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.darkTextColor;

    //    [self metalKit];

    [self sceneKit];
}

- (void)metalKit {
    self.mtkView = [[MTKView alloc] init];
    [self.view addSubview:self.mtkView];
    self.mtkView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.mtkView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.mtkView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.mtkView.heightAnchor constraintEqualToAnchor:self.view.widthAnchor],
        [self.mtkView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    ]];
    [self.view layoutIfNeeded];

    self.renderder = [[KKRenderder alloc] initWithMtkView:self.mtkView];
}

- (void)sceneKit {
    self.sceneView = [[SCNView alloc] init];
    self.resetButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.resetButton.backgroundColor = UIColor.orangeColor;
    [self.resetButton setTitle:@"Reset" forState:UIControlStateNormal];
    [self.resetButton addTarget:self action:@selector(resetButtonAction:) forControlEvents:UIControlEventTouchUpInside];

    self.startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.startButton.backgroundColor = UIColor.orangeColor;
    [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
    [self.startButton setTitle:@"Stop" forState:UIControlStateSelected];
    [self.startButton addTarget:self action:@selector(startButtonAction:) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.spacing = 10;
    [stackView addArrangedSubview:self.startButton];
    [stackView addArrangedSubview:self.resetButton];

    [self.view addSubview:self.sceneView];
    [self.view addSubview:stackView];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.sceneView.translatesAutoresizingMaskIntoConstraints = NO;
    self.startButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.resetButton.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.sceneView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.sceneView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.sceneView.heightAnchor constraintEqualToAnchor:self.view.widthAnchor],
        [self.sceneView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],

        [self.startButton.widthAnchor constraintEqualToConstant:80],
        [self.resetButton.widthAnchor constraintEqualToConstant:80],

        [stackView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20],
        [stackView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],

    ]];
    [self.view layoutIfNeeded];

    //    SCNScene *scene = [SCNScene sceneNamed:@"untitled.dae"];
    NSString *objName = @"finger.obj";
    objName = @"untitled.obj";
    //        objName = @"cup.obj";
//    objName = @"ht.obj";
    NSString *textureImageName = @"IMG_3289.JPG";
    //    textureImageName = @"ht.png";
    NSURL *url = [[NSBundle mainBundle] URLForResource:objName withExtension:nil];
    MDLAsset *asset = [[MDLAsset alloc] initWithURL:url];

    MDLScatteringFunction *scatFunction = [MDLScatteringFunction new];
    MDLMaterial *material = [[MDLMaterial alloc] initWithName:objName scatteringFunction:scatFunction];

    NSURL *materialURL = [[NSBundle mainBundle] URLForResource:textureImageName withExtension:nil];
    MDLMaterialProperty *baseColour = [MDLMaterialProperty new];
    [baseColour setSemantic:MDLMaterialSemanticBaseColor];
    [baseColour setType:MDLMaterialPropertyTypeTexture];
    [baseColour setURLValue:materialURL];
    //    [baseColour setType:MDLMaterialPropertyTypeColor];
    //    [baseColour setColor:UIColor.orangeColor.CGColor];
    [material setProperty:baseColour];

    vector_float3 minBounds = simd_make_float3(9999999);
    vector_float3 maxBounds = simd_make_float3(-9999999);
    for (MDLMesh *mesh in asset) {
        MDLAxisAlignedBoundingBox boundingBox = mesh.boundingBox;
        minBounds = simd_min(minBounds, boundingBox.minBounds);
        maxBounds = simd_max(maxBounds, boundingBox.maxBounds);
        for (MDLSubmesh *submesh in mesh.submeshes) {
            submesh.material = material;
//            for (MDLMaterialProperty *property in submesh.material) {
//                NSLog(@"%@", property.name);
//                if (property.semantic == MDLMaterialSemanticBaseColor) {
//                    NSLog(@"url: %@", property.URLValue);
//                }
//            }
        }
    }

    vector_float3 aabbCenter = (maxBounds + minBounds) * 0.5;
    NSLog(@"minBounds: %f %f %f", minBounds.x, minBounds.y, minBounds.z);
    NSLog(@"maxBounds: %f %f %f", maxBounds.x, maxBounds.y, maxBounds.z);
    NSLog(@"aabbCenter: %f %f %f", aabbCenter.x, aabbCenter.y, aabbCenter.z);

    vector_float3 diff = maxBounds - minBounds;
    float max = diff.x;
    if (diff.y > max) {
        max = diff.y;
    }
    if (diff.z > max) {
        max = diff.z;
    }

    float scale = 0.5 / max;

    SCNScene *scene = [SCNScene sceneWithMDLAsset:asset];
    //    SCNScene *scene = [SCNScene sceneNamed:@"untitled.obj"];
    SCNNode *cameraNode = [SCNNode new];
    SCNCamera *camera = [SCNCamera new];
    self.cameraNode = cameraNode;
    self.camera = camera;
    camera.automaticallyAdjustsZRange = YES;
    NSLog(@"camera: %@", camera);
    camera.zNear = 0.1;
    camera.zFar = 100;
    camera.fieldOfView = 60;
    cameraNode.camera = camera;
    cameraNode.position = SCNVector3Make(0, 0, 0);
    cameraNode.constraints = @[[SCNLookAtConstraint lookAtConstraintWithTarget:scene.rootNode]];
    [scene.rootNode addChildNode:cameraNode];

    do {
        Camera camera(glm::vec3(0.0f, 0.0f, 0.0f));
        camera.Zoom = 60;
        float aspect = CGRectGetWidth(self.sceneView.frame) / CGRectGetHeight(self.sceneView.frame);
        const struct Frustum frustum = createFrustumFromCamera(camera,
                                                               aspect,
                                                               glm::radians(camera.Zoom),
                                                               0.1,
                                                               100);

        float distance = frustum.nearFace.getSignedDistanceToPlan(glm::vec3(aabbCenter.x, aabbCenter.y, aabbCenter.z));

        //        scene.rootNode.childNodes.firstObject.transform = SCNMatrix4MakeScale(distance,distance,distance);
        //                cameraNode.transform = SCNMatrix4MakeTranslation(0, 0, distance);
        NSLog(@"distance: %f", distance);
    } while (0);

    SCNNode *lightNode = [SCNNode new];
    lightNode.light = [SCNLight new];
    lightNode.light.type = SCNLightTypeOmni;
    lightNode.position = SCNVector3Make(0, 10, 10);
    //    [scene.rootNode addChildNode:lightNode];

    SCNNode *ambientLightNode = [SCNNode new];
    ambientLightNode.light = [SCNLight new];
    ambientLightNode.light.type = SCNLightTypeAmbient;
    ambientLightNode.light.color = UIColor.whiteColor;
    ambientLightNode.position = SCNVector3Make(10, 10, 10);
    //    [scene.rootNode addChildNode:ambientLightNode];

    self.sceneView.allowsCameraControl = YES;
    self.sceneView.backgroundColor = UIColor.darkGrayColor;
    self.sceneView.cameraControlConfiguration.allowsTranslation = NO;
    self.sceneView.showsStatistics = YES;
    self.sceneView.scene = scene;

    SCNNode *rootNode = scene.rootNode;
    SCNMatrix4 scaleMatrix = SCNMatrix4MakeScale(scale, scale, scale);
    SCNMatrix4 transMatrix = SCNMatrix4MakeTranslation(-aabbCenter.x, -aabbCenter.y, -aabbCenter.z);
    self.fixTransform = SCNMatrix4Mult(scaleMatrix, transMatrix);
    //    self.fixTransform = SCNMatrix4MakeRotation(M_PI_2, 0, -1, 0);
    self.fixTransform = SCNMatrix4Identity;
    rootNode.childNodes.firstObject.transform = self.fixTransform;
    SCNCameraController *cameraController = self.sceneView.defaultCameraController;
    Method m = class_getInstanceMethod(cameraController.class, @selector(frameNodes:));
    IMP imp = method_getImplementation(m);
    NSLog(@"%p", imp);
    [cameraController frameNodes:@[rootNode]];

    self.initParameters = (ObjInitialParameters){
        .transform = self.sceneView.pointOfView.transform,
        .position = self.sceneView.pointOfView.position,
        .cameraFieldOfView = self.sceneView.pointOfView.camera.fieldOfView,
    };

    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
    [self.displayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSDefaultRunLoopMode];
    self.displayLink.paused = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)startButtonAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.displayLink.paused = !sender.selected;
}

- (void)resetButtonAction:(UIButton *)sender {
    self.rotation = 0;
    //    SCNNode *rootNode = self.sceneView.scene.rootNode.childNodes.firstObject;
    //    rootNode.transform = SCNMatrix4Identity;
#if 1
    self.sceneView.pointOfView.transform = self.initParameters.transform;
    self.sceneView.pointOfView.position = self.initParameters.position;
    self.sceneView.pointOfView.camera.fieldOfView = self.initParameters.cameraFieldOfView;
#else
    /* 私有API
     * allowsCameraControl = YES 后,双击手势会被启用
     * 在双击手势中会调用 SCNView 的 switchToNextCamera
     */
    SCNCameraController *cameraController = self.sceneView.defaultCameraController;
    NSLog(@"switch begin camera: %@", cameraController.pointOfView.camera);
    [self.sceneView performSelector:@selector(switchToNextCamera)];
    NSLog(@"switch end camera: %@", cameraController.pointOfView.camera);
#endif
}

- (void)update {

    self.rotation += 0.2;

    SCNNode *rootNode = self.sceneView.scene.rootNode.childNodes.firstObject;
    rootNode.transform = SCNMatrix4Rotate(self.fixTransform, GLKMathDegreesToRadians(self.rotation), 0, 1.0, 0);
}

#pragma mark - MDLAssetResolver
- (BOOL)canResolveAssetNamed:(NSString *)name {
    return YES;
}

- (NSURL *)resolveAssetNamed:(NSString *)name {
    NSURL *url = [[NSBundle mainBundle] URLForResource:name withExtension:nil];
    return url;
}

@end

