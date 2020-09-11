//
//  AssetReader.m
//  MetalCamera
//
//  Created by king on 2020/9/11.
//  Copyright © 2020 0x1306a94. All rights reserved.
//

#import "AssetReader.h"

#import <AVFoundation/AVFoundation.h>

@interface AssetReader ()
@property (nonatomic, strong) AVAssetReaderTrackOutput *output;
@property (nonatomic, strong) AVAssetReader *reader;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, strong) AVURLAsset *asset;
@end

@implementation AssetReader
- (instancetype)initWithURL:(NSURL *)url {
	if (self == [super init]) {
		self.lock  = [[NSLock alloc] init];
		self.url   = url;
		self.asset = [[AVURLAsset alloc] initWithURL:url options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @YES}];

		/* clang-format off */
		[self.asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
			dispatch_async(dispatch_get_global_queue(0, 0), ^{
				if ([self.asset statusOfValueForKey:@"tracks" error:nil] == AVKeyValueStatusLoaded) {
					[self process];
				}
			});
		}];
		/* clang-format on */
	}
	return self;
}

- (void)process {
	[self.lock lock];
	NSError *error = nil;
	self.reader    = [AVAssetReader assetReaderWithAsset:self.asset error:&error];
	if (error) {
		NSLog(@"%@", error);
		[self.lock unlock];
		return;
	}

	AVAssetTrack *track = [self.asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
	if (!track) {
		NSLog(@"%@", @"视频文件没有视频轨道");
		[self.lock unlock];
		return;
	}

	NSDictionary<NSString *, NSNumber *> *outputSettings = @{
		(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange),
	};
	self.output                        = [[AVAssetReaderTrackOutput alloc] initWithTrack:track outputSettings:outputSettings];
	self.output.alwaysCopiesSampleData = NO;
	[self.reader addOutput:self.output];
	if ([self.reader startReading] == NO) {
		NSLog(@"AVAssetReaderTrackOutput startReading error: %@", self.reader.error);
	}
	[self.lock unlock];
}

- (CMSampleBufferRef)readBuffer {
	CMSampleBufferRef sampleBufferRef = NULL;
	if (self.reader && self.output) {
		sampleBufferRef = [self.output copyNextSampleBuffer];
		if (self.reader.status == AVAssetReaderStatusCompleted) {
			self.reader = nil;
			self.output = nil;
			[self process];
		}
	}
	return sampleBufferRef;
}

- (void)dealloc {
	[self.reader cancelReading];
}
@end

