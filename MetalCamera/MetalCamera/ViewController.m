//
//  ViewController.m
//  MetalCamera
//
//  Created by king on 2020/9/11.
//  Copyright © 2020 0x1306a94. All rights reserved.
//

#import "MetalCameraViewController.h"
#import "ViewController.h"

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

//N形
static void genMTLTextureCoordinates(CGRect rect, CGSize containerSize, float coordinates[8], BOOL reverse, NSInteger degree) {

	//degree预留字段，支持旋转纹理
	if (coordinates == NULL) {
		NSLog(@"generateMTLTextureCoordinates params coordinates illegal.");
		assert(0);
		return;
	}
	if (containerSize.width <= 0 || containerSize.height <= 0) {
		NSLog(@"generateMTLTextureCoordinates params containerSize illegal.");
		assert(0);
		return;
	}
	float originX, originY, width, height;
	originX = rect.origin.x / containerSize.width;
	originY = rect.origin.y / containerSize.height;
	width   = rect.size.width / containerSize.width;
	height  = rect.size.height / containerSize.height;

	if (reverse) {
		float tempCoordintes[] = {originX, originY, originX, originY + height, originX + width, originY, originX + width, originY + height};
		replaceArrayElements(coordinates, tempCoordintes, 8);
		return;
	}
	float tempCoordintes[] = {originX, originY + height, originX, originY, originX + width, originY + height, originX + width, originY};
	replaceArrayElements(coordinates, tempCoordintes, 8);
}
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view.

	CGSize viewportSize = CGSizeMake(1280, 720);
	CGRect renderRect   = CGRectMake(100, 100, 300, 300);
	CGRect maskRect     = CGRectMake(100, 100, 100, 100);
	float vertices[16], maskCoordinates[8], sourceCoordinates[8];
	genMTLVertices(renderRect, viewportSize, vertices, NO);
	genMTLTextureCoordinates(maskRect, viewportSize, maskCoordinates, YES, 0);
	replaceArrayElements(sourceCoordinates, (void *)kMTLTextureCoordinatesIdentity, 8);

	NSLog(@"顶点坐标");
	for (int i = 0; i < 16; i += 4) {
		NSLog(@"%f %f %f %f", vertices[i], vertices[i + 1], vertices[i + 2], vertices[i + 3]);
	}

	NSLog(@"背景纹理坐标");
	for (int i = 0; i < 8; i += 2) {
		NSLog(@"%f %f", sourceCoordinates[i], sourceCoordinates[i + 1]);
	}

	NSLog(@"遮罩纹理坐标");
	for (int i = 0; i < 8; i += 2) {
		NSLog(@"%f %f", maskCoordinates[i], maskCoordinates[i + 1]);
	}
}

- (IBAction)buttonAction:(UIButton *)sender {
	MetalCameraViewController *vc = [[MetalCameraViewController alloc] init];
	[self presentViewController:vc animated:YES completion:nil];
}

@end

