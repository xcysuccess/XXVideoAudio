//
//  XXImageTool.m
//  XXAudioVideo
//
//  Created by tomxiang on 2017/9/15.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import "XXImageTool.h"

@implementation XXImageTool

+ (void) printPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    size_t length = CVPixelBufferGetDataSize(pixelBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
    unsigned char *imageData = (unsigned char *)malloc(length);
    memcpy(imageData, baseAddress, length);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CFDataRef data = CFDataCreate(NULL, imageData, length);
    NSLog(@"%@",data);
    free(imageData);
    CFRelease(data);
}


+ (void) writePixelBufferToLocalFile:(CVPixelBufferRef)pixelBuffer {
    size_t length = CVPixelBufferGetDataSize(pixelBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
    unsigned char *imageData = (unsigned char *)malloc(length);
    memcpy(imageData, baseAddress, length);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CFDataRef dataCF = CFDataCreate(NULL, imageData, length);
    NSData* dataNS = (__bridge_transfer NSData*) dataCF;
    
    //写文件
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *savePath = [documentsDirectory stringByAppendingPathComponent:@"ImageData.data"];
    [fileManager removeItemAtPath:savePath error:nil];
    [fileManager createFileAtPath:savePath contents:nil attributes:nil];
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:savePath];
    NSLog(@"%@",dataNS);
    [fileHandle writeData:dataNS];

    free(imageData);
}


@end
