//
//  ViewController.m
//  MetalSample
//
//  Created by king on 2020/10/13.
//

#import "MetalView.h"
#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	// Do any additional setup after loading the view.
}

- (void)viewDidAppear {
	[super viewDidAppear];

	[((MetalView *)self.view) startDrawing];
}

@end

