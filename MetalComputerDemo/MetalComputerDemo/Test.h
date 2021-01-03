//
//  Test.h
//  MetalComputerDemo
//
//  Created by king on 2021/1/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


typedef struct {
    uint8 data[2][2];
} DataGroupBuffer;

typedef struct {
    uint8 data[16][16];
} DataBuffer;

@interface Test : NSObject

@end

NS_ASSUME_NONNULL_END
