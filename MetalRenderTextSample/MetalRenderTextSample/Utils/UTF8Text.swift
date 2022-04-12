//
//  UTF8Text.swift
//  MetalRenderTextSample
//
//  Created by king on 2022/4/12.
//

import Foundation
/*
 int UTF8TextCount(const char *str);

 int32_t UTF8TextNextChar(const char **ptr);
 */

@_silgen_name("UTF8TextCount")
func uft8_text_count(ptr: UnsafePointer<Int8>) -> Int

@_silgen_name("UTF8TextNextChar")
func uft8_text_next_char(ptr: UnsafeMutablePointer<UnsafePointer<Int8>>) -> Int32
