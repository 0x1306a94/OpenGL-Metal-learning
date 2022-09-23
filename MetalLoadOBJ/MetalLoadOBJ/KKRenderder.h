//
//  KKRenderder.h
//  MetalLoadOBJ
//
//  Created by king on 2022/9/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class MTKView;
@interface KKRenderder : NSObject
- (instancetype)initWithMtkView:(MTKView *)mtkView;
@end

NS_ASSUME_NONNULL_END

