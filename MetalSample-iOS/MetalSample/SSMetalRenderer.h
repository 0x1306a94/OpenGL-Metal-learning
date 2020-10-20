//
//  SSMetalRenderer.h
//  MetalSample
//
//  Created by king on 2020/10/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MTLDevice;
@protocol MTKViewDelegate;

@interface SSMetalRenderer : NSObject <MTKViewDelegate>
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithDevice:(id<MTLDevice>)device NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END

