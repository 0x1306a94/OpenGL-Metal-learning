//
//  AssetReader.h
//  MetalCamera
//
//  Created by king on 2020/9/11.
//  Copyright © 2020 0x1306a94. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreMedia/CMSampleBuffer.h>

NS_ASSUME_NONNULL_BEGIN

@interface AssetReader : NSObject
- (instancetype)initWithURL:(NSURL *)url;
- (CMSampleBufferRef)readBuffer;
@end

NS_ASSUME_NONNULL_END

