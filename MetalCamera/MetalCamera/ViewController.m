//
//  ViewController.m
//  MetalCamera
//
//  Created by king on 2020/9/11.
//  Copyright © 2020 0x1306a94. All rights reserved.
//

#import "MetalCameraViewController.h"
#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (IBAction)buttonAction:(UIButton *)sender {
	MetalCameraViewController *vc = [[MetalCameraViewController alloc] init];
	[self presentViewController:vc animated:YES completion:nil];
}

@end

