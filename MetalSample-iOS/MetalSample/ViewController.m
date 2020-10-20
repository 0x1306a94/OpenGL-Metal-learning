//
//  ViewController.m
//  MetalSample
//
//  Created by king on 2020/10/19.
//

#import "ViewController.h"

#import "SSMetalRenderer.h"
#import "SSUtil.h"

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
@interface ViewController ()
@property (nonatomic, strong) MTKView *metalView;
@property (nonatomic, strong) SSMetalRenderer *renderer;
@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view.

	self.metalView                  = [[MTKView alloc] init];
	self.metalView.device           = MTLCreateSystemDefaultDevice();
	self.metalView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
	self.metalView.framebufferOnly  = NO;

	[self.view addSubview:self.metalView];
	self.metalView.translatesAutoresizingMaskIntoConstraints = NO;
	[NSLayoutConstraint activateConstraints:@[
		[self.metalView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
		[self.metalView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
		[self.metalView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
		[self.metalView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
	]];

	self.renderer           = [[SSMetalRenderer alloc] initWithDevice:self.metalView.device];
	self.metalView.delegate = self.renderer;

	CGRect rect        = CGRectMake((UIScreen.mainScreen.bounds.size.width - 200) * 0.5, 400, 200, 300);
	UIView *v1         = [[UIView alloc] initWithFrame:rect];
	v1.backgroundColor = UIColor.orangeColor;

	CGPoint p0 = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
	CGPoint p1 = rect.origin;
	CGPoint p2 = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
	CGPoint p3 = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));
	NSLog(@"p0: %@", NSStringFromCGPoint(p0));
	NSLog(@"p1: %@", NSStringFromCGPoint(p1));
	NSLog(@"p2: %@", NSStringFromCGPoint(p2));
	NSLog(@"p3: %@", NSStringFromCGPoint(p3));
	NSLog(@"rect: %@", NSStringFromCGRect(rect));
	CGPoint c = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));

	CGPointRotation t = CGPointMakeRotation(c, -15);

	p0 = CGPointToRotation(p0, t);
	p1 = CGPointToRotation(p1, t);
	p2 = CGPointToRotation(p2, t);
	p3 = CGPointToRotation(p3, t);

	NSLog(@"p0: %@", NSStringFromCGPoint(p0));
	NSLog(@"p1: %@", NSStringFromCGPoint(p1));
	NSLog(@"p2: %@", NSStringFromCGPoint(p2));
	NSLog(@"p3: %@", NSStringFromCGPoint(p3));

	rect = CGPointsToCGRect(p0, p1, p2, p3);
	NSLog(@"rect: %@", NSStringFromCGRect(rect));

	UIView *v2         = [[UIView alloc] initWithFrame:rect];
	v2.backgroundColor = UIColor.purpleColor;

	[self.view addSubview:v2];
	[self.view addSubview:v1];
}

@end

