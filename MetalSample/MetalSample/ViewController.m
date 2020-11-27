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

- (void)viewWillAppear {
	[super viewWillAppear];
	[self.view.window setFrame:NSMakeRect(0, 0, 360, 640) display:YES];
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.view.window center];
	});
}

- (void)viewDidAppear {
	[super viewDidAppear];

	self.view.window.movableByWindowBackground = YES;

	[((MetalView *)self.view) startDrawing];
}

@end

