//
//  UTF8Text.h
//  MetalRenderTextSample
//
//  Created by king on 2022/4/12.
//

#ifndef UTF8Text_h
#define UTF8Text_h

#include <stdio.h>

int UTF8TextCount(const char *str);

int32_t UTF8TextNextChar(const char **ptr);
#endif /* UTF8Text_h */

