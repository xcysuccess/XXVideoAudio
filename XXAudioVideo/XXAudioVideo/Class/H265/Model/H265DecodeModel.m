//
//  H265DecodeModel.m
//  XXAudioVideo
//
//  Created by tomxiang on 2017/12/4.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import "H265DecodeModel.h"

@implementation H265DecodeModel

-(void)dealloc{
    CFRelease(_pixelBuffer);
}

-(void)setPixelBuffer:(CVImageBufferRef)pixelBuffer{
    if(_pixelBuffer){
        CFRelease(_pixelBuffer);
        _pixelBuffer = NULL;
    }
    _pixelBuffer = CFRetain(pixelBuffer);
}
@end
