//
//  UTF8Text.c
//  MetalRenderTextSample
//
//  Created by king on 2022/4/12.
//

#include "UTF8Text.h"

#include <string.h>

int UTF8TextCount(const char *str) {
    if (str == NULL) {
        return -1;
    }
    size_t len = strlen(str);

    int count = 0;
    const char *start = &(str[0]);
    const char *stop = start + len;
    while (start < stop) {
        UTF8TextNextChar(&start);
        ++count;
    }
    return count;
}

static inline int32_t LeftShift(int32_t value) {
    return (int32_t)(((uint32_t)value) << 1);
}

int32_t UTF8TextNextChar(const char **ptr) {
    const uint8_t *p = (const uint8_t *)*ptr;
    int c = *p;
    int hic = c << 24;
    if (hic < 0) {
        uint32_t mask = (~0x3F);
        hic = LeftShift(hic);
        do {
            c = (c << 6) | (*++p & 0x3F);
            mask <<= 5;
        } while ((hic = LeftShift(hic)) < 0);
        c &= ~mask;
    }
    *ptr = ((const char *)((const void *)(p + 1)));
    return c;
}

