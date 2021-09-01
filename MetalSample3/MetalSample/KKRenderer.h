//
//  KKRenderer.h
//  MetalSample3
//
//  Created by king on 2021/9/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MTKView;
@protocol MTKViewDelegate;

@interface KKRenderer : NSObject <MTKViewDelegate>
- (instancetype)initWithView:(MTKView *)view;
@end

NS_ASSUME_NONNULL_END

