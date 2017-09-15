//
//  XXImageTool.h
//  XXAudioVideo
//
//  Created by tomxiang on 2017/9/15.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

@interface XXImageTool : NSObject


/**
 打印CVPixBuffer原始数据

 @param pixelBuffer RGB/YUV数据
 */
+ (void) printPixelBuffer:(CVPixelBufferRef)pixelBuffer;

/**
 写入PixBuffer到本地文件

 @param pixelBuffer RGB/YUV数据
 */
+ (void) writePixelBufferToLocalFile:(CVPixelBufferRef)pixelBuffer;

@end
