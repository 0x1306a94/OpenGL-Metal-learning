//
//  ViewController.m
//  MetalSample
//
//  Created by king on 2020/10/13.
//

#import "ViewController.h"

#import "KKRenderer.h"
#import "ShaderTypes.h"
#import "Util.h"

#import <MetalKit/MetalKit.h>

@interface ViewController ()
@property (nonatomic, weak) IBOutlet MTKView *metalView;
@property (nonatomic, strong) KKRenderer *renderer;
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
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

    self.metalView.device = MTLCreateSystemDefaultDevice();

    self.renderer = [[KKRenderer alloc] initWithView:self.metalView];
    self.metalView.clearColor = MTLClearColorMake(1, 1, 1, 1);
    self.metalView.delegate = self.renderer;
}
@end

